:- use_module(library(plunit)).
:- use_module(library(assoc)).
:- use_module(library(aggregate)).
:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/tables').
:- use_module('../prolog/thistle').

/** <module> Pruebas de la fase 4 y del solver completo de Thistlethwaite.

Comprueba la tabla parcial de la fase 4, la resolución de estados de G3 y el
encadenado de las cuatro fases hasta el cubo resuelto. Para estadísticas:
swipl -g report_phase4 -t halt tests/test_phase4.pl
*/

:- set_random(seed(42)).

:- begin_tests(phase4).

random_moves(Moves, Length, Word) :-
    length(Word, Length),
    maplist(random_pick(Moves), Word).

random_pick(Moves, Move) :-
    random_member(Move, Moves).

% La tabla parcial tiene 84433 estados con el conteo por profundidad esperado.
test(phase4_table_layers) :-
    phase4_table(Table),
    assoc_to_list(Table, Pairs),
    length(Pairs, 84433),
    Expected = [0-1, 1-6, 2-27, 3-120, 4-519, 5-1932,
                6-6484, 7-20310, 8-55034],
    forall(member(Depth-Count, Expected),
           ( aggregate_all(count, member(_-Depth, Pairs), Found),
             Found =:= Count )).

% Estados aleatorios de G3 se resuelven con medios giros.
test(solve_phase4_random_g3, [forall(between(1, 20, _))]) :-
    random_moves([u2,d2,l2,r2,f2,b2], 60, Word),
    solved(Solved),
    apply_sequence(Word, Solved, State),
    solve_phase4(State, Moves, _),
    apply_sequence(Moves, State, Result),
    Result == Solved,
    phase4_moves(Allowed),
    subset(Moves, Allowed),
    length(Moves, Length),
    Length =< 15.

% Las cuatro fases en cadena resuelven cualquier mezcla.
test(four_phases_solve_cube, [forall(between(1, 10, _))]) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, S0),
    solve_phase1(S0, M1, _), apply_sequence(M1, S0, S1),
    solve_phase2(S1, M2, _), apply_sequence(M2, S1, S2),
    solve_phase3(S2, M3, _), apply_sequence(M3, S2, S3),
    solve_phase4(S3, M4, _), apply_sequence(M4, S3, S4),
    S4 == Solved.

:- end_tests(phase4).

%% report_phase4 is det.
% Estadísticas sobre 20 mezclas de 25 movimientos con las cuatro fases.
report_phase4 :-
    statistics(cputime, Start),
    phase4_table(_),
    statistics(cputime, End),
    TableSeconds is End - Start,
    findall(row(L1, L2, L3, L4, N4, T4),
            ( between(1, 20, _),
              random_scramble(25, Scramble),
              solved(Solved),
              apply_sequence(Scramble, Solved, S0),
              solve_phase1(S0, M1, _), apply_sequence(M1, S0, S1),
              solve_phase2(S1, M2, _), apply_sequence(M2, S1, S2),
              solve_phase3(S2, M3, _), apply_sequence(M3, S2, S3),
              solve_phase4(S3, M4, stats(N4, T4)),
              length(M1, L1), length(M2, L2),
              length(M3, L3), length(M4, L4) ),
            Rows),
    format("Tabla fase 4 (carga o construccion): ~2f s~n", [TableSeconds]),
    forall(member(Index-Name, [1-"Fase 1", 2-"Fase 2", 3-"Fase 3", 4-"Fase 4"]),
           ( column(Index, Rows, Values),
             mean_max(Values, Mean, Max),
             format("~s: longitud media ~2f, maxima ~w~n", [Name, Mean, Max]) )),
    findall(Total, ( member(row(A,B,C,D,_,_), Rows), Total is A+B+C+D ), Totals),
    mean_max(Totals, TotalMean, TotalMax),
    min_list(Totals, TotalMin),
    format("Total: media ~2f, minimo ~w, maximo ~w~n",
           [TotalMean, TotalMin, TotalMax]),
    column(5, Rows, Nodes), mean_max(Nodes, NodeMean, NodeMax),
    column(6, Rows, Times), mean_max(Times, TimeMean, TimeMax),
    format("Nodos fase 4: media ~2f, maximo ~w~n", [NodeMean, NodeMax]),
    format("Tiempo fase 4: medio ~4f s, maximo ~4f s~n", [TimeMean, TimeMax]).

column(Index, Rows, Values) :-
    findall(V, ( member(Row, Rows), arg(Index, Row, V) ), Values).

mean_max(Values, Mean, Max) :-
    sum_list(Values, Sum),
    length(Values, Count),
    Mean is Sum / Count,
    max_list(Values, Max).