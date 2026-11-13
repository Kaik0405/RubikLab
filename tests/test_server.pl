:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/server').
:- use_module(library(lists), [append/3, sum_list/2]).

/** <module> Pruebas de la respuesta pura del servidor.

Verifica la solución de mezclas y el rechazo de estados ilegales.
*/

:- begin_tests(server).

test(solve_random_scrambles) :-
    set_random(seed(42)),
    forall(between(1, 5, _),
           solve_sample).

test(illegal_state_returns_error) :-
    solved(state(CP, CO, EP, EO)),
    CO = [First|Rest],
    Twisted is (First + 1) mod 3,
    solve_response(state(CP, [Twisted|Rest], EP, EO), Dict),
    get_dict(error, Dict, "illegal_state").

test(method_responses_solve_both_methods, [forall(between(1, 3, _))]) :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    method_response(thistle, State, Thistle),
    method_response(cfop, State, Cfop),
    check_method_response(Thistle, 4, State, Solved),
    check_method_response(Cfop, 7, State, Solved).

check_method_response(Response, ExpectedSteps, State, Solved) :-
    get_dict(steps, Response, Steps),
    length(Steps, ExpectedSteps),
    findall(Moves, (member(Step, Steps), get_dict(moves, Step, Moves)),
            MoveLists),
    append(MoveLists, AllMoves),
    apply_sequence(AllMoves, State, Solved).

solve_sample :-
    random_scramble(25, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, State),
    solve_response(Scramble, Dict),
    get_dict(phases, Dict, Phases),
    phases_moves(Phases, Solution),
    apply_sequence(Solution, State, Solved),
    get_dict(total_moves, Dict, TotalMoves),
    maplist(phase_length, Phases, Lengths),
    sum_list(Lengths, TotalMoves).

phases_moves([], []).
phases_moves([Phase|Phases], Moves) :-
    get_dict(moves, Phase, PhaseMoves),
    phases_moves(Phases, Rest),
    append(PhaseMoves, Rest, Moves).

phase_length(Phase, Length) :-
    get_dict(moves, Phase, Moves),
    length(Moves, Length).

:- end_tests(server).
