:- module(benchmark, [
    benchmark/3,
    benchmark_summary/2,
    report_benchmark/2
]).

:- use_module(cube, [solved/1, apply_sequence/3]).
:- use_module(moves, [random_scramble/2]).
:- use_module(thistle, []).
:- use_module(cfop, []).
:- use_module(library(lists), [append/2, sum_list/2, max_list/2, min_list/2]).
:- use_module(library(random), [set_random/1]).

/** <module> Benchmark comparativo de los dos métodos de resolución.

benchmark(+N, +Semilla, -Filas) resuelve las MISMAS N mezclas de 25 movimientos
con Thistlethwaite y con CFOP (la semilla fija el azar, así que es
reproducible) y devuelve una fila row(Indice, Metodo, Movimientos, Nodos,
Segundos) por método y mezcla. Antes de medir, un calentamiento carga tablas y
patrones para que el tiempo no incluya su construcción.

benchmark_summary/2 agrega con findall y sum_list/max_list/min_list (segundo
orden, Conferencia 6) la media, el mínimo y el máximo por método.
Los movimientos cuentan giros de cara (una capa central M cuenta como dos).
Depende de cube.pl, moves.pl, thistle.pl y cfop.pl.
*/

%% benchmark(+N, +Seed, -Rows) is det.
benchmark(N, Seed, Rows) :-
    warm_up,
    set_random(seed(Seed)),
    findall(Pair, ( between(1, N, Index), run_index(Index, Pair) ), Pairs),
    append(Pairs, Rows).

warm_up :-
    solved(Solved),
    thistle:solve(Solved, _, _),
    cfop:solve_cfop(Solved, _, _).

run_index(Index, [Row1, Row2]) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    run_method(thistle, Index, State, Row1),
    run_method(cfop, Index, State, Row2).

run_method(Method, Index, State, row(Index, Method, Moves, Nodes, Seconds)) :-
    solve_method(Method, State, Phases, stats(Nodes, Seconds)),
    findall(Length,
            ( member(phase(_, _, PhaseMoves, _), Phases), length(PhaseMoves, Length) ),
            Lengths),
    sum_list(Lengths, Moves).

solve_method(thistle, State, Phases, Stats) :-
    thistle:solve(State, Phases, Stats).
solve_method(cfop, State, Phases, Stats) :-
    cfop:solve_cfop(State, Phases, Stats).

%% benchmark_summary(+Rows, -Summaries) is det.
% summary(Metodo, Mezclas, MediaMov, MinMov, MaxMov, MediaNodos, MediaSeg, MaxSeg).
benchmark_summary(Rows, Summaries) :-
    findall(Summary,
            ( member(Method, [thistle, cfop]),
              method_summary(Method, Rows, Summary) ),
            Summaries).

method_summary(Method, Rows, summary(Method, Count, MeanMoves, MinMoves, MaxMoves,
                                     MeanNodes, MeanSeconds, MaxSeconds)) :-
    findall(M, member(row(_, Method, M, _, _), Rows), Moves),
    findall(N, member(row(_, Method, _, N, _), Rows), Nodes),
    findall(S, member(row(_, Method, _, _, S), Rows), Seconds),
    Moves \== [],
    length(Moves, Count),
    sum_list(Moves, SumMoves), MeanMoves is SumMoves / Count,
    min_list(Moves, MinMoves), max_list(Moves, MaxMoves),
    sum_list(Nodes, SumNodes), MeanNodes is SumNodes / Count,
    sum_list(Seconds, SumSeconds), MeanSeconds is SumSeconds / Count,
    max_list(Seconds, MaxSeconds).

%% report_benchmark(+N, +Seed) is det.
% Imprime una tabla en Markdown lista para pegar en el informe.
report_benchmark(N, Seed) :-
    benchmark(N, Seed, Rows),
    benchmark_summary(Rows, Summaries),
    format("Benchmark: ~w mezclas de 25 movimientos, semilla ~w~n~n", [N, Seed]),
    format("| Metodo | Movimientos (media / min / max) | Nodos (media) | Tiempo medio (s) | Tiempo max (s) |~n"),
    format("|---|---|---|---|---|~n"),
    forall(member(summary(Method, _, MeanMoves, MinMoves, MaxMoves,
                          MeanNodes, MeanSeconds, MaxSeconds), Summaries),
           format("| ~w | ~2f / ~w / ~w | ~0f | ~3f | ~3f |~n",
                  [Method, MeanMoves, MinMoves, MaxMoves,
                   MeanNodes, MeanSeconds, MaxSeconds])).
