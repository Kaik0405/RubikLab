:- module(explainer, [explain/3]).

:- use_module(thistle, []).
:- use_module(cfop, []).
:- use_module(library(lists), [reverse/2]).
:- use_module(library(apply), [maplist/3, maplist/4]).

/** <module> Explicador de soluciones mediante un metaintérprete.

explain(+Metodo, +Estado, -Pasos) resuelve el cubo ejecutando el solver a
través de un metaintérprete "vainilla" (Conferencia 6). El metaintérprete lee
con clause/2 las cláusulas de los predicados orquestadores (thistle:solve/3,
cfop:solve_cfop/3 y cfop:solve_f2l/9), de modo que ve qué etapa se ejecuta y en
qué orden, y delega con call/1 en los predicados hoja (IDA*, tablas), que
serían demasiado lentos de interpretar.

Cada vez que termina una etapa registra qué regla se usó (búsqueda con qué
heurística, o el caso OLL/PLL reconocido). Los pasos devueltos son
paso(Metodo, Etapa, Regla, Movimientos), con el nombre de la etapa tomado de
las fases del solver. Depende de thistle.pl y cfop.pl.
*/

%% explain(+Method, +State, -Steps) is semidet.
% Method es thistle o cfop. Steps = [paso(Method, Stage, Rule, Moves), ...].
explain(Method, State, Steps) :-
    method_goal(Method, State, Phases, Goal),
    once(meta(Goal, [], ReverseEvents)),
    reverse(ReverseEvents, Events),
    maplist(combine_step(Method), Events, Phases, Steps).

method_goal(thistle, State, Phases, thistle:solve(State, Phases, _)).
method_goal(cfop, State, Phases, cfop:solve_cfop(State, Phases, _)).

combine_step(Method, event(Rule, Moves), phase(_, Name, PhaseMoves, _),
             paso(Method, Name, Rule, Moves)) :-
    Moves == PhaseMoves.

%% ------------------------------------------------------------------
%% Metaintérprete
%% ------------------------------------------------------------------

%% meta(+ModuleGoal, +Trace0, -Trace) is nondet.
% Interpreta un objetivo Modulo:Meta acumulando eventos (en orden inverso).
meta(_:true, Trace, Trace) :-
    !.
meta(Module:(A, B), Trace0, Trace) :-
    !,
    meta(Module:A, Trace0, Trace1),
    meta(Module:B, Trace1, Trace).
meta(Module:Goal, Trace0, Trace) :-
    orchestrator(Module, Goal),
    !,
    clause(Module:Goal, Body),
    meta(Module:Body, Trace0, Trace).
meta(Module:Goal, Trace0, Trace) :-
    call(Module:Goal),
    (   stage_event(Module:Goal, Event)
    ->  Trace = [Event|Trace0]
    ;   Trace = Trace0
    ).

orchestrator(Module, Goal) :-
    functor(Goal, Name, Arity),
    orchestrator_predicate(Module, Name, Arity).

orchestrator_predicate(thistle, solve, 3).
orchestrator_predicate(cfop, solve_cfop, 3).
orchestrator_predicate(cfop, solve_f2l, 9).

%% ------------------------------------------------------------------
%% Eventos de etapa: se crean DESPUÉS de ejecutar el objetivo hoja
%% ------------------------------------------------------------------

stage_event(thistle:solve_phase1(_, Moves, _), event(Rule, Moves)) :-
    Rule = 'IDA* con la tabla exacta de orientacion de aristas; los 18 movimientos'.
stage_event(thistle:solve_phase2(_, Moves, _), event(Rule, Moves)) :-
    Rule = 'IDA* con el maximo de las tablas de orientacion de esquinas y de capa media; movimientos U D L R F2 B2'.
stage_event(thistle:solve_phase3(_, Moves, _), event(Rule, Moves)) :-
    Rule = 'IDA* con la tabla exacta de 29400 coclases; movimientos U D L2 R2 F2 B2'.
stage_event(thistle:solve_phase4(_, Moves, _), event(Rule, Moves)) :-
    Rule = 'IDA* con tabla parcial hasta profundidad 8; solo medios giros'.
stage_event(cfop:ida_star(_, IsGoal, _, _, _, Moves, _), event(Rule, Moves)) :-
    search_rule(IsGoal, Rule).
stage_event(cfop:timed(solve_oll(_, Moves, OllRule), _), event(Rule, Moves)) :-
    oll_text(OllRule, Rule).
stage_event(cfop:timed(solve_pll(_, Moves, PllRule), _), event(Rule, Moves)) :-
    pll_text(PllRule, Rule).

search_rule(cross_goal, 'IDA* optimo; heuristica: maximo de 6 tablas de pares de aristas').
search_rule(f2l_goal(_, Remaining), Rule) :-
    maplist(slot_name, Remaining, Names),
    format(atom(Rule),
           'IDA* optimo; objetivo: cualquiera de los pares ~w (se resuelve el mas corto); heuristica: tablas de pares y de trios',
           [Names]).

slot_name(Index, Name) :-
    nth_slot(Index, Name).

nth_slot(1, 'FR').
nth_slot(2, 'FL').
nth_slot(3, 'BL').
nth_slot(4, 'BR').

oll_text(skip, 'El ultimo piso ya estaba orientado (OLL skip)').
oll_text(oll(Id, Pre), Rule) :-
    format(atom(Rule),
           'Caso OLL ~w reconocido por unificacion de la firma de orientacion; AUF previo ~w',
           [Id, Pre]).

pll_text(pll(skip, Pre, Post), Rule) :-
    !,
    format(atom(Rule), 'Solo hizo falta ajustar la capa superior (AUF previo ~w, final ~w)',
           [Pre, Post]).
pll_text(pll(Name, Pre, Post), Rule) :-
    format(atom(Rule),
           'Caso PLL ~w reconocido por unificacion de la firma de permutacion; AUF previo ~w, final ~w',
           [Name, Pre, Post]).
