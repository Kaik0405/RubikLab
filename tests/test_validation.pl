:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/validation').
:- use_module('../prolog/moves').

/** <module> Pruebas unitarias para la validación de estados del Cubo de Rubik.
    Garantiza que el módulo validation.pl detecte correctamente cubos válidos
    y clasifique con precisión las violaciones de la física del cubo.
*/

:- begin_tests(validation).

% 1. El estado resuelto original debe ser legal por definición.
test(solved_is_legal) :-
    solved(S),
    legal(S).

% 2. Cualquier secuencia de movimientos válidos debe mantener la legalidad del cubo.
test(scrambled_is_legal) :-
    solved(S),
    apply_sequence([r, u, f, d], S, S1),
    legal(S1).

% 3. Modificar la orientación de una sola esquina rompe la regla mod 3.
test(twisted_corner_is_illegal) :-
    solved(state(CP, [First|Rest], EP, EO)),
    Twisted is (First + 1) mod 3,
    illegal_reason(
        state(CP, [Twisted|Rest], EP, EO),
        orientacion_esquinas_invalida
    ),
    \+ legal(state(CP, [Twisted|Rest], EP, EO)).

% 4. Modificar la orientación de una sola arista rompe la regla mod 2.
test(flipped_edge_is_illegal) :-
    solved(state(CP, CO, EP, [First|Rest])),
    Flipped is (First + 1) mod 2,
    illegal_reason(
        state(CP, CO, EP, [Flipped|Rest]),
        orientacion_aristas_invalida
    ),
    \+ legal(state(CP, CO, EP, [Flipped|Rest])).

% 5. Intercambiar de posición dos esquinas cambia la paridad y hace que el estado sea imposible.
test(swapped_corners_is_illegal) :-
    solved(state([First, Second|Rest], CO, EP, EO)),
    illegal_reason(
        state([Second, First|Rest], CO, EP, EO),
        paridad_permutacion_invalida
    ),
    \+ legal(state([Second, First|Rest], CO, EP, EO)).

test(swapped_edges_is_illegal) :-
    solved(state(CP, CO, [First, Second|Rest], EO)),
    illegal_reason(
        state(CP, CO, [Second, First|Rest], EO),
        paridad_permutacion_invalida
    ),
    \+ legal(state(CP, CO, [Second, First|Rest], EO)).

test(swapped_corners_and_edges_is_legal) :-
    solved(state([FirstCorner, SecondCorner|CornerRest], CO,
                 [FirstEdge, SecondEdge|EdgeRest], EO)),
    legal(state([SecondCorner, FirstCorner|CornerRest], CO,
                [SecondEdge, FirstEdge|EdgeRest], EO)).

test(duplicated_corner_is_illegal) :-
    solved(state(_CP, CO, EP, EO)),
    illegal_reason(
        state([0,0,2,3,4,5,6,7], CO, EP, EO),
        piezas_invalidas_o_duplicadas
    ).

test(legal_state_has_no_illegal_reason) :-
    solved(S),
    \+ illegal_reason(S, _).

test(random_scrambles_are_legal, [forall(between(1, 50, _))]) :-
    random_scramble(25, Moves),
    solved(S),
    apply_sequence(Moves, S, Scrambled),
    legal(Scrambled).

:- end_tests(validation).