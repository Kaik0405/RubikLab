:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module('../prolog/benchmark').

/** <module> Pruebas del benchmark.

Comprueba el número de filas, el resumen por método y que la misma semilla
produce las mismas mezclas (mismos movimientos y nodos para cada método).
*/

:- begin_tests(benchmark).

test(rows_and_summary) :-
    benchmark(3, 7, Rows),
    length(Rows, 6),
    benchmark_summary(Rows, Summaries),
    length(Summaries, 2),
    forall(member(summary(_, 3, Mean, Min, Max, _, _, _), Summaries),
           ( Min =< Mean, Mean =< Max )).

test(same_seed_same_scrambles) :-
    benchmark(3, 7, Rows1),
    benchmark(3, 7, Rows2),
    findall(I-M-Moves-Nodes, member(row(I, M, Moves, Nodes, _), Rows1), A),
    findall(I-M-Moves-Nodes, member(row(I, M, Moves, Nodes, _), Rows2), B),
    A == B.

test(cfop_is_longer_than_thistlethwaite_on_average) :-
    benchmark(3, 7, Rows),
    benchmark_summary(Rows, Summaries),
    memberchk(summary(thistle, _, ThistleMean, _, _, _, _, _), Summaries),
    memberchk(summary(cfop, _, CfopMean, _, _, _, _, _), Summaries),
    ThistleMean < CfopMean.

:- end_tests(benchmark).
