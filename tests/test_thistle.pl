:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/tables').
:- use_module('../prolog/thistle').
:- use_module(library(lists), [max_list/2, sum_list/2]).
:- use_module(library(time), [call_with_time_limit/2]).

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
    format(user_output, '~nAverage phase 1 nodes: ~2f~nAverage phase 1 seconds: ~6f~n',
           [AverageNodes, AverageSeconds]),
    !.

test(phase2_solves_random_states) :-
    build_time_phase2(BuildSeconds),
    collect_phase2_samples(20, Stats),
    maplist(stat_nodes, Stats, Nodes),
    maplist(stat_seconds, Stats, Seconds),
    sum_list(Nodes, TotalNodes),
    sum_list(Seconds, TotalSeconds),
    max_list(Nodes, MaximumNodes),
    max_list(Seconds, MaximumSeconds),
    length(Stats, Count),
    AverageNodes is TotalNodes / Count,
    AverageSeconds is TotalSeconds / Count,
    format(user_output, '~nPhase 2 table build seconds: ~6f~nAverage phase 2 nodes: ~2f~nMaximum phase 2 nodes: ~w~nAverage phase 2 seconds: ~6f~nMaximum phase 2 seconds: ~6f~n',
           [BuildSeconds, AverageNodes, MaximumNodes,
            AverageSeconds, MaximumSeconds]),
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

collect_phase2_samples(0, []).
collect_phase2_samples(Count, [stats(Nodes, Seconds)|Stats]) :-
    Count > 0,
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    solve_phase1(State, Phase1Moves, _),
    apply_sequence(Phase1Moves, State, Phase1State),
    solve_phase2_with_limit(Scramble, Phase1State, Phase2Moves,
                            stats(Nodes, Seconds)),
    phase2_moves(AllowedMoves),
    subset_of(Phase2Moves, AllowedMoves),
    apply_sequence(Phase2Moves, Phase1State, Result),
    in_g2(Result),
    length(Phase2Moves, Length),
    (   in_g2(Phase1State)
    ->  Length >= 0
    ;   Length >= 5
    ),
    Length =< 10,
    Seconds =< 30,
    NextCount is Count - 1,
    collect_phase2_samples(NextCount, Stats).

solve_phase2_with_limit(Scramble, State, Moves, Stats) :-
    catch(
        call_with_time_limit(
            30,
            solve_phase2(State, Moves, Stats)
        ),
        time_limit_exceeded,
        (
            format(user_error,
                   '~nPhase 2 timeout after 30 seconds. Scramble: ~w~n',
                   [Scramble]),
            throw(phase2_timeout(Scramble))
        )
    ).

subset_of([], _).
subset_of([Move|Moves], AllowedMoves) :-
    memberchk(Move, AllowedMoves),
    subset_of(Moves, AllowedMoves).

:- end_tests(thistle).
