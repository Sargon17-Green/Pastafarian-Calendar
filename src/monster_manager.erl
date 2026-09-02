-module(monster_manager).
-export([execute_bootstrap/2]).

execute_bootstrap(CalculationDay, TargetDay) ->
    Context = monster_context:new(CalculationDay, TargetDay),
    monster_dispatcher:dispatch(Context).
