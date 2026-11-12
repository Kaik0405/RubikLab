# RubikLab

**A comparative laboratory of solving strategies for the 3x3x3 Rubik's Cube, built with logic programming in Prolog.**

![SWI-Prolog](https://img.shields.io/badge/SWI--Prolog-9.x-blue)
![Paradigm](https://img.shields.io/badge/paradigm-declarative-success)
![Status](https://img.shields.io/badge/status-functional-success)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

RubikLab models the Rubik's Cube as a declarative knowledge base, validates whether a configuration is physically reachable, and solves it with a complete four-phase Thistlethwaite-style solver driven by IDA* and pruning tables.

All cube logic lives in Prolog. The web interface is a framework-free client that renders the cube, captures moves, requests solutions and animates the result through the HTTP API.

---

## Table of Contents

- [Features](#features)
- [Design Principles](#design-principles)
- [Architecture](#architecture)
- [Cube Representation](#cube-representation)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [HTTP API](#http-api)
- [Testing Strategy](#testing-strategy)
- [Roadmap](#roadmap)
- [Tech Stack](#tech-stack)
- [References](#references)
- [Academic Context](#academic-context)
- [License](#license)

---

## Features

| Capability | Description | Status |
|---|---|---|
| Cube model | Cubie-based state with permutation and orientation | Done |
| 18 moves | Quarter, inverse and half turns of the six faces | Done |
| Move utilities | Inverse of a move or sequence, random scrambles | Done |
| State validation | Detects unreachable states and explains why | Done |
| Solver A | Four-phase Thistlethwaite approach with IDA* and pruning tables | Done |
| Solver B | CFOP: cross and F2L via IDA*, OLL/PLL via a verified algorithm catalog | Planned |
| Solver response | Reports phases, moves, nodes and execution time | Done |
| Web UI | 2D cube, keyboard controls, scramble and animated solving | Done |

The solver measured **31.65 moves on average** over 20 scrambles of 25 moves,
with a minimum of 27 and a maximum of 36.

## Design Principles

- **Declarative first.** Moves are facts, states are immutable terms, and repetition is recursion. There is no destructive assignment anywhere in the model.
- **Logic in Prolog, presentation elsewhere.** The frontend only draws, captures keys and calls the HTTP API.
- **Everything is verified.** Move tables and algorithms are never trusted blindly: they are validated through algebraic properties of the cube group.
- **One responsibility per module.** Dependencies flow in a single direction, with no cycles.
- **Honest benchmarking.** Solvers are compared on the same scrambles, using a fixed random seed for reproducibility.

## Architecture

```
rubiklab/
├── prolog/
│   ├── cube.pl         # Model: state, 18 moves, apply/3
│   ├── moves.pl        # Move vocabulary: faces, inverses, scrambles
│   ├── validation.pl   # Legality of a state
│   ├── facelets.pl     # State <-> 54-sticker view
│   ├── search.pl       # Generic IDA* with node counting
│   ├── tables.pl       # Pruning tables
│   ├── thistle.pl      # Solver A
│   └── server.pl       # HTTP API and static web server
├── tests/              # plunit test suites, one per module
├── web/                # index.html, style.css, app.js
├── docs/               # Report and bibliography
└── run_tests.sh
```

Module dependencies (arrows point to what is imported):

```
cube        (no dependencies)
moves       -> cube
validation  -> cube
facelets    -> cube
tables      -> cube, moves
search      -> cube, moves
thistle     -> search, tables, cube, moves
server      -> thistle, facelets, validation, moves, cube
```

## Cube Representation

The cube is represented by its **cubies**, following the convention used by Kociemba. Centers never move relative to each other, so only corners and edges are stored:

```prolog
% state(CornerPerm, CornerOri, EdgePerm, EdgeOri)
solved(state([0,1,2,3,4,5,6,7], [0,0,0,0,0,0,0,0],
             [0,1,2,3,4,5,6,7,8,9,10,11],
             [0,0,0,0,0,0,0,0,0,0,0,0])).
```

| Component | Meaning | Values |
|---|---|---|
| `CornerPerm` | Which corner piece sits in each of the 8 slots | 0-7 |
| `CornerOri` | Twist of each corner | 0, 1, 2 |
| `EdgePerm` | Which edge piece sits in each of the 12 slots | 0-11 |
| `EdgeOri` | Flip of each edge | 0, 1 |

Slot order:

```
Corners: URF UFL ULB UBR DFR DLF DBL DRB
Edges:   UR UF UL UB DR DF DL DB FR FL BL BR
```

Each move is stored as a fact holding the state that results from applying it to the solved cube. Applying a move reorders the pieces according to its table and adds the orientation offsets (mod 3 for corners, mod 2 for edges).

Moves are named in lowercase: `u`, `ui` (inverse), `u2` (half turn), and likewise for `r`, `f`, `d`, `l`, `b`.

## Getting Started

### Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/) 9.x or later, available on your `PATH`
- Git
- Bash (Git Bash on Windows works)

Check your installation:

```bash
swipl --version
```
 
### Installation

```bash
git clone https://github.com/Kaik0405/rubiklab.git
cd rubiklab
```

### Run the tests

```bash
bash run_tests.sh
```

Start the HTTP server:

```bash
swipl -q -s prolog/server.pl -g "server:start,thread_get_message(_)"
```

Open [http://localhost:8080](http://localhost:8080) in a browser to use the
2D cube viewer.

## Usage

Load the modules in the SWI-Prolog interpreter:

```bash
swipl prolog/cube.pl prolog/moves.pl
```

Apply the well-known "sexy move" and inspect the result:

```prolog
?- solved(S), apply_sequence([r,u,ri,ui], S, S1).
```

Repeating that sequence six times returns the cube to the solved state:

```prolog
?- solved(S),
   length(Reps, 6), maplist(=([r,u,ri,ui]), Reps), append(Reps, Moves),
   apply_sequence(Moves, S, S1), S1 == S.
true.
```

Generate a scramble and undo it with its inverse:

```prolog
?- random_scramble(25, Scramble),
   inverse_sequence(Scramble, Undo),
   solved(S),
   apply_sequence(Scramble, S, Mixed),
   apply_sequence(Undo, Mixed, Back),
   Back == S.
```

## HTTP API

The server listens on port `8080` by default and exposes the following
endpoints:

| Endpoint | Description |
|---|---|
| `GET /api/scramble?n=25` | Generates a scramble with `n` valid moves. |
| `GET /api/state?moves=r,u,ri` | Applies moves and returns the facelets and state legality. |
| `GET /api/validate?facelets=...` | Validates a 54-sticker facelet string. |
| `GET /api/solve?moves=r,u,f` | Solves the state and returns all four phases with metrics. |

Unknown moves return HTTP `400`. Illegal cube states return HTTP `422` from
the solve endpoint. Successful solve responses include the total move count,
node count, elapsed time and the moves and metrics for EO, CO+slice, G3 and
Solved.

## Testing Strategy

Move tables are easy to get subtly wrong, and a single bad index corrupts everything built on top. The test suite therefore checks **properties of the cube group** instead of isolated examples:

- Each face turn applied four times is the identity.
- A move followed by its inverse is the identity.
- Each half turn equals two quarter turns.
- `R U R' U'` repeated six times is the identity, and not before.
- For several pairs of faces (`R U`, `F R`, `L F`, `B D`, `D L`, `B R`) the composition has order exactly **105**, which is its known value on a real cube. This catches errors in how two faces interact.
- Any random scramble followed by its inverse returns the solved cube.
- Facelet conversion, legality reasons and invalid configurations are tested.
- IDA* pruning, phase coordinates and all four solver phases are tested.
- The HTTP solver response is tested without requiring a running server.

Move tables were also cross-checked against Kociemba's reference implementation.

## Roadmap

- [x] Cubie-based model and 18 move tables
- [x] Property-based tests for the move group
- [x] Move utilities: inverses and random scrambles
- [x] State validation with explanations
- [x] Facelet conversion and a minimal 2D viewer
- [x] Generic IDA* with pruning and node counting
- [x] Solver A: Thistlethwaite phases with pruning tables
- [ ] Solver B: CFOP (cross, F2L, OLL, PLL)
- [ ] Explainer via meta-interpreter
- [ ] Benchmark comparing both solvers
- [x] HTTP API and framework-free 2D web interface

OLL and PLL are planned in their full form (57 + 21 cases), with a 2-look subset as a fallback. Every algorithm is checked automatically against the cube model.

## Tech Stack

- **Backend:** SWI-Prolog, `plunit` for testing, `library(http/http_server)` for the API
- **Frontend:** HTML, CSS and a small amount of JavaScript for rendering and input
- **Tooling:** Git, VS Code

## References

- H. Kociemba, *Two-Phase Algorithm* and the reference implementation [`RubiksCube-TwophaseSolver`](https://github.com/hkociemba/RubiksCube-TwophaseSolver)
- M. Thistlethwaite, four-phase algorithm for solving the Rubik's Cube (1981)
- R. Korf, *Finding Optimal Solutions to Rubik's Cube Using Pattern Databases*, AAAI-97
- [SWI-Prolog Reference Manual](https://www.swi-prolog.org/pldoc/doc_for?object=manual)

## Academic Context

This project was developed for the **Declarative Programming** course. It applies concepts such as recursion over lists, unification, backtracking and the cut, negation as failure, arithmetic, second-order predicates (`findall`, `setof`), meta-programming, and modular design.

## License

Distributed under the MIT License. See `LICENSE` for details.