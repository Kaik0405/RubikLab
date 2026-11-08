:- use_module(library(plunit)).
:- use_module('../prolog/cubo').

:- begin_tests(cubo).

test(u_cambia_el_estado) :-
    resuelto(S), aplicar(u, S, S1), S1 \== S.
test(u4_es_identidad) :-
    resuelto(S), aplicar_seq([u,u,u,u], S, S1), S1 == S.
test(r4_es_identidad) :-
    resuelto(S), aplicar_seq([r,r,r,r], S, S1), S1 == S.
test(r_cambia_el_estado) :-
    resuelto(S), aplicar(r, S, S1), S1 \== S.

:- end_tests(cubo).