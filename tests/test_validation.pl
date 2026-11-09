:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/validation').

/** <module> Pruebas unitarias para la validación de estados del Cubo de Rubik.
    Garantiza que el módulo validation.pl detecte correctamente cubos válidos
    y clasifique con precisión las violaciones de la física del cubo.
*/

:- begin_tests(validation).

% 1. El estado resuelto original debe ser legal por definición.
test(solved_is_legal) :-
    solved(state(CP, CO, EP, EO)),
    legal(estado(CP, CO, EP, EO)).

% 2. Cualquier secuencia de movimientos válidos debe mantener la legalidad del cubo.
test(scrambled_is_legal) :-
    solved(S),
    apply_sequence([r, u, f, d], S, state(CP, CO, EP, EO)),
    legal(estado(CP, CO, EP, EO)).

% 3. Modificar la orientación de una sola esquina rompe la regla mod 3.
test(twisted_corner_is_illegal) :-
    solved(state(CP, [First|Rest], EP, EO)),
    Twisted is (First + 1) mod 3,
    illegal_reason(
        estado(CP, [Twisted|Rest], EP, EO),
        orientacion_esquinas_invalida
    ),
    \+ legal(estado(CP, [Twisted|Rest], EP, EO)).

% 4. Modificar la orientación de una sola arista rompe la regla mod 2.
test(flipped_edge_is_illegal) :-
    solved(state(CP, CO, EP, [First|Rest])),
    Flipped is (First + 1) mod 2,
    illegal_reason(
        estado(CP, CO, EP, [Flipped|Rest]),
        orientacion_aristas_invalida
    ),
    \+ legal(estado(CP, CO, EP, [Flipped|Rest])).

% 5. Intercambiar de posición dos esquinas cambia la paridad y hace que el estado sea imposible.
test(swapped_corners_is_illegal) :-
    solved(state([First, Second|Rest], CO, EP, EO)),
    illegal_reason(
        estado([Second, First|Rest], CO, EP, EO),
        paridad_permutacion_invalida
    ),
    \+ legal(estado([Second, First|Rest], CO, EP, EO)).

:- end_tests(validation).