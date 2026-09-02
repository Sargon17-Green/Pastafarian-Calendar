-module(spaghetti_monster).
-export([bootstrap_probe/2, calendar_date_spaghetti/2]).

bootstrap_probe(CalculationDay, TargetDay) ->
    monster_manager:execute_bootstrap(CalculationDay, TargetDay).

calendar_date_spaghetti(CalculationDay, TargetDay) ->
    case bootstrap_probe(CalculationDay, TargetDay) of
        {ok, Context} -> {stage_not_integrated, 1, Context};
        {error, Context} -> {error, Context}
    end.
