:- module(search, [ida_star/7, zero_heuristic/2]).

:- use_module(cube, [apply/3]).
:- use_module(moves, [face_of/2]).

/** <module> Búsqueda IDA* para estados del cubo.

Exporta una búsqueda IDA* con poda de movimientos consecutivos por cara y
una heurística nula. Depende de cube.pl para aplicar movimientos y de
moves.pl para obtener la cara de cada movimiento.
*/

:- meta_predicate ida_star(+, 1, 2, +, +, -, -).

%% ida_star(+Start, :IsGoal, :Heuristic, +Moves, +MaxDepth, -Path, -Stats) is semidet.
% Busca un camino hasta la meta usando umbrales iterativos de IDA*.
ida_star(Start, IsGoal, Heuristic, Moves, MaxDepth, Path,
         stats(Nodes, Seconds)) :-
    nb_setval(search_nodes, 0),
    statistics(cputime, StartTime),
    call(Heuristic, Start, InitialHeuristic),
    ida_search(Start, IsGoal, Heuristic, Moves, MaxDepth,
               InitialHeuristic, Path),
    statistics(cputime, EndTime),
    nb_getval(search_nodes, Nodes),
    Seconds is EndTime - StartTime.

%% zero_heuristic(+State, -Value) is det.
% Devuelve una heurística nula para cualquier estado.
zero_heuristic(_, 0).

%% ida_search(+State, :IsGoal, :Heuristic, +Moves, +MaxDepth, +Threshold, -Path) is semidet.
% Repite la búsqueda hasta encontrar una solución o superar la profundidad máxima.
ida_search(State, IsGoal, Heuristic, Moves, MaxDepth, Threshold, Path) :-
    Threshold =< MaxDepth,
    nb_setval(next_threshold, MaxDepth + 1),
    depth_first_search(State, IsGoal, Heuristic, Moves, 0,
                       MaxDepth, Threshold, none, Path),
    !.
ida_search(State, IsGoal, Heuristic, Moves, MaxDepth, Threshold, Path) :-
    Threshold =< MaxDepth,
    nb_getval(next_threshold, NextThreshold),
    ida_search(State, IsGoal, Heuristic, Moves, MaxDepth,
               NextThreshold, Path).

%% depth_first_search(+State, :IsGoal, :Heuristic, +Moves, +Depth, +MaxDepth, +Threshold, +PreviousMove, -Path) is semidet.
% Explora en profundidad y registra los valores f que exceden el umbral.
depth_first_search(State, IsGoal, _, _, _, _, _, _, []) :-
    call(IsGoal, State),
    !.
depth_first_search(State, IsGoal, Heuristic, Moves, Depth, MaxDepth,
                   Threshold, PreviousMove, [Move|Path]) :-
    Depth < MaxDepth,
    member(Move, Moves),
    allowed_move(PreviousMove, Move),
    apply(Move, State, NextState),
    increment_nodes,
    NextDepth is Depth + 1,
    call(Heuristic, NextState, HeuristicValue),
    FValue is NextDepth + HeuristicValue,
    (   FValue > Threshold
    ->  record_threshold(FValue),
        fail
    ;   depth_first_search(NextState, IsGoal, Heuristic, Moves,
                           NextDepth, MaxDepth, Threshold, Move, Path)
    ).

%% increment_nodes is det.
% Incrementa el contador por cada aplicación exitosa de un movimiento.
increment_nodes :-
    nb_getval(search_nodes, Nodes),
    NextNodes is Nodes + 1,
    nb_setval(search_nodes, NextNodes).

%% record_threshold(+Value) is det.
% Conserva el menor umbral excedido durante la iteración actual.
record_threshold(Value) :-
    nb_getval(next_threshold, Current),
    (   Value < Current
    ->  nb_setval(next_threshold, Value)
    ;   true
    ).

%% allowed_move(+PreviousMove, +Move) is semidet.
% Aplica la poda de caras iguales y de pares opuestos en orden inverso.
allowed_move(none, _) :-
    !.
allowed_move(PreviousMove, Move) :-
    face_of(PreviousMove, PreviousFace),
    face_of(Move, Face),
    PreviousFace \== Face,
    \+ forbidden_order(PreviousFace, Face).

%% forbidden_order(+PreviousFace, +Face) is semidet.
% Define los órdenes opuestos que la poda no permite.
forbidden_order(d, u).
forbidden_order(l, r).
forbidden_order(b, f).
