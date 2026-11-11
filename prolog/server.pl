:- module(server, [start/0, start/1]).

:- use_module(library(http/thread_httpd), [http_server/2]).
:- use_module(library(http/http_dispatch), [
    http_dispatch/1,
    http_handler/3
]).
:- use_module(library(http/http_json), [reply_json_dict/1]).
:- use_module(library(http/http_parameters), [http_parameters/2]).
:- use_module(library(http/http_files), [http_reply_from_files/3]).
:- use_module(library(apply), [maplist/2]).
:- use_module(cube, [move/1, solved/1, apply_sequence/3]).
:- use_module(moves, [random_scramble/2]).
:- use_module(facelets, [state_to_facelets/2, facelets_to_state/2]).
:- use_module(validation, [legal/1, illegal_reason/2]).

/** <module> Servidor HTTP de RubikLab.

Expone la API JSON para mezclas, estados y validación, y sirve la carpeta
web/. Depende de cube.pl, moves.pl, facelets.pl y validation.pl.
*/

:- http_handler(root(api/scramble), api_scramble, [method(get)]).
:- http_handler(root(api/state), api_state, [method(get)]).
:- http_handler(root(api/validate), api_validate, [method(get)]).
:- http_handler(root(.), static_files, [prefix]).

%% start is det.
% Inicia el servidor en el puerto predeterminado.
start :-
    start(8080).

%% start(+Port) is det.
% Inicia el servidor en el puerto indicado.
start(Port) :-
    http_server(http_dispatch, [port(Port)]).

%% api_scramble(+Request) is det.
% Devuelve una mezcla aleatoria del tamaño solicitado.
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

%% validate_state(+State) is det.
% Genera la respuesta JSON para un estado ya decodificado.
validate_state(State) :-
    (   legal(State)
    ->  reply_json_dict(_{valid: true})
    ;   illegal_reason(State, Reason),
        reply_json_dict(_{valid: false, reason: Reason})
    ).

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

%% static_files(+Request) is det.
% Sirve los archivos estáticos de la carpeta web del proyecto.
static_files(Request) :-
    web_directory(Directory),
    http_reply_from_files(Directory, [], Request).

%% web_directory(-Directory) is det.
% Resuelve la carpeta web relativa a la raíz del proyecto.
web_directory(Directory) :-
    source_file(server:start, ServerFile),
    file_directory_name(ServerFile, PrologDirectory),
    directory_file_path(PrologDirectory, '..', ProjectDirectory),
    absolute_file_name(ProjectDirectory, RootDirectory,
                       [file_type(directory)]),
    directory_file_path(RootDirectory, web, Directory).
