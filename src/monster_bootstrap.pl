:- module(monster_bootstrap,
    [ new_monster_context/3,
      monster_manager_execute/3,
      calendar_date_spaghetti/3
    ]).

new_monster_context(CalculationDay, TargetDay,
    monster_context(
        CalculationDay,
        TargetDay,
        bootstrap,
        entry,
        authoritative,
        new,
        0,
        none,
        none,
        [],
        metrics(0,0),
        [],
        none
    )).

monster_manager_execute(CalculationDay, TargetDay, FinalContext) :-
    new_monster_context(CalculationDay, TargetDay, Context0),
    base_dispatch(entry, Context0, FinalContext).

base_dispatch(entry, Context0, FinalContext) :-
    context_with_phase(Context0, validation, entered, Context1),
    base_dispatch(validation, Context1, FinalContext).
base_dispatch(validation, Context0, FinalContext) :-
    Context0 = monster_context(CalculationDay,TargetDay,_,_,_,_,_,_,_,Trace,Metrics,Logs,Error),
    ( integer(CalculationDay), integer(TargetDay) ->
        Context1 = monster_context(CalculationDay,TargetDay,bootstrap,ready,authoritative,
                                   validated,0,base_validator,none,
                                   [validated|Trace],Metrics,Logs,Error),
        base_dispatch(ready, Context1, FinalContext)
    ; Context1 = monster_context(CalculationDay,TargetDay,bootstrap,failed,authoritative,
                                 validation_error,0,base_validator,none,
                                 [validation_failed|Trace],Metrics,Logs,invalid_day_input),
      base_dispatch(failed, Context1, FinalContext)
    ).
base_dispatch(ready, Context0, FinalContext) :-
    bump_dispatch_metric(Context0, Context1),
    context_with_status(Context1, bootstrap_ready, FinalContext).
base_dispatch(failed, Context, Context).

context_with_phase(
    monster_context(C,T,_,_,M,_,R,H,P,Trace,Metrics,Logs,Error),
    Phase, Status,
    monster_context(C,T,bootstrap,Phase,M,Status,R,H,P,[Phase|Trace],Metrics,Logs,Error)).

context_with_status(
    monster_context(C,T,Boot,Phase,Mode,_,R,H,P,Trace,Metrics,Logs,Error),
    Status,
    monster_context(C,T,Boot,Phase,Mode,Status,R,H,P,Trace,Metrics,Logs,Error)).

bump_dispatch_metric(
    monster_context(C,T,Boot,Phase,Mode,Status,R,H,P,Trace,metrics(Dispatches,Failures),Logs,Error),
    monster_context(C,T,Boot,Phase,Mode,Status,R,H,P,Trace,metrics(Dispatches2,Failures),Logs,Error)) :-
    Dispatches2 is Dispatches + 1.

calendar_date_spaghetti(CalculationDay, TargetDay, _) :-
    monster_manager_execute(CalculationDay, TargetDay, Context),
    Context = monster_context(_,_,_,_,_,bootstrap_ready,_,_,_,_,_,_,_),
    throw(error(stage_not_available(54), calendar_date_spaghetti/3)).
