:- module(moves, [face_of/2, inverse/2, inverse_sequence/2, random_scramble/2]).
:- use_module(library(random), [random_member/2]).
:- use_module(cube, [move/1]).

%% face_of(+Move, -Face) is det.
% Estos hechos evitan descomponer átomos en cada llamada; se usan millones
% de veces durante la búsqueda.
face_of(u, u).
face_of(ui, u).
face_of(u2, u).
face_of(r, r).
face_of(ri, r).
face_of(r2, r).
face_of(f, f).
face_of(fi, f).
face_of(f2, f).
face_of(d, d).
face_of(di, d).
face_of(d2, d).
face_of(l, l).
face_of(li, l).
face_of(l2, l).
face_of(b, b).
face_of(bi, b).
face_of(b2, b).

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