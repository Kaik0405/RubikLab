:- module(tables, [
    coord_apply/4,
    state_coord/3,
    goal_coord/2,
    build_table/3,
    table_distance/3,
    cached_table/3
]).

:- use_module(cube, [base_move/2]).
:- use_module(library(assoc)).
:- use_module(library(lists), [numlist/3]).

/** <module> Tablas de coordenadas para las fases del cubo.

Exporta transformaciones de coordenadas, construcción BFS y caché de tablas.
Depende de cube.pl para las tablas de movimientos base.
*/

:- dynamic table_cache/3.

%% coord_apply(+Kind, +Move, +Coord0, -Coord1) is det.
% Aplica un movimiento a una coordenada de orientación o de capa.
coord_apply(eo, Move, Coord0, Coord1) :-
    base_move(Move, state(_, _, MEP, MEO)),
    numlist(0, 11, Positions),
    maplist(apply_edge_orientation(Coord0, MEP, MEO), Positions, Coord1).
coord_apply(co, Move, Coord0, Coord1) :-
    base_move(Move, state(MCP, MCO, _, _)),
    numlist(0, 7, Positions),
    maplist(apply_corner_orientation(Coord0, MCP, MCO), Positions, Coord1).
coord_apply(slice, Move, Coord0, Coord1) :-
    base_move(Move, state(_, _, MEP, _)),
    numlist(0, 11, Positions),
    maplist(select_edge_coordinate(Coord0, MEP), Positions, Coord1).

%% state_coord(+Kind, +State, -Coord) is det.
% Extrae la coordenada solicitada desde un estado completo.
state_coord(eo, state(_, _, _, EO), EO).
state_coord(co, state(_, CO, _, _), CO).
state_coord(slice, state(_, _, EP, _), Coord) :-
    maplist(slice_value(EP), EP, Coord).

%% goal_coord(+Kind, -Coord) is det.
% Construye la coordenada objetivo de una fase.
goal_coord(eo, Coord) :-
    length(Coord, 12),
    maplist(=(0), Coord).
goal_coord(co, Coord) :-
    length(Coord, 8),
    maplist(=(0), Coord).
goal_coord(slice, [0,0,0,0,0,0,0,0,1,1,1,1]).

%% build_table(+Kind, +Moves, -Table) is det.
% Construye por BFS la tabla de distancias desde la coordenada objetivo.
build_table(Kind, Moves, Table) :-
    goal_coord(Kind, Goal),
    empty_assoc(InitialTable),
    put_assoc(Goal, InitialTable, 0, Table0),
    bfs(Kind, Moves, [Goal], Table0, Table).

%% table_distance(+Table, +Coord, -Distance) is semidet.
% Obtiene la distancia de una coordenada en una tabla.
table_distance(Table, Coord, Distance) :-
    get_assoc(Coord, Table, Distance).

%% cached_table(+Kind, +Moves, -Table) is det.
% Construye una tabla una sola vez y reutiliza las llamadas posteriores.
cached_table(Kind, Moves, Table) :-
    table_cache(Kind, Moves, Table),
    !.
cached_table(Kind, Moves, Table) :-
    build_table(Kind, Moves, Table),
    assertz(table_cache(Kind, Moves, Table)).

%% bfs(+Kind, +Moves, +Queue, +Table0, -Table) is det.
% Recorre todas las coordenadas alcanzables y asigna sus distancias.
bfs(_, _, [], Table, Table).
bfs(Kind, Moves, [Coord|Queue], Table0, Table) :-
    get_assoc(Coord, Table0, Distance),
    NextDistance is Distance + 1,
    bfs_moves(Kind, Moves, Coord, NextDistance, Queue,
              Table0, NextQueue, Table1),
    bfs(Kind, Moves, NextQueue, Table1, Table).

%% bfs_moves(+Kind, +Moves, +Coord, +Distance, +Queue0, +Table0, -Queue, -Table) is det.
% Expande una coordenada con todos los movimientos permitidos.
bfs_moves(_, [], _, _, Queue, Table, Queue, Table).
bfs_moves(Kind, [Move|Moves], Coord, Distance, Queue0, Table0,
          Queue, Table) :-
    coord_apply(Kind, Move, Coord, NextCoord),
    (   get_assoc(NextCoord, Table0, _)
    ->  Queue1 = Queue0,
        Table1 = Table0
    ;   put_assoc(NextCoord, Table0, Distance, Table1),
        append(Queue0, [NextCoord], Queue1)
    ),
    bfs_moves(Kind, Moves, Coord, Distance, Queue1, Table1,
              Queue, Table).

%% apply_edge_orientation(+Coord0, +Permutation, +Offsets, +Position, -Value) is det.
% Calcula una posición de la coordenada de orientación de aristas.
apply_edge_orientation(Coord0, Permutation, Offsets, Position, Value) :-
    nth0(Position, Offsets, Offset),
    nth0(Position, Permutation, Source),
    nth0(Source, Coord0, Previous),
    Value is (Previous + Offset) mod 2.

%% apply_corner_orientation(+Coord0, +Permutation, +Offsets, +Position, -Value) is det.
% Calcula una posición de la coordenada de orientación de esquinas.
apply_corner_orientation(Coord0, Permutation, Offsets, Position, Value) :-
    nth0(Position, Offsets, Offset),
    nth0(Position, Permutation, Source),
    nth0(Source, Coord0, Previous),
    Value is (Previous + Offset) mod 3.

%% select_edge_coordinate(+Coord0, +Permutation, +Position, -Value) is det.
% Reordena una posición de la coordenada de capa.
select_edge_coordinate(Coord0, Permutation, Position, Value) :-
    nth0(Position, Permutation, Source),
    nth0(Source, Coord0, Value).

%% slice_value(+Permutation, +Piece, -Value) is det.
% Marca si una pieza de arista pertenece a la capa slice.
slice_value(_, Piece, 1) :-
    Piece >= 8,
    !.
slice_value(_, _, 0).
