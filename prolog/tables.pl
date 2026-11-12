:- module(tables, [
    coord_apply/4,
    state_coord/3,
    goal_coord/2,
    build_table/3,
    table_distance/3,
    cached_table/3,
    phase3_key/2,
    phase3_goal_key/1,
    phase3_table/1,
    state_key/2,
    phase4_table/1
]).

:- use_module(cube, [apply/3, base_move/2, solved/1]).
:- use_module(library(assoc), [assoc_to_list/2, empty_assoc/1,
                               get_assoc/3, put_assoc/4]).
:- use_module(library(lists), [append/3, member/2, memberchk/2, nth0/3,
                               numlist/3, permutation/2, reverse/2]).
:- use_module(library(apply), [maplist/3, maplist/4, maplist/5]).

/** <module> Tablas de coordenadas para las fases del cubo.

Contiene las coordenadas reducidas (orientación de aristas, orientación de
esquinas y capa intermedia), la construcción de tablas de distancias por BFS
con caché en memoria, y la coordenada de coclase de la fase 3 de
Thistlethwaite (29400 clases, 12 clases de S3^5 por órbita de generadores).

La tabla de la fase 3 se guarda en disco (data/phase3.cache, formato binario
con número de versión) para no reconstruirla en cada ejecución. Si el archivo
no existe, está corrupto o es de otra versión, se reconstruye sin error.
Depende de cube.pl para los movimientos y estados.
*/

:- dynamic table_cache/3.
:- dynamic phase3_table_cache/1.
:- dynamic phase3_goal_cache/1.

%% ------------------------------------------------------------------
%% Coordenadas simples (fases 1 y 2)
%% ------------------------------------------------------------------

%% coord_apply(+Kind, +Move, +Coord0, -Coord1) is det.
% Aplica un movimiento a una coordenada de orientación o de capa.
coord_apply(eo, Move, Coord0, Coord1) :-
    base_move(Move, state(_, _, MEP, MEO)),
    numlist(0, 11, Positions),
    maplist(apply_edge_orientation(Coord0, MEP, MEO), Positions, Coord1).
coord_apply(co, Move, Coord0, Coord1) :-
    base_move(Move, state(MCP, MCO, _, _)),
    numlist(0, 7, Positions),
    maplist(apply_corner_orientation(Coord0, MCP, MCO), Positions, Coord1).
coord_apply(slice, Move, Coord0, Coord1) :-
    base_move(Move, state(_, _, MEP, _)),
    numlist(0, 11, Positions),
    maplist(select_edge_coordinate(Coord0, MEP), Positions, Coord1).

%% state_coord(+Kind, +State, -Coord) is det.
% Extrae la coordenada solicitada desde un estado completo.
state_coord(eo, state(_, _, _, EO), EO).
state_coord(co, state(_, CO, _, _), CO).
state_coord(slice, state(_, _, EP, _), Coord) :-
    maplist(slice_value(EP), EP, Coord).

%% goal_coord(+Kind, -Coord) is det.
% Construye la coordenada objetivo de una fase.
goal_coord(eo, Coord) :-
    length(Coord, 12),
    maplist(=(0), Coord).
goal_coord(co, Coord) :-
    length(Coord, 8),
    maplist(=(0), Coord).
goal_coord(slice, [0,0,0,0,0,0,0,0,1,1,1,1]).

%% build_table(+Kind, +Moves, -Table) is det.
% Construye por BFS la tabla de distancias desde la coordenada objetivo.
build_table(Kind, Moves, Table) :-
    goal_coord(Kind, Goal),
    empty_assoc(InitialTable),
    put_assoc(Goal, InitialTable, 0, Table0),
    bfs(Kind, Moves, [Goal], Table0, Table).

%% table_distance(+Table, +Coord, -Distance) is semidet.
% Obtiene la distancia de una coordenada. Acepta coordenadas en forma de
% lista (fases 1 y 2) o claves f(_,_,_) de la fase 3.
table_distance(Table, Coord, Distance) :-
    (   Coord = f(_, _, _)
    ->  tuple_index_from_key(Coord, Index),
        get_assoc(Index, Table, Distance)
    ;   get_assoc(Coord, Table, Distance)
    ).

%% cached_table(+Kind, +Moves, -Table) is det.
% Construye una tabla una sola vez y reutiliza las llamadas posteriores.
cached_table(Kind, Moves, Table) :-
    table_cache(Kind, Moves, Table),
    !.
cached_table(Kind, Moves, Table) :-
    build_table(Kind, Moves, Table),
    assertz(table_cache(Kind, Moves, Table)).

%% ------------------------------------------------------------------
%% Fase 3: coordenada de coclase
%% ------------------------------------------------------------------

%% phase3_key(+State, -Key) is det.
% Calcula la clave de coclase f(EtiquetasEsquinas, EtiquetasAristas, Clase).
phase3_key(state(CP, _, EP, _), Key) :-
    maplist(corner_orbit_label, CP, CornerLabels),
    maplist(edge_orbit_label, EP, EdgeLabels),
    orbit_array(a, CP, CornerLabels, A),
    orbit_array(b, CP, CornerLabels, B),
    orbit_array(s, EP, EdgeLabels, S),
    orbit_array(m, EP, EdgeLabels, M),
    orbit_array(e, EP, EdgeLabels, E),
    maplist(psi, [A,B,S,M,E], Psi),
    phase3_class_id(Psi, ClassId),
    Key = f(CornerLabels, EdgeLabels, ClassId).

%% phase3_goal_key(?Key) is semidet.
% Clave de coclase del estado resuelto (se calcula una sola vez).
phase3_goal_key(Key) :-
    phase3_goal_cache(Cached),
    !,
    Key = Cached.
phase3_goal_key(Key) :-
    solved(State),
    phase3_key(State, GoalKey),
    assertz(phase3_goal_cache(GoalKey)),
    Key = GoalKey.

%% phase3_table(-Table) is det.
% Devuelve la tabla exacta de distancias de la fase 3 (assoc Index-Distancia).
% Orden: memoria, archivo de caché, construcción por BFS.
phase3_table(Table) :-
    phase3_table_cache(Cached),
    !,
    Table = Cached.
phase3_table(Table) :-
    load_or_build_phase3_table(Built),
    assertz(phase3_table_cache(Built)),
    Table = Built.

load_or_build_phase3_table(Table) :-
    phase3_cache_file(File),
    exists_file(File),
    catch(read_phase3_cache(File, Table), _, fail),
    !.
load_or_build_phase3_table(Table) :-
    statistics(cputime, Start),
    phase3_moves(Moves),
    build_phase3_table(Moves, Table),
    statistics(cputime, End),
    Seconds is End - Start,
    (   Seconds > 5
    ->  ignore(catch(write_phase3_cache(Table), _, true))
    ;   true
    ).

%% phase3_moves(-Moves) is det.
% Movimientos que generan la fase 3.
phase3_moves([u,ui,u2,d,di,d2,l2,r2,f2,b2]).

%% phase3_class_id(+Psi, -ClassId) is det.
% Clase (0..11) de una tupla de cinco elementos de S3.
phase3_class_id(Psi, ClassId) :-
    tuple_index(Psi, Index),
    phase3_class_table(Table),
    get_assoc(Index, Table, ClassId).

%% phase3_class_table(-Table) is det.
% Tabla Index-ClassId de las 7776 tuplas de S3^5, construida una sola vez.
% Las clases son las componentes conexas bajo la acción de los seis
% generadores (deben salir exactamente 12).
phase3_class_table(Table) :-
    nb_current(phase3_class_index, Table),
    !.
phase3_class_table(Table) :-
    s3_permutations(Permutations),
    tuple_space(Permutations, Tuples),
    phase3_generators(Generators),
    empty_assoc(Initial),
    class_bfs(Tuples, Generators, 0, Initial, TupleTable),
    assoc_to_list(TupleTable, Pairs),
    maplist(index_class_pair, Pairs, IndexedPairs),
    empty_assoc(IndexedInitial),
    put_pairs(IndexedPairs, IndexedInitial, Table),
    nb_setval(phase3_class_index, Table).

%% build_phase3_table(+Moves, -Table) is det.
% BFS por clases usando un estado representante por clave.
build_phase3_table(Moves, Table) :-
    phase3_goal_key(GoalKey),
    solved(Solved),
    empty_assoc(Initial),
    tuple_index_from_key(GoalKey, GoalIndex),
    put_assoc(GoalIndex, Initial, 0, Table0),
    phase3_bfs(Moves, queue([GoalKey-Solved], []), Table0, Table).

phase3_bfs(Moves, Queue0, Table0, Table) :-
    (   Queue0 = queue([], [])
    ->  Table = Table0
    ;   Queue0 = queue([], Back)
    ->  reverse(Back, Front),
        phase3_bfs(Moves, queue(Front, []), Table0, Table)
    ;   Queue0 = queue([Key-State|Queue], Back),
        tuple_index_from_key(Key, Index),
        get_assoc(Index, Table0, Distance),
        NextDistance is Distance + 1,
        once(phase3_expand(Moves, State, NextDistance, queue(Queue, Back),
                           Table0, NextQueue, Table1)),
        phase3_bfs(Moves, NextQueue, Table1, Table)
    ).

phase3_expand([], _, _, Queue, Table, Queue, Table) :-
    !.
phase3_expand([Move|Moves], State, Distance, Queue0, Table0,
              Queue, Table) :-
    apply(Move, State, NextState),
    phase3_key(NextState, NextKey),
    tuple_index_from_key(NextKey, NextIndex),
    (   get_assoc(NextIndex, Table0, _)
    ->  Queue1 = Queue0,
        Table1 = Table0
    ;   put_assoc(NextIndex, Table0, Distance, Table1),
        queue_add(NextKey-NextState, Queue0, Queue1)
    ),
    phase3_expand(Moves, State, Distance, Queue1, Table1, Queue, Table).

queue_add(Item, queue(Front, Back), queue(Front, [Item|Back])).

%% tuple_index_from_key(+Key, -Index) is det.
% Codifica una clave f(EtiquetasEsquinas, EtiquetasAristas, Clase) como entero.
tuple_index_from_key(f(CornerLabels, EdgeLabels, ClassId), Index) :-
    integer(ClassId),
    labels_index(CornerLabels, 2, 0, CornerIndex),
    labels_index(EdgeLabels, 3, 0, EdgeIndex),
    Index is (CornerIndex * 531441 + EdgeIndex) * 12 + ClassId.

labels_index([], _, Index, Index).
labels_index([Label|Labels], Base, Accumulator, Index) :-
    label_value(Label, Value),
    NextAccumulator is Accumulator * Base + Value,
    labels_index(Labels, Base, NextAccumulator, Index).

label_value(a, 0).
label_value(b, 1).
label_value(s, 0).
label_value(m, 1).
label_value(e, 2).

%% tuple_index(+Psi, -Index) is det.
% Codifica una tupla de cinco permutaciones de S3 como un entero.
tuple_index(Psi, Index) :-
    tuple_index(Psi, 0, Index).

tuple_index([], Index, Index).
tuple_index([Permutation|Permutations], Accumulator, Index) :-
    permutation_index(Permutation, Value),
    NextAccumulator is Accumulator * 6 + Value,
    tuple_index(Permutations, NextAccumulator, Index).

permutation_index([0,1,2], 0).
permutation_index([0,2,1], 1).
permutation_index([1,0,2], 2).
permutation_index([1,2,0], 3).
permutation_index([2,0,1], 4).
permutation_index([2,1,0], 5).

index_class_pair(Psi-ClassId, Index-ClassId) :-
    tuple_index(Psi, Index).

put_pairs([], Table, Table).
put_pairs([Key-Value|Pairs], Table0, Table) :-
    put_assoc(Key, Table0, Value, Table1),
    put_pairs(Pairs, Table1, Table).

%% ------------------------------------------------------------------
%% Etiquetas de órbita y permutaciones internas
%% ------------------------------------------------------------------

%% lambda_labels(+Permutation, +Kind, -Labels) is det.
% Etiqueta cada hueco con la órbita de la pieza que lo ocupa.
lambda_labels(Permutation, corner, Labels) :-
    maplist(corner_orbit_label, Permutation, Labels).
lambda_labels(Permutation, edge, Labels) :-
    maplist(edge_orbit_label, Permutation, Labels).

corner_orbit_label(Piece, Label) :-
    (   memberchk(Piece, [0,2,5,7])
    ->  Label = a
    ;   Label = b
    ).

edge_orbit_label(Piece, Label) :-
    (   memberchk(Piece, [0,2,4,6])
    ->  Label = s
    ;   memberchk(Piece, [1,3,5,7])
    ->  Label = m
    ;   Label = e
    ).

%% phase3_arrays(+CP, +EP, -Arrays) is det.
% Las cinco permutaciones internas de las órbitas a, b, s, m, e.
phase3_arrays(CP, EP, [A,B,S,M,E]) :-
    maplist(corner_orbit_label, CP, CornerLabels),
    maplist(edge_orbit_label, EP, EdgeLabels),
    orbit_array(a, CP, CornerLabels, A),
    orbit_array(b, CP, CornerLabels, B),
    orbit_array(s, EP, EdgeLabels, S),
    orbit_array(m, EP, EdgeLabels, M),
    orbit_array(e, EP, EdgeLabels, E).

%% orbit_array(+Orbit, +Permutation, +Labels, -Array) is det.
% Para los huecos etiquetados con Orbit (en orden ascendente), la posición
% de su pieza dentro de la lista ascendente de piezas de la órbita.
orbit_array(Orbit, Permutation, Labels, Array) :-
    orbit_pieces(Orbit, OrbitPieces),
    orbit_positions(Permutation, Labels, Orbit, OrbitPieces, Array).

orbit_positions([], [], _, _, []).
orbit_positions([Piece|Pieces], [Label|Labels], Orbit, OrbitPieces, Array) :-
    (   Label == Orbit
    ->  once(nth0(Position, OrbitPieces, Piece)),
        Array = [Position|Rest]
    ;   Array = Rest
    ),
    orbit_positions(Pieces, Labels, Orbit, OrbitPieces, Rest).

orbit_pieces(a, [0,2,5,7]).
orbit_pieces(b, [1,3,4,6]).
orbit_pieces(s, [0,2,4,6]).
orbit_pieces(m, [1,3,5,7]).
orbit_pieces(e, [8,9,10,11]).

%% psi(+Permutation, -PartitionPermutation) is det.
% Homomorfismo S4 -> S3 por la acción sobre las tres particiones en pares.
psi([First,Second,Third,Fourth], [Q1,Q2,Q3]) :-
    part_index(First, Second, Q1),
    part_index(First, Third, Q2),
    part_index(First, Fourth, Q3).

part_index(X, Y, Index) :-
    (   pair_member(X, Y, [0,1])
    ;   pair_member(X, Y, [2,3])
    ),
    !,
    Index = 0.
part_index(X, Y, Index) :-
    (   pair_member(X, Y, [0,2])
    ;   pair_member(X, Y, [1,3])
    ),
    !,
    Index = 1.
part_index(_, _, 2).

pair_member(X, Y, Pair) :-
    memberchk(X, Pair),
    memberchk(Y, Pair).

%% phase3_generators(-Generators) is det.
% Imagen en S3^5 de los seis medios giros.
phase3_generators(Generators) :-
    Moves = [u2,d2,l2,r2,f2,b2],
    maplist(phase3_generator, Moves, Generators).

phase3_generator(Move, Generator) :-
    base_move(Move, state(CP, _, EP, _)),
    phase3_arrays(CP, EP, Arrays),
    maplist(psi, Arrays, Generator).

%% s3_permutations(-Permutations) is det.
s3_permutations(Permutations) :-
    findall(Permutation, permutation([0,1,2], Permutation), Permutations).

%% tuple_space(+Values, -Tuples) is det.
% Enumera las 7776 tuplas de cinco elementos de S3.
tuple_space(Values, Tuples) :-
    tuple_space(5, Values, Tuples).

tuple_space(0, _, [[]]) :-
    !.
tuple_space(N, Values, Tuples) :-
    N > 0,
    M is N - 1,
    tuple_space(M, Values, Suffixes),
    findall([Value|Suffix],
            (member(Value, Values), member(Suffix, Suffixes)),
            Tuples).

%% class_bfs(+Tuples, +Generators, +ClassId, +Table0, -Table) is det.
% Asigna un identificador a cada componente conexa.
class_bfs([], _, _, Table, Table).
class_bfs([Tuple|Tuples], Generators, ClassId, Table0, Table) :-
    (   get_assoc(Tuple, Table0, _)
    ->  class_bfs(Tuples, Generators, ClassId, Table0, Table)
    ;   component_bfs(Generators, [Tuple], ClassId, Table0, Table1),
        NextId is ClassId + 1,
        class_bfs(Tuples, Generators, NextId, Table1, Table)
    ).

component_bfs(_, [], _, Table, Table).
component_bfs(Generators, [Tuple|Queue], ClassId, Table0, Table) :-
    get_assoc(Tuple, Table0, _),
    !,
    component_bfs(Generators, Queue, ClassId, Table0, Table).
component_bfs(Generators, [Tuple|Queue], ClassId, Table0, Table) :-
    put_assoc(Tuple, Table0, ClassId, Table1),
    component_successors(Generators, Tuple, Successors),
    append(Queue, Successors, NextQueue),
    component_bfs(Generators, NextQueue, ClassId, Table1, Table).

component_successors([], _, []).
component_successors([Generator|Generators], Tuple, [Successor|Successors]) :-
    apply_generator(Generator, Tuple, Successor),
    component_successors(Generators, Tuple, Successors).

apply_generator(Generator, Tuple, Result) :-
    maplist(apply_s3, Generator, Tuple, Result).

apply_s3(Permutation, Value, Result) :-
    maplist(index_value(Permutation), Value, Result).

index_value(Permutation, Index, Value) :-
    nth0(Index, Permutation, Value).

%% ------------------------------------------------------------------
%% Caché en disco de la tabla de la fase 3
%% ------------------------------------------------------------------

phase3_cache_version(1).

%% phase3_cache_file(-File) is semidet.
% data/phase3.cache en la raíz del proyecto (carpeta padre de prolog/).
phase3_cache_file(File) :-
    module_property(tables, file(TablesFile)),
    file_directory_name(TablesFile, PrologDirectory),
    file_directory_name(PrologDirectory, Root),
    atomic_list_concat([Root, '/data/phase3.cache'], File).

read_phase3_cache(File, Table) :-
    setup_call_cleanup(
        open(File, read, Stream, [type(binary)]),
        fast_read(Stream, Term),
        close(Stream)),
    Term = phase3_cache(Version, Table),
    phase3_cache_version(Version).

write_phase3_cache(Table) :-
    phase3_cache_file(File),
    file_directory_name(File, Directory),
    (   exists_directory(Directory)
    ->  true
    ;   make_directory(Directory)
    ),
    phase3_cache_version(Version),
    setup_call_cleanup(
        open(File, write, Stream, [type(binary)]),
        fast_write(Stream, phase3_cache(Version, Table)),
        close(Stream)).

%% ------------------------------------------------------------------
%% BFS genérico y auxiliares de coordenadas simples
%% ------------------------------------------------------------------

%% bfs(+Kind, +Moves, +Queue, +Table0, -Table) is det.
bfs(_, _, [], Table, Table).
bfs(Kind, Moves, [Coord|Queue], Table0, Table) :-
    get_assoc(Coord, Table0, Distance),
    NextDistance is Distance + 1,
    bfs_moves(Kind, Moves, Coord, NextDistance, Queue,
              Table0, NextQueue, Table1),
    bfs(Kind, Moves, NextQueue, Table1, Table).

bfs_moves(_, [], _, _, Queue, Table, Queue, Table).
bfs_moves(Kind, [Move|Moves], Coord, Distance, Queue0, Table0,
          Queue, Table) :-
    coord_apply(Kind, Move, Coord, NextCoord),
    (   get_assoc(NextCoord, Table0, _)
    ->  Queue1 = Queue0,
        Table1 = Table0
    ;   put_assoc(NextCoord, Table0, Distance, Table1),
        append(Queue0, [NextCoord], Queue1)
    ),
    bfs_moves(Kind, Moves, Coord, Distance, Queue1, Table1,
              Queue, Table).

apply_edge_orientation(Coord0, Permutation, Offsets, Position, Value) :-
    nth0(Position, Offsets, Offset),
    nth0(Position, Permutation, Source),
    nth0(Source, Coord0, Previous),
    Value is (Previous + Offset) mod 2.

apply_corner_orientation(Coord0, Permutation, Offsets, Position, Value) :-
    nth0(Position, Offsets, Offset),
    nth0(Position, Permutation, Source),
    nth0(Source, Coord0, Previous),
    Value is (Previous + Offset) mod 3.

select_edge_coordinate(Coord0, Permutation, Position, Value) :-
    nth0(Position, Permutation, Source),
    nth0(Source, Coord0, Value).

slice_value(_, Piece, 1) :-
    Piece >= 8,
    !.
slice_value(_, _, 0).

%% ------------------------------------------------------------------
%% Fase 4: tabla parcial de distancias hasta el cubo resuelto
%% ------------------------------------------------------------------

:- dynamic phase4_table_cache/1.

phase4_depth_limit(8).

phase4_moves([u2,d2,l2,r2,f2,b2]).

%% state_key(+State, -Key) is det.
% Clave inyectiva de las permutaciones: k(EnteroEsquinas, EnteroAristas).
state_key(state(CP, _, EP, _), k(CornerInt, EdgeInt)) :-
    digits_integer(CP, 8, 0, CornerInt),
    digits_integer(EP, 12, 0, EdgeInt).

digits_integer([], _, Integer, Integer).
digits_integer([Digit|Digits], Base, Accumulator, Integer) :-
    NextAccumulator is Accumulator * Base + Digit,
    digits_integer(Digits, Base, NextAccumulator, Integer).

%% phase4_table(-Table) is det.
% Tabla Key-Distancia de los estados de G3 a distancia <= 8 del resuelto
% (84433 estados). Orden: memoria, archivo de caché, construcción por BFS.
phase4_table(Table) :-
    phase4_table_cache(Cached),
    !,
    Table = Cached.
phase4_table(Table) :-
    load_or_build_phase4_table(Built),
    assertz(phase4_table_cache(Built)),
    Table = Built.

load_or_build_phase4_table(Table) :-
    phase4_cache_file(File),
    exists_file(File),
    catch(read_phase4_cache(File, Table), _, fail),
    !.
load_or_build_phase4_table(Table) :-
    statistics(cputime, Start),
    build_phase4_table(Table),
    statistics(cputime, End),
    Seconds is End - Start,
    (   Seconds > 5
    ->  ignore(catch(write_phase4_cache(Table), _, true))
    ;   true
    ).

%% build_phase4_table(-Table) is det.
% BFS por niveles desde el estado resuelto, solo con medios giros.
build_phase4_table(Table) :-
    phase4_moves(Moves),
    solved(Solved),
    state_key(Solved, GoalKey),
    empty_assoc(Empty),
    put_assoc(GoalKey, Empty, 0, Table0),
    phase4_levels(Moves, 0, [Solved], Table0, Table).

phase4_levels(_, Depth, Frontier, Table0, Table) :-
    phase4_depth_limit(Limit),
    (   Depth >= Limit
    ;   Frontier == []
    ),
    !,
    Table = Table0.
phase4_levels(Moves, Depth, Frontier, Table0, Table) :-
    NextDepth is Depth + 1,
    phase4_expand_level(Frontier, Moves, NextDepth, Table0, Table1,
                        [], NextFrontier),
    phase4_levels(Moves, NextDepth, NextFrontier, Table1, Table).

phase4_expand_level([], _, _, Table, Table, Next, Next).
phase4_expand_level([State|States], Moves, Depth, Table0, Table,
                    Acc0, Next) :-
    phase4_expand_state(Moves, State, Depth, Table0, Table1, Acc0, Acc1),
    phase4_expand_level(States, Moves, Depth, Table1, Table, Acc1, Next).

phase4_expand_state([], _, _, Table, Table, Acc, Acc).
phase4_expand_state([Move|Moves], State, Depth, Table0, Table, Acc0, Acc) :-
    apply(Move, State, NextState),
    state_key(NextState, Key),
    (   get_assoc(Key, Table0, _)
    ->  Table1 = Table0,
        Acc1 = Acc0
    ;   put_assoc(Key, Table0, Depth, Table1),
        Acc1 = [NextState|Acc0]
    ),
    phase4_expand_state(Moves, State, Depth, Table1, Table, Acc1, Acc).

%% Caché en disco (data/phase4.cache, binario y con número de versión)

phase4_cache_version(1).

phase4_cache_file(File) :-
    module_property(tables, file(TablesFile)),
    file_directory_name(TablesFile, PrologDirectory),
    file_directory_name(PrologDirectory, Root),
    atomic_list_concat([Root, '/data/phase4.cache'], File).

read_phase4_cache(File, Table) :-
    setup_call_cleanup(
        open(File, read, Stream, [type(binary)]),
        fast_read(Stream, Term),
        close(Stream)),
    Term = phase4_cache(Version, Table),
    phase4_cache_version(Version).

write_phase4_cache(Table) :-
    phase4_cache_file(File),
    file_directory_name(File, Directory),
    (   exists_directory(Directory)
    ->  true
    ;   make_directory(Directory)
    ),
    phase4_cache_version(Version),
    setup_call_cleanup(
        open(File, write, Stream, [type(binary)]),
        fast_write(Stream, phase4_cache(Version, Table)),
        close(Stream)).