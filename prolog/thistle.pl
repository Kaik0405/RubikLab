:- module(thistle, [solve_phase1/3]).

:- use_module(cube, [move/1]).
:- use_module(moves, []).
:- use_module(search, [ida_star/7]).
:- use_module(tables, [
    cached_table/3,
    state_coord/3,
    table_distance/3
]).

/** <module> Primera fase del método de Thistlethwaite.

Exporta la resolución de la orientación de aristas mediante IDA* y una tabla
de distancias EO. Depende de cube.pl, moves.pl, search.pl y tables.pl.
*/

:- meta_predicate solve_phase1(+, -, -).

%% solve_phase1(+State, -Moves, -Stats) is semidet.
% Resuelve la orientación de aristas en un máximo de siete movimientos.
solve_phase1(State, Moves, Stats) :-
    findall(Move, move(Move), AllowedMoves),
    cached_table(eo, AllowedMoves, Table),
    ida_star(State, phase1_goal, phase1_heuristic(Table),
             AllowedMoves, 7, Moves, Stats).

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
