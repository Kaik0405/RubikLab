:- module(server, [start/0, start/1, solve_response/2, method_response/3]).

:- use_module(library(http/thread_httpd), [http_server/2]).
:- use_module(library(http/http_dispatch), [
    http_dispatch/1,
    http_handler/3
]).
:- use_module(library(http/http_json), [reply_json_dict/1]).
:- use_module(library(http/http_parameters), [http_parameters/2]).
:- use_module(library(http/http_files), [http_reply_from_files/3]).
:- use_module(library(apply), [maplist/2, maplist/3]).
:- use_module(library(lists), [sum_list/2, memberchk/2]).
:- use_module(cube, [move/1, solved/1, apply_sequence/3]).
:- use_module(moves, [random_scramble/2]).
:- use_module(facelets, [state_to_facelets/2, facelets_to_state/2]).
:- use_module(validation, [legal/1, illegal_reason/2]).
:- use_module(thistle, []).
:- use_module(cfop, []).
:- use_module(explainer, [explain/3]).
:- use_module(benchmark, [benchmark/3, benchmark_summary/2]).

/** <module> Servidor HTTP de RubikLab.

Expone la API JSON para mezclas, estados, validacion, resolucion y
benchmark, y sirve la carpeta web/.
*/

:- http_handler(root(api/scramble), api_scramble, [method(get)]).
:- http_handler(root(api/state), api_state, [method(get)]).
:- http_handler(root(api/validate), api_validate, [method(get)]).
:- http_handler(root(api/solve), api_solve, [method(get)]).
:- http_handler(root(api/compare), api_compare, [method(get)]).
:- http_handler(root(api/benchmark), api_benchmark, [method(get)]).
:- http_handler(root(.), static_files, [prefix]).

%% start is det.
% Inicia el servidor en el puerto predeterminado.
start :-
    start(8080).

%% start(+Port) is det.
% Precalienta ambos solvers antes de aceptar peticiones.
start(Port) :-
    prewarm_solver,
    http_server(http_dispatch, [port(Port)]).

%% prewarm_solver is det.
% Resuelve el estado resuelto con ambos metodos para construir sus tablas.
prewarm_solver :-
    solved(State),
    thistle:solve(State, _, _),
    cfop:solve_cfop(State, _, _).

%% api_scramble(+Request) is det.
% Devuelve una mezcla aleatoria del tamano solicitado.
api_scramble(Request) :-
    http_parameters(Request, [
        n(Length, [optional(true), default(25), integer])
    ]),
    valid_scramble_length(Length),
    random_scramble(Length, Moves),
    maplist(atom_string, Moves, MoveStrings),
    reply_json_dict(_{moves: MoveStrings}).

%% api_state(+Request) is det.
% Aplica los movimientos recibidos y devuelve los facelets y su legalidad.
api_state(Request) :-
    http_parameters(Request, [
        moves(MoveText, [optional(true), default(''), atom])
    ]),
    parse_moves(MoveText, Moves),
    solved(Solved),
    apply_sequence(Moves, Solved, State),
    state_to_facelets(State, Facelets),
    (   legal(State)
    ->  Legal = true
    ;   Legal = false
    ),
    reply_json_dict(_{facelets: Facelets, legal: Legal}).

%% api_validate(+Request) is det.
% Valida los facelets recibidos y devuelve el motivo si son ilegales.
api_validate(Request) :-
    http_parameters(Request, [
        facelets(Facelets, [atom])
    ]),
    (   facelets_to_state(Facelets, State)
    ->  validate_state(State)
    ;   reply_json_dict(_{valid: false, reason: invalid_facelets})
    ).

%% api_solve(+Request) is det.
% Resuelve una mezcla con el metodo indicado.
api_solve(Request) :-
    http_parameters(Request, [
        method(MethodText, [optional(true), default('thistle'), atom]),
        moves(MoveText, [optional(true), default(''), atom])
    ]),
    parse_method(MethodText, Method),
    parse_moves(MoveText, Moves),
    state_from_moves(Moves, State),
    reply_method_state(State, Method).

%% api_compare(+Request) is det.
% Resuelve el mismo estado con Thistlethwaite y CFOP.
api_compare(Request) :-
    http_parameters(Request, [
        moves(MoveText, [optional(true), default(''), atom])
    ]),
    parse_moves(MoveText, Moves),
    state_from_moves(Moves, State),
    (   legal(State)
    ->  method_response(thistle, State, Thistle),
        method_response(cfop, State, Cfop),
        reply_json_dict(_{thistle: Thistle, cfop: Cfop})
    ;   illegal_response(State)
    ).

%% api_benchmark(+Request) is det.
% Ejecuta el benchmark con un maximo de veinte mezclas.
api_benchmark(Request) :-
    http_parameters(Request, [
        n(N, [optional(true), default(10), integer]),
        seed(Seed, [optional(true), default(42), integer])
    ]),
    valid_benchmark_size(N),
    benchmark(N, Seed, Rows),
    benchmark_summary(Rows, Summaries),
    maplist(row_dict, Rows, RowDicts),
    maplist(summary_dict, Summaries, SummaryDicts),
    reply_json_dict(_{rows: RowDicts, summary: SummaryDicts}).

%% solve_response(+Moves, -Dict) is semidet.
% Aplica una secuencia y construye la respuesta tradicional del solver.
solve_response(Moves, Dict) :-
    is_list(Moves),
    state_from_moves(Moves, State),
    solve_response_state(State, Dict).

solve_response(State, Dict) :-
    State = state(_, _, _, _),
    (   legal(State)
    ->  solve_response_state(State, Dict)
    ;   illegal_reason(State, Reason),
        Dict = _{error: "illegal_state", reason: Reason}
    ).

%% reply_method_state(+State, +Method) is det.
% Responde con error 422 o con el resultado del metodo solicitado.
reply_method_state(State, Method) :-
    (   legal(State)
    ->  method_response(Method, State, Dict),
        reply_json_dict(Dict)
    ;   illegal_response(State)
    ).

%% illegal_response(+State) is failure.
% Genera la respuesta HTTP para un estado ilegal.
illegal_response(State) :-
    illegal_reason(State, Reason),
    throw(http_reply(status(422, json(_{error: "illegal_state",
                                         reason: Reason})))).

%% state_from_moves(+Moves, -State) is det.
% Construye un estado desde una lista de movimientos validos.
state_from_moves(Moves, State) :-
    solved(Solved),
    apply_sequence(Moves, Solved, State).

%% solve_response_state(+State, -Dict) is semidet.
% Construye la respuesta tradicional de Thistlethwaite.
solve_response_state(State, _{reached: "solved",
                              total_moves: TotalMoves,
                              nodes: TotalNodes,
                              seconds: TotalSeconds,
                              phases: PhaseDicts}) :-
    legal(State),
    thistle:solve(State, Phases, stats(TotalNodes, TotalSeconds)),
    maplist(phase_dict, Phases, PhaseDicts),
    maplist(phase_moves, Phases, PhaseMoves),
    maplist(length, PhaseMoves, Lengths),
    sum_list(Lengths, TotalMoves).

%% method_response(+Method, +State, -Dict) is semidet.
% Une fases del solver y pasos del explicador por posicion.
method_response(Method, State, _{method: Method,
                                 total_moves: TotalMoves,
                                 nodes: TotalNodes,
                                 seconds: TotalSeconds,
                                 steps: StepDicts}) :-
    method_solve(Method, State, Phases, stats(TotalNodes, TotalSeconds)),
    explain(Method, State, Steps),
    maplist(phase_moves, Phases, PhaseMoves),
    maplist(length, PhaseMoves, Lengths),
    sum_list(Lengths, TotalMoves),
    maplist(combine_step, Phases, Steps, StepDicts).

%% method_solve(+Method, +State, -Phases, -Stats) is semidet.
% Selecciona el solver indicado.
method_solve(thistle, State, Phases, Stats) :-
    thistle:solve(State, Phases, Stats).
method_solve(cfop, State, Phases, Stats) :-
    cfop:solve_cfop(State, Phases, Stats).

%% combine_step(+Phase, +Step, -Dict) is det.
% Combina metadatos de una fase con la regla explicada en la misma posicion.
combine_step(phase(Id, Stage, Moves, stats(Nodes, Seconds)),
             paso(_, Stage, Rule, Moves),
             _{id: Id, stage: Stage, rule: Rule, moves: Moves,
               nodes: Nodes, seconds: Seconds}).

%% phase_dict(+Phase, -Dict) is det.
% Convierte una fase del solver al formato JSON tradicional.
phase_dict(phase(Id, Name, Moves, stats(Nodes, Seconds)),
           _{id: Id, name: Name, moves: Moves, nodes: Nodes, seconds: Seconds}).

%% phase_moves(+Phase, -Moves) is det.
% Extrae los movimientos de una fase.
phase_moves(phase(_, _, Moves, _), Moves).

%% parse_method(+Text, -Method) is semidet.
% Valida el metodo solicitado.
parse_method(Text, Method) :-
    atom(Text),
    memberchk(Text, [thistle, cfop]),
    Method = Text,
    !.
parse_method(_, _) :-
    throw(http_reply(bad_request('Unknown method'))).

%% parse_moves(+Text, -Moves) is semidet.
% Convierte movimientos separados por comas y valida cada uno.
parse_moves('', []) :-
    !.
parse_moves(Text, Moves) :-
    split_string(Text, ',', ' \t', MoveStrings),
    MoveStrings \= [''],
    maplist(atom_string, Moves, MoveStrings),
    maplist(valid_move, Moves).

%% valid_move(+Move) is semidet.
% Comprueba que un movimiento exista y responde 400 si no existe.
valid_move(Move) :-
    move(Move),
    !.
valid_move(_) :-
    throw(http_reply(bad_request('Unknown move'))).

%% valid_scramble_length(+Length) is semidet.
% Comprueba que la longitud de la mezcla sea no negativa.
valid_scramble_length(Length) :-
    integer(Length),
    Length >= 0,
    !.
valid_scramble_length(_) :-
    throw(http_reply(bad_request('Invalid scramble length'))).

%% valid_benchmark_size(+Length) is semidet.
% Comprueba que el benchmark no exceda veinte filas por metodo.
valid_benchmark_size(Length) :-
    integer(Length),
    Length >= 0,
    Length =< 20,
    !.
valid_benchmark_size(_) :-
    throw(http_reply(bad_request('Invalid benchmark size'))).

%% row_dict(+Row, -Dict) is det.
% Convierte una fila de benchmark a JSON.
row_dict(row(Index, Method, Moves, Nodes, Seconds),
         _{index: Index, method: Method, moves: Moves,
           nodes: Nodes, seconds: Seconds}).

%% summary_dict(+Summary, -Dict) is det.
% Convierte un resumen de benchmark a JSON.
summary_dict(summary(Method, Count, MeanMoves, MinMoves, MaxMoves,
                     MeanNodes, MeanSeconds, MaxSeconds),
             _{method: Method, count: Count, mean_moves: MeanMoves,
               min_moves: MinMoves, max_moves: MaxMoves,
               mean_nodes: MeanNodes, mean_seconds: MeanSeconds,
               max_seconds: MaxSeconds}).

%% validate_state(+State) is det.
% Genera la respuesta JSON para un estado ya decodificado.
validate_state(State) :-
    (   legal(State)
    ->  reply_json_dict(_{valid: true})
    ;   illegal_reason(State, Reason),
        reply_json_dict(_{valid: false, reason: Reason})
    ).

%% static_files(+Request) is det.
% Sirve los archivos estaticos de la carpeta web.
static_files(Request) :-
    web_directory(Directory),
    http_reply_from_files(Directory, [], Request).

%% web_directory(-Directory) is det.
% Resuelve la carpeta web relativa a la raiz del proyecto.
web_directory(Directory) :-
    source_file(server:start, ServerFile),
    file_directory_name(ServerFile, PrologDirectory),
    directory_file_path(PrologDirectory, '..', ProjectDirectory),
    absolute_file_name(ProjectDirectory, RootDirectory,
                       [file_type(directory)]),
    directory_file_path(RootDirectory, web, Directory).
