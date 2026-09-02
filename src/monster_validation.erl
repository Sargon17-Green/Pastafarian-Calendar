-module(monster_validation).
-export([validate_days/1, validate_bootstrap_context/1]).

validate_days(Context) ->
    C = maps:get(calculation_day, Context),
    T = maps:get(target_day, Context),
    case is_integer(C) andalso is_integer(T) of
        true -> ok;
        false -> {error, invalid_discrete_day}
    end.

validate_bootstrap_context(Context) ->
    case {maps:get(phase, Context), maps:get(mode, Context)} of
        {bootstrap, authoritative_bootstrap} -> ok;
        _ -> {error, invalid_bootstrap_context}
    end.
