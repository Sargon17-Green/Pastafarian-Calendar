-module(monster_metrics).
-export([bump/2]).

bump(Key, Context) ->
    Metrics = maps:get(metrics, Context),
    Value = maps:get(Key, Metrics, 0),
    Context#{metrics := maps:put(Key, Value + 1, Metrics)}.
