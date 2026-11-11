:- module(facelets, [state_to_facelets/2, facelets_to_state/2]).
:- use_module(cube, [solved/1]).

/** <module> Conversión entre estados del cubo y facelets.

Exporta las conversiones entre state(CP, CO, EP, EO) y un átomo de 54
caracteres. Depende de cube.pl para la representación de los estados.
*/

%% state_to_facelets(+State, -Facelets) is semidet.
% Convierte un estado del cubo en un átomo ordenado por caras.
state_to_facelets(state(CP, CO, EP, EO), Facelets) :-
    blank_facelets(BlankFacelets),
    set_centers(BlankFacelets, CenteredFacelets),
    place_corners(CP, CO, CenteredFacelets, CornerFacelets),
    place_edges(EP, EO, CornerFacelets, FaceletList),
    atom_chars(Facelets, FaceletList),
    !.

%% facelets_to_state(+Facelets, -State) is semidet.
% Convierte un átomo de facelets en un estado válido o falla.
facelets_to_state(Facelets, state(CP, CO, EP, EO)) :-
    atom_chars(Facelets, FaceletList),
    length(FaceletList, 54),
    centers_are_valid(FaceletList),
    decode_corners(FaceletList, CP, CO),
    decode_edges(FaceletList, EP, EO),
    !.

%% blank_facelets(-Facelets) is det.
% Crea una lista de 54 posiciones vacías.
blank_facelets(Facelets) :-
    length(Facelets, 54),
    maplist(=('?'), Facelets).

%% set_centers(+Facelets, -Updated) is det.
% Coloca los colores fijos de los centros.
set_centers(Facelets, Updated) :-
    set_index(Facelets, 4, 'U', U),
    set_index(U, 13, 'R', R),
    set_index(R, 22, 'F', F),
    set_index(F, 31, 'D', D),
    set_index(D, 40, 'L', L),
    set_index(L, 49, 'B', Updated).

%% centers_are_valid(+Facelets) is semidet.
% Comprueba que los seis centros tengan sus colores correspondientes.
centers_are_valid(Facelets) :-
    nth0(4, Facelets, 'U'),
    nth0(13, Facelets, 'R'),
    nth0(22, Facelets, 'F'),
    nth0(31, Facelets, 'D'),
    nth0(40, Facelets, 'L'),
    nth0(49, Facelets, 'B').

%% place_corners(+CP, +CO, +Facelets, -Updated) is det.
% Coloca los stickers de las ocho esquinas.
place_corners(CP, CO, Facelets, Updated) :-
    place_corners(0, CP, CO, Facelets, Updated).

place_corners(8, _, _, Facelets, Facelets).
place_corners(I, CP, CO, Facelets, Updated) :-
    nth0(I, CP, Piece),
    nth0(I, CO, Orientation),
    corner_facelet(I, Positions),
    corner_color(Piece, Colors),
    place_corner_stickers(0, Orientation, Positions, Colors,
                          Facelets, Placed),
    Next is I + 1,
    place_corners(Next, CP, CO, Placed, Updated).

%% place_corner_stickers(+N, +Orientation, +Positions, +Colors, +Facelets, -Updated) is det.
% Coloca los tres stickers de una esquina según su giro.
place_corner_stickers(3, _, _, _, Facelets, Facelets).
place_corner_stickers(N, Orientation, Positions, Colors, Facelets, Updated) :-
    PositionIndex is (N + Orientation) mod 3,
    nth0(PositionIndex, Positions, FaceletIndex),
    nth0(N, Colors, Color),
    set_index(Facelets, FaceletIndex, Color, Placed),
    Next is N + 1,
    place_corner_stickers(Next, Orientation, Positions, Colors,
                          Placed, Updated).

%% place_edges(+EP, +EO, +Facelets, -Updated) is det.
% Coloca los stickers de las doce aristas.
place_edges(EP, EO, Facelets, Updated) :-
    place_edges(0, EP, EO, Facelets, Updated).

place_edges(12, _, _, Facelets, Facelets).
place_edges(I, EP, EO, Facelets, Updated) :-
    nth0(I, EP, Piece),
    nth0(I, EO, Orientation),
    edge_facelet(I, Positions),
    edge_color(Piece, Colors),
    place_edge_stickers(0, Orientation, Positions, Colors,
                         Facelets, Placed),
    Next is I + 1,
    place_edges(Next, EP, EO, Placed, Updated).

%% place_edge_stickers(+N, +Orientation, +Positions, +Colors, +Facelets, -Updated) is det.
% Coloca los dos stickers de una arista según su giro.
place_edge_stickers(2, _, _, _, Facelets, Facelets).
place_edge_stickers(N, Orientation, Positions, Colors, Facelets, Updated) :-
    PositionIndex is (N + Orientation) mod 2,
    nth0(PositionIndex, Positions, FaceletIndex),
    nth0(N, Colors, Color),
    set_index(Facelets, FaceletIndex, Color, Placed),
    Next is N + 1,
    place_edge_stickers(Next, Orientation, Positions, Colors,
                         Placed, Updated).

%% decode_corners(+Facelets, -CP, -CO) is semidet.
% Recupera las piezas y giros de las esquinas sin repetir piezas.
decode_corners(Facelets, CP, CO) :-
    decode_corners(0, Facelets, [], CP, CO).

decode_corners(8, _, _, [], []).
decode_corners(I, Facelets, Used, [Piece|CP], [Orientation|CO]) :-
    corner_facelet(I, Positions),
    between(0, 7, Piece),
    \+ memberchk(Piece, Used),
    corner_matches(Facelets, Positions, Piece, Orientation),
    Next is I + 1,
    decode_corners(Next, Facelets, [Piece|Used], CP, CO).

%% corner_matches(+Facelets, +Positions, +Piece, -Orientation) is semidet.
% Busca el giro que coincide con los stickers de una esquina.
corner_matches(Facelets, Positions, Piece, Orientation) :-
    corner_color(Piece, Colors),
    between(0, 2, Orientation),
    corner_colors_match(0, Orientation, Positions, Colors, Facelets).

corner_colors_match(3, _, _, _, _).
corner_colors_match(N, Orientation, Positions, Colors, Facelets) :-
    PositionIndex is (N + Orientation) mod 3,
    nth0(PositionIndex, Positions, FaceletIndex),
    nth0(FaceletIndex, Facelets, Color),
    nth0(N, Colors, Color),
    Next is N + 1,
    corner_colors_match(Next, Orientation, Positions, Colors, Facelets).

%% decode_edges(+Facelets, -EP, -EO) is semidet.
% Recupera las piezas y giros de las aristas sin repetir piezas.
decode_edges(Facelets, EP, EO) :-
    decode_edges(0, Facelets, [], EP, EO).

decode_edges(12, _, _, [], []).
decode_edges(I, Facelets, Used, [Piece|EP], [Orientation|EO]) :-
    edge_facelet(I, Positions),
    between(0, 11, Piece),
    \+ memberchk(Piece, Used),
    edge_matches(Facelets, Positions, Piece, Orientation),
    Next is I + 1,
    decode_edges(Next, Facelets, [Piece|Used], EP, EO).

%% edge_matches(+Facelets, +Positions, +Piece, -Orientation) is semidet.
% Busca el giro que coincide con los stickers de una arista.
edge_matches(Facelets, Positions, Piece, Orientation) :-
    edge_color(Piece, Colors),
    between(0, 1, Orientation),
    edge_colors_match(0, Orientation, Positions, Colors, Facelets).

edge_colors_match(2, _, _, _, _).
edge_colors_match(N, Orientation, Positions, Colors, Facelets) :-
    PositionIndex is (N + Orientation) mod 2,
    nth0(PositionIndex, Positions, FaceletIndex),
    nth0(FaceletIndex, Facelets, Color),
    nth0(N, Colors, Color),
    Next is N + 1,
    edge_colors_match(Next, Orientation, Positions, Colors, Facelets).

%% set_index(+List, +Index, +Value, -Updated) is det.
% Sustituye el valor de una posición indexada desde cero.
set_index([_|Tail], 0, Value, [Value|Tail]).
set_index([Head|Tail], Index, Value, [Head|Updated]) :-
    Index > 0,
    Next is Index - 1,
    set_index(Tail, Next, Value, Updated).

corner_facelet(0, [8,9,20]).
corner_facelet(1, [6,18,38]).
corner_facelet(2, [0,36,47]).
corner_facelet(3, [2,45,11]).
corner_facelet(4, [29,26,15]).
corner_facelet(5, [27,44,24]).
corner_facelet(6, [33,53,42]).
corner_facelet(7, [35,17,51]).

edge_facelet(0, [5,10]).
edge_facelet(1, [7,19]).
edge_facelet(2, [3,37]).
edge_facelet(3, [1,46]).
edge_facelet(4, [32,16]).
edge_facelet(5, [28,25]).
edge_facelet(6, [30,43]).
edge_facelet(7, [34,52]).
edge_facelet(8, [23,12]).
edge_facelet(9, [21,41]).
edge_facelet(10, [50,39]).
edge_facelet(11, [48,14]).

corner_color(0, ['U','R','F']).
corner_color(1, ['U','F','L']).
corner_color(2, ['U','L','B']).
corner_color(3, ['U','B','R']).
corner_color(4, ['D','F','R']).
corner_color(5, ['D','L','F']).
corner_color(6, ['D','B','L']).
corner_color(7, ['D','R','B']).

edge_color(0, ['U','R']).
edge_color(1, ['U','F']).
edge_color(2, ['U','L']).
edge_color(3, ['U','B']).
edge_color(4, ['D','R']).
edge_color(5, ['D','F']).
edge_color(6, ['D','L']).
edge_color(7, ['D','B']).
edge_color(8, ['F','R']).
edge_color(9, ['F','L']).
edge_color(10, ['B','L']).
edge_color(11, ['B','R']).
