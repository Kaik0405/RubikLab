:- module(cfop, [
    solve_cfop/3,
    solve_cross/3,
    cfop_tables/1,
    cross_goal/1,
    f2l_solved/1
]).

:- use_module(cube, [move/1, base_move/2, solved/1, apply_sequence/3]).
:- use_module(search, [ida_star/7]).
:- use_module(oll_pll, [solve_oll/3, solve_pll/3]).
:- use_module(library(assoc), [empty_assoc/1, get_assoc/3, put_assoc/4]).
:- use_module(library(lists), [nth0/3, select/3, member/2, append/3]).
:- use_module(library(apply), [maplist/4, foldl/4]).
:- use_module(library(aggregate), [aggregate_all/3]).

/** <module> Método CFOP: cruz, F2L, OLL y PLL.

Resuelve el cubo por etapas: cruz, los cuatro pares de F2L, OLL y PLL.
La cruz y cada par de F2L se buscan con IDA* de forma óptima por etapa. En
cada etapa de F2L se elige automáticamente el par que se puede resolver con
menos movimientos (el objetivo es "cualquier par restante resuelto"). OLL y PLL
se reconocen con el catálogo de oll_pll.pl.

Las heurísticas son tablas de distancias exactas de grupos pequeños de piezas
(cada una es una cota inferior admisible):
  - 6 tablas de pares de aristas de la cruz (528 estados cada una),
  - 4 tablas de pares esquina-arista de F2L (576 estados cada una),
  - 16 tablas de tríos arista de cruz + esquina + arista de F2L (12672 estados).
Se construyen por BFS la primera vez y se guardan en disco
(data/cfop.cache, binario y con número de versión).

solve_cfop/3 devuelve las fases con el mismo formato que thistle:solve/3:
phase(Id, Nombre, Movimientos, stats(Nodos, Segundos)).
Depende de cube.pl, search.pl y oll_pll.pl.
*/

:- dynamic edge_step/3.        % edge_step(Move, Code, NextCode)
:- dynamic corner_step/3.      % corner_step(Move, Code, NextCode)
:- dynamic steps_ready/0.
:- dynamic cfop_tables_cache/1.

%% ------------------------------------------------------------------
%% Datos del problema
%% ------------------------------------------------------------------

% Aristas de la cruz: 4 (DR), 5 (DF), 6 (DL), 7 (DB).
% f2l_pair(Indice, Esquina, Arista, Nombre): esquina DFR/DLF/DBL/DRB con su arista.
f2l_pair(1, 4, 8,  'FR').
f2l_pair(2, 5, 9,  'FL').
f2l_pair(3, 6, 10, 'BL').
f2l_pair(4, 7, 11, 'BR').

% cross_pair(IdTabla, ArC1, ArC2): pares de aristas de la cruz.
cross_pair(1, 4, 5).
cross_pair(2, 4, 6).
cross_pair(3, 4, 7).
cross_pair(4, 5, 6).
cross_pair(5, 5, 7).
cross_pair(6, 6, 7).

%% table_spec(?Id, ?Pieces) is nondet.
% Id 1..6: pares de la cruz. Id 7..10: pares de F2L (6 + indice de par).
% Id 11..26: tríos (arista de cruz X, esquina, arista), Id = 10 + (P-1)*4 + X.
table_spec(Id, [e(A), e(B)]) :-
    cross_pair(Id, A, B).
table_spec(Id, [c(Corner), e(Edge)]) :-
    f2l_pair(Pair, Corner, Edge, _),
    Id is 6 + Pair.
table_spec(Id, [e(CrossEdge), c(Corner), e(Edge)]) :-
    f2l_pair(Pair, Corner, Edge, _),
    between(1, 4, X),
    CrossEdge is X + 3,
    Id is 10 + (Pair - 1) * 4 + X.

%% ------------------------------------------------------------------
%% Transiciones de una sola pieza (códigos 0..23)
%% ------------------------------------------------------------------

% Arista: código = hueco*2 + orientación. Esquina: código = hueco*3 + orientación.

ensure_steps :-
    steps_ready,
    !.
ensure_steps :-
    with_mutex(cfop_steps, build_steps_once).

build_steps_once :-
    steps_ready,
    !.
build_steps_once :-
    forall(move(Move),
           ( base_move(Move, state(MCP, MCO, MEP, MEO)),
             forall(( between(0, 11, Slot), between(0, 1, Ori) ),
                    ( nth0(Next, MEP, Slot),
                      nth0(Next, MEO, Offset),
                      NextOri is (Ori + Offset) mod 2,
                      Code is Slot * 2 + Ori,
                      NextCode is Next * 2 + NextOri,
                      assertz(edge_step(Move, Code, NextCode)) )),
             forall(( between(0, 7, Slot), between(0, 2, Ori) ),
                    ( nth0(Next, MCP, Slot),
                      nth0(Next, MCO, Offset),
                      NextOri is (Ori + Offset) mod 3,
                      Code is Slot * 3 + Ori,
                      NextCode is Next * 3 + NextOri,
                      assertz(corner_step(Move, Code, NextCode)) ))
           )),
    assertz(steps_ready).

piece_step(Move, Kind, Code, NextCode) :-
    (   Kind == e
    ->  once(edge_step(Move, Code, NextCode))
    ;   once(corner_step(Move, Code, NextCode))
    ).

%% ------------------------------------------------------------------
%% Construcción de tablas por BFS
%% ------------------------------------------------------------------

%% build_piece_table(+Pieces, +Moves, -Table) is det.
% Tabla assoc Codigo-Distancia desde la posición resuelta de las piezas.
build_piece_table(Pieces, Moves, Table) :-
    ensure_steps,
    pieces_kinds_goal(Pieces, Kinds, Goal),
    codes_key(Goal, GoalKey),
    empty_assoc(Empty),
    put_assoc(GoalKey, Empty, 0, Table0),
    piece_levels(Moves, Kinds, 0, [Goal], Table0, Table).

pieces_kinds_goal([], [], []).
pieces_kinds_goal([Piece|Pieces], [Kind|Kinds], [Code|Codes]) :-
    (   Piece = e(Edge)
    ->  Kind = e,
        Code is Edge * 2
    ;   Piece = c(Corner),
        Kind = c,
        Code is Corner * 3
    ),
    pieces_kinds_goal(Pieces, Kinds, Codes).

codes_key(Codes, Key) :-
    foldl(accumulate_code, Codes, 0, Key).

accumulate_code(Code, Acc0, Acc) :-
    Acc is Acc0 * 24 + Code.

piece_levels(_, _, _, [], Table, Table) :-
    !.
piece_levels(Moves, Kinds, Depth, Frontier, Table0, Table) :-
    NextDepth is Depth + 1,
    expand_codes(Frontier, Moves, Kinds, NextDepth, Table0, Table1,
                 [], NextFrontier),
    piece_levels(Moves, Kinds, NextDepth, NextFrontier, Table1, Table).

expand_codes([], _, _, _, Table, Table, Next, Next).
expand_codes([Codes|Rest], Moves, Kinds, Depth, Table0, Table, Next0, Next) :-
    expand_moves(Moves, Kinds, Codes, Depth, Table0, Table1, Next0, Next1),
    expand_codes(Rest, Moves, Kinds, Depth, Table1, Table, Next1, Next).

expand_moves([], _, _, _, Table, Table, Next, Next).
expand_moves([Move|Moves], Kinds, Codes, Depth, Table0, Table, Next0, Next) :-
    maplist(piece_step(Move), Kinds, Codes, NextCodes),
    codes_key(NextCodes, Key),
    (   get_assoc(Key, Table0, _)
    ->  Table1 = Table0,
        Next1 = Next0
    ;   put_assoc(Key, Table0, Depth, Table1),
        Next1 = [NextCodes|Next0]
    ),
    expand_moves(Moves, Kinds, Codes, Depth, Table1, Table, Next1, Next).

%% cfop_tables(-Tables) is det.
% Término tables(T1,...,T26) con las 26 tablas. Orden: memoria, caché en disco,
% construcción por BFS (y se guarda en disco si tarda más de 5 segundos).
cfop_tables(Tables) :-
    cfop_tables_cache(Cached),
    !,
    Tables = Cached.
cfop_tables(Tables) :-
    load_or_build_tables(Built),
    assertz(cfop_tables_cache(Built)),
    Tables = Built.

load_or_build_tables(Tables) :-
    cfop_cache_file(File),
    exists_file(File),
    catch(read_cfop_cache(File, Tables), _, fail),
    !.
load_or_build_tables(Tables) :-
    statistics(cputime, Start),
    findall(Move, move(Move), Moves),
    findall(Id-Pieces, table_spec(Id, Pieces), Specs0),
    keysort(Specs0, Specs),
    findall(Table,
            ( member(_-Pieces, Specs), build_piece_table(Pieces, Moves, Table) ),
            Assocs),
    Tables =.. [tables|Assocs],
    statistics(cputime, End),
    Seconds is End - Start,
    (   Seconds > 5
    ->  ignore(catch(write_cfop_cache(Tables), _, true))
    ;   true
    ).

%% Caché en disco (data/cfop.cache, binario y con número de versión)

cfop_cache_version(1).

cfop_cache_file(File) :-
    module_property(cfop, file(CfopFile)),
    file_directory_name(CfopFile, PrologDirectory),
    file_directory_name(PrologDirectory, Root),
    atomic_list_concat([Root, '/data/cfop.cache'], File).

read_cfop_cache(File, Tables) :-
    setup_call_cleanup(
        open(File, read, Stream, [type(binary)]),
        fast_read(Stream, Term),
        close(Stream)),
    Term = cfop_cache(Version, Tables),
    cfop_cache_version(Version).

write_cfop_cache(Tables) :-
    cfop_cache_file(File),
    file_directory_name(File, Directory),
    (   exists_directory(Directory)
    ->  true
    ;   make_directory(Directory)
    ),
    cfop_cache_version(Version),
    setup_call_cleanup(
        open(File, write, Stream, [type(binary)]),
        fast_write(Stream, cfop_cache(Version, Tables)),
        close(Stream)).

%% ------------------------------------------------------------------
%% Códigos de piezas de un estado y comprobaciones de meta
%% ------------------------------------------------------------------

edge_code(EP, EO, Edge, Code) :-
    nth0(Slot, EP, Edge),
    !,
    nth0(Slot, EO, Orientation),
    Code is Slot * 2 + Orientation.

corner_code(CP, CO, Corner, Code) :-
    nth0(Slot, CP, Corner),
    !,
    nth0(Slot, CO, Orientation),
    Code is Slot * 3 + Orientation.

% Códigos de las aristas 4..11 (argumentos 1..8) y esquinas 4..7 (argumentos 9..12).
piece_codes(state(CP, CO, EP, EO),
            codes(E4, E5, E6, E7, E8, E9, E10, E11, C4, C5, C6, C7)) :-
    edge_code(EP, EO, 4, E4),   edge_code(EP, EO, 5, E5),
    edge_code(EP, EO, 6, E6),   edge_code(EP, EO, 7, E7),
    edge_code(EP, EO, 8, E8),   edge_code(EP, EO, 9, E9),
    edge_code(EP, EO, 10, E10), edge_code(EP, EO, 11, E11),
    corner_code(CP, CO, 4, C4), corner_code(CP, CO, 5, C5),
    corner_code(CP, CO, 6, C6), corner_code(CP, CO, 7, C7).

edge_arg(Edge, Codes, Code) :-
    Index is Edge - 3,
    arg(Index, Codes, Code).

corner_arg(Corner, Codes, Code) :-
    Index is Corner + 5,
    arg(Index, Codes, Code).

edge_home(EP, EO, Edge) :-
    nth0(Edge, EP, Edge),
    nth0(Edge, EO, 0).

corner_home(CP, CO, Corner) :-
    nth0(Corner, CP, Corner),
    nth0(Corner, CO, 0).

%% cross_goal(+State) is semidet.
% Las cuatro aristas de la cruz están en su sitio y orientadas.
cross_goal(state(_, _, EP, EO)) :-
    edge_home(EP, EO, 4),
    edge_home(EP, EO, 5),
    edge_home(EP, EO, 6),
    edge_home(EP, EO, 7).

pair_solved(state(CP, CO, EP, EO), Pair) :-
    f2l_pair(Pair, Corner, Edge, _),
    corner_home(CP, CO, Corner),
    edge_home(EP, EO, Edge).

%% f2l_solved(+State) is semidet.
% Cruz y los cuatro pares de F2L resueltos (dos primeras capas).
f2l_solved(State) :-
    cross_goal(State),
    forall(between(1, 4, Pair), pair_solved(State, Pair)).

f2l_goal(Done, Remaining, State) :-
    cross_goal(State),
    forall(member(Pair, Done), pair_solved(State, Pair)),
    member(Other, Remaining),
    pair_solved(State, Other),
    !.

%% ------------------------------------------------------------------
%% Heurísticas
%% ------------------------------------------------------------------

cfop_distance(Tables, Id, Code, Distance) :-
    arg(Id, Tables, Assoc),
    get_assoc(Code, Assoc, Distance).

cross_heuristic(Tables, State, Bound) :-
    piece_codes(State, Codes),
    cross_bound(Tables, Codes, Bound).

cross_bound(Tables, Codes, Bound) :-
    aggregate_all(max(Distance),
                  ( cross_pair(Id, A, B),
                    edge_arg(A, Codes, CodeA),
                    edge_arg(B, Codes, CodeB),
                    Code is CodeA * 24 + CodeB,
                    cfop_distance(Tables, Id, Code, Distance) ),
                  Bound).

% Cota de un par ya resuelto: solo su tabla de par.
pair_only_bound(Tables, Codes, Pair, Bound) :-
    f2l_pair(Pair, Corner, Edge, _),
    corner_arg(Corner, Codes, CornerCode),
    edge_arg(Edge, Codes, EdgeCode),
    Code is CornerCode * 24 + EdgeCode,
    Id is 6 + Pair,
    cfop_distance(Tables, Id, Code, Bound).

% Cota de un par por resolver: máximo entre su tabla de par y sus cuatro tríos.
pair_bound(Tables, Codes, Pair, Bound) :-
    f2l_pair(Pair, Corner, Edge, _),
    corner_arg(Corner, Codes, CornerCode),
    edge_arg(Edge, Codes, EdgeCode),
    PairCode is CornerCode * 24 + EdgeCode,
    PairId is 6 + Pair,
    cfop_distance(Tables, PairId, PairCode, PairDistance),
    aggregate_all(max(Distance),
                  ( between(1, 4, X),
                    CrossEdge is X + 3,
                    edge_arg(CrossEdge, Codes, CrossCode),
                    TripleCode is (CrossCode * 24 + CornerCode) * 24 + EdgeCode,
                    TripleId is 10 + (Pair - 1) * 4 + X,
                    cfop_distance(Tables, TripleId, TripleCode, Distance) ),
                  TripleBound),
    Bound is max(PairDistance, TripleBound).

done_bound(_, _, [], 0).
done_bound(Tables, Codes, [Pair|Pairs], Bound) :-
    pair_only_bound(Tables, Codes, Pair, Bound0),
    done_bound(Tables, Codes, Pairs, Bound1),
    Bound is max(Bound0, Bound1).

% Mínimo sobre los pares por resolver (la meta es "cualquiera de ellos").
remaining_bound(Tables, Codes, [Pair], Bound) :-
    !,
    pair_bound(Tables, Codes, Pair, Bound).
remaining_bound(Tables, Codes, [Pair|Pairs], Bound) :-
    pair_bound(Tables, Codes, Pair, Bound0),
    remaining_bound(Tables, Codes, Pairs, Bound1),
    Bound is min(Bound0, Bound1).

f2l_heuristic(Tables, Done, Remaining, State, Bound) :-
    piece_codes(State, Codes),
    cross_bound(Tables, Codes, CrossBound),
    done_bound(Tables, Codes, Done, DoneBound),
    remaining_bound(Tables, Codes, Remaining, RemainingBound),
    Bound is max(CrossBound, max(DoneBound, RemainingBound)).

%% ------------------------------------------------------------------
%% Resolución
%% ------------------------------------------------------------------

%% solve_cross(+State, -Moves, -Stats) is semidet.
% Cruz óptima (máximo 9 movimientos).
solve_cross(State, Moves, Stats) :-
    cfop_tables(Tables),
    findall(Move, move(Move), AllMoves),
    ida_star(State, cross_goal, cross_heuristic(Tables),
             AllMoves, 9, Moves, Stats).

%% solve_cfop(+State, -Phases, -Stats) is semidet.
% Cruz, cuatro pares de F2L (el más corto primero), OLL y PLL. Phases =
% [phase(Id, Nombre, Movimientos, stats(Nodos, Segundos)), ...] con 7 fases.
% Stats acumula nodos y segundos. Falla si el estado no es legal.
solve_cfop(State, Phases, stats(TotalNodes, TotalSeconds)) :-
    cfop_tables(Tables),
    findall(Move, move(Move), AllMoves),
    ida_star(State, cross_goal, cross_heuristic(Tables),
             AllMoves, 9, CrossMoves, CrossStats),
    apply_sequence(CrossMoves, State, State1),
    solve_f2l(Tables, AllMoves, State1, 2, [1,2,3,4], [],
              F2LPhases, State2, NextId),
    timed(solve_oll(State2, OllMoves, OllRule), OllSeconds),
    apply_sequence(OllMoves, State2, State3),
    rule_name(oll, OllRule, OllName),
    PllId is NextId + 1,
    timed(solve_pll(State3, PllMoves, PllRule), PllSeconds),
    apply_sequence(PllMoves, State3, State4),
    solved(Solved),
    State4 == Solved,
    rule_name(pll, PllRule, PllName),
    append(F2LPhases,
           [ phase(NextId, OllName, OllMoves, stats(0, OllSeconds)),
             phase(PllId, PllName, PllMoves, stats(0, PllSeconds)) ],
           Tail),
    Phases = [phase(1, 'Cross', CrossMoves, CrossStats)|Tail],
    foldl(add_stats, Phases, 0-0, TotalNodes-TotalSeconds).

solve_f2l(_, _, State, Id, [], _, [], State, Id).
solve_f2l(Tables, AllMoves, State0, Id0, Remaining, Done,
          [Phase|Phases], State, Id) :-
    Remaining = [_|_],
    ida_star(State0, f2l_goal(Done, Remaining),
             f2l_heuristic(Tables, Done, Remaining),
             AllMoves, 13, Moves, Stats),
    apply_sequence(Moves, State0, State1),
    once(( member(Pair, Remaining), pair_solved(State1, Pair) )),
    select(Pair, Remaining, Remaining1),
    f2l_pair(Pair, _, _, Slot),
    format(atom(Name), 'F2L ~w', [Slot]),
    Phase = phase(Id0, Name, Moves, Stats),
    Id1 is Id0 + 1,
    solve_f2l(Tables, AllMoves, State1, Id1, Remaining1, [Pair|Done],
              Phases, State, Id).

timed(Goal, Seconds) :-
    statistics(cputime, Start),
    call(Goal),
    statistics(cputime, End),
    Seconds is End - Start.

rule_name(oll, skip, 'OLL skip') :-
    !.
rule_name(oll, oll(Id, _), Name) :-
    format(atom(Name), 'OLL ~w', [Id]).
rule_name(pll, pll(Pll, _, _), Name) :-
    format(atom(Name), 'PLL ~w', [Pll]).

add_stats(phase(_, _, _, stats(Nodes, Seconds)), Nodes0-Seconds0,
          Nodes1-Seconds1) :-
    Nodes1 is Nodes0 + Nodes,
    Seconds1 is Seconds0 + Seconds.
