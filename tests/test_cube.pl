:- use_module(library(plunit)).
:- use_module('../prolog/cube').

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

repeat_seq(0, _, S, S) :- !.
repeat_seq(N, Seq, S0, S) :-
    apply_sequence(Seq, S0, S1), N1 is N - 1, repeat_seq(N1, Seq, S1, S).

test(cuatro_giros_identidad, [forall(member(M,[u,r,f,d,l,b]))]) :-
    solved(S), repeat_seq(4, [M], S, S1), S1 == S.

test(inverso_deshace, [forall(member(M-I,[u-ui,r-ri,f-fi,d-di,l-li,b-bi]))]) :-
    solved(S), apply_sequence([M,I], S, S1), S1 == S.

test(doble_es_dos_veces, [forall(member(M-D,[u-u2,r-r2,f-f2,d-d2,l-l2,b-b2]))]) :-
    solved(S), apply_sequence([M,M], S, A), apply(D, S, B), A == B.

% Prueba fuerte: A B tiene orden 105 (no vuelve antes de 105 repeticiones)
test(orden_105, [forall(member([A,B],[[r,u],[f,r],[l,f],[b,d],[d,l],[b,r]]))]) :-
    solved(S),
    repeat_seq(105, [A,B], S, S1), S1 == S,
    forall(member(K,[15,21,35]),
           ( repeat_seq(K, [A,B], S, Sk), Sk \== S )).

:- end_tests(cube).