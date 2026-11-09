:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').

:- begin_tests(moves).

test(inverse_is_a_move, [forall(move(M))]) :-
    inverse(M, I), move(I).

test(inverse_is_involution, [forall(move(M))]) :-
    inverse(M, I), inverse(I, M2), M2 == M.

test(inverse_sequence) :-
    inverse_sequence([r,u,ri,ui], X), X == [u,r,ui,ri].

test(scramble_length) :-
    random_scramble(25, S), length(S, 25).

test(no_same_face_twice, [forall(between(1,50,_))]) :-
    random_scramble(25, S),
    \+ ( append(_, [A,B|_], S), face_of(A,F), face_of(B,F) ).

% Mezclar y deshacer con la inversa devuelve el cubo resuelto
test(scramble_then_inverse_is_identity, [forall(between(1,50,_))]) :-
    random_scramble(25, S), inverse_sequence(S, Inv),
    solved(St),
    apply_sequence(S, St, E), apply_sequence(Inv, E, R),
    R == St.

:- end_tests(moves).