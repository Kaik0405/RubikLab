:- module(cube, [solved/1, base_move/2, apply/3, apply_sequence/3, move/1]).

/** <module> Estado y operaciones del cubo de Rubik.

El estado almacena la permutación y orientación de las esquinas,
seguidas de la permutación y orientación de las aristas.
*/

%% solved(-State) is semidet.
%
% Un estado resuelto utiliza la misma estructura de cuatro listas que los
% demás estados, pero con las permutaciones en orden y orientaciones nulas.
solved(state([0,1,2,3,4,5,6,7], [0,0,0,0,0,0,0,0],
             [0,1,2,3,4,5,6,7,8,9,10,11],
             [0,0,0,0,0,0,0,0,0,0,0,0])).

% Los movimientos base se representan como hechos usando la notación de
% giros de cuarto de vuelta en sentido horario.

base_move(u, state([3,0,1,2,4,5,6,7], [0,0,0,0,0,0,0,0],
                   [3,0,1,2,4,5,6,7,8,9,10,11],
                   [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(ui, state([1,2,3,0,4,5,6,7], [0,0,0,0,0,0,0,0],
                    [1,2,3,0,4,5,6,7,8,9,10,11],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(u2, state([2,3,0,1,4,5,6,7], [0,0,0,0,0,0,0,0],
                    [2,3,0,1,4,5,6,7,8,9,10,11],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).                

base_move(r, state([4,1,2,0,7,5,6,3], [2,0,0,1,1,0,0,2],
                   [8,1,2,3,11,5,6,7,4,9,10,0],
                   [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(ri, state([3,1,2,7,0,5,6,4], [2,0,0,1,1,0,0,2],
                    [11,1,2,3,8,5,6,7,0,9,10,4],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(r2, state([7,1,2,4,3,5,6,0], [0,0,0,0,0,0,0,0],
                    [4,1,2,3,0,5,6,7,11,9,10,8],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).

base_move(f, state([1,5,2,3,0,4,6,7], [1,2,0,0,2,1,0,0],
                   [0,9,2,3,4,8,6,7,1,5,10,11],
                   [0,1,0,0,0,1,0,0,1,1,0,0])).
base_move(fi, state([4,0,2,3,5,1,6,7], [1,2,0,0,2,1,0,0],
                    [0,8,2,3,4,9,6,7,5,1,10,11],
                    [0,1,0,0,0,1,0,0,1,1,0,0])).
base_move(f2, state([5,4,2,3,1,0,6,7], [0,0,0,0,0,0,0,0],
                    [0,5,2,3,4,1,6,7,9,8,10,11],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).

base_move(d, state([0,1,2,3,5,6,7,4], [0,0,0,0,0,0,0,0],
                   [0,1,2,3,5,6,7,4,8,9,10,11],
                   [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(di, state([0,1,2,3,7,4,5,6], [0,0,0,0,0,0,0,0],
                    [0,1,2,3,7,4,5,6,8,9,10,11],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(d2, state([0,1,2,3,6,7,4,5], [0,0,0,0,0,0,0,0],
                    [0,1,2,3,6,7,4,5,8,9,10,11],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).

base_move(l, state([0,2,6,3,4,1,5,7], [0,1,2,0,0,2,1,0],
                   [0,1,10,3,4,5,9,7,8,2,6,11],
                   [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(li, state([0,5,1,3,4,6,2,7], [0,1,2,0,0,2,1,0],
                    [0,1,9,3,4,5,10,7,8,6,2,11],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).
base_move(l2, state([0,6,5,3,4,2,1,7], [0,0,0,0,0,0,0,0],
                    [0,1,6,3,4,5,2,7,8,10,9,11],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).

base_move(b, state([0,1,3,7,4,5,2,6], [0,0,1,2,0,0,2,1],
                   [0,1,2,11,4,5,6,10,8,9,3,7],
                   [0,0,0,1,0,0,0,1,0,0,1,1])).
base_move(bi, state([0,1,6,2,4,5,7,3], [0,0,1,2,0,0,2,1],
                    [0,1,2,10,4,5,6,11,8,9,7,3],
                    [0,0,0,1,0,0,0,1,0,0,1,1])).
base_move(b2, state([0,1,7,6,4,5,3,2], [0,0,0,0,0,0,0,0],
                    [0,1,2,7,4,5,6,3,8,9,11,10],
                    [0,0,0,0,0,0,0,0,0,0,0,0])).

%% move(?Move) is nondet.
%
% Move es uno de los movimientos definidos en base_move/2. Es la unica
% fuente de verdad: si agregas un movimiento, aparece aqui solo.
move(Move) :- base_move(Move, _).                

%% apply(+Move, +InitialState, -FinalState) is semidet.
%
% Aplica un movimiento usando los índices de permutación y el módulo de
% orientación correspondiente a esquinas y aristas.

apply(Move, state(CP,CO,EP,EO), state(CP2,CO2,EP2,EO2)) :-
    once(base_move(Move, state(MCP,MCO,MEP,MEO))),
    maplist(element(CP), MCP, CP2),
    maplist(element(EP), MEP, EP2),
    maplist(orientation(CO,3), MCP, MCO, CO2),
    maplist(orientation(EO,2), MEP, MEO, EO2).

element(List, Index, Value) :-
    nth0(Index, List, Value).

orientation(Orientations, Modulus, Position, Offset, Result) :-
    nth0(Position, Orientations, Value),
    Result is (Value + Offset) mod Modulus.

%% apply_sequence(+Moves, +InitialState, -FinalState) is semidet.
%
% Aplica los movimientos de izquierda a derecha.

apply_sequence([], State, State).
apply_sequence([Move|Moves], InitialState, FinalState) :-
    apply(Move, InitialState, IntermediateState),
    apply_sequence(Moves, IntermediateState, FinalState).