-module(monster_dispatcher).
-export([dispatch/1]).

dispatch(Context0) ->
    Context1 = monster_context:append_trace(bootstrap_dispatch, Context0),
    Context2 = monster_metrics:bump(dispatch_calls, Context1),
    case monster_validation:validate_days(Context2) of
        ok ->
            case monster_validation:validate_bootstrap_context(Context2) of
                ok -> {ok, Context2#{status := bootstrap_ready, current_handler := bootstrap_handler}};
                {error, Code} -> {error, monster_error:wrap(Code, Context2)}
            end;
        {error, Code} -> {error, monster_error:wrap(Code, Context2)}
    end.
