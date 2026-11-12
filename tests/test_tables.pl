:- use_module(library(plunit)).
:- use_module(library(assoc), [assoc_to_list/2]).
:- use_module(library(lists), [max_list/2]).
:- use_module('../prolog/cube').
:- use_module('../prolog/tables').
:- use_module('../prolog/thistle', [phase2_moves/1]).

/** <module> Pruebas de tablas de coordenadas.

Verifica la tabla completa de orientación de aristas y su distancia máxima.
*/

:- begin_tests(tables).

test(edge_orientation_table) :-
    findall(Move, move(Move), Moves),
    build_table(eo, Moves, Table),
    assoc_to_list(Table, Entries),
    length(Entries, 2048),
    findall(Distance, member(_-Distance, Entries), Distances),
    max_list(Distances, 7).

test(corner_orientation_table) :-
    phase2_moves(Moves),
    build_table(co, Moves, Table),
    assoc_to_list(Table, Entries),
    length(Entries, 2187),
    findall(Distance, member(_-Distance, Entries), Distances),
    max_list(Distances, 7).

test(slice_table) :-
    phase2_moves(Moves),
    build_table(slice, Moves, Table),
    assoc_to_list(Table, Entries),
    length(Entries, 495),
    findall(Distance, member(_-Distance, Entries), Distances),
    max_list(Distances, 5).

:- end_tests(tables).
