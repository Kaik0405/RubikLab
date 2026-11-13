:- module(oll_pll, [
    oll/2,
    pll/2,
    oll_signature/2,
    pll_signature/2,
    solve_oll/3,
    solve_pll/3
]).

:- use_module(cube, [solved/1, apply_sequence/3]).
:- use_module(moves, [inverse_sequence/2]).
:- use_module(library(lists), [append/2, append/3]).

/** <module> Catálogo OLL/PLL y reconocimiento de casos por unificación.

Contiene los 57 casos de OLL y los 21 de PLL como hechos oll(Id, Movimientos)
y pll(Nombre, Movimientos). Los algoritmos ya están convertidos a giros de las
seis caras (los giros anchos, las capas centrales y las rotaciones del cubo se
reescribieron siguiendo el marco de referencia), de modo que solo usan los 18
movimientos de cube.pl. Un giro de capa central M cuenta como dos giros de cara.

El reconocimiento NO usa dibujos escritos a mano: el patrón de cada caso se
DERIVA aplicando la inversa del algoritmo al cubo resuelto y leyendo la firma
del último piso:
  - OLL: la firma es la orientación de las 4 esquinas y 4 aristas de U.
  - PLL: la firma es la permutación de las 4 esquinas y 4 aristas de U
    (con el último piso ya orientado), para cada AUF final posible.
Reconocer es unificar la firma del estado (tras cada AUF previo posible) con
los patrones derivados: oll_pattern/3 y pll_pattern/4.

Se asume que las dos primeras capas (cruz y F2L) están resueltas. Depende de
cube.pl y moves.pl.
*/

:- dynamic oll_pattern/3.        % oll_pattern(Signature, Id, Moves)
:- dynamic pll_pattern/4.        % pll_pattern(Signature, Name, Moves, PostAuf)
:- dynamic patterns_ready/0.

%% auf(?Turns, ?Moves) is nondet.
% Ajuste de la capa superior (Adjust U Face): 0, 1, 2 o 3 cuartos de giro.
auf(0, []).
auf(1, [u]).
auf(2, [u2]).
auf(3, [ui]).

%% oll_signature(+State, -Signature) is det.
% Firma de orientación del último piso: sig(OrientacionesEsquinas, OrientacionesAristas)
% con los huecos de U (esquinas 0..3 y aristas 0..3).
oll_signature(state(_, CO, _, EO), sig(COs, EOs)) :-
    first4(CO, COs),
    first4(EO, EOs).

%% pll_signature(+State, -Signature) is det.
% Firma de permutación del último piso: sig(PiezasEsquinas, PiezasAristas)
% en los huecos de U.
pll_signature(state(CP, _, EP, _), sig(Corners, Edges)) :-
    first4(CP, Corners),
    first4(EP, Edges).

first4([A,B,C,D|_], [A,B,C,D]).

%% ensure_patterns is det.
% Deriva una sola vez los patrones de reconocimiento a partir del catálogo.
ensure_patterns :-
    patterns_ready,
    !.
ensure_patterns :-
    with_mutex(oll_pll_patterns, build_patterns_once).

build_patterns_once :-
    patterns_ready,
    !.
build_patterns_once :-
    solved(Solved),
    forall(oll(Id, Moves),
           ( inverse_sequence(Moves, Inverse),
             apply_sequence(Inverse, Solved, Case),
             oll_signature(Case, Signature),
             assertz(oll_pattern(Signature, Id, Moves)) )),
    forall(( pll(Name, Moves), auf(_, Post) ),
           ( append(Moves, Post, Full),
             inverse_sequence(Full, Inverse),
             apply_sequence(Inverse, Solved, Case),
             pll_signature(Case, Signature),
             assertz(pll_pattern(Signature, Name, Moves, Post)) )),
    forall(auf(_, Post),
           ( inverse_sequence(Post, Inverse),
             apply_sequence(Inverse, Solved, Case),
             pll_signature(Case, Signature),
             assertz(pll_pattern(Signature, skip, [], Post)) )),
    assertz(patterns_ready).

%% solve_oll(+State, -Moves, -Rule) is semidet.
% Orienta el último piso. Rule es skip (ya orientado) o oll(Id, AufPrevio).
% Entre los casos que encajan elige la secuencia más corta. Falla si las dos
% primeras capas no están resueltas.
solve_oll(State, Moves, Rule) :-
    ensure_patterns,
    (   oll_signature(State, sig([0,0,0,0], [0,0,0,0]))
    ->  Moves = [],
        Rule = skip
    ;   findall(Length-(Moves0-Rule0),
                ( auf(_, Pre),
                  apply_sequence(Pre, State, Rotated),
                  oll_signature(Rotated, Signature),
                  oll_pattern(Signature, Id, Algorithm),
                  append(Pre, Algorithm, Moves0),
                  Rule0 = oll(Id, Pre),
                  length(Moves0, Length) ),
                Candidates),
        Candidates \== [],
        keysort(Candidates, [_-(Moves-Rule)|_])
    ).

%% solve_pll(+State, -Moves, -Rule) is semidet.
% Permuta el último piso (ya orientado) hasta resolver el cubo. Rule es
% pll(Nombre, AufPrevio, AufFinal); Nombre es skip si solo hace falta un AUF.
solve_pll(State, Moves, Rule) :-
    ensure_patterns,
    findall(Length-(Moves0-Rule0),
            ( auf(_, Pre),
              apply_sequence(Pre, State, Rotated),
              pll_signature(Rotated, Signature),
              pll_pattern(Signature, Name, Algorithm, Post),
              append([Pre, Algorithm, Post], Moves0),
              Rule0 = pll(Name, Pre, Post),
              length(Moves0, Length) ),
            Candidates),
    Candidates \== [],
    keysort(Candidates, [_-(Moves-Rule)|_]).

%% ------------------------------------------------------------------
%% Catálogo OLL (57 casos). Cada comentario muestra la notación original.
%% ------------------------------------------------------------------

%  OLL 1: R U2 R2 F R F' U2 R' F R F'
oll(1, [r,u2,r2,f,r,fi,u2,ri,f,r,fi]).
%  OLL 2: F R U R' U' F' f R U R' U' f'
oll(2, [f,r,u,ri,ui,fi,b,u,l,ui,li,bi]).
%  OLL 3: f R U R' U' f' U' F R U R' U' F'
oll(3, [b,u,l,ui,li,bi,ui,f,r,u,ri,ui,fi]).
%  OLL 4: f R U R' U' f' U F R U R' U' F'
oll(4, [b,u,l,ui,li,bi,u,f,r,u,ri,ui,fi]).
%  OLL 5: r' U2 R U R' U r
oll(5, [li,b2,r,b,ri,b,l]).
%  OLL 6: r U2 R' U' R U' r'
oll(6, [l,f2,ri,fi,r,fi,li]).
%  OLL 7: r U R' U R U2 r'
oll(7, [l,f,ri,f,r,f2,li]).
%  OLL 8: r' U' R U' R' U2 r
oll(8, [li,bi,r,bi,ri,b2,l]).
%  OLL 9: R U R' U' R' F R2 U R' U' F'
oll(9, [r,u,ri,ui,ri,f,r2,u,ri,ui,fi]).
%  OLL 10: R U R' U R' F R F' R U2 R'
oll(10, [r,u,ri,u,ri,f,r,fi,r,u2,ri]).
%  OLL 11: r U R' U R' F R F' R U2 r'
oll(11, [l,f,ri,f,ri,d,r,di,r,f2,li]).
%  OLL 12: F R U R' U' F' U F R U R' U' F'
oll(12, [f,r,u,ri,ui,fi,u,f,r,u,ri,ui,fi]).
%  OLL 13: F U R U' R2 F' R U R U' R'
oll(13, [f,u,r,ui,r2,fi,r,u,r,ui,ri]).
%  OLL 14: R' F R U R' F' R F U' F'
oll(14, [ri,f,r,u,ri,fi,r,f,ui,fi]).
%  OLL 15: r' U' r R' U' R U r' U r
oll(15, [li,bi,l,ri,ui,r,u,li,b,l]).
%  OLL 16: r U r' R U R' U' r U' r'
oll(16, [l,f,li,r,u,ri,ui,l,fi,li]).
%  OLL 17: R U R' U R' F R F' U2 R' F R F'
oll(17, [r,u,ri,u,ri,f,r,fi,u2,ri,f,r,fi]).
%  OLL 18: R U2 R2 F R F' U2 M' U R U' r'
oll(18, [r,u2,r2,f,r,fi,u2,ri,l,f,r,fi,li]).
%  OLL 19: r' R U R U R' U' M' R' F R F'
oll(19, [li,r,b,r,b,ri,bi,ri,l,ri,f,r,fi]).
%  OLL 20: r U R' U' M2 U R U' R' U' M'
oll(20, [l,f,ri,fi,r2,l2,b,r,bi,ri,bi,ri,l]).
%  OLL 21: R U R' U R U' R' U R U2 R'
oll(21, [r,u,ri,u,r,ui,ri,u,r,u2,ri]).
%  OLL 22: R U2 R2 U' R2 U' R2 U2 R
oll(22, [r,u2,r2,ui,r2,ui,r2,u2,r]).
%  OLL 23: R2 D R' U2 R D' R' U2 R'
oll(23, [r2,d,ri,u2,r,di,ri,u2,ri]).
%  OLL 24: r U R' U' r' F R F'
oll(24, [l,f,ri,fi,li,f,r,fi]).
%  OLL 25: F' r U R' U' r' F R
oll(25, [fi,l,f,ri,fi,li,f,r]).
%  OLL 26: R U2 R' U' R U' R'
oll(26, [r,u2,ri,ui,r,ui,ri]).
%  OLL 27: R U R' U R U2 R'
oll(27, [r,u,ri,u,r,u2,ri]).
%  OLL 28: r U R' U' r' R U R U' R'
oll(28, [l,f,ri,fi,li,r,u,r,ui,ri]).
%  OLL 29: R U R' U' R U' R' F' U' F R U R'
oll(29, [r,u,ri,ui,r,ui,ri,fi,ui,f,r,u,ri]).
%  OLL 30: F R' F R2 U' R' U' R U R' F2
oll(30, [f,ri,f,r2,ui,ri,ui,r,u,ri,f2]).
%  OLL 31: R' U' F U R U' R' F' R
oll(31, [ri,ui,f,u,r,ui,ri,fi,r]).
%  OLL 32: R U B' U' R' U R B R'
oll(32, [r,u,bi,ui,ri,u,r,b,ri]).
%  OLL 33: R U R' U' R' F R F'
oll(33, [r,u,ri,ui,ri,f,r,fi]).
%  OLL 34: R U R2 U' R' F R U R U' F'
oll(34, [r,u,r2,ui,ri,f,r,u,r,ui,fi]).
%  OLL 35: R U2 R2 F R F' R U2 R'
oll(35, [r,u2,r2,f,r,fi,r,u2,ri]).
%  OLL 36: R' U' R U' R' U R U R B' R' B
oll(36, [ri,ui,r,ui,ri,u,r,u,r,bi,ri,b]).
%  OLL 37: F R' F' R U R U' R'
oll(37, [f,ri,fi,r,u,r,ui,ri]).
%  OLL 38: R U R' U R U' R' U' R' F R F'
oll(38, [r,u,ri,u,r,ui,ri,ui,ri,f,r,fi]).
%  OLL 39: R U R' F' U' F U R U2 R'
oll(39, [r,u,ri,fi,ui,f,u,r,u2,ri]).
%  OLL 40: R' F R U R' U' F' U R
oll(40, [ri,f,r,u,ri,ui,fi,u,r]).
%  OLL 41: R U R' U R U2 R' F R U R' U' F'
oll(41, [r,u,ri,u,r,u2,ri,f,r,u,ri,ui,fi]).
%  OLL 42: R' U' R U' R' U2 R F R U R' U' F'
oll(42, [ri,ui,r,ui,ri,u2,r,f,r,u,ri,ui,fi]).
%  OLL 43: R' U' F' U F R
oll(43, [ri,ui,fi,u,f,r]).
%  OLL 44: F U R U' R' F'
oll(44, [f,u,r,ui,ri,fi]).
%  OLL 45: F R U R' U' F'
oll(45, [f,r,u,ri,ui,fi]).
%  OLL 46: R' U' R' F R F' U R
oll(46, [ri,ui,ri,f,r,fi,u,r]).
%  OLL 47: R' U' R' F R F' R' F R F' U R
oll(47, [ri,ui,ri,f,r,fi,ri,f,r,fi,u,r]).
%  OLL 48: F R U R' U' R U R' U' F'
oll(48, [f,r,u,ri,ui,r,u,ri,ui,fi]).
%  OLL 49: r U' r2 U r2 U r2 U' r
oll(49, [l,fi,l2,b,l2,f,l2,bi,l]).
%  OLL 50: r' U r2 U' r2 U' r2 U r'
oll(50, [li,b,l2,fi,l2,bi,l2,f,li]).
%  OLL 51: F U R U' R' U R U' R' F'
oll(51, [f,u,r,ui,ri,u,r,ui,ri,fi]).
%  OLL 52: R U R' U R U' B U' B' R'
oll(52, [r,u,ri,u,r,ui,b,ui,bi,ri]).
%  OLL 53: r' U' R U' R' U R U' R' U2 r
oll(53, [li,bi,r,bi,ri,b,r,bi,ri,b2,l]).
%  OLL 54: r U R' U R U' R' U R U2 r'
oll(54, [l,f,ri,f,r,fi,ri,f,r,f2,li]).
%  OLL 55: R U2 R2 U' R U' R' U2 F R F'
oll(55, [r,u2,r2,ui,r,ui,ri,u2,f,r,fi]).
%  OLL 56: r U r' U R U' R' U R U' R' r U' r'
oll(56, [l,f,li,u,r,ui,ri,u,r,ui,ri,l,fi,li]).
%  OLL 57: R U R' U' M' U R U' r'
oll(57, [r,u,ri,ui,ri,l,f,r,fi,li]).

%% ------------------------------------------------------------------
%% Catálogo PLL (21 casos).
%% ------------------------------------------------------------------

%  PLL Aa: x R' U R' D2 R U' R' D2 R2
pll(aa, [ri,f,ri,b2,r,fi,ri,b2,r2]).
%  PLL Ab: x R2 D2 R U R' D2 R U' R
pll(ab, [r2,b2,r,f,ri,b2,r,fi,r]).
%  PLL E: x' R U' R' D R U R' D' R U R' D R U' R' D'
pll(e, [r,bi,ri,f,r,b,ri,fi,r,b,ri,f,r,bi,ri,fi]).
%  PLL F: R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R
pll(f, [ri,ui,fi,r,u,ri,ui,ri,f,r2,ui,ri,ui,r,u,ri,u,r]).
%  PLL Ga: R2 U R' U R' U' R U' R2 D U' R' U R D'
pll(ga, [r2,u,ri,u,ri,ui,r,ui,r2,d,ui,ri,u,r,di]).
%  PLL Gb: R' U' R U D' R2 U R' U R U' R U' R2 D
pll(gb, [ri,ui,r,u,di,r2,u,ri,u,r,ui,r,ui,r2,d]).
%  PLL Gc: R2 U' R U' R U R' U R2 D' U R U' R' D
pll(gc, [r2,ui,r,ui,r,u,ri,u,r2,di,u,r,ui,ri,d]).
%  PLL Gd: R U R' U' D R2 U' R U' R' U R' U R2 D'
pll(gd, [r,u,ri,ui,d,r2,ui,r,ui,ri,u,ri,u,r2,di]).
%  PLL H: M2 U M2 U2 M2 U M2
pll(h, [r2,l2,d,r2,l2,u2,r2,l2,d,r2,l2]).
%  PLL Ja: x R2 F R F' R U2 r' U r U2
pll(ja, [r2,d,r,di,r,f2,li,u,l,f2]).
%  PLL Jb: R U R' F' R U R' U' R' F R2 U' R' U'
pll(jb, [r,u,ri,fi,r,u,ri,ui,ri,f,r2,ui,ri,ui]).
%  PLL Na: R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'
pll(na, [r,u,ri,u,r,u,ri,fi,r,u,ri,ui,ri,f,r2,ui,ri,u2,r,ui,ri]).
%  PLL Nb: R' U R U' R' F' U' F R U R' F R' F' R U' R
pll(nb, [ri,u,r,ui,ri,fi,ui,f,r,u,ri,f,ri,fi,r,ui,r]).
%  PLL Ra: R U' R' U' R U R D R' U' R D' R' U2 R'
pll(ra, [r,ui,ri,ui,r,u,r,d,ri,ui,r,di,ri,u2,ri]).
%  PLL Rb: R' U2 R U2 R' F R U R' U' R' F' R2
pll(rb, [ri,u2,r,u2,ri,f,r,u,ri,ui,ri,fi,r2]).
%  PLL T: R U R' U' R' F R2 U' R' U' R U R' F'
pll(t, [r,u,ri,ui,ri,f,r2,ui,ri,ui,r,u,ri,fi]).
%  PLL Ua: M2 U M U2 M' U M2
pll(ua, [r2,l2,d,r,li,f2,ri,l,d,r2,l2]).
%  PLL Ub: M2 U' M U2 M' U' M2
pll(ub, [r2,l2,di,r,li,f2,ri,l,di,r2,l2]).
%  PLL V: R' U R' U' y R' F' R2 U' R' U R' F R F
pll(v, [ri,u,ri,ui,bi,ri,b2,ui,bi,u,bi,r,b,r]).
%  PLL Y: F R U' R' U' R U R' F' R U R' U' R' F R F'
pll(y, [f,r,ui,ri,ui,r,u,ri,fi,r,u,ri,ui,ri,f,r,fi]).
%  PLL Z: M' U M2 U M2 U M' U2 M2
pll(z, [ri,l,f,r2,l2,b,r2,l2,f,ri,l,d2,r2,l2]).
