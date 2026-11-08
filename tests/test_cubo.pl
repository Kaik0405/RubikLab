:- use_module(library(plunit)).
:- use_module('../prolog/cubo').

:- begin_tests(cubo).

test(u_cambia_el_estado) :-
    resuelto(S), aplicar(u, S, S1), S1 \== S.

test(u4_es_identidad) :-
    resuelto(S), aplicar_seq([u,u,u,u], S, S1), S1 == S.

test(r4_es_identidad) :-
    resuelto(S), aplicar_seq([r,r,r,r], S, S1), S1 == S.

test(u2x2_es_identidad) :-
    resuelto(S), aplicar_seq([u2,u2], S, S1), S1 == S.

test(r2x2_es_identidad) :-
    resuelto(S), aplicar_seq([r2,r2], S, S1), S1 == S.

test(r_cambia_el_estado) :-
    resuelto(S), aplicar(r, S, S1), S1 \== S.

test(movimiento_desconocido_falla, [fail]) :-
    resuelto(S),
    aplicar(otro_movimiento, S, _).

test(sexymove_x6_es_identidad) :-
    resuelto(S),
    length(Veces, 6),
    maplist(=([r,u,ri,ui]), Veces),
    append(Veces, Seq),
    aplicar_seq(Seq, S, S1),
    S1 == S.

:- end_tests(cubo).