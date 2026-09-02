:- module monster_bootstrap.
:- interface.

:- import_module integer.
:- import_module list.

:- type z == integer.

:- type phase
    --->    bootstrap_entry
    ;       bootstrap_validate
    ;       bootstrap_ready.

:- type monster_context
    --->    monster_context(
                calculation_day :: z,
                target_day      :: z,
                phase           :: phase,
                status_code     :: string,
                branch_trace    :: list(string),
                metric_events   :: list(string),
                log_events      :: list(string),
                validation_codes:: list(string)
            ).

:- type dispatch_result
    --->    dispatch_ok(monster_context)
    ;       dispatch_error(string, monster_context).

:- func new_context(z, z) = monster_context.
:- func base_dispatch(monster_context) = dispatch_result.
:- pred validate_bootstrap_context(monster_context::in) is semidet.

:- implementation.

new_context(C, T) = monster_context(
    C,
    T,
    bootstrap_entry,
    "BOOTSTRAP_NEW",
    ["BOOTSTRAP_ENTER"],
    [],
    [],
    []
).

base_dispatch(Context0) = Result :-
    Context1 = Context0 ^ phase := bootstrap_validate,
    Context2 = Context1 ^ branch_trace :=
        Context1 ^ branch_trace ++ ["BOOTSTRAP_VALIDATE"],
    ( if validate_bootstrap_context(Context2) then
        Context3 = Context2 ^ phase := bootstrap_ready,
        Context4 = Context3 ^ status_code := "BOOTSTRAP_READY",
        Context5 = Context4 ^ metric_events :=
            Context4 ^ metric_events ++ ["bootstrap.ready"],
        Result = dispatch_ok(Context5)
    else
        Context3 = Context2 ^ status_code := "BOOTSTRAP_INVALID",
        Context4 = Context3 ^ validation_codes :=
            Context3 ^ validation_codes ++ ["BOOTSTRAP_CONTEXT_INVALID"],
        Result = dispatch_error("BOOTSTRAP_CONTEXT_INVALID", Context4)
    ).

validate_bootstrap_context(Context) :-
    Context ^ status_code = Status,
    Status \= "".
