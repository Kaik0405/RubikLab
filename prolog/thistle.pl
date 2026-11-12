:- module(thistle, [
    phase2_moves/1,
    in_g2/1,
    solve_phase1/3,
    solve_phase2/3,
    build_time_phase2/1,
    phase3_moves/1,
    in_g3/1,
    solve_phase3/3,
    phase4_moves/1,
    solve_phase4/3
]).

:- use_module(cube, [move/1, solved/1]).
:- use_module(moves, []).
:- use_module(search, [ida_star/7]).
:- use_module(tables, [
    cached_table/3,
    build_table/3,
    goal_coord/2,
    phase3_key/2,
    phase3_goal_key/1,
    phase3_table/1,
    phase4_table/1,
    state_coord/3,
    state_key/2,
    table_distance/3
]).
:- use_module(library(assoc), [get_assoc/3]).
:- use_module(library(lists), [max_list/2]).
:- use_module(library(apply), [maplist/2]).

/** <module> Fases iniciales del método de Thistlethwaite.

Exporta las tres primeras fases de Thistlethwaite, sus movimientos permitidos
y predicados de pertenencia a G2 y G3. Depende de cube.pl, moves.pl, search.pl
y tables.pl.
*/

:- meta_predicate solve_phase1(+, -, -).

%% solve_phase1(+State, -Moves, -Stats) is semidet.
% Resuelve la orientación de aristas en un máximo de siete movimientos.
solve_phase1(State, Moves, Stats) :-
    findall(Move, move(Move), AllowedMoves),
    cached_table(eo, AllowedMoves, Table),
    ida_star(State, phase1_goal, phase1_heuristic(Table),
             AllowedMoves, 7, Moves, Stats).

%% phase2_moves(-Moves) is det.
% Devuelve los movimientos permitidos durante la segunda fase.
phase2_moves([u,ui,u2,d,di,d2,l,li,l2,r,ri,r2,f2,b2]).

%% in_g2(+State) is semidet.
% Comprueba que el estado cumpla las restricciones del grupo G2.
in_g2(State) :-
    state_coord(eo, State, EO),
    state_coord(co, State, CO),
    state_coord(slice, State, Slice),
    maplist(=(0), EO),
    maplist(=(0), CO),
    goal_coord(slice, Slice).

%% solve_phase2(+State, -Moves, -Stats) is semidet.
% Resuelve la segunda fase en un máximo de diez movimientos.
solve_phase2(State, Moves, Stats) :-
    phase2_moves(AllowedMoves),
    cached_table(co, AllowedMoves, CornerTable),
    cached_table(slice, AllowedMoves, SliceTable),
    ida_star(State, phase2_goal(CornerTable, SliceTable),
             phase2_heuristic(CornerTable, SliceTable),
             AllowedMoves, 10, Moves, Stats).

%% phase3_moves(-Moves) is det.
% Devuelve los movimientos permitidos durante la tercera fase.
phase3_moves([u,ui,u2,d,di,d2,l2,r2,f2,b2]).

%% in_g3(+State) is semidet.
% Comprueba que la clave del estado sea la clave objetivo de G3.
in_g3(State) :-
    phase3_key(State, Key),
    phase3_goal_key(Key).

%% solve_phase3(+State, -Moves, -Stats) is semidet.
% Resuelve la tercera fase en un máximo de catorce movimientos.
solve_phase3(State, Moves, Stats) :-
    phase3_moves(AllowedMoves),
    phase3_table(Table),
    ida_star(State, in_g3, phase3_heuristic(Table),
             AllowedMoves, 14, Moves, Stats).

%% build_time_phase2(-Seconds) is det.
% Mide la construcción independiente de las dos tablas de la fase 2.
build_time_phase2(Seconds) :-
    phase2_moves(Moves),
    statistics(cputime, Start),
    build_table(co, Moves, _),
    build_table(slice, Moves, _),
    statistics(cputime, End),
    Seconds is End - Start.

%% phase1_goal(+State) is semidet.
% Comprueba que todas las aristas estén orientadas.
phase1_goal(State) :-
    state_coord(eo, State, EO),
    maplist(=(0), EO).

%% phase1_heuristic(+Table, +State, -Distance) is semidet.
% Consulta la distancia EO de un estado.
phase1_heuristic(Table, State, Distance) :-
    state_coord(eo, State, Coordinate),
    table_distance(Table, Coordinate, Distance).

%% phase2_goal(+CornerTable, +SliceTable, +State) is semidet.
% Comprueba la meta de la segunda fase.
phase2_goal(_, _, State) :-
    in_g2(State).

%% phase2_heuristic(+CornerTable, +SliceTable, +State, -Distance) is semidet.
% Usa el máximo de las distancias de orientación y capa.
phase2_heuristic(CornerTable, SliceTable, State, Distance) :-
    state_coord(co, State, CornerCoordinate),
    state_coord(slice, State, SliceCoordinate),
    table_distance(CornerTable, CornerCoordinate, CornerDistance),
    table_distance(SliceTable, SliceCoordinate, SliceDistance),
    max_list([CornerDistance, SliceDistance], Distance).

%% phase3_heuristic(+Table, +State, -Distance) is semidet.
% Consulta la distancia exacta de la clave de fase 3.
phase3_heuristic(Table, State, Distance) :-
    phase3_key(State, Key),
    table_distance(Table, Key, Distance).

%% phase4_moves(-Moves) is det.
% Movimientos permitidos durante la cuarta fase (solo medios giros).
phase4_moves([u2,d2,l2,r2,f2,b2]).

%% solve_phase4(+State, -Moves, -Stats) is semidet.
% Lleva un estado de G3 al cubo resuelto con IDA* en un máximo de quince
% movimientos. La heurística es la distancia exacta si el estado está en la
% tabla parcial (profundidad <= 8) y 9 en caso contrario (cota admisible).
solve_phase4(State, Moves, Stats) :-
    phase4_moves(AllowedMoves),
    phase4_table(Table),
    solved(Solved),
    ida_star(State, phase4_goal(Solved), phase4_heuristic(Table),
             AllowedMoves, 15, Moves, Stats).

%% phase4_goal(+Solved, +State) is semidet.
phase4_goal(Solved, State) :-
    State == Solved.

%% phase4_heuristic(+Table, +State, -Distance) is det.
phase4_heuristic(Table, State, Distance) :-
    state_key(State, Key),
    (   get_assoc(Key, Table, Known)
    ->  Distance = Known
    ;   Distance = 9
    ).