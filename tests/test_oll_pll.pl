:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/oll_pll').

/** <module> Pruebas del catálogo OLL/PLL y del reconocimiento.

Comprueba el tamaño del catálogo, que cada algoritmo conserva las dos primeras
capas, que los 216 patrones de orientación y las 288 permutaciones del último
piso se reconocen y se resuelven, y que cada caso del catálogo se resuelve.
*/

:- begin_tests(oll_pll).

% Las dos primeras capas: esquinas 4..7 y aristas 4..11 en su sitio y sin giro.
f2l_intact(state(CP, CO, EP, EO)) :-
    length(CTail, 4), append(_, CTail, CP), CTail == [4,5,6,7],
    length(COTail, 4), append(_, COTail, CO), COTail == [0,0,0,0],
    length(ETail, 8), append(_, ETail, EP), ETail == [4,5,6,7,8,9,10,11],
    length(EOTail, 8), append(_, EOTail, EO),
    EOTail == [0,0,0,0,0,0,0,0].

ll_oriented(state(_, CO, _, EO)) :-
    length(Corners, 4), append(Corners, _, CO), Corners == [0,0,0,0],
    length(Edges, 4), append(Edges, _, EO), Edges == [0,0,0,0].

ll_state(CO4, EO4, CP4, EP4, state(CP, CO, EP, EO)) :-
    append(CP4, [4,5,6,7], CP),
    append(CO4, [0,0,0,0], CO),
    append(EP4, [4,5,6,7,8,9,10,11], EP),
    append(EO4, [0,0,0,0,0,0,0,0], EO).

perm_parity(List, Parity) :-
    findall(x, ( nth0(I, List, A), nth0(J, List, B), I < J, A > B ), Inversions),
    length(Inversions, N),
    Parity is N mod 2.

test(catalog_sizes) :-
    findall(Id, oll(Id, _), Olls), length(Olls, 57),
    findall(Name, pll(Name, _), Plls), length(Plls, 21).

test(oll_algorithms_keep_two_layers) :-
    solved(Solved),
    forall(oll(_, Moves),
           ( apply_sequence(Moves, Solved, State), f2l_intact(State) )).

test(oll_cases_are_oriented_by_their_algorithm) :-
    solved(Solved),
    forall(oll(_, Moves),
           ( inverse_sequence(Moves, Inverse),
             apply_sequence(Inverse, Solved, Case),
             f2l_intact(Case),
             apply_sequence(Moves, Case, After),
             ll_oriented(After) )).

test(pll_algorithms_keep_two_layers_and_orientation) :-
    solved(Solved),
    forall(pll(_, Moves),
           ( apply_sequence(Moves, Solved, State),
             f2l_intact(State), ll_oriented(State) )).

% Los 216 patrones de orientación posibles del último piso se resuelven.
test(all_216_oll_orientations_are_recognised) :-
    findall(CO4-EO4,
            ( CO4 = [A,B,C,D],
              member(A, [0,1,2]), member(B, [0,1,2]),
              member(C, [0,1,2]), member(D, [0,1,2]),
              0 =:= (A+B+C+D) mod 3,
              EO4 = [E,F,G,H],
              member(E, [0,1]), member(F, [0,1]),
              member(G, [0,1]), member(H, [0,1]),
              0 =:= (E+F+G+H) mod 2 ),
            Cases),
    length(Cases, 216),
    forall(member(CO4-EO4, Cases),
           ( ll_state(CO4, EO4, [0,1,2,3], [0,1,2,3], State),
             solve_oll(State, Moves, _),
             apply_sequence(Moves, State, After),
             ll_oriented(After), f2l_intact(After) )).

% Las 288 permutaciones posibles del último piso (con paridad compatible) se resuelven.
test(all_288_pll_permutations_are_solved) :-
    solved(Solved),
    findall(CP4-EP4,
            ( permutation([0,1,2,3], CP4),
              permutation([0,1,2,3], EP4),
              perm_parity(CP4, P), perm_parity(EP4, P) ),
            Cases),
    length(Cases, 288),
    forall(member(CP4-EP4, Cases),
           ( ll_state([0,0,0,0], [0,0,0,0], CP4, EP4, State),
             solve_pll(State, Moves, _),
             apply_sequence(Moves, State, After),
             After == Solved )).

% Cada caso del catálogo se reconoce y se resuelve completo (OLL y luego PLL no aplica aquí).
test(every_oll_case_is_solved_by_oll_step) :-
    solved(Solved),
    forall(oll(_, Moves),
           ( inverse_sequence(Moves, Inverse),
             apply_sequence(Inverse, Solved, Case),
             solve_oll(Case, Found, _),
             apply_sequence(Found, Case, After),
             ll_oriented(After) )).

test(every_pll_case_is_solved) :-
    solved(Solved),
    forall(pll(_, Moves),
           ( inverse_sequence(Moves, Inverse),
             apply_sequence(Inverse, Solved, Case),
             solve_pll(Case, Found, _),
             apply_sequence(Found, Case, After),
             After == Solved )).

test(solved_cube_needs_no_moves) :-
    solved(Solved),
    solve_oll(Solved, [], skip),
    solve_pll(Solved, [], pll(skip, [], [])).

:- end_tests(oll_pll).
