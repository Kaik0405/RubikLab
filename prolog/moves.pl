:- module(moves, [face_of/2, inverse/2, inverse_sequence/2, random_scramble/2]).
:- use_module(library(random), [random_member/2]).
:- use_module(cube, [move/1]).

%% face_of(+Move, -Face) is det.
% Obtiene la cara asociada al primer carácter del movimiento.
face_of(Move, Face) :-
    atom_chars(Move, [C|_]),
    atom_chars(Face, [C]).

%% inverse(+Move, -Inverse) is det.
% Calcula el movimiento inverso.
inverse(Move, Inverse) :-
    atom_chars(Move, Cs),
    inverse_chars(Cs, Is),
    atom_chars(Inverse, Is).

inverse_chars([F],     [F,i])  :- !.
inverse_chars([F,i],   [F])    :- !.
inverse_chars([F,'2'], [F,'2']).

%% inverse_sequence(+Moves, -Inverse) is det.
% Invierte el orden de una secuencia y cada uno de sus movimientos.
inverse_sequence(Moves, Inverse) :-
    reverse(Moves, Rev),
    maplist(inverse, Rev, Inverse).

%% random_scramble(+N, -Moves) is det.
% Genera N movimientos sin repetir la misma cara consecutivamente.
random_scramble(N, Moves) :- scramble(N, none, Moves).

scramble(0, _, []) :- !.
scramble(N, Prev, [M|Ms]) :-
    N > 0,
    findall(X, allowed(Prev, X), Candidates),
    random_member(M, Candidates),
    face_of(M, F),
    N1 is N - 1,
    scramble(N1, F, Ms).

allowed(Prev, Move) :-
    move(Move), face_of(Move, F), F \== Prev.