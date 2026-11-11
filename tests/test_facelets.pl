:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/facelets').
:- use_module('../prolog/moves').

/** <module> Pruebas de conversión entre estados y facelets.

Verifica la conversión directa, la conversión inversa y el rechazo de
representaciones inválidas.
*/

:- begin_tests(facelets).

test(solved_to_facelets) :-
    solved(State),
    state_to_facelets(
        State,
        'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB'
    ).

test(r_to_facelets) :-
    solved(State),
    apply(r, State, RState),
    state_to_facelets(
        RState,
        'UUFUUFUUFRRRRRRRRRFFDFFDFFDDDBDDBDDBLLLLLLLLLUBBUBBUBB'
    ).

test(f_to_facelets) :-
    solved(State),
    apply(f, State, FState),
    state_to_facelets(
        FState,
        'UUUUUULLLURRURRURRFFFFFFFFFRRRDDDDDDLLDLLDLLDBBBBBBBBB'
    ).

test(facelets_length, [forall(between(1, 50, _))]) :-
    random_scramble(25, Moves),
    solved(State),
    apply_sequence(Moves, State, Scrambled),
    state_to_facelets(Scrambled, Facelets),
    atom_length(Facelets, 54).

test(round_trip, [forall(between(1, 50, _))]) :-
    random_scramble(25, Moves),
    solved(State),
    apply_sequence(Moves, State, Scrambled),
    state_to_facelets(Scrambled, Facelets),
    facelets_to_state(Facelets, Recovered),
    Recovered == Scrambled.

test(invalid_facelets, [fail]) :-
    facelets_to_state(
        'RUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB',
        _
    ).

:- end_tests(facelets).
