:- use_module(library(plunit)).
:- use_module('../prolog/cube').
:- use_module('../prolog/moves').
:- use_module('../prolog/search').

/** <module> Pruebas de la búsqueda IDA*.

Verifica soluciones con heurística nula, límites de profundidad y poda de
movimientos consecutivos.
*/

:- begin_tests(search).

test(random_scrambles_are_solved,
     [forall((between(1, 4, Length), between(1, 10, _)))]) :-
    random_scramble(Length, Scramble),
    solved(Solved),
    apply_sequence(Scramble, Solved, Scrambled),
    findall(Move, move(Move), Moves),
    ida_star(Scrambled, same_state(Solved), zero_heuristic,
             Moves, Length, Path, stats(Nodes, _Seconds)),
    length(Path, PathLength),
    PathLength =< Length,
    Nodes > 0,
    apply_sequence(Path, Scrambled, Result),
    Result == Solved.

test(depth_limit_is_respected, [fail]) :-
    solved(Solved),
    apply_sequence([r, u, f], Solved, Scrambled),
    findall(Move, move(Move), Moves),
    ida_star(Scrambled, same_state(Solved), zero_heuristic,
             Moves, 2, _, _).

test(solution_has_no_repeated_face) :-
    solved(Solved),
    apply_sequence([r, u, f], Solved, Scrambled),
    findall(Move, move(Move), Moves),
    ida_star(Scrambled, same_state(Solved), zero_heuristic,
             Moves, 3, Path, _),
    \+ repeated_face(Path).

same_state(Expected, Actual) :-
    Actual == Expected.

repeated_face([First, Second|Rest]) :-
    face_of(First, FirstFace),
    face_of(Second, SecondFace),
    (   FirstFace == SecondFace
    ;   repeated_face([Second|Rest])
    ).

:- end_tests(search).
