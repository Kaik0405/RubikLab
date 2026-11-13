:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/thistle').
:- use_module('../prolog/cfop').
:- use_module('../prolog/explainer').

/** <module> Pruebas del explicador (metaintérprete).

Comprueba que explain/3 devuelve una etapa por fase con su regla y que los
movimientos de los pasos coinciden con los del solver ejecutado directamente.
*/

:- set_random(seed(42)).

:- begin_tests(explainer).

scrambled_state(State) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State).

test(thistle_steps, [forall(between(1, 3, _))]) :-
    scrambled_state(State),
    explain(thistle, State, Steps),
    length(Steps, 4),
    Steps = [paso(thistle, 'EO', Rule, _)|_],
    atom(Rule),
    findall(M, member(paso(_, _, _, M), Steps), MoveLists),
    append(MoveLists, All),
    apply_sequence(All, State, Result),
    solved(Result).

test(cfop_steps, [forall(between(1, 3, _))]) :-
    scrambled_state(State),
    explain(cfop, State, Steps),
    length(Steps, 7),
    Steps = [paso(cfop, 'Cross', _, _)|_],
    forall(member(paso(_, _, Rule, _), Steps), atom(Rule)),
    findall(M, member(paso(_, _, _, M), Steps), MoveLists),
    append(MoveLists, All),
    apply_sequence(All, State, Result),
    solved(Result).

% La traza del metaintérprete reproduce exactamente las fases del solver directo.
test(trace_matches_direct_solver) :-
    scrambled_state(State),
    solve_cfop(State, Phases, _),
    explain(cfop, State, Steps),
    findall(M, member(phase(_, _, M, _), Phases), Direct),
    findall(M, member(paso(_, _, _, M), Steps), Explained),
    Direct == Explained.

test(oll_and_pll_rules_name_the_case) :-
    scrambled_state(State),
    explain(cfop, State, Steps),
    last(Steps, paso(cfop, PllName, PllRule, _)),
    sub_atom(PllName, 0, _, _, 'PLL'),
    atom(PllRule).

:- end_tests(explainer).
