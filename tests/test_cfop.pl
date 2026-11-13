:- use_module(library(plunit)).
:- use_module(library(assoc)).
:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/cfop').

/** <module> Pruebas del método CFOP.

Comprueba las 26 tablas de distancias (tamaños y distancias máximas), la cruz,
el encadenado cruz + F2L y el solver completo. Estadísticas con:
swipl -g report_cfop -t halt tests/test_cfop.pl
*/

:- set_random(seed(42)).

:- begin_tests(cfop).

table_stats(Tables, Id, Size, Max) :-
    arg(Id, Tables, Assoc),
    assoc_to_list(Assoc, Pairs),
    length(Pairs, Size),
    findall(D, member(_-D, Pairs), Distances),
    max_list(Distances, Max).

% 6 tablas de pares de aristas (528 estados, distancia máxima 5),
% 4 de pares esquina-arista (576, máximo 6) y 16 de tríos (12672, máximo 7).
test(table_sizes_and_depths) :-
    cfop_tables(Tables),
    functor(Tables, tables, 26),
    forall(between(1, 6, Id),
           ( table_stats(Tables, Id, 528, Max), Max =< 5 )),
    forall(between(7, 10, Id),
           ( table_stats(Tables, Id, 576, Max), Max =< 6 )),
    forall(between(11, 26, Id),
           ( table_stats(Tables, Id, 12672, Max), Max =< 7 )).

test(solved_cube_has_cross_and_f2l) :-
    solved(Solved),
    cross_goal(Solved),
    f2l_solved(Solved).

test(cross_is_solved_in_at_most_8, [forall(between(1, 10, _))]) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    solve_cross(State, Moves, _),
    apply_sequence(Moves, State, After),
    cross_goal(After),
    length(Moves, Length),
    Length =< 8.

test(cfop_solves_the_cube, [forall(between(1, 5, _))]) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    solve_cfop(State, Phases, stats(Nodes, Seconds)),
    length(Phases, 7),
    Phases = [phase(1, 'Cross', _, _)|_],
    findall(Moves, member(phase(_, _, Moves, _), Phases), MoveLists),
    append(MoveLists, AllMoves),
    apply_sequence(AllMoves, State, Result),
    Result == Solved,
    Nodes >= 0,
    Seconds >= 0.

% Tras las cinco primeras fases (cruz y 4 pares) las dos primeras capas están hechas.
test(first_two_layers_after_five_phases, [forall(between(1, 3, _))]) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    solve_cfop(State, Phases, _),
    length(FirstFive, 5),
    append(FirstFive, _, Phases),
    findall(Moves, member(phase(_, _, Moves, _), FirstFive), MoveLists),
    append(MoveLists, AllMoves),
    apply_sequence(AllMoves, State, Layers),
    f2l_solved(Layers).

:- end_tests(cfop).

%% report_cfop is det.
% Estadísticas de 20 mezclas de 25 movimientos.
report_cfop :-
    statistics(cputime, Start),
    cfop_tables(_),
    statistics(cputime, End),
    TableSeconds is End - Start,
    findall(row(Cross, F2L, Oll, Pll, Nodes, Seconds),
            ( between(1, 20, _),
              random_scramble(25, Scramble),
              solved(Solved),
              apply_sequence(Scramble, Solved, State),
              solve_cfop(State, Phases, stats(Nodes, Seconds)),
              phase_lengths(Phases, Cross, F2L, Oll, Pll) ),
            Rows),
    format("Tablas CFOP (carga o construccion): ~2f s~n", [TableSeconds]),
    forall(member(Index-Name, [1-"Cruz", 2-"F2L", 3-"OLL", 4-"PLL"]),
           ( column(Index, Rows, Values),
             mean_max(Values, Mean, Max),
             format("~s: longitud media ~2f, maxima ~w~n", [Name, Mean, Max]) )),
    findall(Total,
            ( member(row(A, B, C, D, _, _), Rows), Total is A + B + C + D ),
            Totals),
    mean_max(Totals, TotalMean, TotalMax),
    min_list(Totals, TotalMin),
    format("Total: media ~2f, minimo ~w, maximo ~w~n",
           [TotalMean, TotalMin, TotalMax]),
    column(5, Rows, Nodes5), mean_max(Nodes5, NodeMean, NodeMax),
    column(6, Rows, Times), mean_max(Times, TimeMean, TimeMax),
    format("Nodos por resolucion: media ~2f, maximo ~w~n", [NodeMean, NodeMax]),
    format("Tiempo por resolucion: medio ~3f s, maximo ~3f s~n",
           [TimeMean, TimeMax]).

phase_lengths([phase(_, _, CrossMoves, _)|Rest], Cross, F2L, Oll, Pll) :-
    length(CrossMoves, Cross),
    length(F2LPhases, 4),
    append(F2LPhases, [phase(_, _, OllMoves, _), phase(_, _, PllMoves, _)], Rest),
    findall(L, ( member(phase(_, _, M, _), F2LPhases), length(M, L) ), Lengths),
    sum_list(Lengths, F2L),
    length(OllMoves, Oll),
    length(PllMoves, Pll).

column(Index, Rows, Values) :-
    findall(V, ( member(Row, Rows), arg(Index, Row, V) ), Values).

mean_max(Values, Mean, Max) :-
    sum_list(Values, Sum),
    length(Values, Count),
    Mean is Sum / Count,
    max_list(Values, Max).
