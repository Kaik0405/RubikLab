:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/tables').
:- use_module('../prolog/thistle').
:- use_module(library(lists), [sum_list/2]).

/** <module> Pruebas de la primera fase de Thistlethwaite.

Verifica que la orientación de aristas se resuelva en siete movimientos o
menos y registra promedios de nodos y tiempo.
*/

:- begin_tests(thistle).

test(phase1_solves_random_states) :-
    collect_samples(20, Stats),
    maplist(stat_nodes, Stats, Nodes),
    maplist(stat_seconds, Stats, Seconds),
    sum_list(Nodes, TotalNodes),
    sum_list(Seconds, TotalSeconds),
    length(Stats, Count),
    AverageNodes is TotalNodes / Count,
    AverageSeconds is TotalSeconds / Count,
    format('~nAverage phase 1 nodes: ~2f~nAverage phase 1 seconds: ~6f~n',
           [AverageNodes, AverageSeconds]),
    !.

collect_samples(0, []).
collect_samples(Count, [stats(Nodes, Seconds)|Stats]) :-
    Count > 0,
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    solve_phase1(State, Moves, stats(Nodes, Seconds)),
    apply_sequence(Moves, State, Result),
    state_coord(eo, Result, EO),
    maplist(=(0), EO),
    length(Moves, Length),
    Length =< 7,
    NextCount is Count - 1,
    collect_samples(NextCount, Stats).

stat_nodes(stats(Nodes, _), Nodes).
stat_seconds(stats(_, Seconds), Seconds).

:- end_tests(thistle).
