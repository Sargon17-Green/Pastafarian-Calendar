-module(stage01_tests).
-export([run/0]).

run() ->
    ok = catalog_tests(),
    ok = arithmetic_tests(),
    ok = stone_tests(),
    ok = sauce_tests(),
    ok = selection_tests(),
    ok = permutation_tests(),
    ok = family_tests(),
    ok = weaving_tests(),
    ok = bootstrap_tests(),
    ok = production_oracle_separation_test(),
    ok = future_patch_absence_test(),
    io:format("סטאַגע 1: אַלע לאָקאַלע טעסטן זענען דורכגעגאַנגען.~n"),
    ok.

catalog_tests() ->
    ok = source_language_catalog:validate(),
    eq(17, source_language_catalog:cutlet_count(), cutlet_count),
    eq(47, source_language_catalog:month_count(), month_count),
    eq(<<"ווייץ"/utf8>>, source_language_catalog:cutlet_name(12), wheat_name),
    eq(<<"זאַלץ"/utf8>>, source_language_catalog:month_name(44), salt_name),
    eq(lists:seq(1, 17), [I || {I, _} <- source_language_catalog:cutlet_entries()], cutlet_indexes),
    eq(lists:seq(1, 47), [I || {I, _} <- source_language_catalog:month_entries()], month_indexes),
    ok.

arithmetic_tests() ->
    F = fixtures_stage01:primitive(),
    M = maps:get(m, F),
    eq(M, normative_oracle:m(), m_value),
    eq(maps:get(foundation, F), normative_oracle:foundation_day(), foundation_value),
    eq(maps:get(tablets, F), normative_oracle:tablets_day(), tablets_value),
    eq(14777149, normative_oracle:tablets_day() - normative_oracle:foundation_day(), anchor_distance),
    eq(1, normative_oracle:save(1), save_1),
    eq(M - 1, normative_oracle:save(M - 1), save_m_minus_1),
    eq(M, normative_oracle:save(M), save_m),
    eq(1, normative_oracle:save(M + 1), save_m_plus_1),
    eq(M, normative_oracle:save(2 * M), save_2m),
    eq(M, normative_oracle:save(0), save_zero),
    FDay = normative_oracle:foundation_day(),
    eq(1, normative_oracle:day_count(FDay), day_count_foundation),
    eq(2, normative_oracle:day_count(FDay - 1), day_count_before),
    eq(3, normative_oracle:day_count(FDay + 1), day_count_after),
    eq(#{action => 1, target => 1, distance => 1, connection => 2, direction => 2},
       normative_oracle:work_counts(FDay, FDay), work_counts_same),
    eq(#{action => 1, target => 3, distance => 2, connection => 4, direction => 3},
       normative_oracle:work_counts(FDay, FDay + 1), work_counts_forward),
    eq(#{action => 3, target => 1, distance => 2, connection => 4, direction => 1},
       normative_oracle:work_counts(FDay + 1, FDay), work_counts_backward),
    eq(1, normative_oracle:save(M * M + 1), arbitrary_precision_save),
    ok.

stone_tests() ->
    Stones = normative_oracle:build_stones(),
    F = fixtures_stage01:primitive(),
    eq(46, length(Stones), stone_count),
    eq({17, 29, 43, 71, 101}, lists:nth(1, Stones), stone_1),
    eq(maps:get(stone_2, F), lists:nth(2, Stones), stone_2),
    ok.

sauce_tests() ->
    FDay = normative_oracle:foundation_day(),
    R1 = normative_oracle:sauce(FDay, FDay),
    R2 = normative_oracle:sauce(FDay, FDay),
    eq(R1, R2, sauce_determinism),
    Bowls = maps:get(bowls, R1),
    Order = maps:get(order_at_drop46, R1),
    eq(6, tuple_size(Bowls), sauce_six_bowls),
    eq([1, 2, 3, 4, 5, 6], lists:sort(Order), sauce_order_is_permutation),
    ok.

selection_tests() ->
    M = normative_oracle:m(),
    Forward = #{first => 1, step => 1},
    Edge = #{first => M, step => 1},
    eq(1, normative_oracle:choose_rank_short(Forward, 1), choose_short_one),
    eq(1, normative_oracle:choose_rank_short(Forward, M), choose_short_m_first),
    eq(M, normative_oracle:choose_rank_short(Edge, M), choose_short_m_last),
    eq(1, normative_oracle:choose_rank_short(Edge, 2), choose_short_rejection_wrap),
    eq(M + 1, normative_oracle:choose_rank_wide(Forward, M + 1), choose_wide_m_plus_1),
    eq(M + 1, normative_oracle:choose_rank_wide(Forward, M * M), choose_wide_m_squared),
    eq(M - 1, normative_oracle:choose_rank_wide(Forward, M * M + 1), choose_wide_m_squared_plus_1),
    ok.

permutation_tests() ->
    F = fixtures_stage01:primitive(),
    eq(maps:get(permutation_1, F), normative_oracle:bowl_order_from_number(1), permutation_1),
    eq(maps:get(permutation_720, F), normative_oracle:bowl_order_from_number(720), permutation_720),
    eq(maps:get(permutation_720, F), normative_oracle:bowl_order_from_drop(720), permutation_drop_720),
    eq(maps:get(permutation_1, F), normative_oracle:bowl_order_from_drop(721), permutation_drop_721),
    eq(maps:get(falling_17_6, F), normative_oracle:falling_factorial(17, 6), falling_17_6),
    eq([1, 2, 3], normative_oracle:unrank_distinct_indices(3, 3, 1), distinct_first),
    eq([3, 2, 1], normative_oracle:unrank_distinct_indices(3, 3, 6), distinct_last),
    ok.

family_tests() ->
    F = fixtures_stage01:bounded(),
    eq(maps:get(count_8_2_4_123, F), normative_oracle:count_bounded_compositions(8, 2, 4, 123), bounded_count_8),
    eq(maps:get(row_8_2_4_123_1, F), normative_oracle:unrank_bounded_composition(8, 2, 4, 123, 1), bounded_row_8),
    eq(maps:get(count_9_2_4_123, F), normative_oracle:count_bounded_compositions(9, 2, 4, 123), bounded_count_9),
    eq(maps:get(row_9_2_4_123_1, F), normative_oracle:unrank_bounded_composition(9, 2, 4, 123, 1), bounded_row_9_1),
    eq(maps:get(row_9_2_4_123_2, F), normative_oracle:unrank_bounded_composition(9, 2, 4, 123, 2), bounded_row_9_2),
    eq(maps:get(cutlet_8_2_none_count, F), normative_oracle:count_cutlet_partitions(8, 2, none), cutlet_count_none),
    eq(maps:get(cutlet_8_2_none_first, F), normative_oracle:unrank_cutlet_partition(8, 2, none, 1), cutlet_first_none),
    eq(maps:get(cutlet_8_2_none_last, F), normative_oracle:unrank_cutlet_partition(8, 2, none, 7), cutlet_last_none),
    eq(maps:get(cutlet_6_3_required_3_count, F), normative_oracle:count_cutlet_partitions(6, 3, 3), cutlet_required_count),
    eq(maps:get(cutlet_6_3_required_3_first, F), normative_oracle:unrank_cutlet_partition(6, 3, 3, 1), cutlet_required_first),
    eq(maps:get(cutlet_6_3_required_3_last, F), normative_oracle:unrank_cutlet_partition(6, 3, 3, 4), cutlet_required_last),
    ok.

weaving_tests() ->
    F = fixtures_stage01:weaving(),
    eq(maps:get(count_2_2, F), normative_oracle:count_weavings([2, 2]), weave_count_2_2),
    eq(maps:get(row_2_2_1, F), normative_oracle:unrank_weaving([2, 2], 1), weave_2_2_1),
    eq(maps:get(row_2_2_2, F), normative_oracle:unrank_weaving([2, 2], 2), weave_2_2_2),
    eq(maps:get(count_1_1, F), normative_oracle:count_weavings([1, 1]), weave_count_1_1),
    eq(maps:get(row_1_1_1, F), normative_oracle:unrank_weaving([1, 1], 1), weave_1_1_1),
    ok.

bootstrap_tests() ->
    {ok, Context} = spaghetti_monster:bootstrap_probe(10, -20),
    eq(bootstrap_ready, maps:get(status, Context), bootstrap_ready),
    eq([bootstrap_dispatch], maps:get(branch_trace, Context), bootstrap_trace),
    {error, Bad} = spaghetti_monster:bootstrap_probe(10, bad_day),
    eq(failed, maps:get(status, Bad), bootstrap_bad_day),
    ok.

production_oracle_separation_test() ->
    Files = filelib:wildcard("src/*.erl"),
    lists:foreach(fun(Path) ->
        {ok, Bin} = file:read_file(Path),
        eq(nomatch, binary:match(Bin, <<"normative_oracle">>), {oracle_reference_in_production, Path})
    end, Files),
    ok.

future_patch_absence_test() ->
    {ok, StageBin} = file:read_file("DEVELOPMENT_STAGE.md"),
    case binary:match(StageBin, <<"CURRENT_STAGE=1\n">>) of
        nomatch -> ok;
        _ ->
            Forbidden = [
                <<"oldRemainder">>, <<"savePatch">>, <<"oldDayTag">>, <<"oldDistance">>,
                <<"mutateStonesWrong">>, <<"legacyPrior">>, <<"oldPermutationUnrank0">>,
                <<"bowlAlias">>, <<"orderAt46Latch">>, <<"oldNextBowlFixedName">>,
                <<"biasedLegacyPick">>, <<"wideDetour">>, <<"oldGateQuestionDay">>,
                <<"LEGACY_YEAR_MAX">>, <<"oldJumpGuess">>, <<"oldStructureSauce">>,
                <<"legacyPositiveCompositions">>, <<"legacyNameRowWithRepeats">>,
                <<"VirtualLegacyList">>, <<"legacyChooseEachDaySeparately">>,
                <<"oldContiguousMonthDayGuess">>
            ],
            Files = filelib:wildcard("src/*.erl"),
            lists:foreach(fun(Path) ->
                {ok, Bin} = file:read_file(Path),
                lists:foreach(fun(Token) ->
                    eq(nomatch, binary:match(Bin, Token), {future_patch_token, Path, Token})
                end, Forbidden)
            end, Files),
            ok
    end.

eq(Expected, Actual, _Label) when Expected =:= Actual -> ok;
eq(Expected, Actual, Label) -> erlang:error({test_failed, Label, Expected, Actual}).
