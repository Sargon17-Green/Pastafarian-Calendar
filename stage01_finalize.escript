#!/usr/bin/env escript
-mode(compile).

main(_) ->
    ok = filelib:ensure_dir("ebin/placeholder"),
    Files = lists:sort(filelib:wildcard("src/*.erl") ++ filelib:wildcard("test/*.erl")),
    case compile_all(Files) of
        ok ->
            true = code:add_patha(filename:absname("ebin")),
            case catch stage01_tests:run() of
                ok ->
                    ok = write_green_state(),
                    io:format("סטאַגע 1 איז פֿאַרענדיקט געוואָרן אין אַ געבוירענער Erlang־לויפֿ.~n"),
                    halt(0);
                {'EXIT', Reason} ->
                    io:format("די סטאַגע־1־טעסטן זענען דורכגעפֿאַלן: ~p~n", [Reason]),
                    halt(1);
                Other ->
                    io:format("דער טעסט־ראַנער האָט צוריקגעגעבן אַן אומגעריכטן ווערט: ~p~n", [Other]),
                    halt(1)
            end;
        {error, Reason} ->
            io:format("די Erlang־קאָמפּילאַציע איז דורכגעפֿאַלן: ~p~n", [Reason]),
            halt(1)
    end.

compile_all([]) -> ok;
compile_all([Path | Rest]) ->
    case compile:file(Path, [report_errors, report_warnings, warnings_as_errors, {outdir, "ebin"}]) of
        {ok, _Module} -> compile_all(Rest);
        {ok, _Module, []} -> compile_all(Rest);
        Error -> {error, {Path, Error}}
    end.

write_green_state() ->
    Development = unicode:characters_to_binary([
        "TOTAL_STAGES=55\n",
        "CURRENT_STAGE=1\n",
        "CURRENT_KIND=BOOTSTRAP\n",
        "CURRENT_PATCH=none\n",
        "LAST_COMPLETED_STAGE=1\n",
        "EXPECTED_REPOSITORY_STATE=GREEN\n",
        "FOREIGN_LANGUAGE_USAGE=NONE\n",
        "IMPLEMENTATION_STARTED_FROM_ZERO=YES\n",
        "CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO\n",
        "CROSS_IMPLEMENTATION_HASH_CHECKS=NO\n",
        "CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO\n",
        "PROGRAMMING_LANGUAGE=Erlang\n",
        "NATURAL_LANGUAGE=יידיש\n",
        "SOURCE_LANGUAGE_CATALOG_FROZEN=YES\n",
        "MONSTER_ARCHITECTURE_GROWTH=נייטראַלער context-manager-dispatcher-validation-error-metrics גרונט־שאָל\n",
        "SEMANTIC_STATE_OWNER_VALIDATED=YES\n",
        "GITHUB_ACTIONS_PERFORMED=NO\n",
        "GIT_HISTORY_MUTATED=NO\n",
        "HANDOFF_PACKAGE_PREPARED=YES\n"
    ]),
    OTP = erlang:system_info(otp_release),
    Status = unicode:characters_to_binary(io_lib:format(
        "STAGE=1~nTARGET_STATE=GREEN~nLOCAL_ERLANG_RUNTIME=AVAILABLE~nOTP_RELEASE=~s~nLOCAL_COMPILE=PASS~nLOCAL_TESTS=PASS~nFINAL_STAGE_STATUS=GREEN~n",
        [OTP]
    )),
    ok = file:write_file("DEVELOPMENT_STAGE.md", Development),
    ok = file:write_file("STAGE_01_EXECUTION_STATUS.txt", Status),
    ok.
