:- module(validation, [
    legal/1,
    illegal_reason/2
]).

:- use_module(cube, [solved/1]).
:- use_module(library(lists), [sum_list/2]).

/** <module> Validación de estados físicos del Cubo de Rubik.
    Implementa las restricciones matemáticas de la teoría de grupos para 
    determinar si una configuración del cubo es alcanzable y legal en el mundo real.
*/

%% legal_corner_orientation(+CO) is semidet.
% Comprueba que la suma de las orientaciones de las esquinas sea múltiplo de 3.
legal_corner_orientation(CO) :-
    sum_list(CO, Sum),
    Sum mod 3 =:= 0.

%% legal_edge_orientation(+EO) is semidet.
% Comprueba que la suma de las orientaciones de las aristas sea múltiplo de 2.
legal_edge_orientation(EO) :-
    sum_list(EO, Sum),
    Sum mod 2 =:= 0.

%% count_inversions(+List, -Count) is det.
% Cuenta el número de inversiones en una lista de permutación.
count_inversions([], 0).
count_inversions([Head|Tail], Count) :-
    count_smaller(Head, Tail, Current),
    count_inversions(Tail, Rest),
    Count is Current + Rest.

count_smaller(_, [], 0).
count_smaller(Value, [Head|Tail], Count) :-
    count_smaller(Value, Tail, Rest),
    (Value > Head -> Count is Rest + 1 ; Count = Rest).

%% permutation_parity(+List, -Parity) is det.
% Determina si la paridad de las inversiones es 0 (par) o 1 (impar).
permutation_parity(List, Parity) :-
    count_inversions(List, Count),
    Parity is Count mod 2.

%% legal_parity(+CP, +EP) is semidet.
% Verifica que la paridad de la permutación de esquinas y aristas coincida.
legal_parity(CP, EP) :-
    permutation_parity(CP, CornerParity),
    permutation_parity(EP, EdgeParity),
    CornerParity =:= EdgeParity.

%% legal_elements(+CP, +EP) is semidet.
% Asegura que las listas contengan exactamente las piezas válidas sin duplicados.
legal_elements(CP, EP) :-
    msort(CP, [0,1,2,3,4,5,6,7]),
    msort(EP, [0,1,2,3,4,5,6,7,8,9,10,11]).

%% legal(+State) is semidet.
% Un estado es completamente legal si cumple las orientaciones, paridad e integridad.
legal(state(CP, CO, EP, EO)) :-
    legal_elements(CP, EP),
    legal_corner_orientation(CO),
    legal_edge_orientation(EO),
    legal_parity(CP, EP).

%% illegal_reason(+State, -Reason) is semidet.
% Diagnóstica la primera razón exacta por la cual un estado no es físico ni legal.
illegal_reason(state(CP, _CO, EP, _EO), piezas_invalidas_o_duplicadas) :-
    \+ legal_elements(CP, EP),
    !.
illegal_reason(state(_CP, CO, _EP, _EO), orientacion_esquinas_invalida) :-
    \+ legal_corner_orientation(CO),
    !.
illegal_reason(state(_CP, _CO, _EP, EO), orientacion_aristas_invalida) :-
    \+ legal_edge_orientation(EO),
    !.
illegal_reason(state(CP, _CO, EP, _EO), paridad_permutacion_invalida) :-
    \+ legal_parity(CP, EP),
    !.