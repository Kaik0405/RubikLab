:- use_module(library(plunit)).
:- use_module(library(assoc)).
:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/tables').
:- use_module('../prolog/thistle').

/** <module> Pruebas de la fase 3 de Thistlethwaite.

Comprueba la tabla de clases de S3^5, la tabla exacta de coclases, la
invarianza de la clave, la pertenencia a G3 y el encadenado de las fases
1, 2 y 3. Para ver estadísticas: swipl -g report_phase3 -t halt tests/test_phase3.pl
*/

:- set_random(seed(42)).

:- begin_tests(phase3).

random_word(Moves, Word) :-
    random_between(1, 20, Length),
    length(Word, Length),
    maplist(random_pick(Moves), Word).

random_pick(Moves, Move) :-
    random_member(Move, Moves).

% Las 7776 tuplas de S3^5 se agrupan en exactamente 12 clases.
test(class_table_has_12_classes) :-
    tables:phase3_class_table(Table),
    assoc_to_list(Table, Pairs),
    length(Pairs, 7776),
    findall(Class, member(_-Class, Pairs), Classes),
    sort(Classes, Unique),
    length(Unique, 12).

% La tabla de fase 3 tiene 29400 clases y distancia máxima 13.
test(phase3_table_size_and_depth) :-
    phase3_table(Table),
    assoc_to_list(Table, Pairs),
    length(Pairs, 29400),
    findall(Distance, member(_-Distance, Pairs), Distances),
    max_list(Distances, 13).

% Aplicar antes una palabra de medios giros no cambia la clave de coclase.
test(key_is_coset_invariant, [forall(between(1, 50, _))]) :-
    phase2_moves(Phase2Moves),
    random_word(Phase2Moves, StateWord),
    random_word([u2,d2,l2,r2,f2,b2], GroupWord),
    solved(Solved),
    apply_sequence(StateWord, Solved, State0),
    append(GroupWord, StateWord, Combined),
    apply_sequence(Combined, Solved, State1),
    phase3_key(State0, Key0),
    phase3_key(State1, Key1),
    Key0 == Key1.

test(in_g3_after_half_turns, [forall(between(1, 50, _))]) :-
    random_word([u2,d2,l2,r2,f2,b2], Word),
    solved(Solved),
    apply_sequence(Word, Solved, State),
    in_g3(State).

test(not_in_g3_after_r) :-
    solved(Solved),
    apply(r, Solved, State),
    \+ in_g3(State).

% Fases 1, 2 y 3 encadenadas llevan cualquier mezcla a G3.
test(phases_1_to_3_reach_g3, [forall(between(1, 10, _))]) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State0),
    solve_phase1(State0, Moves1, _),
    apply_sequence(Moves1, State0, State1),
    solve_phase2(State1, Moves2, _),
    apply_sequence(Moves2, State1, State2),
    solve_phase3(State2, Moves3, _),
    apply_sequence(Moves3, State2, State3),
    in_g3(State3),
    phase3_moves(Allowed),
    subset(Moves3, Allowed),
    length(Moves3, Length),
    Length =< 13.

:- end_tests(phase3).

%% report_phase3 is det.
% Imprime tiempo de tabla y estadísticas de la fase 3 sobre 20 mezclas.
report_phase3 :-
    statistics(cputime, Start),
    phase3_table(_),
    statistics(cputime, End),
    TableSeconds is End - Start,
    findall(Length-Nodes-Seconds,
            ( between(1, 20, _),
              random_scramble(25, Scramble),
              solved(Solved),
              apply_sequence(Scramble, Solved, State0),
              solve_phase1(State0, Moves1, _),
              apply_sequence(Moves1, State0, State1),
              solve_phase2(State1, Moves2, _),
              apply_sequence(Moves2, State1, State2),
              solve_phase3(State2, Moves3, stats(Nodes, Seconds)),
              length(Moves3, Length) ),
            Rows),
    findall(L, member(L-_-_, Rows), Lengths),
    findall(N, member(_-N-_, Rows), NodeCounts),
    findall(S, member(_-_-S, Rows), Times),
    sum_list(Lengths, SumLengths), length(Lengths, Count),
    sum_list(NodeCounts, SumNodes), sum_list(Times, SumTimes),
    max_list(Lengths, MaxLength), max_list(NodeCounts, MaxNodes),
    max_list(Times, MaxTime),
    AvgLength is SumLengths / Count,
    AvgNodes is SumNodes / Count,
    AvgTime is SumTimes / Count,
    format("Tabla fase 3 (carga o construccion): ~2f s~n", [TableSeconds]),
    format("Longitud fase 3: media ~2f, maxima ~w~n", [AvgLength, MaxLength]),
    format("Nodos fase 3: media ~2f, maximo ~w~n", [AvgNodes, MaxNodes]),
    format("Tiempo fase 3: medio ~4f s, maximo ~4f s~n", [AvgTime, MaxTime]).