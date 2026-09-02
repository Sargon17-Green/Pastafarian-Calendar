-module(monster_error).
-export([wrap/2]).

wrap(Code, Context) ->
    Context#{last_error := Code, status := failed}.
