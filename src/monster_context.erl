-module(monster_context).
-export([new/2, put/3, get/2, append_trace/2]).

new(CalculationDay, TargetDay) ->
    #{calculation_day => CalculationDay,
      target_day => TargetDay,
      phase => bootstrap,
      sub_phase => 0,
      mode => authoritative_bootstrap,
      status => new,
      retry_budget => 0,
      recovery_depth => 0,
      current_handler => entry,
      previous_handler => none,
      branch_trace => [],
      semantic_snapshot => undefined,
      pending_snapshot => undefined,
      rollback_snapshot => undefined,
      commit_token => 0,
      metrics => #{},
      logs => [],
      diagnostics => [],
      warnings => [],
      validation_failures => [],
      last_error => none}.

put(Key, Value, Context) -> maps:put(Key, Value, Context).
get(Key, Context) -> maps:get(Key, Context).
append_trace(Item, Context) ->
    Trace = maps:get(branch_trace, Context),
    Context#{branch_trace := Trace ++ [Item]}.
