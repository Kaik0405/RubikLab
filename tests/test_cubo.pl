:- use_module(library(plunit)).
:- use_module('../prolog/cubo').

/** <module> Pruebas de las operaciones del cubo.

Verifica los movimientos básicos, sus repeticiones, las secuencias
conocidas y el comportamiento ante movimientos desconocidos.
*/

:- begin_tests(cube).

% Un giro de cuarto de vuelta debe modificar el estado resuelto.
test(u_changes_state) :-
    solved(S), apply(u, S, S1), S1 \== S.

% Cuatro giros iguales deben devolver el cubo a su estado inicial.
test(u4_is_identity) :-
    solved(S), apply_sequence([u,u,u,u], S, S1), S1 == S.

test(r4_is_identity) :-
    solved(S), apply_sequence([r,r,r,r], S, S1), S1 == S.

% Dos giros de media vuelta equivalen a la identidad.
test(u2x2_is_identity) :-
    solved(S), apply_sequence([u2,u2], S, S1), S1 == S.

test(r2x2_is_identity) :-
    solved(S), apply_sequence([r2,r2], S, S1), S1 == S.

test(r_changes_state) :-
    solved(S), apply(r, S, S1), S1 \== S.

% Un movimiento que no existe debe hacer que la prueba falle.
test(unknown_move_fails, [fail]) :-
    solved(S),
    apply(unknown_move, S, _).

% La secuencia sexy repetida seis veces es una identidad.
test(sexy_move_x6_is_identity) :-
    solved(S),
    length(Sequences, 6),
    maplist(=([r,u,ri,ui]), Sequences),
    append(Sequences, Moves),
    apply_sequence(Moves, S, S1),
    S1 == S.

:- end_tests(cube).