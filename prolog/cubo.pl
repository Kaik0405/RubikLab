:- module(cubo, [resuelto/1, mov_base/2, aplicar/3, aplicar_seq/3]).

% estado(CP, CO, EP, EO)
resuelto(estado([0,1,2,3,4,5,6,7], [0,0,0,0,0,0,0,0],
                [0,1,2,3,4,5,6,7,8,9,10,11],
                [0,0,0,0,0,0,0,0,0,0,0,0])).

% Movimientos base (cuarto de giro horario) como hechos
mov_base(u, estado([3,0,1,2,4,5,6,7], [0,0,0,0,0,0,0,0],
                   [3,0,1,2,4,5,6,7,8,9,10,11],
                   [0,0,0,0,0,0,0,0,0,0,0,0])).

mov_base(r, estado([4,1,2,0,7,5,6,3], [2,0,0,1,1,0,0,2],
                   [8,1,2,3,11,5,6,7,4,9,10,0],
                   [0,0,0,0,0,0,0,0,0,0,0,0])).

% aplicar(+Mov, +E0, -E1): nuevo[i] = viejo[M.perm[i]], orientacion = suma mod
aplicar(M, estado(CP,CO,EP,EO), estado(CP2,CO2,EP2,EO2)) :-
    mov_base(M, estado(MCP,MCO,MEP,MEO)),
    maplist(elem(CP), MCP, CP2),
    maplist(elem(EP), MEP, EP2),
    maplist(ori(CO,3), MCP, MCO, CO2),
    maplist(ori(EO,2), MEP, MEO, EO2).

elem(L, I, X) :- nth0(I, L, X).
ori(Os, Mod, P, O, R) :- nth0(P, Os, V), R is (V + O) mod Mod.

aplicar_seq([], E, E).
aplicar_seq([M|Ms], E0, E) :- aplicar(M, E0, E1), aplicar_seq(Ms, E1, E).