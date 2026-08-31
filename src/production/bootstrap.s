.intel_syntax noprefix
.equ CTX_CALCULATION_DAY,0
.equ CTX_TARGET_DAY,8
.equ CTX_PHASE,16
.equ CTX_SUBPHASE,24
.equ CTX_MODE,32
.equ CTX_STATUS,40
.equ CTX_RETRY_BUDGET,48
.equ CTX_RECOVERY_DEPTH,56
.equ CTX_CURRENT_HANDLER,64
.equ CTX_PREVIOUS_HANDLER,72
.equ CTX_BRANCH_COUNT,80
.equ CTX_METRIC_COUNT,88
.equ CTX_LOG_COUNT,96
.equ CTX_LAST_ERROR,104
.equ CTX_VALIDATION_FAILURES,112
.equ CTX_LEGACY_REMAINDER_INPUT,120
.equ CTX_LEGACY_REMAINDER_RESULT,128
.equ CTX_LEGACY_REMAINDER_SEEN,136
.equ CTX_PATCHED_REMAINDER_RESULT,144
.equ CTX_SAVE_PATCH_SEEN,152
.equ CTX_DAYTAG_CALC_INPUT,160
.equ CTX_LEGACY_DAYTAG_CALC_RESULT,168
.equ CTX_DAYTAG_TARGET_INPUT,176
.equ CTX_LEGACY_DAYTAG_TARGET_RESULT,184
.equ CTX_LEGACY_DAYTAG_SEEN,192
.equ CTX_PATCHED_DAYTAG_CALC_RESULT,200
.equ CTX_PATCHED_DAYTAG_TARGET_RESULT,208
.equ CTX_DAYTAG_PATCH_SEEN,216
.equ CTX_LEGACY_DISTANCE_RESULT,224
.equ CTX_DISTANCE_ROUTE_RESULT,232
.equ CTX_LEGACY_DISTANCE_SEEN,240
.equ CTX_DISTANCE_ROUTE_SEEN,248
.equ CTX_CHRONOLOGICAL_DISTANCE,256
.equ CTX_PATCHED_DISTANCE_RESULT,264
.equ CTX_DISTANCE_PATCH_SEEN,272
.equ CTX_LEGACY_STONE_ROW,280
.equ CTX_STONE_ROUTE_RESULT,288
.equ CTX_LEGACY_STONE_SEEN,296
.equ CTX_STONE_ROUTE_SEEN,304
.equ CTX_STONE_ITERATION,312
.equ CTX_STONE_PATCH_INPUT,320
.equ CTX_PATCHED_STONE_ROW,328
.equ CTX_STONE_PATCH_SEEN,336
.equ CTX_HIDDEN_BACKWARD,344
.equ CTX_HIDDEN_QUERY_K,352
.equ CTX_LEGACY_HIDDEN_QUERY_RESULT,360
.equ CTX_LEGACY_HIDDEN_STORAGE_SEEN,368
.equ CTX_LEGACY_HIDDEN_QUERY_SEEN,376
.equ CTX_PATCHED_HIDDEN_QUERY_RESULT,384
.equ CTX_HIDDEN_NEARNESS_PATCH_SEEN,392
.equ CTX_DROP_STORE,400
.equ CTX_PRIOR_I,408
.equ CTX_PRIOR_BACK,416
.equ CTX_LEGACY_PRIOR_RESULT,424
.equ CTX_PRIOR_ROUTE_RESULT,432
.equ CTX_LEGACY_PRIOR_SEEN,440
.equ CTX_PRIOR_ROUTE_SEEN,448
.equ CTX_PATCHED_PRIOR_RESULT,456
.equ CTX_PRIOR_PATCH_SEEN,464
.equ CTX_LEGACY_VISIBLE_DROP_RESULT,472
.equ CTX_VISIBLE_DROP_ROUTE_RESULT,480
.equ CTX_LEGACY_GRIND_ROW1,488
.equ CTX_LEGACY_GRIND_TABLE_SEEN,496
.equ CTX_LEGACY_VISIBLE_DROP_SEEN,504
.equ CTX_VISIBLE_DROP_I,512
.equ CTX_GRIND_SENTINEL_PATCH_SEEN,520
.equ CTX_LEGACY_PERMUTATION_DROP,528
.equ CTX_LEGACY_PERMUTATION_RANK0,536
.equ CTX_LEGACY_PERMUTATION_ORDER,544
.equ CTX_PERMUTATION_ROUTE_ORDER,552
.equ CTX_LEGACY_PERMUTATION_SEEN,560
.equ CTX_PERMUTATION_ROUTE_SEEN,568
.equ CTX_PATCHED_PERMUTATION_ONE_BASED,576
.equ CTX_PATCHED_PERMUTATION_RANK0,584
.equ CTX_PATCHED_PERMUTATION_ORDER,592
.equ CTX_PERMUTATION_PATCH_SEEN,600
.equ CTX_LEGACY_POUR_DROP,608
.equ CTX_LEGACY_POUR_I,616
.equ CTX_LEGACY_POUR_ORDER,624
.equ CTX_LEGACY_POUR_FIXED_IDS,632
.equ CTX_LEGACY_POUR_OLD_BOWLS,640
.equ CTX_LEGACY_POUR_STONE_ROW,648
.equ CTX_LEGACY_POUR_RESULT,656
.equ CTX_POUR_ROUTE_RESULT,664
.equ CTX_LEGACY_POUR_SEEN,672
.equ CTX_POUR_ROUTE_SEEN,680
.equ CTX_PATCHED_POUR_ORDER,688
.equ CTX_BOWL_ALIAS,696
.equ CTX_PATCHED_POUR_RESULT,704
.equ CTX_BOWL_ALIAS_PATCH_SEEN,712
.equ CTX_LEGACY_BOWL_STIR_DROP,720
.equ CTX_LEGACY_BOWL_STIR_I,728
.equ CTX_LEGACY_BOWL_STIR_INPUT,736
.equ CTX_LEGACY_BOWL_STIR_STONE_ROW,744
.equ CTX_LEGACY_BOWL_STIR_ORDER,752
.equ CTX_LEGACY_BOWL_STIR_POURS,760
.equ CTX_LEGACY_BOWL_STIR_OUTPUT,768
.equ CTX_LEGACY_BOWL_STIR_SEEN,776
.equ CTX_BOWL_STIR_ROUTE_RESULT,784
.equ CTX_BOWL_STIR_ROUTE_SEEN,792
.equ CTX_BOWL_SHADOW_PATCH_SEEN,800
.equ CTX_STAGE22_SAUCE_RESULT,808
.equ CTX_STAGE22_DROP46_DIAGNOSTIC,816
.equ CTX_STAGE22_LEGACY_ORDER_MEMORY,824
.equ CTX_STAGE22_QUERY_ORDER,832
.equ CTX_STAGE22_ORDER_WRITE_COUNT,840
.equ CTX_STAGE22_LAST_SOURCE_KIND,848
.equ CTX_STAGE22_LAST_SOURCE_ORDINAL,856
.equ CTX_STAGE22_SEEN,864
.equ CTX_STAGE23_ORDER46_LATCH,872
.equ CTX_STAGE23_LATCH_WRITE_COUNT,880
.equ CTX_STAGE23_LATCH_SOURCE_ORDINAL,888
.equ CTX_STAGE23_LEGACY_DIAGNOSTIC_RESULT,896
.equ CTX_STAGE23_SEEN,904
.equ CTX_STAGE24_QUERIED_BOWL_ID,912
.equ CTX_STAGE24_LEGACY_NEXT_BOWL_ID,920
.equ CTX_STAGE24_ROUTE_NEXT_BOWL_ID,928
.equ CTX_STAGE24_LEGACY_SEEN,936
.equ CTX_STAGE24_ROUTE_SEEN,944
.equ CTX_STAGE25_QUERIED_POSITION,952
.equ CTX_STAGE25_PATCHED_NEXT_BOWL_ID,960
.equ CTX_STAGE25_PATCH_SEEN,968
.equ CTX_STAGE26_ANSWER_RING,976
.equ CTX_STAGE26_FAMILY_SIZE,984
.equ CTX_STAGE26_FIRST_ANSWER,992
.equ CTX_STAGE26_LEGACY_SELECTION,1000
.equ CTX_STAGE26_ROUTE_SELECTION,1008
.equ CTX_STAGE26_QUERIED_BOWL_ID,1016
.equ CTX_STAGE26_NEXT_BOWL_ID,1024
.equ CTX_STAGE26_SEAL,1032
.equ CTX_STAGE26_DIRECTION,1040
.equ CTX_STAGE26_LEGACY_SEEN,1048
.equ CTX_STAGE26_ROUTE_SEEN,1056
.equ CTX_STAGE27_ACCEPTANCE_LIMIT,1064
.equ CTX_STAGE27_ACCEPTED_ANSWER,1072
.equ CTX_STAGE27_ACCEPTED_OFFSET,1080
.equ CTX_STAGE27_PATCHED_SELECTION,1088
.equ CTX_STAGE27_PATCH_SEEN,1096
.equ CTX_STAGE28_WIDE_RING,1104
.equ CTX_STAGE28_WIDE_FAMILY_SIZE,1112
.equ CTX_STAGE28_LEGACY_RESULT,1120
.equ CTX_STAGE28_LEGACY_ASSUMED_SHORT,1128
.equ CTX_STAGE28_LEGACY_UNSUPPORTED,1136
.equ CTX_STAGE28_ROUTE_SEEN,1144
.equ CTX_STAGE29_ROUTE_RESULT,1152
.equ CTX_STAGE29_PLACES,1160
.equ CTX_STAGE29_SPACE,1168
.equ CTX_STAGE29_COMBINED_INITIAL,1176
.equ CTX_STAGE29_ACCEPTANCE_LIMIT,1184
.equ CTX_STAGE29_ACCEPTED_COMBINED,1192
.equ CTX_STAGE29_REJECTION_STEPS,1200
.equ CTX_STAGE29_USED_WIDE,1208
.equ CTX_STAGE29_PATCH_SEEN,1216
.equ CTX_STAGE30_SIGNED_STEP,1224
.equ CTX_STAGE30_ABS_STEP,1232
.equ CTX_STAGE30_LEGACY_RESULT,1240
.equ CTX_STAGE30_ROUTE_RESULT,1248
.equ CTX_STAGE30_LEGACY_SEEN,1256
.equ CTX_STAGE30_ROUTE_SEEN,1264
.equ CTX_STAGE31_PATCHED_RESULT,1272
.equ CTX_STAGE31_PATCH_SEEN,1280
.equ CTX_STAGE32_LEGACY_YEAR_MAX_OBSERVED,1288
.equ CTX_STAGE32_CANDIDATE_MASK,1296
.equ CTX_STAGE32_LEGACY_SEEN,1304
.equ CTX_STAGE33_REAL_YEAR_MAX_OBSERVED,1312
.equ CTX_STAGE33_LEGACY_RAW_COUNT,1320
.equ CTX_STAGE33_REJECTED_BEFORE_SORT_COUNT,1328
.equ CTX_STAGE33_FILTERED_PRE_SORT_COUNT,1336
.equ CTX_STAGE33_SORTED_COUNT,1344
.equ CTX_STAGE33_SELECTION_CALLED,1352
.equ CTX_STAGE33_SELECTED_LENGTH,1360
.equ CTX_STAGE33_PATCH_SEEN,1368
.equ CTX_STAGE34_YEAR_NUMBER,1376
.equ CTX_STAGE34_TIE_LENGTH,1384
.equ CTX_STAGE34_TIE_COUNT,1392
.equ CTX_STAGE34_LEGACY_SELECTED_OPEN,1400
.equ CTX_STAGE34_ROUTE_SELECTED_OPEN,1408
.equ CTX_STAGE34_LEGACY_SEEN,1416
.equ CTX_STAGE34_ROUTE_SEEN,1424
.equ CTX_STAGE35_PATCH_SELECTED_OPEN,1432
.equ CTX_STAGE35_PATCH_SEEN,1440
.equ CTX_STAGE36_ANCHOR,1448
.equ CTX_STAGE36_TARGET_DAY,1456
.equ CTX_STAGE36_DELTA_FROM_FIRST,1464
.equ CTX_STAGE36_LEGACY_GUESS,1472
.equ CTX_STAGE36_ROUTE_GUESS,1480
.equ CTX_STAGE36_LEGACY_SEEN,1488
.equ CTX_STAGE36_ROUTE_SEEN,1496
.equ CTX_STAGE36_GUESS_USED_AS_SEMANTIC,1504
.equ CTX_STAGE36_ANCHOR_LENGTH,1512
.equ CTX_STAGE37_TELEMETRY_GUESS,1520
.equ CTX_STAGE37_PATCHED_YEAR,1528
.equ CTX_STAGE37_FINAL_YEAR,1536
.equ CTX_STAGE37_FORWARD_STEPS,1544
.equ CTX_STAGE37_BACKWARD_STEPS,1552
.equ CTX_STAGE37_TELEMETRY_ONLY,1560
.equ CTX_STAGE37_PATCH_SEEN,1568
.equ CTX_STAGE37_TARGET_DAY,1576
.equ CTX_STAGE38_CACHE_KEY_YEAR,1584
.equ CTX_STAGE38_CALCULATION_STALE,1592
.equ CTX_STAGE38_OPEN_STALE,1600
.equ CTX_STAGE38_CLOSE_STALE,1608
.equ CTX_STAGE38_ROUTE_CASES,1616
.equ CTX_STAGE38_NUMBER_ONLY_KEY,1624
.equ CTX_STAGE38_SEEN,1632
.equ CTX_STAGE39_CALCULATION_REFRESH,1640
.equ CTX_STAGE39_OPEN_REFRESH,1648
.equ CTX_STAGE39_CLOSE_REFRESH,1656
.equ CTX_STAGE39_LEGACY_STALE_CASES,1664
.equ CTX_STAGE39_SAME_STATE_HIT,1672
.equ CTX_STAGE39_NUMBER_ONLY_KEY_KEPT,1680
.equ CTX_STAGE39_PATCH_SEEN,1688
.equ CTX_STAGE40_YEAR,1696
.equ CTX_STAGE40_YEAR_FIRST_DAY,1704
.equ CTX_STAGE40_ORIGINAL_TARGET,1712
.equ CTX_STAGE40_GHOST_SAUCE,1720
.equ CTX_STAGE40_ROUTE_SAUCE,1728
.equ CTX_STAGE40_TARGET_DIFFERS_FIRSTDAY,1736
.equ CTX_STAGE40_GHOST_USED_AS_SEMANTIC,1744
.equ CTX_STAGE40_SEEN,1752
.equ CTX_STAGE41_ROUTE_GHOST,1760
.equ CTX_STAGE41_ROUTE_GHOST_SEEN,1768
.equ CTX_STAGE41_PATCH_SEEN,1776
.equ CTX_STAGE41_GHOST_REUSE_EQUAL,1784
.equ CTX_STAGE42_GAP_COUNT,1792
.equ CTX_STAGE42_CUTLET_COUNT,1800
.equ CTX_STAGE42_CALC_GATE_OFFSET,1808
.equ CTX_STAGE42_ROUTE_FAMILY_COUNT,1816
.equ CTX_STAGE42_ROUTE_PARTITION,1824
.equ CTX_STAGE42_LEGACY_ALL_POSITIVE,1832
.equ CTX_STAGE42_ROUTE_SEEN,1840
.equ CTX_STAGE42_SEEN,1848
.equ CTX_STAGE42_SELECTED_RANK,1856
.equ CTX_STAGE43_GHOST_FAMILY_COUNT,1864
.equ CTX_STAGE43_GHOST_PARTITION,1872
.equ CTX_STAGE43_GHOST_SEEN,1880
.equ CTX_STAGE43_FILTERED_USED,1888
.equ CTX_STAGE43_PATCH_SEEN,1896
.equ CTX_STAGE43_GHOST_REUSED,1904
.equ CTX_STAGE44_CUTLET_COUNT,1912
.equ CTX_STAGE44_SELECTED_RANK,1920
.equ CTX_STAGE44_ROUTE_NAMES,1928
.equ CTX_STAGE44_REPEAT_SEEN,1936
.equ CTX_STAGE44_ROUTE_SEEN,1944
.equ CTX_STAGE44_SEEN,1952
.equ CTX_STAGE45_GHOST_NAMES,1960
.equ CTX_STAGE45_GHOST_SEEN,1968
.equ CTX_STAGE45_PATCH_SEEN,1976
.equ CTX_STAGE45_GHOST_REUSED_EQUAL,1984
.equ CTX_STAGE45_CORRECT_USED_DIFFERENT,1992
.equ CTX_STAGE45_EQUAL_ROUTE_NAMES,2000
.equ CTX_STAGE45_EQUAL_GHOST_NAMES,2008
.equ CTX_STAGE46_YEAR_LENGTH,2016
.equ CTX_STAGE46_MONTH_COUNT,2024
.equ CTX_STAGE46_ROUTE_LIST,2032
.equ CTX_STAGE46_ROUTE_KIND,2040
.equ CTX_STAGE46_ROUTE_COUNT_U64,2048
.equ CTX_STAGE46_ROUTE_ROWS,2056
.equ CTX_STAGE46_FIRST_ROW,2064
.equ CTX_STAGE46_LAST_ROW,2072
.equ CTX_STAGE46_SEEN,2080
.equ CTX_STAGE46_LEGACY_MATERIALIZED,2088
.equ CTX_STAGE47_ROUTE_LIST,2096
.equ CTX_STAGE47_ROUTE_KIND,2104
.equ CTX_STAGE47_COUNT_BIG,2112
.equ CTX_STAGE47_ROUTE_ROWS,2120
.equ CTX_STAGE47_FIRST_ROW,2128
.equ CTX_STAGE47_LAST_ROW,2136
.equ CTX_STAGE47_GHOST_LIST,2144
.equ CTX_STAGE47_GHOST_SEEN,2152
.equ CTX_STAGE47_PATCH_SEEN,2160
.equ CTX_STAGE47_SEEN,2168
.equ CTX_SIZE,2176
.equ HCOUNTS_ACTION,0
.equ HCOUNTS_TARGET,8
.equ HCOUNTS_DISTANCE,16
.equ HCOUNTS_CONNECTION,24
.equ HCOUNTS_DIRECTION,32
.equ HCOUNTS_SIZE,40
.equ S22_BOWLS_AFTER_DROPS,0
.equ S22_FINAL_BOWLS,8
.equ S22_DROP46_DIAGNOSTIC,16
.equ S22_LEGACY_ORDER_MEMORY,24
.equ S22_LAST_POST_ORDER,32
.equ S22_QUERY_ORDER,40
.equ S22_DROPS,48
.equ S22_HIDDEN,56
.equ S22_ORDER_WRITE_COUNT,64
.equ S22_LAST_SOURCE_KIND,72
.equ S22_LAST_SOURCE_ORDINAL,80
.equ S22_SIZE,88
.equ S23_BOWLS_AFTER_DROPS,0
.equ S23_FINAL_BOWLS,8
.equ S23_DROP46_DIAGNOSTIC,16
.equ S23_LEGACY_ORDER_MEMORY,24
.equ S23_LAST_POST_ORDER,32
.equ S23_QUERY_ORDER,40
.equ S23_DROPS,48
.equ S23_HIDDEN,56
.equ S23_ORDER_WRITE_COUNT,64
.equ S23_LAST_SOURCE_KIND,72
.equ S23_LAST_SOURCE_ORDINAL,80
.equ S23_ORDER46_LATCH,88
.equ S23_LATCH_WRITE_COUNT,96
.equ S23_LATCH_SOURCE_ORDINAL,104
.equ S23_LEGACY_DIAGNOSTIC_RESULT,112
.equ S23_SIZE,120
.equ S26_RING_FIRST,0
.equ S26_RING_STEP,8
.equ S26_RING_SIZE,16
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_CAP,16
.equ BI_DATA,24
.equ LEGACY_YEAR_MAX,5781
.equ REAL_YEAR_MAX_PATCH,5778
.equ YC_OPEN,0
.equ YC_CLOSE,8
.equ YC_LENGTH,16
.equ YC_SIZE,24
.equ YJ_NUMBER,0
.equ YJ_OPEN_DAY,8
.equ YJ_FIRST_DAY,16
.equ YJ_CLOSE_DAY,24
.equ YJ_SIZE,32
.equ L38_CACHE_COUNT,0
.equ L38_CACHE_SLOTS,8
.equ L38_CACHE_SLOT_SIZE,16
.equ L38_CACHE_CAPACITY,4
.equ L38_CACHE_SIZE,72
.equ G39_ENTRY_CALC_FP,0
.equ G39_ENTRY_OPEN_GATE,8
.equ G39_ENTRY_CLOSE_GATE,16
.equ G39_ENTRY_VALUE,24
.equ G39_ENTRY_SIZE,32
.equ ML46_COUNT_BIG,0
.equ ML46_COUNT_U64,8
.equ ML46_TOTAL,16
.equ ML46_SLOTS,24
.equ ML46_ROWS,32
.equ ML46_KIND,40
.equ ML46_ROW_BYTES,48
.equ ML46_SIZE,56
.equ ML47_RESIDUAL,56
.equ ML47_STRIDE,64
.equ ML47_DP_TABLE,72
.equ ML47_GHOST_LIST,80
.equ ML47_GHOST_SEEN,88
.equ ML47_GHOST_SKIPPED,96
.equ ML47_SIZE,104
.equ E46_TOTAL,0
.equ E46_SLOTS,8
.equ E46_SCRATCH,16
.equ E46_ROWS,24
.equ E46_COUNT,32
.equ E46_FILL,40
.equ E46_SIZE,48

.section .data.rel.ro
.align 8
.global legacy_remainder_M
legacy_remainder_M:
    .quad 1
    .quad 2
    .quad 2
    .quad legacy_remainder_M_limbs
legacy_remainder_M_limbs:
    .quad 0xffffffffffffffff
    .quad 0x7fffffffffffffff

.section .rodata
.align 8
legacy_hidden_coeff:
    .quad 3,4,6,8
    .quad 5,7,10,12
    .quad 7,10,14,16
    .quad 9,13,18,20
    .quad 11,16,22,24
    .quad 13,19,26,28
    .quad 15,22,30,32
legacy_hidden_stone_kind:
    .quad 1,2,3,4,5,1,2

# ⲠStage 14 ⲁϥⲕⲱ ⲛ11 ⲛrow ⲛⲙⲉ ϩⲓ 0..10 ϩⲟⲡⲟⲩ ⲡlegacy loop ⲟⲩⲏϩ ⲉϥϫⲓ 1..11.
# ⲠStage 15 ⲙⲡⲉϥϣⲓⲃⲉ ⲙⲡlegacy indexing: ⲁϥⲟⲩⲱϩ ⲛⲟⲩsentinel ⲉϥϣⲟⲩⲓⲧ ϩⲓ index 0, ⲁⲩⲱ ⲛ11 ⲛrow ⲛⲙⲉ ⲥⲉϣⲟⲟⲡ ϩⲓ 1..11.
# Ⲡfence ⲛStage 14 ⲟⲩⲏϩ ⲉϥⲟⲩⲟϩ ⲙⲛⲛⲥⲁ ⲡtable ⲛⲟⲩϣⲟⲩⲱⲃⲉ, ⲁⲗⲗⲁ ⲛϥⲙⲟⲟϣⲉ ⲁⲛ ϩⲙⲡCOPY_AUTHORITATIVE.
legacy_visible_grinds_indexed:
    .quad 0,0,0,0,0
    .quad 3,5,7,11,1
    .quad 5,7,11,13,2
    .quad 7,11,13,17,3
    .quad 11,13,17,19,4
    .quad 13,17,19,23,5
    .quad 17,19,23,29,1
    .quad 19,23,29,31,2
    .quad 23,29,31,37,3
    .quad 29,31,37,41,4
    .quad 31,37,41,43,5
    .quad 37,41,43,47,1
legacy_visible_grind_missing_fence:
    .quad 0,0,0,0,0

.align 8
legacy_factorial_0_5:
    .quad 1,1,2,6,24,120

.align 8
legacy_fixed_pour_ids:
    .quad 1,2,3
legacy_pour_factor:
    .quad 3,5,7
stage22_bowl_prime:
    .quad 17,19,23,29,31,37
# Ⲡlegacy ⲙⲡⲃⲁⲑⲙⲟⲥ 20 ϫⲓ ⲙⲡⲱⲛⲉ ⲕⲁⲧⲁ ⲡposition.
legacy_bowl_stir_stone_by_position:
    .quad 0,1,2,3,4,0

.section .text
.extern arena_alloc
.extern bi_abs
.extern bi_divmod_u64_abs
.extern bi_mod_abs
.extern bi_divmod_abs
.extern bi_mul_abs
.extern bi_is_zero
.extern bi_sub_abs
.extern bi_sub
.extern bi_mul_u64
.extern bi_mul_abs
.extern bi_add_abs
.extern bi_from_i64
.extern bi_from_u64
.extern bi_clone
.extern bi_add_u64
.extern bi_add
.global monster_context_new
.global monster_validate_base
.global monster_metrics_bump
.global monster_dispatch_base
.global calendarDateSpaghetti
.global oldRemainder
.global savePatch
.global monster_stage03_save_patch_wrapper
.global monster_stage02_legacy_remainder_handler
.global monster_remainder_route
.global oldDayTag
.global dayTagWithFoundationScar
.global monster_stage05_daytag_patch_wrapper
.global monster_daytag_route
.global monster_stage04_legacy_daytag_handler
.global oldDistance
.global distanceWithChronologicalScar
.global monster_stage07_distance_patch_wrapper
.global monster_distance_route
.global monster_stage06_legacy_distance_handler
.global mutateStonesWrong
.global monster_stone_mutation_route
.global monster_stage08_legacy_stone_handler
.global stonePatch
.global monster_stage09_stone_patch_wrapper
.global getStoneTableThroughLegacyBuilder
.global getHiddenStonePrefixThroughLegacyBuilder
.global makeHiddenLegacyStoredValue
.global buildHiddenWithBackwardStorage
.global legacyHiddenAtNearnessWrong
.global hiddenByNearness
.global monster_stage11_hidden_nearness_patch_wrapper
.global monster_hidden_route
.global monster_stage10_legacy_hidden_handler
.global legacyPrior
.global priorPatch
.global monster_stage13_prior_patch_wrapper
.global monster_prior_route
.global monster_stage12_legacy_prior_handler
.global legacyGrindRowAtIndex
.global oneVisibleDropLegacyGrindIndexWrong
.global monster_visible_drop_route
.global monster_stage14_legacy_grind_handler
.global grindSentinelRow0
.global monster_stage15_grind_sentinel_patch_wrapper
.global oldPermutationUnrank0
.global legacyPermutationRank0FromDropWrong
.global legacyPermutationOrderFromDropWrong
.global monster_permutation_route
.global monster_stage16_legacy_permutation_handler
.global permutationOneBasedFromDropPatch08
.global orderPatchFromValue
.global monster_stage17_permutation_patch_wrapper
.global legacyPoursToFixedBowlIds
.global monster_pour_route
.global monster_stage18_legacy_fixed_pour_handler
.global installOrderAliases
.global bowlByLegacyPosition
.global patchedPours
.global monster_stage19_bowl_alias_patch_wrapper
.global legacyStirOneDropInPlace
.global monster_bowl_stir_route
.global monster_stage20_legacy_inplace_bowl_handler
.global stirOneDropViaShadow
.global monster_stage21_bowl_shadow_patch_wrapper
.global initialBowlsThroughStage22OldFactory
.global postStirOneOverwritingOrderMemoryStage22
.global legacySauceWithOverwritableOrderMemory
.global monster_order46_memory_route
.global monster_stage22_overwritable_order_handler
.global sauceWithOrderAt46Latch
.global monster_stage23_order46_latch_patch_wrapper
.global monster_stage23_order46_latch_handler
.global oldNextBowlFixedName
.global legacyNextBowlAdapter
.global monster_next_bowl_route
.global monster_stage24_legacy_next_bowl_handler
.global nextBowlQueryPatch
.global monster_stage25_next_bowl_patch_wrapper
.global monster_stage25_next_bowl_patch_handler
.global answerRingThroughPatchedNextBowl
.global ringAnswer
.global biasedLegacyPick
.global legacyBiasedSelectionBeforeRejection
.global patchedSmallPick
.global monster_stage27_rejection_patch_wrapper
.global monster_biased_selection_route
.global monster_stage26_legacy_biased_selection_handler
.global monster_stage27_rejection_patch_handler
.global legacySelectionAssumingNLeM
.global wideRingStepPatch14
.global wideDetour
.global selectionPatch14
.global monster_stage29_wide_patch_wrapper
.global monster_wide_selection_route
.global monster_stage28_legacy_wide_assumption_handler
.global monster_stage29_wide_patch_handler
.global oldGateQuestionDay
.global legacyGateQuestionDayFromSignedStepWrong
.global monster_gate_question_day_route
.global monster_stage30_legacy_gate_question_handler
.global gateQuestionDayPatch15
.global monster_stage31_gate_question_patch_wrapper
.global monster_stage31_gate_question_patch_handler
.global oldYearCandidate
.global yearCandidateAfterFootnotePatch
.global legacyYearCandidatesBeforeSortStage33
.global yearCandidatesAfterFootnotePatchBeforeSort
.global stableLengthOnlyPatchedYearCandidates
.global legacyYearSelectFirst
.global monster_stage33_year_ceiling_patch_wrapper
.global monster_year_candidate_route
.global monster_stage32_legacy_year_max_handler
.global monster_stage33_year_ceiling_patch_handler
.global legacyYear5000TieSelection
.global monster_stage34_legacy_year5000_tie_wrapper
.global monster_year5000_tie_route
.global monster_stage34_legacy_year5000_tie_handler
.global reorderEqualLengthRunsByOpeningAfterLegacySort
.global year5000TieSelectionPatch17
.global monster_stage35_year5000_tie_patch_wrapper
.global monster_stage35_year5000_tie_patch_handler
.global oldJumpGuess
.global stage36Year5000JumpAnchorFromPatchedTie
.global legacyYearJumpAdapter
.global monster_year_jump_route
.global monster_stage36_legacy_year_jump_handler
.global patchedNextYear
.global patchedPreviousYear
.global findYearByWalkPatch
.global monster_stage37_year_walk_patch_wrapper
.global monster_stage37_year_walk_patch_handler
.global stage38NewLegacyYearCache
.global legacyYearNumberOnlyCacheGetOrPut
.global buildLegacyYearCacheValueStage38
.global stage38YearVariant
.global legacyYearNumberOnlyCacheRoute
.global monster_year_cache_route
.global stage38LegacyCollisionCase
.global monster_stage38_legacy_year_number_cache_handler
.global calculationDayFingerprintPatch19
.global stage39NewGuardedEntry
.global guardedYearNumberOnlyCacheGetOrPut
.global guardedYearNumberOnlyCacheRoute
.global monster_stage39_year_cache_guard_patch_wrapper
.global stage39GuardedCollisionCase
.global monster_stage39_year_cache_guard_patch_handler
.global oldStructureSauce
.global legacyStructureSauceUsingOriginalTarget
.global structureSaucePatch
.global monster_stage41_structure_sauce_patch_wrapper
.global monster_structure_sauce_route
.global monster_stage40_legacy_structure_sauce_handler
.global stage42LegacyBinomialU64
.global oldCutletPartitionFamilyCount
.global oldCutletPartitionFamilyUnrank
.global oldCutletPartitionFamily
.global legacyCutletPartitionWithoutCalculationGate
.global monster_cutlet_partition_route
.global monster_stage42_legacy_cutlet_partition_handler
.global filteredCutletPartitionFamilyCount
.global filteredCutletPartitionFamilyUnrank
.global filteredCutletPartitionFamily
.global cutletPartitionPatch21
.global monster_stage43_cutlet_partition_patch_wrapper
.global oldCutletNameRowWithRepeats
.global legacyCutletNamesWithRepeats
.global stage45FallingU64
.global unrankDistinctCutletNames17
.global cutletNamesPatch22
.global monster_stage45_cutlet_names_patch_wrapper
.global monster_cutlet_names_route
.global monster_stage44_legacy_repeated_names_handler
.global monster_stage45_cutlet_names_patch_handler
.global oldMonthLengthMaterializedList
.global legacyMonthLengthMaterializedList
.global legacyMonthLengthListCount
.global legacyMonthLengthListItemAt1
.global monster_month_length_family_route
.global monster_stage46_legacy_month_materialization_handler
.global VirtualLegacyList
.global virtualMonthLengthListCount
.global virtualMonthLengthListItemAt1Big
.global virtualMonthLengthListItemAt1
.global monthLengthVirtualListPatch23
.global monster_stage47_month_length_patch_wrapper
.global monster_stage47_virtual_month_length_patch_handler

.type monster_context_new,@function
monster_context_new:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rdi,CTX_SIZE
    call arena_alloc
    mov r8,rax
    mov rdi,r8
    xor eax,eax
    mov rcx,CTX_SIZE/8
    rep stosq
    mov qword ptr [r8+CTX_CALCULATION_DAY],r12
    mov qword ptr [r8+CTX_TARGET_DAY],r13
    mov qword ptr [r8+CTX_MODE],1
    mov qword ptr [r8+CTX_STATUS],1
    mov rax,r8
    pop r13
    pop r12
    leave
    ret
.size monster_context_new,.-monster_context_new

.type monster_validate_base,@function
monster_validate_base:
    test rdi,rdi
    je .Lmvb_fail
    cmp qword ptr [rdi+CTX_CALCULATION_DAY],0
    je .Lmvb_fail_count
    cmp qword ptr [rdi+CTX_TARGET_DAY],0
    je .Lmvb_fail_count
    mov eax,1
    ret
.Lmvb_fail_count:
    inc qword ptr [rdi+CTX_VALIDATION_FAILURES]
.Lmvb_fail:
    xor eax,eax
    ret
.size monster_validate_base,.-monster_validate_base

.type monster_metrics_bump,@function
monster_metrics_bump:
    test rdi,rdi
    je .Lmmb_done
    inc qword ptr [rdi+CTX_METRIC_COUNT]
.Lmmb_done:
    ret
.size monster_metrics_bump,.-monster_metrics_bump

.type monster_dispatch_base,@function
monster_dispatch_base:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lmdb_fail
    test r13,r13
    je .Lmdb_fail
    mov rax,qword ptr [r12+CTX_CURRENT_HANDLER]
    mov qword ptr [r12+CTX_PREVIOUS_HANDLER],rax
    mov qword ptr [r12+CTX_CURRENT_HANDLER],r13
    inc qword ptr [r12+CTX_BRANCH_COUNT]
    mov rdi,r12
    call r13
    jmp .Lmdb_done
.Lmdb_fail:
    xor eax,eax
.Lmdb_done:
    pop r13
    pop r12
    leave
    ret
.size monster_dispatch_base,.-monster_dispatch_base


.type oldRemainder,@function
oldRemainder:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,qword ptr [r12+BI_SIGN]
    mov rdi,r12
    call bi_abs
    mov rdi,rax
    lea rsi,[rip+legacy_remainder_M]
    call bi_mod_abs
    mov r14,rax
    test r13,r13
    jge .Lor_done_value
    mov rdi,r14
    call bi_is_zero
    test eax,eax
    jne .Lor_done_value
    lea rdi,[rip+legacy_remainder_M]
    mov rsi,r14
    call bi_sub_abs
    jmp .Lor_done
.Lor_done_value:
    mov rax,r14
.Lor_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oldRemainder,.-oldRemainder

# Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ϯ 0 ϩⲓ ⲛⲡⲟⲗⲗⲁⲡⲗⲁⲥⲓⲟⲛ ⲙⲡ M. Ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ ϫⲉ ⲟⲩϣⲟⲩⲱⲃⲉ ⲛⲧⲉⲡϩⲓⲥⲧⲟⲣⲓⲁ ⲡⲉ.
# Ⲡ savePatch ⲕⲱ M ⲉϩⲣⲁⲓ ⲉϣϫⲉ ⲡ oldRemainder ϯ 0. Ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ SAVE ⲁⲩⲱ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲛⲟⲩⲕⲉⲁⲡⲟⲕⲣⲓⲥⲓⲥ.
.type savePatch,@function
savePatch:
    push rbp
    mov rbp,rsp
    push r12
    call oldRemainder
    mov r12,rax
    mov rdi,r12
    call bi_is_zero
    test eax,eax
    je .Lsp_old_value
    lea rdi,[rip+legacy_remainder_M]
    call bi_clone
    jmp .Lsp_done
.Lsp_old_value:
    mov rax,r12
.Lsp_done:
    pop r12
    leave
    ret
.size savePatch,.-savePatch

.type monster_stage03_save_patch_wrapper,@function
monster_stage03_save_patch_wrapper:
    jmp savePatch
.size monster_stage03_save_patch_wrapper,.-monster_stage03_save_patch_wrapper

.type monster_remainder_route,@function
monster_remainder_route:
    jmp monster_stage03_save_patch_wrapper
.size monster_remainder_route,.-monster_remainder_route

.type monster_stage02_legacy_remainder_handler,@function
monster_stage02_legacy_remainder_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    test r12,r12
    je .Lms02_fail
    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    call bi_from_i64
    mov r13,rax
    mov qword ptr [r12+CTX_LEGACY_REMAINDER_INPUT],r13
    mov rdi,r13
    call oldRemainder
    mov qword ptr [r12+CTX_LEGACY_REMAINDER_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_REMAINDER_SEEN]
    mov rdi,r13
    call monster_remainder_route
    mov qword ptr [r12+CTX_PATCHED_REMAINDER_RESULT],rax
    inc qword ptr [r12+CTX_SAVE_PATCH_SEEN]
    mov eax,1
    jmp .Lms02_done
.Lms02_fail:
    xor eax,eax
.Lms02_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage02_legacy_remainder_handler,.-monster_stage02_legacy_remainder_handler


# Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲉⲧⲉⲓ ⲙⲡⲉϥⲡⲱⲣϫ ⲙⲙⲟⲥ ϫⲉ ⲛⲉϩⲟⲟⲩ ⲙⲛⲛⲥⲁ ⲡϩⲟⲟⲩ ⲛⲧⲉⲥⲛⲧⲉ ⲥⲉϣⲟⲟⲡ ⲛⲕⲟⲧ ⲛⲟⲩⲱⲧ. Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩⲡⲁⲧϣ ϩⲙ ⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ.
.type oldDayTag,@function
oldDayTag:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    mov rdi,-15055671
    call bi_from_i64
    mov rsi,rax
    mov rdi,r12
    call bi_sub
    mov rdi,rax
    call bi_abs
    mov rdi,rax
    mov rsi,2
    call bi_mul_u64
    pop r12
    leave
    ret
.size oldDayTag,.-oldDayTag

# Ⲡ oldDayTag ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲙⲛ ⲡⲉϥⲡⲗⲁⲛⲏ. Ⲡⲡⲁⲧϣ ⲉⲧⲛⲏⲩ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲙⲟϥ; ⲛϥⲟⲩⲱϩ ⲙⲙⲁⲧⲉ ⲉϫⲱϥ.
# Ⲡ guard ⲙⲡ FOUNDATION ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩϣⲟⲩⲱⲃⲉ ⲛⲧⲉⲡϩⲓⲥⲧⲟⲣⲓⲁ, ϩⲟⲡⲟⲩ ⲡ +1 ⲛϣⲟⲣⲡ ⲧⲁⲙⲓⲟ ⲙⲡ 1.
.type dayTagWithFoundationScar,@function
dayTagWithFoundationScar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    call oldDayTag
    mov r13,rax

    mov rdi,-15055671
    call bi_from_i64
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jl .Ldtfs_done

    mov rdi,r13
    mov rsi,1
    call bi_add_u64
    mov r13,rax

    mov rdi,r12
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Ldtfs_done
    mov rdi,r13
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    jne .Ldtfs_done
    mov rdi,1
    call bi_from_u64
    mov r13,rax
.Ldtfs_done:
    mov rax,r13
    pop r14
    pop r13
    pop r12
    leave
    ret
.size dayTagWithFoundationScar,.-dayTagWithFoundationScar

.type monster_stage05_daytag_patch_wrapper,@function
monster_stage05_daytag_patch_wrapper:
    jmp dayTagWithFoundationScar
.size monster_stage05_daytag_patch_wrapper,.-monster_stage05_daytag_patch_wrapper

.type monster_daytag_route,@function
monster_daytag_route:
    jmp monster_stage05_daytag_patch_wrapper
.size monster_daytag_route,.-monster_daytag_route

.type monster_stage04_legacy_daytag_handler,@function
monster_stage04_legacy_daytag_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    test r12,r12
    je .Lms04_fail

    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    call bi_from_i64
    mov r13,rax
    mov qword ptr [r12+CTX_DAYTAG_CALC_INPUT],r13
    mov rdi,r13
    call oldDayTag
    mov qword ptr [r12+CTX_LEGACY_DAYTAG_CALC_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DAYTAG_SEEN]
    mov rdi,r13
    call monster_daytag_route
    mov qword ptr [r12+CTX_PATCHED_DAYTAG_CALC_RESULT],rax
    inc qword ptr [r12+CTX_DAYTAG_PATCH_SEEN]

    mov rdi,qword ptr [r12+CTX_TARGET_DAY]
    call bi_from_i64
    mov r13,rax
    mov qword ptr [r12+CTX_DAYTAG_TARGET_INPUT],r13
    mov rdi,r13
    call oldDayTag
    mov qword ptr [r12+CTX_LEGACY_DAYTAG_TARGET_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DAYTAG_SEEN]
    mov rdi,r13
    call monster_daytag_route
    mov qword ptr [r12+CTX_PATCHED_DAYTAG_TARGET_RESULT],rax
    inc qword ptr [r12+CTX_DAYTAG_PATCH_SEEN]

    mov eax,1
    jmp .Lms04_done
.Lms04_fail:
    xor eax,eax
.Lms04_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage04_legacy_daytag_handler,.-monster_stage04_legacy_daytag_handler

# Ⲡ oldDistance ⲥⲱⲟⲩϩ ⲙⲡⲟⲩⲱϣⲃ ⲛⲛⲧⲁⲅ ⲛⲛϩⲟⲟⲩ, ⲛⲧⲟϥ ⲇⲉ ⲛϥϣⲓⲛⲉ ⲁⲛ ⲛⲥⲁ ⲡⲟⲩⲁϩⲥⲁϩⲛⲉ ⲛⲛϩⲟⲟⲩ ϩⲛ ⲡⲉⲩⲧⲁⲝⲓⲥ.
# Ⲡⲣⲱⲧⲉ ⲡⲁⲓ ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲗⲉⲅⲁⲥⲓ; ⲙⲛ ⲡⲁⲧϣ ⲉϥϣⲟⲟⲡ ϩⲙ ⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ.
.type oldDistance,@function
oldDistance:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call dayTagWithFoundationScar
    mov r14,rax
    mov rdi,r13
    call dayTagWithFoundationScar
    mov rsi,rax
    mov rdi,r14
    call bi_sub
    mov rdi,rax
    call bi_abs
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oldDistance,.-oldDistance

# Ⲡ oldDistance ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲙⲛ ⲡⲉϥⲡⲗⲁⲛⲏ. Ⲡⲡⲁⲧϣ ⲙⲉⲧⲣⲉ ⲙⲡⲙⲁⲕⲣⲟⲛ ⲛⲧⲉⲛϩⲟⲟⲩ, ⲁⲩⲱ ⲛϥϣⲓⲃⲉ ⲙⲡlegacy ⲙⲙⲁⲧⲉ ⲉϣϫⲉ ⲛⲥⲉⲧⲱⲛ ⲁⲛ.
# Ⲙⲛⲛⲥⲱⲥ ⲛϥⲟⲩⲱϩ 1. Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ oldDistance, ⲁⲩⲱ ⲙⲛ fallback ⲉϥⲥⲟⲡⲥⲡ ⲉϥϣⲟⲟⲡ.
.type distanceWithChronologicalScar,@function
distanceWithChronologicalScar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi

    mov rdi,r12
    mov rsi,r13
    call oldDistance
    mov r14,rax

    mov rdi,r13
    mov rsi,r12
    call bi_sub
    mov rdi,rax
    call bi_abs
    mov r15,rax

    mov rdi,r14
    mov rsi,r15
    call bi_cmp
    test eax,eax
    je .Ldwcs_keep_legacy
    mov r14,r15
.Ldwcs_keep_legacy:
    mov rdi,r14
    mov rsi,1
    call bi_add_u64

    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size distanceWithChronologicalScar,.-distanceWithChronologicalScar

.type monster_stage07_distance_patch_wrapper,@function
monster_stage07_distance_patch_wrapper:
    jmp distanceWithChronologicalScar
.size monster_stage07_distance_patch_wrapper,.-monster_stage07_distance_patch_wrapper

.type monster_distance_route,@function
monster_distance_route:
    jmp monster_stage07_distance_patch_wrapper
.size monster_distance_route,.-monster_distance_route

.type monster_stage06_legacy_distance_handler,@function
monster_stage06_legacy_distance_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    test r12,r12
    je .Lms06_fail
    mov r13,qword ptr [r12+CTX_DAYTAG_CALC_INPUT]
    mov r14,qword ptr [r12+CTX_DAYTAG_TARGET_INPUT]
    test r13,r13
    je .Lms06_fail
    test r14,r14
    je .Lms06_fail

    mov rdi,r13
    mov rsi,r14
    call oldDistance
    mov qword ptr [r12+CTX_LEGACY_DISTANCE_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DISTANCE_SEEN]

    mov rdi,r14
    mov rsi,r13
    call bi_sub
    mov rdi,rax
    call bi_abs
    mov qword ptr [r12+CTX_CHRONOLOGICAL_DISTANCE],rax

    mov rdi,r13
    mov rsi,r14
    call monster_distance_route
    mov qword ptr [r12+CTX_DISTANCE_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_PATCHED_DISTANCE_RESULT],rax
    inc qword ptr [r12+CTX_DISTANCE_ROUTE_SEEN]
    inc qword ptr [r12+CTX_DISTANCE_PATCH_SEEN]

    mov eax,1
    jmp .Lms06_done
.Lms06_fail:
    xor eax,eax
.Lms06_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage06_legacy_distance_handler,.-monster_stage06_legacy_distance_handler



# Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲛϣⲟⲙⲛⲧ ⲛⲉⲣⲅⲁⲥⲓⲁ ⲙⲡⲉⲓⲙⲁ ⲛⲁϣⲱⲡⲉ ⲛⲟⲩⲱⲧ ϩⲛ ⲟⲩⲥⲱⲙⲁ ⲛ state. Ⲡ mutateStonesWrong ϣⲓⲃⲉ ⲙⲡⲉϥⲥⲱⲙⲁ ϩⲛ ⲟⲩⲧⲁⲝⲓⲥ, ⲁⲩⲱ ⲛϥϫⲓ ⲛⲛⲉⲁⲡⲟⲕⲣⲓⲥⲓⲥ ⲛⲃⲣⲣⲉ ϩⲛ ⲛⲗⲟⲅⲓⲥⲙⲟⲥ ⲉⲧⲛⲏⲩ.
# Ⲙⲛ snapshot ⲛⲕⲁⲛⲱⲛ ⲉϥϣⲟⲟⲡ ϩⲙ ⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ. Ⲡⲡⲗⲁⲛⲏ ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲙⲡⲣⲱⲧⲉ.
.type mutateStonesWrong,@function
mutateStonesWrong:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lmsw_fail

    # w = SAVE(w*w + 3*b + i)
    mov rdi,qword ptr [r12]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+8]
    mov rsi,3
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    mov rdi,rax
    call savePatch
    mov qword ptr [r12],rax

    # b = SAVE(b*b + 5*s + w) ; w ⲡⲉ ⲡⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+8]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+16]
    mov rsi,5
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+8],rax

    # s = SAVE(s*s + 7*m + b) ; b ⲡⲉ ⲡⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+16]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+24]
    mov rsi,7
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12+8]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+16],rax

    # m = SAVE(m*m + 11*r + s) ; s ⲡⲉ ⲡⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+24]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+32]
    mov rsi,11
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12+16]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+24],rax

    # r = SAVE(r*r + 13*w + m) ; w ⲙⲛ m ⲛⲉ ⲛⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+32]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12]
    mov rsi,13
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12+24]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+32],rax

    mov rax,r12
    jmp .Lmsw_done
.Lmsw_fail:
    xor eax,eax
.Lmsw_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size mutateStonesWrong,.-mutateStonesWrong

# Ⲡ mutateStonesWrong ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲁⲩⲱ ⲡ stonePatch ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ϩⲓ ⲟⲩclone. Ⲡgarbage ⲛⲗⲉⲅⲁⲥⲓ ⲛϥⲃⲱⲗ ⲁⲛ ⲉⲃⲟⲗ; ⲁⲗⲗⲁ ⲛ5 ⲛⲧⲓⲙⲏ ⲥⲉⲥϩⲁⲓ ⲛⲕⲉⲥⲟⲡ ⲉⲃⲟⲗ ϩⲙⲡsnapshot ⲛϣⲟⲣⲡ.
# Ⲡsnapshot ⲙⲛ ⲡgarbage ⲛⲉ 40 bytes ⲙⲡⲟⲓⲛⲧⲉⲣ. ⲚBigInt ⲥⲉⲟ ⲛimmutable ϩⲙⲡⲉⲓⲣⲱⲧⲉ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡclone ⲛⲧⲉⲡrow ⲧⲁϫⲣⲏⲩ.
.type stonePatch,@function
stonePatch:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lsp4_fail

    # old = clone(S)
    mov rdi,40
    call arena_alloc
    mov r14,rax
    mov rax,qword ptr [r12]
    mov qword ptr [r14],rax
    mov rax,qword ptr [r12+8]
    mov qword ptr [r14+8],rax
    mov rax,qword ptr [r12+16]
    mov qword ptr [r14+16],rax
    mov rax,qword ptr [r12+24]
    mov qword ptr [r14+24],rax
    mov rax,qword ptr [r12+32]
    mov qword ptr [r14+32],rax

    # garbage = mutateStonesWrong(i, clone(S))
    mov rdi,40
    call arena_alloc
    mov r15,rax
    mov rax,qword ptr [r12]
    mov qword ptr [r15],rax
    mov rax,qword ptr [r12+8]
    mov qword ptr [r15+8],rax
    mov rax,qword ptr [r12+16]
    mov qword ptr [r15+16],rax
    mov rax,qword ptr [r12+24]
    mov qword ptr [r15+24],rax
    mov rax,qword ptr [r12+32]
    mov qword ptr [r15+32],rax
    mov rdi,r15
    mov rsi,r13
    call mutateStonesWrong
    test rax,rax
    je .Lsp4_fail
    mov r15,rax

    # w = SAVE(old.w*old.w + 3*old.b + i)
    mov rdi,qword ptr [r14]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+8]
    mov rsi,3
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    mov rdi,rax
    call savePatch
    mov qword ptr [r15],rax

    # b = SAVE(old.b*old.b + 5*old.s + old.w)
    mov rdi,qword ptr [r14+8]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+16]
    mov rsi,5
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+8],rax

    # s = SAVE(old.s*old.s + 7*old.m + old.b)
    mov rdi,qword ptr [r14+16]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+24]
    mov rsi,7
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14+8]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+16],rax

    # m = SAVE(old.m*old.m + 11*old.r + old.s)
    mov rdi,qword ptr [r14+24]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+32]
    mov rsi,11
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14+16]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+24],rax

    # r = SAVE(old.r*old.r + 13*old.w + old.m)
    mov rdi,qword ptr [r14+32]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14]
    mov rsi,13
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14+24]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+32],rax

    mov rax,r15
    jmp .Lsp4_done
.Lsp4_fail:
    xor eax,eax
.Lsp4_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stonePatch,.-stonePatch

# Ⲡwrapper ϩⲁⲣⲉϩ ⲉⲡcontract ⲙⲡroute ⲛⲗⲉⲅⲁⲥⲓ: ⲡpointer ⲉⲧⲃⲱⲕ ⲉϩⲟⲩⲛ ⲡⲉ ⲡpointer ⲉⲧⲛⲏⲩ ⲉⲃⲟⲗ. Ⲡ stonePatch ⲛⲧⲟϥ ⲟⲩⲏϩ ⲉϥⲕⲱ ⲙⲡgarbage clone ⲉⲃⲟⲗ.
.type monster_stage09_stone_patch_wrapper,@function
monster_stage09_stone_patch_wrapper:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call stonePatch
    test rax,rax
    je .Lms09w_fail
    mov r13,rax
    mov rax,qword ptr [r13]
    mov qword ptr [r12],rax
    mov rax,qword ptr [r13+8]
    mov qword ptr [r12+8],rax
    mov rax,qword ptr [r13+16]
    mov qword ptr [r12+16],rax
    mov rax,qword ptr [r13+24]
    mov qword ptr [r12+24],rax
    mov rax,qword ptr [r13+32]
    mov qword ptr [r12+32],rax
    mov rax,r12
    jmp .Lms09w_done
.Lms09w_fail:
    xor eax,eax
.Lms09w_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage09_stone_patch_wrapper,.-monster_stage09_stone_patch_wrapper

.type monster_stone_mutation_route,@function
monster_stone_mutation_route:
    jmp monster_stage09_stone_patch_wrapper
.size monster_stone_mutation_route,.-monster_stone_mutation_route

# Ⲡbuilder ⲛⲗⲉⲅⲁⲥⲓ ⲕⲱ ⲉϩⲣⲁⲓ ⲛ46 ⲛrows. Ⲛrow 2..46 ⲥⲉⲛⲏⲩ ϩⲓⲧⲛ stonePatch, ⲉⲣⲉ mutateStonesWrong ⲙⲟⲟϣⲉ ⲙⲙⲏⲛⲉ ϩⲙⲡⲁⲧϣ.
.type getStoneTableThroughLegacyBuilder,@function
getStoneTableThroughLegacyBuilder:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov rdi,1840
    call arena_alloc
    mov r12,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r12],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r12+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r12+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r12+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r12+32],rax
    mov r13,2
.Lgst_loop:
    cmp r13,47
    jae .Lgst_done_rows
    mov rax,r13
    sub rax,2
    imul rax,40
    lea r14,[r12+rax]
    mov rdi,r14
    mov rsi,r13
    call stonePatch
    test rax,rax
    je .Lgst_fail
    mov r15,rax
    mov rax,r13
    dec rax
    imul rax,40
    lea r14,[r12+rax]
    mov rax,qword ptr [r15]
    mov qword ptr [r14],rax
    mov rax,qword ptr [r15+8]
    mov qword ptr [r14+8],rax
    mov rax,qword ptr [r15+16]
    mov qword ptr [r14+16],rax
    mov rax,qword ptr [r15+24]
    mov qword ptr [r14+24],rax
    mov rax,qword ptr [r15+32]
    mov qword ptr [r14+32],rax
    inc r13
    jmp .Lgst_loop
.Lgst_done_rows:
    mov rax,r12
    jmp .Lgst_done
.Lgst_fail:
    xor eax,eax
.Lgst_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size getStoneTableThroughLegacyBuilder,.-getStoneTableThroughLegacyBuilder

.type monster_stage08_legacy_stone_handler,@function
monster_stage08_legacy_stone_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    test r12,r12
    je .Lms08_fail

    # Ⲡrow ⲛϣⲟⲣⲡ ⲃⲱⲕ ⲉ mutateStonesWrong ⲙⲙⲁⲧⲉ, ⲉⲧⲣⲉ ⲡgarbage ⲟⲩⲱⲛϩ ⲉⲃⲟⲗ ϩⲙⲡcontext.
    mov rdi,40
    call arena_alloc
    mov r13,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r13],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r13+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r13+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r13+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r13+32],rax
    mov rdi,r13
    mov rsi,2
    call mutateStonesWrong
    test rax,rax
    je .Lms08_fail
    mov qword ptr [r12+CTX_LEGACY_STONE_ROW],rax
    inc qword ptr [r12+CTX_LEGACY_STONE_SEEN]

    # Ⲡrow ⲛⲥⲛⲁⲩ ⲃⲱⲕ ϩⲓⲧⲛ ⲡroute ⲙⲡⲁⲧϣ.
    mov rdi,40
    call arena_alloc
    mov r14,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r14],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r14+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r14+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r14+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r14+32],rax
    mov qword ptr [r12+CTX_STONE_ITERATION],2
    mov qword ptr [r12+CTX_STONE_PATCH_INPUT],r14
    mov rdi,r14
    mov rsi,2
    call monster_stone_mutation_route
    test rax,rax
    je .Lms08_fail
    mov qword ptr [r12+CTX_STONE_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_PATCHED_STONE_ROW],rax
    inc qword ptr [r12+CTX_STONE_ROUTE_SEEN]
    inc qword ptr [r12+CTX_STONE_PATCH_SEEN]
    mov eax,1
    jmp .Lms08_done
.Lms08_fail:
    xor eax,eax
.Lms08_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage08_legacy_stone_handler,.-monster_stage08_legacy_stone_handler



# Ⲛhidden ⲥⲉϫⲓ ⲙⲙⲁⲧⲉ ⲛⲛrow 1..7 ⲛⲧⲉⲛⲱⲛⲉ. Ⲡbuilder ⲡⲁⲓ ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ stonePatch ⲁⲩⲱ ⲛϥⲕⲱ ⲛⲥⲱϥ ⲛrow 8..46 ⲉⲧⲉ ⲛⲥⲉϫⲓ ⲙⲙⲟⲟⲩ ⲁⲛ ϩⲙⲡⲉⲓⲧⲟϣ.
.type getHiddenStonePrefixThroughLegacyBuilder,@function
getHiddenStonePrefixThroughLegacyBuilder:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov rdi,280
    call arena_alloc
    mov r12,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r12],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r12+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r12+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r12+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r12+32],rax
    mov r13,2
.Lghsp_loop:
    cmp r13,8
    jae .Lghsp_ok
    mov rax,r13
    sub rax,2
    imul rax,40
    lea r14,[r12+rax]
    mov rdi,r14
    mov rsi,r13
    call stonePatch
    test rax,rax
    je .Lghsp_fail
    mov r15,rax
    mov rax,r13
    dec rax
    imul rax,40
    lea r14,[r12+rax]
    mov rax,qword ptr [r15]
    mov qword ptr [r14],rax
    mov rax,qword ptr [r15+8]
    mov qword ptr [r14+8],rax
    mov rax,qword ptr [r15+16]
    mov qword ptr [r14+16],rax
    mov rax,qword ptr [r15+24]
    mov qword ptr [r14+24],rax
    mov rax,qword ptr [r15+32]
    mov qword ptr [r14+32],rax
    inc r13
    jmp .Lghsp_loop
.Lghsp_ok:
    mov rax,r12
    jmp .Lghsp_done
.Lghsp_fail:
    xor eax,eax
.Lghsp_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size getHiddenStonePrefixThroughLegacyBuilder,.-getHiddenStonePrefixThroughLegacyBuilder

# Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡarray ⲛⲛhidden ⲉϥⲥϩⲟⲩⲟⲣⲧ ⲉϥⲟⲩⲱϩ ⲉⲃⲟⲗ ϩⲛ ⲧⲉⲩⲧⲁⲝⲓⲥ ⲛⲟⲩⲱⲧ. Ⲡlegacy ⲇⲉ ⲥϩⲁⲓ ⲙⲡ hidden7 ⲛϣⲟⲣⲡ ⲙⲛ hidden1 ϩⲙⲡϩⲁⲉ.
# Ⲡⲡⲁⲧϣ ⲛStage 11 ⲙⲡϥⲕⲧⲟ ⲙⲡarray. Ⲛϥⲙⲉⲧⲁⲅⲣⲁⲫⲉ ⲙⲙⲁⲧⲉ ⲙⲡk ⲉⲡposition 8-k, ⲉⲣⲉ ⲡstorage ⲛⲥⲁϩⲟⲩ ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ.
.type makeHiddenLegacyStoredValue,@function
makeHiddenLegacyStoredValue:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Lmhlv_fail
    test r13,r13
    je .Lmhlv_fail
    cmp r14,1
    jb .Lmhlv_fail
    cmp r14,7
    ja .Lmhlv_fail

    mov rdi,qword ptr [r12+HCOUNTS_ACTION]
    call bi_clone
    mov r15,rax

    mov rax,r14
    dec rax
    imul rax,32
    lea rbx,[rip+legacy_hidden_coeff]
    add rbx,rax

    mov rdi,qword ptr [r12+HCOUNTS_TARGET]
    mov rsi,qword ptr [rbx]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rdi,qword ptr [r12+HCOUNTS_DISTANCE]
    mov rsi,qword ptr [rbx+8]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rdi,qword ptr [r12+HCOUNTS_CONNECTION]
    mov rsi,qword ptr [rbx+16]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rdi,qword ptr [r12+HCOUNTS_DIRECTION]
    mov rsi,qword ptr [rbx+24]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rax,r14
    dec rax
    imul rax,40
    lea rbx,[r13+rax]
    xor r14d,r14d
.Lmhlv_stone_sum:
    cmp r14,5
    jae .Lmhlv_first_save
    mov rdi,r15
    mov rsi,qword ptr [rbx+r14*8]
    call bi_add_abs
    mov r15,rax
    inc r14
    jmp .Lmhlv_stone_sum

.Lmhlv_first_save:
    mov rdi,r15
    call savePatch
    mov r15,rax
    mov r14,1
.Lmhlv_grind:
    cmp r14,7
    ja .Lmhlv_ok
    mov rdi,r15
    mov rsi,r15
    call bi_mul_abs
    mov r12,rax
    mov rdi,r15
    mov rsi,3
    call bi_mul_u64
    mov rdi,r12
    mov rsi,rax
    call bi_add_abs
    mov r12,rax
    lea r10,[rip+legacy_hidden_stone_kind]
    mov rax,qword ptr [r10+r14*8-8]
    dec rax
    mov rdi,r12
    mov rsi,qword ptr [rbx+rax*8]
    call bi_add_abs
    mov rdi,rax
    mov rsi,r14
    call bi_add_u64
    mov rdi,rax
    call savePatch
    mov r15,rax
    inc r14
    jmp .Lmhlv_grind
.Lmhlv_ok:
    mov rax,r15
    jmp .Lmhlv_done
.Lmhlv_fail:
    xor eax,eax
.Lmhlv_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size makeHiddenLegacyStoredValue,.-makeHiddenLegacyStoredValue

.type buildHiddenWithBackwardStorage,@function
buildHiddenWithBackwardStorage:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lbhbs_fail
    test r13,r13
    je .Lbhbs_fail
    mov rdi,56
    call arena_alloc
    mov r15,rax
    mov r14,1
.Lbhbs_loop:
    cmp r14,7
    ja .Lbhbs_ok
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call makeHiddenLegacyStoredValue
    test rax,rax
    je .Lbhbs_fail
    mov rdx,7
    sub rdx,r14
    mov qword ptr [r15+rdx*8],rax
    inc r14
    jmp .Lbhbs_loop
.Lbhbs_ok:
    mov rax,r15
    jmp .Lbhbs_done
.Lbhbs_fail:
    xor eax,eax
.Lbhbs_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size buildHiddenWithBackwardStorage,.-buildHiddenWithBackwardStorage

.type legacyHiddenAtNearnessWrong,@function
legacyHiddenAtNearnessWrong:
    test rdi,rdi
    je .Llhaw_fail
    cmp rsi,1
    jb .Llhaw_fail
    cmp rsi,7
    ja .Llhaw_fail
    mov rax,qword ptr [rdi+rsi*8-8]
    ret
.Llhaw_fail:
    xor eax,eax
    ret
.size legacyHiddenAtNearnessWrong,.-legacyHiddenAtNearnessWrong

.type hiddenByNearness,@function
hiddenByNearness:
    test rdi,rdi
    je .Lhbn_fail
    cmp rsi,1
    jb .Lhbn_fail
    cmp rsi,7
    ja .Lhbn_fail
    mov rax,7
    sub rax,rsi
    mov rax,qword ptr [rdi+rax*8]
    ret
.Lhbn_fail:
    xor eax,eax
    ret
.size hiddenByNearness,.-hiddenByNearness

.type monster_stage11_hidden_nearness_patch_wrapper,@function
monster_stage11_hidden_nearness_patch_wrapper:
    jmp hiddenByNearness
.size monster_stage11_hidden_nearness_patch_wrapper,.-monster_stage11_hidden_nearness_patch_wrapper

.type monster_hidden_route,@function
monster_hidden_route:
    jmp monster_stage11_hidden_nearness_patch_wrapper
.size monster_hidden_route,.-monster_hidden_route

.type monster_stage10_legacy_hidden_handler,@function
monster_stage10_legacy_hidden_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms10_fail

    mov rdi,HCOUNTS_SIZE
    call arena_alloc
    mov r13,rax
    mov rax,qword ptr [r12+CTX_PATCHED_DAYTAG_CALC_RESULT]
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r13+HCOUNTS_ACTION],rax
    mov rax,qword ptr [r12+CTX_PATCHED_DAYTAG_TARGET_RESULT]
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r13+HCOUNTS_TARGET],rax
    mov rax,qword ptr [r12+CTX_PATCHED_DISTANCE_RESULT]
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r13+HCOUNTS_DISTANCE],rax

    mov rdi,qword ptr [r13+HCOUNTS_ACTION]
    mov rsi,qword ptr [r13+HCOUNTS_TARGET]
    call bi_add_abs
    mov qword ptr [r13+HCOUNTS_CONNECTION],rax

    mov rax,qword ptr [r12+CTX_TARGET_DAY]
    cmp rax,qword ptr [r12+CTX_CALCULATION_DAY]
    jl .Lms10_dir1
    je .Lms10_dir2
    mov edi,3
    jmp .Lms10_make_dir
.Lms10_dir1:
    mov edi,1
    jmp .Lms10_make_dir
.Lms10_dir2:
    mov edi,2
.Lms10_make_dir:
    call bi_from_u64
    mov qword ptr [r13+HCOUNTS_DIRECTION],rax

    call getHiddenStonePrefixThroughLegacyBuilder
    test rax,rax
    je .Lms10_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Lms10_fail
    mov r15,rax
    mov qword ptr [r12+CTX_HIDDEN_BACKWARD],r15
    inc qword ptr [r12+CTX_LEGACY_HIDDEN_STORAGE_SEEN]
    mov qword ptr [r12+CTX_HIDDEN_QUERY_K],1

    # Ⲡlegacy call ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲛⲟⲩCOPY_DIAGNOSTIC: k=1 ⲙⲟⲩⲧⲉ ⲉhidden7.
    mov rdi,r15
    mov esi,1
    call legacyHiddenAtNearnessWrong
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r12+CTX_LEGACY_HIDDEN_QUERY_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_HIDDEN_QUERY_SEEN]

    # Ⲡroute ⲛⲕⲁⲛⲱⲛ ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡtranslator 8-k, ⲁϫⲛ ⲧⲣⲉϥⲕⲧⲟ ⲙⲡstorage.
    mov rdi,r15
    mov esi,1
    call monster_hidden_route
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r12+CTX_PATCHED_HIDDEN_QUERY_RESULT],rax
    inc qword ptr [r12+CTX_HIDDEN_NEARNESS_PATCH_SEEN]
    mov eax,1
    jmp .Lms10_done
.Lms10_fail:
    xor eax,eax
.Lms10_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage10_legacy_hidden_handler,.-monster_stage10_legacy_hidden_handler


# Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡdropStore ⲙⲁⲩⲁⲁϥ ⲛⲁϣϩⲁⲣⲉϩ ⲉⲡhistory ⲛⲓⲙ.
# Ⲡ legacyPrior ⲇⲉ ϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡslot i-back ϩⲙⲡdropStore; ⲛϥⲥⲟⲟⲩⲛ ⲁⲛ ⲙⲡhidden storage.
.type legacyPrior,@function
legacyPrior:
    test rdi,rdi
    je .Llp_fail
    mov rax,rsi
    sub rax,rdx
    mov rax,qword ptr [rdi+rax*8]
    ret
.Llp_fail:
    xor eax,eax
    ret
.size legacyPrior,.-legacyPrior

.type priorPatch,@function
priorPatch:
    # rdi=dropStore(logical slot 0), rsi=hiddenBackward, rdx=i, rcx=back.
    # Ⲡslot ⲉϥⲟ ⲛ1 ⲏ ⲉϥⲛⲁⲁⲁϥ ϫⲓ ⲙⲡlegacy; ⲡslot ⲛ0 ϣⲁ -6 ϫⲓ ⲙⲡhidden ⲕⲁⲧⲁ k=1-slot.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rax,r14
    sub rax,r15
    cmp rax,1
    jl .Lpp_hidden
    mov rdi,r12
    mov rsi,r14
    mov rdx,r15
    call legacyPrior
    jmp .Lpp_done
.Lpp_hidden:
    mov rcx,1
    sub rcx,rax
    cmp rcx,1
    jb .Lpp_fail
    cmp rcx,7
    ja .Lpp_fail
    mov rdi,r13
    mov rsi,rcx
    call hiddenByNearness
    jmp .Lpp_done
.Lpp_fail:
    xor eax,eax
.Lpp_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size priorPatch,.-priorPatch

.type monster_stage13_prior_patch_wrapper,@function
monster_stage13_prior_patch_wrapper:
    jmp priorPatch
.size monster_stage13_prior_patch_wrapper,.-monster_stage13_prior_patch_wrapper

.type monster_prior_route,@function
monster_prior_route:
    jmp monster_stage13_prior_patch_wrapper
.size monster_prior_route,.-monster_prior_route

.type monster_stage12_legacy_prior_handler,@function
monster_stage12_legacy_prior_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms12_fail
    mov r13,qword ptr [r12+CTX_HIDDEN_BACKWARD]
    test r13,r13
    je .Lms12_fail

    # Ⲡbuffer ⲕⲱ ⲛlogical slot -6..8. Ⲛslot ⲙⲡⲥⲁ ⲛⲥⲁϩⲟⲩ ⲥⲉⲟ ⲛ0, ϫⲉ ⲡlegacy ⲛϥⲥⲟⲟⲩⲛ ⲁⲛ ⲙⲡhidden.
    mov edi,120
    call arena_alloc
    test rax,rax
    je .Lms12_fail
    mov r14,rax
    mov rdi,r14
    xor eax,eax
    mov ecx,15
    rep stosq
    lea r15,[r14+48]
    mov qword ptr [r12+CTX_DROP_STORE],r15

    mov edi,111
    call bi_from_u64
    test rax,rax
    je .Lms12_fail
    mov qword ptr [r15+8],rax

    mov qword ptr [r12+CTX_PRIOR_I],1
    mov qword ptr [r12+CTX_PRIOR_BACK],1

    # COPY_DIAGNOSTIC: slot 0 ⲙⲡdropStore ⲟ ⲛ0, ⲉⲣⲉ hidden1 ϣⲟⲟⲡ ϩⲙⲡstorage ⲉⲧⲕⲟⲟϩ.
    mov rdi,r15
    mov esi,1
    mov edx,1
    call legacyPrior
    mov qword ptr [r12+CTX_LEGACY_PRIOR_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_PRIOR_SEEN]

    # Ⲡroute ⲙⲡDISCOVERY ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡlegacy ⲁϫⲛ ⲟⲩdetour.
    mov rdi,r15
    mov rsi,r13
    mov edx,1
    mov ecx,1
    call monster_prior_route
    mov qword ptr [r12+CTX_PRIOR_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_PATCHED_PRIOR_RESULT],rax
    inc qword ptr [r12+CTX_PRIOR_ROUTE_SEEN]
    inc qword ptr [r12+CTX_PRIOR_PATCH_SEEN]
    mov eax,1
    jmp .Lms12_done
.Lms12_fail:
    xor eax,eax
.Lms12_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage12_legacy_prior_handler,.-monster_stage12_legacy_prior_handler



# Ⲡlegacy indexing ⲙⲡStage 14 ⲟⲩⲏϩ ⲁϫⲛ ⲟⲩϣⲓⲃⲉ: g=1..11 ⲡⲉ ⲡindex ⲛⲧⲟϥ.
# ⲠStage 15 ⲕⲱ ⲙⲡsentinel ⲙⲡindex 0 ⲉϩⲣⲁⲓ ⲙⲙⲁⲧⲉ; ⲉⲧⲃⲉ ⲡⲁⲓ g=1..11 ϫⲓ ⲛ11 ⲛgrind ⲛⲙⲉ ⲁϫⲛ ⲧⲣⲉⲩϥⲱϫⲉ ⲙⲡlegacy loop.
.type grindSentinelRow0,@function
grindSentinelRow0:
    lea rax,[rip+legacy_visible_grinds_indexed]
    ret
.size grindSentinelRow0,.-grindSentinelRow0

.type legacyGrindRowAtIndex,@function
legacyGrindRowAtIndex:
    cmp rdi,1
    jb .Llgrai_fail
    cmp rdi,11
    ja .Llgrai_fail
    lea rax,[rip+legacy_visible_grinds_indexed]
    imul rdi,40
    add rax,rdi
    ret
.Llgrai_fail:
    xor eax,eax
    ret
.size legacyGrindRowAtIndex,.-legacyGrindRowAtIndex

.type oneVisibleDropLegacyGrindIndexWrong,@function
oneVisibleDropLegacyGrindIndexWrong:
    # rdi=counts, rsi=stones, rdx=dropStore, rcx=hiddenBackward, r8=i.
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,56
    mov r12,rdi
    mov r13,rsi
    mov qword ptr [rbp-48],rdx
    mov qword ptr [rbp-56],rcx
    mov qword ptr [rbp-64],r8
    test r12,r12
    je .Lovdli_fail
    test r13,r13
    je .Lovdli_fail
    test rdx,rdx
    je .Lovdli_fail
    test rcx,rcx
    je .Lovdli_fail
    cmp r8,1
    jb .Lovdli_fail
    cmp r8,46
    ja .Lovdli_fail

    # Ⲛpredecessor 1/3/7 ⲛⲏⲩ ϩⲓⲧⲛ priorPatch, ⲉⲧⲣⲉ ⲛhidden scars ⲛϣⲟⲣⲡ ⲟⲩⲱϩ ϩⲙⲡroute.
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    mov rdx,qword ptr [rbp-64]
    mov ecx,1
    call priorPatch
    test rax,rax
    je .Lovdli_fail
    mov qword ptr [rbp-72],rax

    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    mov rdx,qword ptr [rbp-64]
    mov ecx,3
    call priorPatch
    test rax,rax
    je .Lovdli_fail
    mov qword ptr [rbp-80],rax

    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    mov rdx,qword ptr [rbp-64]
    mov ecx,7
    call priorPatch
    test rax,rax
    je .Lovdli_fail
    mov qword ptr [rbp-88],rax

    # Ⲡrow ⲙⲡstone i.
    mov rax,qword ptr [rbp-64]
    dec rax
    imul rax,40
    add r13,rax

    # x = SAVE(w*action + b*target + s*distance + m*connection + r*direction + p1 + 3*p3 + 5*p7 + i)
    mov rdi,qword ptr [r13]
    mov rsi,qword ptr [r12+HCOUNTS_ACTION]
    call bi_mul_abs
    mov rbx,rax

    mov rdi,qword ptr [r13+8]
    mov rsi,qword ptr [r12+HCOUNTS_TARGET]
    call bi_mul_abs
    mov rdi,rbx
    mov rsi,rax
    call bi_add_abs
    mov rbx,rax

    mov rdi,qword ptr [r13+16]
    mov rsi,qword ptr [r12+HCOUNTS_DISTANCE]
    call bi_mul_abs
    mov rdi,rbx
    mov rsi,rax
    call bi_add_abs
    mov rbx,rax

    mov rdi,qword ptr [r13+24]
    mov rsi,qword ptr [r12+HCOUNTS_CONNECTION]
    call bi_mul_abs
    mov rdi,rbx
    mov rsi,rax
    call bi_add_abs
    mov rbx,rax

    mov rdi,qword ptr [r13+32]
    mov rsi,qword ptr [r12+HCOUNTS_DIRECTION]
    call bi_mul_abs
    mov rdi,rbx
    mov rsi,rax
    call bi_add_abs
    mov rbx,rax

    mov rdi,rbx
    mov rsi,qword ptr [rbp-72]
    call bi_add_abs
    mov rbx,rax

    mov rdi,qword ptr [rbp-80]
    mov esi,3
    call bi_mul_u64
    mov rdi,rbx
    mov rsi,rax
    call bi_add_abs
    mov rbx,rax

    mov rdi,qword ptr [rbp-88]
    mov esi,5
    call bi_mul_u64
    mov rdi,rbx
    mov rsi,rax
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [rbp-64]
    call bi_add_u64
    mov rdi,rax
    call savePatch
    mov rbx,rax

    mov r14,1
.Lovdli_grind:
    cmp r14,11
    ja .Lovdli_ok
    mov rdi,r14
    call legacyGrindRowAtIndex
    test rax,rax
    je .Lovdli_fail
    mov r15,rax

    # x' = SAVE(x^2 + a*x + b*p1 + c*p3 + d*p7 + stone[kind]).
    mov rdi,rbx
    mov rsi,rbx
    call bi_mul_abs
    mov qword ptr [rbp-96],rax

    mov rdi,rbx
    mov rsi,qword ptr [r15]
    call bi_mul_u64
    mov rdi,qword ptr [rbp-96]
    mov rsi,rax
    call bi_add_abs
    mov qword ptr [rbp-96],rax

    mov rdi,qword ptr [rbp-72]
    mov rsi,qword ptr [r15+8]
    call bi_mul_u64
    mov rdi,qword ptr [rbp-96]
    mov rsi,rax
    call bi_add_abs
    mov qword ptr [rbp-96],rax

    mov rdi,qword ptr [rbp-80]
    mov rsi,qword ptr [r15+16]
    call bi_mul_u64
    mov rdi,qword ptr [rbp-96]
    mov rsi,rax
    call bi_add_abs
    mov qword ptr [rbp-96],rax

    mov rdi,qword ptr [rbp-88]
    mov rsi,qword ptr [r15+24]
    call bi_mul_u64
    mov rdi,qword ptr [rbp-96]
    mov rsi,rax
    call bi_add_abs
    mov qword ptr [rbp-96],rax

    mov rax,qword ptr [r15+32]
    test rax,rax
    je .Lovdli_no_stone
    dec rax
    mov rdi,qword ptr [rbp-96]
    mov rsi,qword ptr [r13+rax*8]
    call bi_add_abs
    mov qword ptr [rbp-96],rax
.Lovdli_no_stone:
    mov rdi,qword ptr [rbp-96]
    call savePatch
    mov rbx,rax
    inc r14
    jmp .Lovdli_grind

.Lovdli_ok:
    mov rax,rbx
    jmp .Lovdli_done
.Lovdli_fail:
    xor eax,eax
.Lovdli_done:
    add rsp,56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oneVisibleDropLegacyGrindIndexWrong,.-oneVisibleDropLegacyGrindIndexWrong

.type monster_stage15_grind_sentinel_patch_wrapper,@function
monster_stage15_grind_sentinel_patch_wrapper:
    # Ⲡwrapper ⲛStage 15 ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡlegacy loop; ⲡsentinel ϩⲙⲡtable ⲡⲉ ⲡⲡⲁⲧϣ ⲛⲧⲟϥ.
    jmp oneVisibleDropLegacyGrindIndexWrong
.size monster_stage15_grind_sentinel_patch_wrapper,.-monster_stage15_grind_sentinel_patch_wrapper

.type monster_visible_drop_route,@function
monster_visible_drop_route:
    jmp monster_stage15_grind_sentinel_patch_wrapper
.size monster_visible_drop_route,.-monster_visible_drop_route

.type monster_stage14_legacy_grind_handler,@function
monster_stage14_legacy_grind_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    test r12,r12
    je .Lms14_fail
    mov r15,qword ptr [r12+CTX_HIDDEN_BACKWARD]
    test r15,r15
    je .Lms14_fail

    # Ⲧⲁⲙⲓⲟ ⲛⲕⲉⲥⲟⲡ ⲙⲡcounts ⲛⲧⲉⲡinvocation; ⲡobservability ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡⲗⲟⲅⲓⲥⲙⲟⲥ.
    mov edi,HCOUNTS_SIZE
    call arena_alloc
    test rax,rax
    je .Lms14_fail
    mov r13,rax
    mov rax,qword ptr [r12+CTX_PATCHED_DAYTAG_CALC_RESULT]
    test rax,rax
    je .Lms14_fail
    mov qword ptr [r13+HCOUNTS_ACTION],rax
    mov rax,qword ptr [r12+CTX_PATCHED_DAYTAG_TARGET_RESULT]
    test rax,rax
    je .Lms14_fail
    mov qword ptr [r13+HCOUNTS_TARGET],rax
    mov rax,qword ptr [r12+CTX_PATCHED_DISTANCE_RESULT]
    test rax,rax
    je .Lms14_fail
    mov qword ptr [r13+HCOUNTS_DISTANCE],rax
    mov rdi,qword ptr [r13+HCOUNTS_ACTION]
    mov rsi,qword ptr [r13+HCOUNTS_TARGET]
    call bi_add_abs
    mov qword ptr [r13+HCOUNTS_CONNECTION],rax
    mov rax,qword ptr [r12+CTX_TARGET_DAY]
    cmp rax,qword ptr [r12+CTX_CALCULATION_DAY]
    jl .Lms14_dir1
    je .Lms14_dir2
    mov edi,3
    jmp .Lms14_make_dir
.Lms14_dir1:
    mov edi,1
    jmp .Lms14_make_dir
.Lms14_dir2:
    mov edi,2
.Lms14_make_dir:
    call bi_from_u64
    mov qword ptr [r13+HCOUNTS_DIRECTION],rax

    call getHiddenStonePrefixThroughLegacyBuilder
    test rax,rax
    je .Lms14_fail
    mov r14,rax

    # ⲠdropStore ⲛⲧⲉ i=1 ⲙⲛ ⲛslot -6..8; ⲡpriorPatch ϫⲓ ⲙⲡhidden ϩⲛ ⲛslot ⲛⲥⲁϩⲟⲩ.
    mov edi,120
    call arena_alloc
    test rax,rax
    je .Lms14_fail
    mov qword ptr [rbp-48],rax
    mov rdi,rax
    xor eax,eax
    mov ecx,15
    rep stosq
    mov rax,qword ptr [rbp-48]
    add rax,48
    mov qword ptr [rbp-56],rax

    mov qword ptr [r12+CTX_VISIBLE_DROP_I],1
    mov edi,1
    call legacyGrindRowAtIndex
    test rax,rax
    je .Lms14_fail
    mov qword ptr [r12+CTX_LEGACY_GRIND_ROW1],rax
    inc qword ptr [r12+CTX_LEGACY_GRIND_TABLE_SEEN]

    # COPY_DIAGNOSTIC ⲙⲛ route ⲥⲉϫⲓ ⲙⲡlegacy indexing ⲛⲟⲩⲱⲧ; ⲡsentinel ⲛStage 15 ⲕⲱ ⲙⲡindex 0 ⲉϩⲣⲁⲓ ⲉⲧⲣⲉⲡⲉⲓindexing ⲟ ⲛⲧⲟϣ.
    mov rdi,r13
    mov rsi,r14
    mov rdx,qword ptr [rbp-56]
    mov rcx,r15
    mov r8d,1
    call oneVisibleDropLegacyGrindIndexWrong
    test rax,rax
    je .Lms14_fail
    mov qword ptr [r12+CTX_LEGACY_VISIBLE_DROP_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_VISIBLE_DROP_SEEN]

    mov rdi,r13
    mov rsi,r14
    mov rdx,qword ptr [rbp-56]
    mov rcx,r15
    mov r8d,1
    call monster_visible_drop_route
    test rax,rax
    je .Lms14_fail
    mov qword ptr [r12+CTX_VISIBLE_DROP_ROUTE_RESULT],rax
    inc qword ptr [r12+CTX_GRIND_SENTINEL_PATCH_SEEN]
    mov eax,1
    jmp .Lms14_done
.Lms14_fail:
    xor eax,eax
.Lms14_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage14_legacy_grind_handler,.-monster_stage14_legacy_grind_handler


# Ⲃⲁⲑⲙⲟⲥ 16 — DISCOVERY 08
# Ⲡlegacy ⲡⲁⲓ ⲥⲟⲟⲩⲛ ⲙⲙⲁⲧⲉ ⲛⲟⲩrank ⲉϥⲁⲣⲭⲉⲓ ϩⲓ 0. Ⲛϥϫⲓ 0..719 ⲁⲩⲱ ⲛϥⲕⲱ ⲉⲃⲟⲗ ⲙⲡpermutation ⲕⲁⲧⲁ factoradic.
# Ⲙⲛ ⲡⲁⲧϣ ⲛdrop-1 ⲉϥϣⲟⲟⲡ ⲉⲧⲓ. Ⲡcaller ⲛⲗⲉⲅⲁⲥⲓ ⲗⲟⲅⲓⲍⲉ ⲙⲡregular remainder ⲙⲡdrop ϩⲓ 720 ⲁⲩⲱ ⲛϥϫⲟⲟⲩϥ ⲛⲟⲩrank0.
.type oldPermutationUnrank0,@function
oldPermutationUnrank0:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,56
    mov r12,rdi
    mov r13,rsi
    test r13,r13
    je .Lopu0_fail
    cmp r12,719
    ja .Lopu0_fail

    lea r8,[rbp-88]
    mov qword ptr [r8],1
    mov qword ptr [r8+8],2
    mov qword ptr [r8+16],3
    mov qword ptr [r8+24],4
    mov qword ptr [r8+32],5
    mov qword ptr [r8+40],6
    mov r14,6
    xor r15d,r15d
.Lopu0_slot:
    test r14,r14
    je .Lopu0_ok
    lea r9,[rip+legacy_factorial_0_5]
    mov rax,r14
    dec rax
    mov rbx,qword ptr [r9+rax*8]
    mov rax,r12
    xor edx,edx
    div rbx
    mov r12,rdx
    mov rcx,rax
    mov rax,qword ptr [r8+rcx*8]
    mov qword ptr [r13+r15*8],rax

    mov rdx,rcx
.Lopu0_remove:
    lea rax,[rdx+1]
    cmp rax,r14
    jae .Lopu0_removed
    mov rbx,qword ptr [r8+rax*8]
    mov qword ptr [r8+rdx*8],rbx
    inc rdx
    jmp .Lopu0_remove
.Lopu0_removed:
    dec r14
    inc r15
    jmp .Lopu0_slot
.Lopu0_ok:
    mov eax,1
    jmp .Lopu0_done
.Lopu0_fail:
    xor eax,eax
.Lopu0_done:
    add rsp,56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oldPermutationUnrank0,.-oldPermutationUnrank0

.type legacyPermutationRank0FromDropWrong,@function
legacyPermutationRank0FromDropWrong:
    # Ⲡⲡⲗⲁⲛⲏ: ⲡdrop ⲛⲧⲟϥ ⲡⲉ ⲡsource ⲙⲡrank0; ⲙⲛ ⲡ`drop-1` ⲉϥⲥⲏϩ ⲙⲡⲉⲓStage.
    mov rsi,720
    call bi_divmod_u64_abs
    mov rax,rdx
    ret
.size legacyPermutationRank0FromDropWrong,.-legacyPermutationRank0FromDropWrong

.type legacyPermutationOrderFromDropWrong,@function
legacyPermutationOrderFromDropWrong:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rsi
    test rdi,rdi
    je .Llpofdw_fail
    test r12,r12
    je .Llpofdw_fail
    call legacyPermutationRank0FromDropWrong
    mov rdi,rax
    mov rsi,r12
    call oldPermutationUnrank0
    test eax,eax
    je .Llpofdw_fail
    mov rax,r12
    jmp .Llpofdw_done
.Llpofdw_fail:
    xor eax,eax
.Llpofdw_done:
    pop r12
    leave
    ret
.size legacyPermutationOrderFromDropWrong,.-legacyPermutationOrderFromDropWrong

# Ⲃⲁⲑⲙⲟⲥ 17 — PATCH 08
# Ⲡcaller ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡStage 16 ⲟⲩⲏϩ ⲁϫⲛ ⲟⲩϣⲓⲃⲉ ⲁⲩⲱ ⲡhandler ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩCOPY_DIAGNOSTIC.
# Ⲡⲡⲁⲧϣ ⲡⲁⲓ ⲕⲱ ⲉϩⲣⲁⲓ ⲛⲧⲉⲓchain ⲛⲧⲟϣ: oneBased=regularMod(drop-1,720)+1; legacyRank0=oneBased-1.
.type permutationOneBasedFromDropPatch08,@function
permutationOneBasedFromDropPatch08:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lpobfdp08_fail

    mov edi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,r12
    call bi_sub
    mov r13,rax
    test r13,r13
    je .Lpobfdp08_fail

    mov r14,qword ptr [r13+BI_SIGN]
    mov rdi,r13
    mov rsi,720
    call bi_divmod_u64_abs
    mov rax,rdx
    test r14,r14
    jge .Lpobfdp08_mod_done
    test rax,rax
    je .Lpobfdp08_mod_done
    mov rcx,720
    sub rcx,rax
    mov rax,rcx
.Lpobfdp08_mod_done:
    inc rax
    jmp .Lpobfdp08_done
.Lpobfdp08_fail:
    xor eax,eax
.Lpobfdp08_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size permutationOneBasedFromDropPatch08,.-permutationOneBasedFromDropPatch08

.type orderPatchFromValue,@function
orderPatchFromValue:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rsi
    test rdi,rdi
    je .Lopfv_fail
    test r12,r12
    je .Lopfv_fail

    # Ⲡ`+1` ⲙⲡoneBased ⲟⲩⲏϩ ⲉϥⲟⲩⲟⲛϩ; ⲙⲡⲟⲩⲥⲉⲕ ⲙⲡchain ⲉⲟⲩrank0 ⲛⲟⲩcall ⲛⲟⲩⲱⲧ.
    call permutationOneBasedFromDropPatch08
    test rax,rax
    je .Lopfv_fail
    mov r13,rax
    dec r13
    mov rdi,r13
    mov rsi,r12
    call oldPermutationUnrank0
    test eax,eax
    je .Lopfv_fail
    mov rax,r12
    jmp .Lopfv_done
.Lopfv_fail:
    xor eax,eax
.Lopfv_done:
    pop r13
    pop r12
    leave
    ret
.size orderPatchFromValue,.-orderPatchFromValue

.type monster_stage17_permutation_patch_wrapper,@function
monster_stage17_permutation_patch_wrapper:
    jmp orderPatchFromValue
.size monster_stage17_permutation_patch_wrapper,.-monster_stage17_permutation_patch_wrapper

.type monster_permutation_route,@function
monster_permutation_route:
    jmp monster_stage17_permutation_patch_wrapper
.size monster_permutation_route,.-monster_permutation_route

.type monster_stage16_legacy_permutation_handler,@function
monster_stage16_legacy_permutation_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms16_fail

    mov r13,qword ptr [r12+CTX_VISIBLE_DROP_ROUTE_RESULT]
    test r13,r13
    je .Lms16_fail
    mov qword ptr [r12+CTX_LEGACY_PERMUTATION_DROP],r13

    mov rdi,r13
    call legacyPermutationRank0FromDropWrong
    mov qword ptr [r12+CTX_LEGACY_PERMUTATION_RANK0],rax

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms16_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call legacyPermutationOrderFromDropWrong
    test rax,rax
    je .Lms16_fail
    mov qword ptr [r12+CTX_LEGACY_PERMUTATION_ORDER],r14
    inc qword ptr [r12+CTX_LEGACY_PERMUTATION_SEEN]

    mov rdi,r13
    call permutationOneBasedFromDropPatch08
    test rax,rax
    je .Lms16_fail
    mov qword ptr [r12+CTX_PATCHED_PERMUTATION_ONE_BASED],rax
    mov rcx,rax
    dec rcx
    mov qword ptr [r12+CTX_PATCHED_PERMUTATION_RANK0],rcx

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms16_fail
    mov r15,rax
    mov rdi,r13
    mov rsi,r15
    call monster_permutation_route
    test rax,rax
    je .Lms16_fail
    mov qword ptr [r12+CTX_PERMUTATION_ROUTE_ORDER],r15
    mov qword ptr [r12+CTX_PATCHED_PERMUTATION_ORDER],r15
    inc qword ptr [r12+CTX_PERMUTATION_ROUTE_SEEN]
    inc qword ptr [r12+CTX_PERMUTATION_PATCH_SEEN]

    mov eax,1
    jmp .Lms16_done
.Lms16_fail:
    xor eax,eax
.Lms16_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage16_legacy_permutation_handler,.-monster_stage16_legacy_permutation_handler


# Ⲃⲁⲑⲙⲟⲥ 18 — DISCOVERY 09
# Ⲡlegacy ⲥⲟⲟⲩⲛ ⲙⲡorder ⲛⲧⲟϣ, ⲁⲗⲗⲁ ϩⲛ ⲛ3 ⲛpour ⲛϣⲟⲣⲡ ⲛϥⲟⲩⲏϩ ⲉϥϫⲓ ⲛbowl ID 1,2,3 ⲛⲧⲟⲩⲱⲧ.
# Ⲡpositions ⲛⲗⲉⲅⲁⲥⲓ ⲁⲩⲕⲁⲁⲩ ⲛbowl IDs ⲛⲥⲁϣϥ. Ⲙⲛ ⲟⲩdetour ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ.
.type legacyPoursToFixedBowlIds,@function
legacyPoursToFixedBowlIds:
    # Ⲛargument ⲛⲉ rdi=drop, rsi=i, rdx=oldBowls[6], rcx=stoneRow[5], r8=orderOut[6], r9=poursOut[3].
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    mov qword ptr [rbp-56],r9
    test r12,r12
    je .Llptfbi_fail
    test r14,r14
    je .Llptfbi_fail
    test r15,r15
    je .Llptfbi_fail
    test r8,r8
    je .Llptfbi_fail
    test r9,r9
    je .Llptfbi_fail

    mov rdi,r12
    mov rsi,qword ptr [rbp-48]
    call orderPatchFromValue
    test rax,rax
    je .Llptfbi_fail

    xor ebx,ebx
.Llptfbi_loop:
    cmp rbx,3
    jae .Llptfbi_ok

    # Ⲡdrop².
    mov rdi,r12
    mov rsi,r12
    call bi_mul_abs
    test rax,rax
    je .Llptfbi_fail
    mov qword ptr [rbp-64],rax

    # Ⲡⲡⲗⲁⲛⲏ ⲛⲗⲉⲅⲁⲥⲓ: oldBowls[position] ⲛⲧⲟϥ, ⲙⲡⲉϥϫⲓ oldBowls[order[position]].
    mov rdi,qword ptr [r15+rbx*8]
    mov rsi,qword ptr [r14+rbx*8]
    call bi_mul_abs
    test rax,rax
    je .Llptfbi_fail
    mov rsi,rax
    mov rdi,qword ptr [rbp-64]
    call bi_add_abs
    test rax,rax
    je .Llptfbi_fail

    lea rcx,[rip+legacy_pour_factor]
    mov rcx,qword ptr [rcx+rbx*8]
    imul rcx,r13
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    test rax,rax
    je .Llptfbi_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Llptfbi_fail
    mov rdx,qword ptr [rbp-56]
    mov qword ptr [rdx+rbx*8],rax

    inc rbx
    jmp .Llptfbi_loop

.Llptfbi_ok:
    mov rax,qword ptr [rbp-56]
    jmp .Llptfbi_done
.Llptfbi_fail:
    xor eax,eax
.Llptfbi_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size legacyPoursToFixedBowlIds,.-legacyPoursToFixedBowlIds


# Ⲃⲁⲑⲙⲟⲥ 19 — PATCH 09
# Ⲡlegacy ⲛfixed bowls ⲟⲩⲏϩ ⲁϫⲛ ⲟⲩϣⲓⲃⲉ. Ⲡⲡⲁⲧϣ ⲧⲁⲙⲓⲟ ⲛⲟⲩalias ⲉϥⲙⲁⲡⲡⲉ ⲙⲡposition ⲉⲡbowl ID ⲕⲁⲧⲁ ⲡorder.
.type installOrderAliases,@function
installOrderAliases:
    # rdi=order[6], rsi=alias[6].
    test rdi,rdi
    je .Lioa_fail
    test rsi,rsi
    je .Lioa_fail
    xor ecx,ecx
    xor r8d,r8d
.Lioa_loop:
    cmp rcx,6
    jae .Lioa_mask
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,1
    jb .Lioa_fail
    cmp rax,6
    ja .Lioa_fail
    mov rdx,rax
    dec rdx
    bt r8,rdx
    jc .Lioa_fail
    bts r8,rdx
    mov qword ptr [rsi+rcx*8],rax
    inc rcx
    jmp .Lioa_loop
.Lioa_mask:
    cmp r8,0x3f
    jne .Lioa_fail
    mov rax,rsi
    ret
.Lioa_fail:
    xor eax,eax
    ret
.size installOrderAliases,.-installOrderAliases

.type bowlByLegacyPosition,@function
bowlByLegacyPosition:
    # rdi=oldBowls[6], rsi=alias[6], rdx=position 1..6.
    test rdi,rdi
    je .Lbblp_fail
    test rsi,rsi
    je .Lbblp_fail
    cmp rdx,1
    jb .Lbblp_fail
    cmp rdx,6
    ja .Lbblp_fail
    mov rcx,rdx
    dec rcx
    mov rax,qword ptr [rsi+rcx*8]
    cmp rax,1
    jb .Lbblp_fail
    cmp rax,6
    ja .Lbblp_fail
    dec rax
    mov rax,qword ptr [rdi+rax*8]
    test rax,rax
    je .Lbblp_fail
    ret
.Lbblp_fail:
    xor eax,eax
    ret
.size bowlByLegacyPosition,.-bowlByLegacyPosition

.type patchedPours,@function
patchedPours:
    # rdi=drop, rsi=i, rdx=oldBowls[6], rcx=stoneRow[5], r8=orderOut[6], r9=poursOut[3].
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,72
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    mov qword ptr [rbp-56],r9
    test r12,r12
    je .Lpp09_fail
    test r14,r14
    je .Lpp09_fail
    test r15,r15
    je .Lpp09_fail
    test r8,r8
    je .Lpp09_fail
    test r9,r9
    je .Lpp09_fail

    mov rdi,r12
    mov rsi,qword ptr [rbp-48]
    call orderPatchFromValue
    test rax,rax
    je .Lpp09_fail

    mov rdi,qword ptr [rbp-48]
    lea rsi,[rbp-112]
    call installOrderAliases
    test rax,rax
    je .Lpp09_fail

    xor ebx,ebx
.Lpp09_loop:
    cmp rbx,3
    jae .Lpp09_ok

    mov rdi,r12
    mov rsi,r12
    call bi_mul_abs
    test rax,rax
    je .Lpp09_fail
    mov qword ptr [rbp-64],rax

    mov rdi,r14
    lea rsi,[rbp-112]
    lea rdx,[rbx+1]
    call bowlByLegacyPosition
    test rax,rax
    je .Lpp09_fail
    mov rsi,rax
    mov rdi,qword ptr [r15+rbx*8]
    call bi_mul_abs
    test rax,rax
    je .Lpp09_fail

    mov rsi,rax
    mov rdi,qword ptr [rbp-64]
    call bi_add_abs
    test rax,rax
    je .Lpp09_fail

    lea rcx,[rip+legacy_pour_factor]
    mov rcx,qword ptr [rcx+rbx*8]
    imul rcx,r13
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    test rax,rax
    je .Lpp09_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Lpp09_fail
    mov rdx,qword ptr [rbp-56]
    mov qword ptr [rdx+rbx*8],rax

    inc rbx
    jmp .Lpp09_loop

.Lpp09_ok:
    mov rax,qword ptr [rbp-56]
    jmp .Lpp09_done
.Lpp09_fail:
    xor eax,eax
.Lpp09_done:
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size patchedPours,.-patchedPours

.type monster_stage19_bowl_alias_patch_wrapper,@function
monster_stage19_bowl_alias_patch_wrapper:
    jmp patchedPours
.size monster_stage19_bowl_alias_patch_wrapper,.-monster_stage19_bowl_alias_patch_wrapper

.type monster_pour_route,@function
monster_pour_route:
    jmp monster_stage19_bowl_alias_patch_wrapper
.size monster_pour_route,.-monster_pour_route

.type monster_stage18_legacy_fixed_pour_handler,@function
monster_stage18_legacy_fixed_pour_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    test r12,r12
    je .Lms18_fail

    mov r13,qword ptr [r12+CTX_VISIBLE_DROP_ROUTE_RESULT]
    test r13,r13
    je .Lms18_fail
    mov qword ptr [r12+CTX_LEGACY_POUR_DROP],r13
    mov rax,qword ptr [r12+CTX_VISIBLE_DROP_I]
    test rax,rax
    jne .Lms18_have_i
    mov eax,1
.Lms18_have_i:
    mov qword ptr [r12+CTX_LEGACY_POUR_I],rax

    # Ⲛold bowls ⲛⲇⲓⲁⲅⲛⲱⲥⲧⲓⲕⲟⲛ ⲥⲉϣⲟⲃⲉ ⲉⲧⲣⲉⲡID ⲛbowl ⲟⲩⲱⲛϩ ⲉⲃⲟⲗ.
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms18_fail
    mov r14,rax
    mov edi,11
    call bi_from_u64
    mov qword ptr [r14],rax
    mov edi,13
    call bi_from_u64
    mov qword ptr [r14+8],rax
    mov edi,17
    call bi_from_u64
    mov qword ptr [r14+16],rax
    mov edi,19
    call bi_from_u64
    mov qword ptr [r14+24],rax
    mov edi,23
    call bi_from_u64
    mov qword ptr [r14+32],rax
    mov edi,29
    call bi_from_u64
    mov qword ptr [r14+40],rax
    mov qword ptr [r12+CTX_LEGACY_POUR_OLD_BOWLS],r14

    mov r15,qword ptr [r12+CTX_PATCHED_STONE_ROW]
    test r15,r15
    je .Lms18_fail
    mov qword ptr [r12+CTX_LEGACY_POUR_STONE_ROW],r15
    lea rax,[rip+legacy_fixed_pour_ids]
    mov qword ptr [r12+CTX_LEGACY_POUR_FIXED_IDS],rax

    mov edi,72
    call arena_alloc
    test rax,rax
    je .Lms18_fail
    mov qword ptr [rbp-48],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-56],rcx

    mov rdi,r13
    mov rsi,qword ptr [r12+CTX_LEGACY_POUR_I]
    mov rdx,r14
    mov rcx,r15
    mov r8,qword ptr [rbp-48]
    mov r9,qword ptr [rbp-56]
    call legacyPoursToFixedBowlIds
    test rax,rax
    je .Lms18_fail
    mov rax,qword ptr [rbp-48]
    mov qword ptr [r12+CTX_LEGACY_POUR_ORDER],rax
    mov qword ptr [r12+CTX_LEGACY_POUR_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_POUR_SEEN]

    mov edi,72
    call arena_alloc
    test rax,rax
    je .Lms18_fail
    mov qword ptr [rbp-48],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-56],rcx
    mov rdi,r13
    mov rsi,qword ptr [r12+CTX_LEGACY_POUR_I]
    mov rdx,r14
    mov rcx,r15
    mov r8,qword ptr [rbp-48]
    mov r9,qword ptr [rbp-56]
    call monster_pour_route
    test rax,rax
    je .Lms18_fail
    mov qword ptr [r12+CTX_POUR_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_PATCHED_POUR_RESULT],rax
    mov rax,qword ptr [rbp-48]
    mov qword ptr [r12+CTX_PATCHED_POUR_ORDER],rax
    inc qword ptr [r12+CTX_POUR_ROUTE_SEEN]

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms18_fail
    mov r13,rax
    mov rdi,qword ptr [rbp-48]
    mov rsi,r13
    call installOrderAliases
    test rax,rax
    je .Lms18_fail
    mov qword ptr [r12+CTX_BOWL_ALIAS],r13
    inc qword ptr [r12+CTX_BOWL_ALIAS_PATCH_SEEN]

    mov eax,1
    jmp .Lms18_done
.Lms18_fail:
    xor eax,eax
.Lms18_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage18_legacy_fixed_pour_handler,.-monster_stage18_legacy_fixed_pour_handler


# Ⲃⲁⲑⲙⲟⲥ 20 — DISCOVERY 10
# Ⲡlegacy ⲥϩⲁⲓ ⲛⲧⲉⲩⲛⲟⲩ ⲉϩⲟⲩⲛ ⲉⲡB ⲛⲟⲩⲱⲧ.
# Ⲡposition ⲉⲧⲛⲏⲩ ⲙⲙⲛⲛⲥⲱϥ ϣϭⲙϭⲟⲙ ⲉϫⲓ ⲙⲡⲉⲧϩⲁⲧⲏϥ ⲉⲁⲩϣⲓⲃⲉ ⲙⲙⲟϥ.
# Ⲙⲛ ⲟⲩⲥⲟⲧⲡ ⲛϣⲟⲣⲡ ⲉϥⲧⲟϣ ⲛⲛread ⲧⲏⲣⲟⲩ ϩⲙⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ.
.type legacyStirOneDropInPlace,@function
legacyStirOneDropInPlace:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,88
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    mov qword ptr [rbp-56],r9
    test r12,r12
    je .Llso_fail
    test r14,r14
    je .Llso_fail
    test r15,r15
    je .Llso_fail
    test r8,r8
    je .Llso_fail
    test r9,r9
    je .Llso_fail
    xor ebx,ebx

.Llso_loop:
    cmp rbx,6
    jae .Llso_ok
    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rbx*8]
    test rax,rax
    je .Llso_fail
    cmp rax,6
    ja .Llso_fail
    mov qword ptr [rbp-64],rax

    mov rcx,rbx
    add rcx,5
    cmp rcx,6
    jb .Llso_prev_ready
    sub rcx,6
.Llso_prev_ready:
    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rcx*8]
    test rax,rax
    je .Llso_fail
    cmp rax,6
    ja .Llso_fail
    mov qword ptr [rbp-72],rax

    mov rcx,rbx
    inc rcx
    cmp rcx,6
    jb .Llso_next_ready
    xor ecx,ecx
.Llso_next_ready:
    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rcx*8]
    test rax,rax
    je .Llso_fail
    cmp rax,6
    ja .Llso_fail
    mov qword ptr [rbp-80],rax

    mov rax,qword ptr [rbp-64]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    test rdi,rdi
    je .Llso_fail
    call bi_clone
    test rax,rax
    je .Llso_fail
    mov qword ptr [rbp-88],rax

    mov rax,qword ptr [rbp-72]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,2
    call bi_mul_u64
    test rax,rax
    je .Llso_fail
    mov rdi,qword ptr [rbp-88]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Llso_fail
    mov qword ptr [rbp-88],rax

    mov rax,qword ptr [rbp-80]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,3
    call bi_mul_u64
    test rax,rax
    je .Llso_fail
    mov rdi,qword ptr [rbp-88]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Llso_fail
    mov qword ptr [rbp-88],rax

    cmp rbx,3
    jae .Llso_no_pour
    mov rax,qword ptr [rbp-56]
    mov rsi,qword ptr [rax+rbx*8]
    test rsi,rsi
    je .Llso_fail
    mov rdi,qword ptr [rbp-88]
    call bi_add_abs
    test rax,rax
    je .Llso_fail
    mov qword ptr [rbp-88],rax
.Llso_no_pour:

    mov rdi,qword ptr [rbp-88]
    mov rsi,r14
    call bi_add_abs
    test rax,rax
    je .Llso_fail
    mov qword ptr [rbp-88],rax

    lea rax,[rip+legacy_bowl_stir_stone_by_position]
    mov rcx,qword ptr [rax+rbx*8]
    mov rsi,qword ptr [r15+rcx*8]
    test rsi,rsi
    je .Llso_fail
    mov rdi,qword ptr [rbp-88]
    call bi_add_abs
    test rax,rax
    je .Llso_fail
    mov qword ptr [rbp-88],rax

    mov rdi,qword ptr [rbp-88]
    mov rsi,rdi
    call bi_mul_abs
    test rax,rax
    je .Llso_fail
    mov qword ptr [rbp-96],rax

    mov rax,qword ptr [rbp-72]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov rax,qword ptr [rbp-80]
    dec rax
    mov rsi,qword ptr [r12+rax*8]
    call bi_mul_abs
    test rax,rax
    je .Llso_fail
    mov rdi,rax
    mov esi,5
    call bi_mul_u64
    test rax,rax
    je .Llso_fail
    mov rdi,qword ptr [rbp-96]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Llso_fail

    mov rcx,rbx
    inc rcx
    imul rcx,r13
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    test rax,rax
    je .Llso_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Llso_fail

    mov rcx,qword ptr [rbp-64]
    dec rcx
    mov qword ptr [r12+rcx*8],rax     # Ⲁⲩⲥϩⲁⲓ ⲉⲡB ⲛⲟⲩⲱⲧ.
    inc rbx
    jmp .Llso_loop

.Llso_ok:
    mov rax,r12
    jmp .Llso_done
.Llso_fail:
    xor eax,eax
.Llso_done:
    add rsp,88
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size legacyStirOneDropInPlace,.-legacyStirOneDropInPlace

# Ⲃⲁⲑⲙⲟⲥ 21 — PATCH 10
# Ⲡlegacy ⲟⲩⲏϩ ⲁϫⲛ ⲟⲩϣⲓⲃⲉ ⲁⲩⲱ ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ϩⲓ clone ⲉϥϣⲟⲃⲉ.
# ⲠvaultOld ⲡⲉ ⲡsnapshot ⲛⲟⲩⲱⲧ ⲛⲧⲉ ⲛ6 ⲛbowl. Ⲛread ⲧⲏⲣⲟⲩ ⲛⲁⲩⲛⲏⲩ ⲉⲃⲟⲗ ϩⲓⲱⲱϥ.
# Ⲛwrite ⲧⲏⲣⲟⲩ ⲃⲱⲕ ⲉpending; ⲡcommit ⲟⲩⲱⲛϩ ⲙⲙⲁⲧⲉ ⲙⲛⲛⲥⲁ ⲛ6 ⲛposition.
.type stirOneDropViaShadow,@function
stirOneDropViaShadow:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,120
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    mov qword ptr [rbp-56],r9
    test r12,r12
    je .Lsodvs_fail
    test r14,r14
    je .Lsodvs_fail
    test r15,r15
    je .Lsodvs_fail
    test r8,r8
    je .Lsodvs_fail
    test r9,r9
    je .Lsodvs_fail

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-64],rax
    xor ecx,ecx
.Lsodvs_legacy_clone:
    cmp rcx,6
    jae .Lsodvs_legacy_call
    mov rdx,qword ptr [r12+rcx*8]
    test rdx,rdx
    je .Lsodvs_fail
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lsodvs_legacy_clone
.Lsodvs_legacy_call:
    mov rdi,qword ptr [rbp-64]
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    mov r8,qword ptr [rbp-48]
    mov r9,qword ptr [rbp-56]
    call legacyStirOneDropInPlace
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-88],rax

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-72],rax
    xor ecx,ecx
.Lsodvs_vault_clone:
    cmp rcx,6
    jae .Lsodvs_pending_make
    mov rdx,qword ptr [r12+rcx*8]
    test rdx,rdx
    je .Lsodvs_fail
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lsodvs_vault_clone

.Lsodvs_pending_make:
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-80],rax
    mov rdi,rax
    xor eax,eax
    mov ecx,6
    rep stosq
    xor ebx,ebx

.Lsodvs_loop:
    cmp rbx,6
    jae .Lsodvs_validate_pending

    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rbx*8]
    test rax,rax
    je .Lsodvs_fail
    cmp rax,6
    ja .Lsodvs_fail
    mov qword ptr [rbp-96],rax

    mov rcx,rbx
    add rcx,5
    cmp rcx,6
    jb .Lsodvs_prev_ready
    sub rcx,6
.Lsodvs_prev_ready:
    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rcx*8]
    test rax,rax
    je .Lsodvs_fail
    cmp rax,6
    ja .Lsodvs_fail
    mov qword ptr [rbp-104],rax

    mov rcx,rbx
    inc rcx
    cmp rcx,6
    jb .Lsodvs_next_ready
    xor ecx,ecx
.Lsodvs_next_ready:
    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rcx*8]
    test rax,rax
    je .Lsodvs_fail
    cmp rax,6
    ja .Lsodvs_fail
    mov qword ptr [rbp-112],rax

    mov rax,qword ptr [rbp-96]
    dec rax
    mov rdx,qword ptr [rbp-72]
    mov rdi,qword ptr [rdx+rax*8]
    call bi_clone
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-120],rax

    mov rax,qword ptr [rbp-104]
    dec rax
    mov rdx,qword ptr [rbp-72]
    mov rdi,qword ptr [rdx+rax*8]
    mov esi,2
    call bi_mul_u64
    test rax,rax
    je .Lsodvs_fail
    mov rdi,qword ptr [rbp-120]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-120],rax

    mov rax,qword ptr [rbp-112]
    dec rax
    mov rdx,qword ptr [rbp-72]
    mov rdi,qword ptr [rdx+rax*8]
    mov esi,3
    call bi_mul_u64
    test rax,rax
    je .Lsodvs_fail
    mov rdi,qword ptr [rbp-120]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-120],rax

    cmp rbx,3
    jae .Lsodvs_no_pour
    mov rax,qword ptr [rbp-56]
    mov rsi,qword ptr [rax+rbx*8]
    test rsi,rsi
    je .Lsodvs_fail
    mov rdi,qword ptr [rbp-120]
    call bi_add_abs
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-120],rax
.Lsodvs_no_pour:

    mov rdi,qword ptr [rbp-120]
    mov rsi,r14
    call bi_add_abs
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-120],rax

    lea rax,[rip+legacy_bowl_stir_stone_by_position]
    mov rcx,qword ptr [rax+rbx*8]
    mov rsi,qword ptr [r15+rcx*8]
    test rsi,rsi
    je .Lsodvs_fail
    mov rdi,qword ptr [rbp-120]
    call bi_add_abs
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-120],rax

    mov rdi,qword ptr [rbp-120]
    mov rsi,rdi
    call bi_mul_abs
    test rax,rax
    je .Lsodvs_fail
    mov qword ptr [rbp-128],rax

    mov rax,qword ptr [rbp-104]
    dec rax
    mov rdx,qword ptr [rbp-72]
    mov rdi,qword ptr [rdx+rax*8]
    mov rax,qword ptr [rbp-112]
    dec rax
    mov rdx,qword ptr [rbp-72]
    mov rsi,qword ptr [rdx+rax*8]
    call bi_mul_abs
    test rax,rax
    je .Lsodvs_fail
    mov rdi,rax
    mov esi,5
    call bi_mul_u64
    test rax,rax
    je .Lsodvs_fail
    mov rdi,qword ptr [rbp-128]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Lsodvs_fail

    mov rcx,rbx
    inc rcx
    imul rcx,r13
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    test rax,rax
    je .Lsodvs_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Lsodvs_fail

    mov rcx,qword ptr [rbp-96]
    dec rcx
    mov rdx,qword ptr [rbp-80]
    mov qword ptr [rdx+rcx*8],rax
    inc rbx
    jmp .Lsodvs_loop

.Lsodvs_validate_pending:
    xor ecx,ecx
.Lsodvs_pending_check:
    cmp rcx,6
    jae .Lsodvs_commit
    mov rax,qword ptr [rbp-80]
    cmp qword ptr [rax+rcx*8],0
    je .Lsodvs_fail
    inc rcx
    jmp .Lsodvs_pending_check

.Lsodvs_commit:
    xor ecx,ecx
.Lsodvs_commit_loop:
    cmp rcx,6
    jae .Lsodvs_ok
    mov rax,qword ptr [rbp-80]
    mov rdx,qword ptr [rax+rcx*8]
    mov qword ptr [r12+rcx*8],rdx
    inc rcx
    jmp .Lsodvs_commit_loop

.Lsodvs_ok:
    mov rax,r12
    jmp .Lsodvs_done
.Lsodvs_fail:
    xor eax,eax
.Lsodvs_done:
    add rsp,120
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stirOneDropViaShadow,.-stirOneDropViaShadow

.type monster_stage21_bowl_shadow_patch_wrapper,@function
monster_stage21_bowl_shadow_patch_wrapper:
    jmp stirOneDropViaShadow
.size monster_stage21_bowl_shadow_patch_wrapper,.-monster_stage21_bowl_shadow_patch_wrapper

.type monster_bowl_stir_route,@function
monster_bowl_stir_route:
    jmp monster_stage21_bowl_shadow_patch_wrapper
.size monster_bowl_stir_route,.-monster_bowl_stir_route

.type monster_stage20_legacy_inplace_bowl_handler,@function
monster_stage20_legacy_inplace_bowl_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    test r12,r12
    je .Lms20_fail

    mov r13,qword ptr [r12+CTX_LEGACY_POUR_DROP]
    mov r14,qword ptr [r12+CTX_LEGACY_POUR_OLD_BOWLS]
    mov r15,qword ptr [r12+CTX_LEGACY_POUR_STONE_ROW]
    test r13,r13
    je .Lms20_fail
    test r14,r14
    je .Lms20_fail
    test r15,r15
    je .Lms20_fail
    mov qword ptr [r12+CTX_LEGACY_BOWL_STIR_DROP],r13
    mov rax,qword ptr [r12+CTX_LEGACY_POUR_I]
    mov qword ptr [r12+CTX_LEGACY_BOWL_STIR_I],rax
    mov qword ptr [r12+CTX_LEGACY_BOWL_STIR_INPUT],r14
    mov qword ptr [r12+CTX_LEGACY_BOWL_STIR_STONE_ROW],r15
    mov rax,qword ptr [r12+CTX_PATCHED_POUR_ORDER]
    mov qword ptr [r12+CTX_LEGACY_BOWL_STIR_ORDER],rax
    mov rcx,qword ptr [r12+CTX_PATCHED_POUR_RESULT]
    mov qword ptr [r12+CTX_LEGACY_BOWL_STIR_POURS],rcx
    test rax,rax
    je .Lms20_fail
    test rcx,rcx
    je .Lms20_fail

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms20_fail
    mov qword ptr [rbp-48],rax
    xor ecx,ecx
.Lms20_clone_loop:
    cmp rcx,6
    jae .Lms20_clone_done
    mov rdx,qword ptr [r14+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lms20_clone_loop
.Lms20_clone_done:
    mov rdi,rax
    mov rsi,qword ptr [r12+CTX_LEGACY_BOWL_STIR_I]
    mov rdx,r13
    mov rcx,r15
    mov r8,qword ptr [r12+CTX_LEGACY_BOWL_STIR_ORDER]
    mov r9,qword ptr [r12+CTX_LEGACY_BOWL_STIR_POURS]
    call legacyStirOneDropInPlace
    test rax,rax
    je .Lms20_fail
    mov qword ptr [r12+CTX_LEGACY_BOWL_STIR_OUTPUT],rax
    inc qword ptr [r12+CTX_LEGACY_BOWL_STIR_SEEN]

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms20_fail
    mov qword ptr [rbp-48],rax
    xor ecx,ecx
.Lms20_route_clone_loop:
    cmp rcx,6
    jae .Lms20_route_clone_done
    mov rdx,qword ptr [r14+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lms20_route_clone_loop
.Lms20_route_clone_done:
    mov rdi,rax
    mov rsi,qword ptr [r12+CTX_LEGACY_BOWL_STIR_I]
    mov rdx,r13
    mov rcx,r15
    mov r8,qword ptr [r12+CTX_LEGACY_BOWL_STIR_ORDER]
    mov r9,qword ptr [r12+CTX_LEGACY_BOWL_STIR_POURS]
    call monster_bowl_stir_route
    test rax,rax
    je .Lms20_fail
    mov qword ptr [r12+CTX_BOWL_STIR_ROUTE_RESULT],rax
    inc qword ptr [r12+CTX_BOWL_STIR_ROUTE_SEEN]
    inc qword ptr [r12+CTX_BOWL_SHADOW_PATCH_SEEN]
    mov eax,1
    jmp .Lms20_done
.Lms20_fail:
    xor eax,eax
.Lms20_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage20_legacy_inplace_bowl_handler,.-monster_stage20_legacy_inplace_bowl_handler


# Ⲃⲁⲑⲙⲟⲥ 22 — DISCOVERY 11
# Ⲡⲙⲉⲉⲩⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲟⲩⲏϩ ⲉϥϩⲁⲣⲉϩ ⲉⲟⲩorder ⲛⲟⲩⲱⲧ. Ⲛ46 ⲛdrop ⲙⲛ ⲛ12 ⲛpost-stir ⲥⲉⲥϩⲁⲓ ⲧⲏⲣⲟⲩ ⲉⲡmemory ⲛⲟⲩⲱⲧ.
# Ⲡorder ⲙⲡdrop 46 ⲥⲉⲁⲁϥ ⲛⲟⲩCOPY_DIAGNOSTIC ⲙⲙⲁⲧⲉ; ⲡquery ⲛStage 22 ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡlegacy memory ⲙⲛⲛⲥⲁ ⲡpost-stir 12.
# Ⲙⲛ ⲟⲩlatch ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ.
.type initialBowlsThroughStage22OldFactory,@function
initialBowlsThroughStage22OldFactory:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Libs22_fail
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Libs22_fail
    mov r13,rax
    mov r14,1
.Libs22_loop:
    cmp r14,6
    ja .Libs22_ok
    mov rdi,qword ptr [r12+HCOUNTS_ACTION]
    call bi_clone
    test rax,rax
    je .Libs22_fail
    mov r15,rax
    mov rdi,qword ptr [r12+HCOUNTS_TARGET]
    mov rsi,r14
    call bi_mul_u64
    test rax,rax
    je .Libs22_fail
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+HCOUNTS_DISTANCE]
    call bi_add_abs
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+HCOUNTS_CONNECTION]
    call bi_add_abs
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+HCOUNTS_DIRECTION]
    call bi_add_abs
    mov r15,rax
    lea r8,[rip+stage22_bowl_prime]
    mov rax,qword ptr [r8+r14*8-8]
    imul rax,rax
    mov rdi,r15
    mov rsi,rax
    call bi_add_u64
    mov rdi,rax
    mov rsi,rax
    call bi_mul_abs
    mov rdi,rax
    mov rsi,r14
    call bi_add_u64
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Libs22_fail
    mov qword ptr [r13+r14*8-8],rax
    inc r14
    jmp .Libs22_loop
.Libs22_ok:
    mov rax,r13
    jmp .Libs22_done
.Libs22_fail:
    xor eax,eax
.Libs22_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size initialBowlsThroughStage22OldFactory,.-initialBowlsThroughStage22OldFactory

.type postStirOneOverwritingOrderMemoryStage22,@function
postStirOneOverwritingOrderMemoryStage22:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,56
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Lpsoom22_fail
    test r14,r14
    je .Lpsoom22_fail
    cmp r13,1
    jb .Lpsoom22_fail
    cmp r13,12
    ja .Lpsoom22_fail
    mov edi,96
    call arena_alloc
    test rax,rax
    je .Lpsoom22_fail
    mov r15,rax
    lea rax,[rax+48]
    mov qword ptr [rbp-48],rax
    xor ecx,ecx
.Lpsoom22_copy_old:
    cmp rcx,6
    jae .Lpsoom22_sum
    mov rax,qword ptr [r12+rcx*8]
    test rax,rax
    je .Lpsoom22_fail
    mov qword ptr [r15+rcx*8],rax
    inc rcx
    jmp .Lpsoom22_copy_old
.Lpsoom22_sum:
    xor edi,edi
    call bi_from_u64
    test rax,rax
    je .Lpsoom22_fail
    mov qword ptr [rbp-56],rax
    xor ebx,ebx
.Lpsoom22_sum_loop:
    cmp rbx,6
    jae .Lpsoom22_saved_sum
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [r15+rbx*8]
    call bi_add_abs
    mov qword ptr [rbp-56],rax
    inc rbx
    jmp .Lpsoom22_sum_loop
.Lpsoom22_saved_sum:
    mov rax,r13
    imul rax,149
    mov rdi,qword ptr [rbp-56]
    mov rsi,rax
    call bi_add_u64
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Lpsoom22_fail
    mov qword ptr [rbp-56],rax
    mov rdi,rax
    mov rsi,r14
    call orderPatchFromValue
    test rax,rax
    je .Lpsoom22_fail
    xor ebx,ebx
.Lpsoom22_bowl_loop:
    cmp rbx,6
    jae .Lpsoom22_validate
    mov rax,qword ptr [r14+rbx*8]
    cmp rax,1
    jb .Lpsoom22_fail
    cmp rax,6
    ja .Lpsoom22_fail
    mov qword ptr [rbp-64],rax
    mov rcx,rbx
    add rcx,5
    cmp rcx,6
    jb .Lpsoom22_prev_ready
    sub rcx,6
.Lpsoom22_prev_ready:
    mov rax,qword ptr [r14+rcx*8]
    mov qword ptr [rbp-72],rax
    mov rcx,rbx
    inc rcx
    cmp rcx,6
    jb .Lpsoom22_next_ready
    xor ecx,ecx
.Lpsoom22_next_ready:
    mov rax,qword ptr [r14+rcx*8]
    mov qword ptr [rbp-80],rax
    mov rax,qword ptr [rbp-64]
    dec rax
    mov rdi,qword ptr [r15+rax*8]
    call bi_clone
    mov qword ptr [rbp-88],rax
    mov rax,qword ptr [rbp-72]
    dec rax
    mov rdi,qword ptr [r15+rax*8]
    mov esi,3
    call bi_mul_u64
    mov rdi,qword ptr [rbp-88]
    mov rsi,rax
    call bi_add_abs
    mov qword ptr [rbp-88],rax
    mov rax,qword ptr [rbp-80]
    dec rax
    mov rdi,qword ptr [r15+rax*8]
    mov esi,5
    call bi_mul_u64
    mov rdi,qword ptr [rbp-88]
    mov rsi,rax
    call bi_add_abs
    mov qword ptr [rbp-88],rax
    mov rdi,qword ptr [rbp-88]
    mov rsi,qword ptr [rbp-56]
    call bi_add_abs
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    mov rcx,rbx
    inc rcx
    imul rcx,rcx
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    mov rdi,rax
    mov rsi,rax
    call bi_mul_abs
    mov qword ptr [rbp-88],rax
    mov rax,qword ptr [rbp-72]
    dec rax
    mov rdi,qword ptr [r15+rax*8]
    mov rax,qword ptr [rbp-80]
    dec rax
    mov rsi,qword ptr [r15+rax*8]
    call bi_mul_abs
    mov rdi,rax
    mov esi,7
    call bi_mul_u64
    mov rdi,qword ptr [rbp-88]
    mov rsi,rax
    call bi_add_abs
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Lpsoom22_fail
    mov rcx,qword ptr [rbp-64]
    dec rcx
    mov rdx,qword ptr [rbp-48]
    mov qword ptr [rdx+rcx*8],rax
    inc rbx
    jmp .Lpsoom22_bowl_loop
.Lpsoom22_validate:
    xor ecx,ecx
.Lpsoom22_validate_loop:
    cmp rcx,6
    jae .Lpsoom22_commit
    mov rax,qword ptr [rbp-48]
    cmp qword ptr [rax+rcx*8],0
    je .Lpsoom22_fail
    inc rcx
    jmp .Lpsoom22_validate_loop
.Lpsoom22_commit:
    xor ecx,ecx
.Lpsoom22_commit_loop:
    cmp rcx,6
    jae .Lpsoom22_ok
    mov rax,qword ptr [rbp-48]
    mov rdx,qword ptr [rax+rcx*8]
    mov qword ptr [r12+rcx*8],rdx
    inc rcx
    jmp .Lpsoom22_commit_loop
.Lpsoom22_ok:
    mov rax,r12
    jmp .Lpsoom22_done
.Lpsoom22_fail:
    xor eax,eax
.Lpsoom22_done:
    add rsp,56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size postStirOneOverwritingOrderMemoryStage22,.-postStirOneOverwritingOrderMemoryStage22

.type legacySauceWithOverwritableOrderMemory,@function
legacySauceWithOverwritableOrderMemory:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,120
    mov qword ptr [rbp-48],rdi
    mov qword ptr [rbp-56],rsi
    mov edi,S22_SIZE
    call arena_alloc
    test rax,rax
    je .Llswoom22_fail
    mov r12,rax
    mov rdi,r12
    xor eax,eax
    mov ecx,11
    rep stosq
    mov edi,HCOUNTS_SIZE
    call arena_alloc
    test rax,rax
    je .Llswoom22_fail
    mov r13,rax
    mov rdi,qword ptr [rbp-48]
    call bi_from_i64
    mov qword ptr [rbp-64],rax
    mov rdi,rax
    call dayTagWithFoundationScar
    mov qword ptr [r13+HCOUNTS_ACTION],rax
    mov rdi,qword ptr [rbp-56]
    call bi_from_i64
    mov qword ptr [rbp-72],rax
    mov rdi,rax
    call dayTagWithFoundationScar
    mov qword ptr [r13+HCOUNTS_TARGET],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-72]
    call distanceWithChronologicalScar
    mov qword ptr [r13+HCOUNTS_DISTANCE],rax
    mov rdi,qword ptr [r13+HCOUNTS_ACTION]
    mov rsi,qword ptr [r13+HCOUNTS_TARGET]
    call bi_add_abs
    mov qword ptr [r13+HCOUNTS_CONNECTION],rax
    mov rax,qword ptr [rbp-56]
    cmp rax,qword ptr [rbp-48]
    jl .Llswoom22_dir1
    je .Llswoom22_dir2
    mov edi,3
    jmp .Llswoom22_dir_make
.Llswoom22_dir1:
    mov edi,1
    jmp .Llswoom22_dir_make
.Llswoom22_dir2:
    mov edi,2
.Llswoom22_dir_make:
    call bi_from_u64
    mov qword ptr [r13+HCOUNTS_DIRECTION],rax
    call getStoneTableThroughLegacyBuilder
    test rax,rax
    je .Llswoom22_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Llswoom22_fail
    mov r15,rax
    mov qword ptr [r12+S22_HIDDEN],r15
    mov edi,424
    call arena_alloc
    test rax,rax
    je .Llswoom22_fail
    mov qword ptr [rbp-80],rax
    mov rdi,rax
    xor eax,eax
    mov ecx,53
    rep stosq
    mov rax,qword ptr [rbp-80]
    add rax,48
    mov qword ptr [rbp-88],rax
    mov qword ptr [r12+S22_DROPS],rax
    mov rdi,r13
    call initialBowlsThroughStage22OldFactory
    test rax,rax
    je .Llswoom22_fail
    mov qword ptr [rbp-96],rax
    mov edi,144
    call arena_alloc
    test rax,rax
    je .Llswoom22_fail
    mov qword ptr [rbp-104],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-112],rcx
    lea rcx,[rax+96]
    mov qword ptr [rbp-120],rcx
    mov qword ptr [r12+S22_LEGACY_ORDER_MEMORY],rax
    mov rcx,qword ptr [rbp-112]
    mov qword ptr [r12+S22_DROP46_DIAGNOSTIC],rcx
    mov rcx,qword ptr [rbp-120]
    mov qword ptr [r12+S22_LAST_POST_ORDER],rcx
    mov rbx,1
.Llswoom22_drop_loop:
    cmp rbx,46
    ja .Llswoom22_after_drops
    mov rdi,r13
    mov rsi,r14
    mov rdx,qword ptr [rbp-88]
    mov rcx,r15
    mov r8,rbx
    call monster_visible_drop_route
    test rax,rax
    je .Llswoom22_fail
    mov rdx,qword ptr [rbp-88]
    mov qword ptr [rdx+rbx*8],rax
    mov qword ptr [rbp-128],rax
    mov edi,72
    call arena_alloc
    test rax,rax
    je .Llswoom22_fail
    mov qword ptr [rbp-136],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-144],rcx
    mov rdi,qword ptr [rbp-128]
    mov rsi,rax
    call orderPatchFromValue
    test rax,rax
    je .Llswoom22_fail
    mov rax,rbx
    dec rax
    imul rax,40
    lea rcx,[r14+rax]
    mov rdi,qword ptr [rbp-128]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-96]
    mov r8,qword ptr [rbp-136]
    mov r9,qword ptr [rbp-144]
    call patchedPours
    test rax,rax
    je .Llswoom22_fail
    mov rax,rbx
    dec rax
    imul rax,40
    lea rcx,[r14+rax]
    mov rdi,qword ptr [rbp-96]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-128]
    mov r8,qword ptr [rbp-136]
    mov r9,qword ptr [rbp-144]
    call stirOneDropViaShadow
    test rax,rax
    je .Llswoom22_fail
    xor ecx,ecx
.Llswoom22_write_drop_order:
    cmp rcx,6
    jae .Llswoom22_drop_written
    mov rax,qword ptr [rbp-136]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Llswoom22_write_drop_order
.Llswoom22_drop_written:
    inc qword ptr [r12+S22_ORDER_WRITE_COUNT]
    mov qword ptr [r12+S22_LAST_SOURCE_KIND],1
    mov qword ptr [r12+S22_LAST_SOURCE_ORDINAL],rbx
    cmp rbx,46
    jne .Llswoom22_next_drop
    xor ecx,ecx
.Llswoom22_copy46:
    cmp rcx,6
    jae .Llswoom22_next_drop
    mov rax,qword ptr [rbp-136]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-112]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Llswoom22_copy46
.Llswoom22_next_drop:
    inc rbx
    jmp .Llswoom22_drop_loop
.Llswoom22_after_drops:
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Llswoom22_fail
    mov qword ptr [r12+S22_BOWLS_AFTER_DROPS],rax
    xor ecx,ecx
.Llswoom22_copy_after_drops:
    cmp rcx,6
    jae .Llswoom22_post_begin
    mov rdx,qword ptr [rbp-96]
    mov rdx,qword ptr [rdx+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Llswoom22_copy_after_drops
.Llswoom22_post_begin:
    mov rbx,1
.Llswoom22_post_loop:
    cmp rbx,12
    ja .Llswoom22_finish
    mov rdi,qword ptr [rbp-96]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-120]
    call postStirOneOverwritingOrderMemoryStage22
    test rax,rax
    je .Llswoom22_fail
    xor ecx,ecx
.Llswoom22_write_post_order:
    cmp rcx,6
    jae .Llswoom22_post_written
    mov rax,qword ptr [rbp-120]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Llswoom22_write_post_order
.Llswoom22_post_written:
    inc qword ptr [r12+S22_ORDER_WRITE_COUNT]
    mov qword ptr [r12+S22_LAST_SOURCE_KIND],2
    mov qword ptr [r12+S22_LAST_SOURCE_ORDINAL],rbx
    inc rbx
    jmp .Llswoom22_post_loop
.Llswoom22_finish:
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Llswoom22_fail
    mov qword ptr [r12+S22_FINAL_BOWLS],rax
    xor ecx,ecx
.Llswoom22_final_copy:
    cmp rcx,6
    jae .Llswoom22_query
    mov rdx,qword ptr [rbp-96]
    mov rdx,qword ptr [rdx+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Llswoom22_final_copy
.Llswoom22_query:
    mov rax,qword ptr [rbp-104]
    mov qword ptr [r12+S22_QUERY_ORDER],rax
    cmp qword ptr [r12+S22_ORDER_WRITE_COUNT],58
    jne .Llswoom22_fail
    cmp qword ptr [r12+S22_LAST_SOURCE_KIND],2
    jne .Llswoom22_fail
    cmp qword ptr [r12+S22_LAST_SOURCE_ORDINAL],12
    jne .Llswoom22_fail
    mov rax,r12
    jmp .Llswoom22_done
.Llswoom22_fail:
    xor eax,eax
.Llswoom22_done:
    add rsp,120
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size legacySauceWithOverwritableOrderMemory,.-legacySauceWithOverwritableOrderMemory

.type sauceWithOrderAt46Latch,@function
sauceWithOrderAt46Latch:
    # Ⲃⲁⲑⲙⲟⲥ 23 — PATCH 11. Ⲡlatch ⲡⲁⲓ ⲥⲏϩ ⲛⲟⲩⲥⲟⲡ ⲙⲙⲁⲧⲉ ⲙⲛⲛⲥⲁ ⲡdrop 46, ⲉⲙⲡⲁⲧⲉ ⲡpost-stir ⲛϣⲟⲣⲡ ⲁⲣⲭⲉⲓ.
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,120
    mov qword ptr [rbp-48],rdi
    mov qword ptr [rbp-56],rsi
    mov edi,S23_SIZE
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov r12,rax
    mov rdi,r12
    xor eax,eax
    mov ecx,11
    rep stosq
    mov edi,HCOUNTS_SIZE
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov r13,rax
    mov rdi,qword ptr [rbp-48]
    call bi_from_i64
    mov qword ptr [rbp-64],rax
    mov rdi,rax
    call dayTagWithFoundationScar
    mov qword ptr [r13+HCOUNTS_ACTION],rax
    mov rdi,qword ptr [rbp-56]
    call bi_from_i64
    mov qword ptr [rbp-72],rax
    mov rdi,rax
    call dayTagWithFoundationScar
    mov qword ptr [r13+HCOUNTS_TARGET],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-72]
    call distanceWithChronologicalScar
    mov qword ptr [r13+HCOUNTS_DISTANCE],rax
    mov rdi,qword ptr [r13+HCOUNTS_ACTION]
    mov rsi,qword ptr [r13+HCOUNTS_TARGET]
    call bi_add_abs
    mov qword ptr [r13+HCOUNTS_CONNECTION],rax
    mov rax,qword ptr [rbp-56]
    cmp rax,qword ptr [rbp-48]
    jl .Lswo46l23_dir1
    je .Lswo46l23_dir2
    mov edi,3
    jmp .Lswo46l23_dir_make
.Lswo46l23_dir1:
    mov edi,1
    jmp .Lswo46l23_dir_make
.Lswo46l23_dir2:
    mov edi,2
.Lswo46l23_dir_make:
    call bi_from_u64
    mov qword ptr [r13+HCOUNTS_DIRECTION],rax
    call getStoneTableThroughLegacyBuilder
    test rax,rax
    je .Lswo46l23_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Lswo46l23_fail
    mov r15,rax
    mov qword ptr [r12+S23_HIDDEN],r15
    mov edi,424
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov qword ptr [rbp-80],rax
    mov rdi,rax
    xor eax,eax
    mov ecx,53
    rep stosq
    mov rax,qword ptr [rbp-80]
    add rax,48
    mov qword ptr [rbp-88],rax
    mov qword ptr [r12+S23_DROPS],rax
    mov rdi,r13
    call initialBowlsThroughStage22OldFactory
    test rax,rax
    je .Lswo46l23_fail
    mov qword ptr [rbp-96],rax
    mov edi,144
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov qword ptr [rbp-104],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-112],rcx
    lea rcx,[rax+96]
    mov qword ptr [rbp-120],rcx
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov qword ptr [rbp-152],rax
    mov qword ptr [r12+S23_ORDER46_LATCH],rax
    mov rax,qword ptr [rbp-104]
    mov qword ptr [r12+S23_LEGACY_ORDER_MEMORY],rax
    mov rcx,qword ptr [rbp-112]
    mov qword ptr [r12+S23_DROP46_DIAGNOSTIC],rcx
    mov rcx,qword ptr [rbp-120]
    mov qword ptr [r12+S23_LAST_POST_ORDER],rcx
    mov rbx,1
.Lswo46l23_drop_loop:
    cmp rbx,46
    ja .Lswo46l23_after_drops
    mov rdi,r13
    mov rsi,r14
    mov rdx,qword ptr [rbp-88]
    mov rcx,r15
    mov r8,rbx
    call monster_visible_drop_route
    test rax,rax
    je .Lswo46l23_fail
    mov rdx,qword ptr [rbp-88]
    mov qword ptr [rdx+rbx*8],rax
    mov qword ptr [rbp-128],rax
    mov edi,72
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov qword ptr [rbp-136],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-144],rcx
    mov rdi,qword ptr [rbp-128]
    mov rsi,rax
    call orderPatchFromValue
    test rax,rax
    je .Lswo46l23_fail
    mov rax,rbx
    dec rax
    imul rax,40
    lea rcx,[r14+rax]
    mov rdi,qword ptr [rbp-128]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-96]
    mov r8,qword ptr [rbp-136]
    mov r9,qword ptr [rbp-144]
    call patchedPours
    test rax,rax
    je .Lswo46l23_fail
    mov rax,rbx
    dec rax
    imul rax,40
    lea rcx,[r14+rax]
    mov rdi,qword ptr [rbp-96]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-128]
    mov r8,qword ptr [rbp-136]
    mov r9,qword ptr [rbp-144]
    call stirOneDropViaShadow
    test rax,rax
    je .Lswo46l23_fail
    xor ecx,ecx
.Lswo46l23_write_drop_order:
    cmp rcx,6
    jae .Lswo46l23_drop_written
    mov rax,qword ptr [rbp-136]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lswo46l23_write_drop_order
.Lswo46l23_drop_written:
    inc qword ptr [r12+S23_ORDER_WRITE_COUNT]
    mov qword ptr [r12+S23_LAST_SOURCE_KIND],1
    mov qword ptr [r12+S23_LAST_SOURCE_ORDINAL],rbx
    cmp rbx,46
    jne .Lswo46l23_next_drop
    xor ecx,ecx
.Lswo46l23_copy46:
    cmp rcx,6
    jae .Lswo46l23_latch46_begin
    mov rax,qword ptr [rbp-136]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-112]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lswo46l23_copy46
.Lswo46l23_latch46_begin:
    cmp qword ptr [r12+S23_LATCH_WRITE_COUNT],0
    jne .Lswo46l23_fail
    xor ecx,ecx
.Lswo46l23_latch46_copy:
    cmp rcx,6
    jae .Lswo46l23_latch46_done
    mov rax,qword ptr [rbp-136]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-152]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lswo46l23_latch46_copy
.Lswo46l23_latch46_done:
    inc qword ptr [r12+S23_LATCH_WRITE_COUNT]
    mov qword ptr [r12+S23_LATCH_SOURCE_ORDINAL],46
.Lswo46l23_next_drop:
    inc rbx
    jmp .Lswo46l23_drop_loop
.Lswo46l23_after_drops:
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov qword ptr [r12+S23_BOWLS_AFTER_DROPS],rax
    xor ecx,ecx
.Lswo46l23_copy_after_drops:
    cmp rcx,6
    jae .Lswo46l23_post_begin
    mov rdx,qword ptr [rbp-96]
    mov rdx,qword ptr [rdx+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lswo46l23_copy_after_drops
.Lswo46l23_post_begin:
    mov rbx,1
.Lswo46l23_post_loop:
    cmp rbx,12
    ja .Lswo46l23_finish
    mov rdi,qword ptr [rbp-96]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-120]
    call postStirOneOverwritingOrderMemoryStage22
    test rax,rax
    je .Lswo46l23_fail
    xor ecx,ecx
.Lswo46l23_write_post_order:
    cmp rcx,6
    jae .Lswo46l23_post_written
    mov rax,qword ptr [rbp-120]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lswo46l23_write_post_order
.Lswo46l23_post_written:
    inc qword ptr [r12+S23_ORDER_WRITE_COUNT]
    mov qword ptr [r12+S23_LAST_SOURCE_KIND],2
    mov qword ptr [r12+S23_LAST_SOURCE_ORDINAL],rbx
    inc rbx
    jmp .Lswo46l23_post_loop
.Lswo46l23_finish:
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lswo46l23_fail
    mov qword ptr [r12+S23_FINAL_BOWLS],rax
    xor ecx,ecx
.Lswo46l23_final_copy:
    cmp rcx,6
    jae .Lswo46l23_query
    mov rdx,qword ptr [rbp-96]
    mov rdx,qword ptr [rdx+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Lswo46l23_final_copy
.Lswo46l23_query:
    mov rax,qword ptr [rbp-152]
    mov qword ptr [r12+S23_QUERY_ORDER],rax
    cmp qword ptr [r12+S23_LATCH_WRITE_COUNT],1
    jne .Lswo46l23_fail
    cmp qword ptr [r12+S23_LATCH_SOURCE_ORDINAL],46
    jne .Lswo46l23_fail
    cmp qword ptr [r12+S23_ORDER_WRITE_COUNT],58
    jne .Lswo46l23_fail
    cmp qword ptr [r12+S23_LAST_SOURCE_KIND],2
    jne .Lswo46l23_fail
    cmp qword ptr [r12+S23_LAST_SOURCE_ORDINAL],12
    jne .Lswo46l23_fail
    mov rax,r12
    jmp .Lswo46l23_done
.Lswo46l23_fail:
    xor eax,eax
.Lswo46l23_done:
    add rsp,120
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size sauceWithOrderAt46Latch,.-sauceWithOrderAt46Latch

.type monster_stage23_order46_latch_patch_wrapper,@function
monster_stage23_order46_latch_patch_wrapper:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    # Ⲡlegacy sauce ⲙⲟⲟϣⲉ ⲛⲟⲩⲙⲉ ⲉⲧⲣⲉⲡoverwritable memory ⲟⲩⲱⲛϩ ⲉⲃⲟⲗ.
    mov rdi,r12
    mov rsi,r13
    call legacySauceWithOverwritableOrderMemory
    test rax,rax
    je .Lms23wrap_fail
    mov r14,rax
    mov rdi,r12
    mov rsi,r13
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Lms23wrap_fail
    mov qword ptr [rax+S23_LEGACY_DIAGNOSTIC_RESULT],r14
    jmp .Lms23wrap_done
.Lms23wrap_fail:
    xor eax,eax
.Lms23wrap_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage23_order46_latch_patch_wrapper,.-monster_stage23_order46_latch_patch_wrapper

.type monster_order46_memory_route,@function
monster_order46_memory_route:
    jmp monster_stage23_order46_latch_patch_wrapper
.size monster_order46_memory_route,.-monster_order46_memory_route

.type monster_stage22_overwritable_order_handler,@function
monster_stage22_overwritable_order_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    test r12,r12
    je .Lms22_fail
    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    mov rsi,qword ptr [r12+CTX_TARGET_DAY]
    call monster_order46_memory_route
    test rax,rax
    je .Lms22_fail
    mov r13,rax
    mov qword ptr [r12+CTX_STAGE22_SAUCE_RESULT],r13
    mov rax,qword ptr [r13+S22_DROP46_DIAGNOSTIC]
    mov qword ptr [r12+CTX_STAGE22_DROP46_DIAGNOSTIC],rax
    mov rax,qword ptr [r13+S22_LEGACY_ORDER_MEMORY]
    mov qword ptr [r12+CTX_STAGE22_LEGACY_ORDER_MEMORY],rax
    mov rax,qword ptr [r13+S22_QUERY_ORDER]
    mov qword ptr [r12+CTX_STAGE22_QUERY_ORDER],rax
    mov rax,qword ptr [r13+S22_ORDER_WRITE_COUNT]
    mov qword ptr [r12+CTX_STAGE22_ORDER_WRITE_COUNT],rax
    mov rax,qword ptr [r13+S22_LAST_SOURCE_KIND]
    mov qword ptr [r12+CTX_STAGE22_LAST_SOURCE_KIND],rax
    mov rax,qword ptr [r13+S22_LAST_SOURCE_ORDINAL]
    mov qword ptr [r12+CTX_STAGE22_LAST_SOURCE_ORDINAL],rax
    inc qword ptr [r12+CTX_STAGE22_SEEN]
    mov eax,1
    jmp .Lms22_done
.Lms22_fail:
    xor eax,eax
.Lms22_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage22_overwritable_order_handler,.-monster_stage22_overwritable_order_handler

.type monster_stage23_order46_latch_handler,@function
monster_stage23_order46_latch_handler:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    test r12,r12
    je .Lms23h_fail
    mov rax,qword ptr [r12+CTX_STAGE22_SAUCE_RESULT]
    test rax,rax
    je .Lms23h_fail
    mov rdx,qword ptr [rax+S23_ORDER46_LATCH]
    test rdx,rdx
    je .Lms23h_fail
    mov qword ptr [r12+CTX_STAGE23_ORDER46_LATCH],rdx
    mov rdx,qword ptr [rax+S23_LATCH_WRITE_COUNT]
    mov qword ptr [r12+CTX_STAGE23_LATCH_WRITE_COUNT],rdx
    mov rdx,qword ptr [rax+S23_LATCH_SOURCE_ORDINAL]
    mov qword ptr [r12+CTX_STAGE23_LATCH_SOURCE_ORDINAL],rdx
    mov rdx,qword ptr [rax+S23_LEGACY_DIAGNOSTIC_RESULT]
    test rdx,rdx
    je .Lms23h_fail
    mov qword ptr [r12+CTX_STAGE23_LEGACY_DIAGNOSTIC_RESULT],rdx
    inc qword ptr [r12+CTX_STAGE23_SEEN]
    mov eax,1
    jmp .Lms23h_done
.Lms23h_fail:
    xor eax,eax
.Lms23h_done:
    pop r12
    leave
    ret
.size monster_stage23_order46_latch_handler,.-monster_stage23_order46_latch_handler


# Ⲃⲁⲑⲙⲟⲥ 24 — DISCOVERY 12
# Ⲡlegacy helper ⲡⲁⲓ ⲙⲟⲟϣⲉ ⲕⲁⲧⲁ ⲡⲣⲓⲛⲅⲕ ⲛⲛbowl ID ⲛⲛⲟⲩⲙⲉⲣⲟⲛ 1..6 ⲁⲩⲱ ⲛϥϫⲓ ⲁⲛ ⲙⲡposition ϩⲙⲡorderAt46Latch.
.type oldNextBowlFixedName,@function
oldNextBowlFixedName:
    cmp rdi,1
    jb .Lonbfn_fail
    cmp rdi,6
    ja .Lonbfn_fail
    cmp rdi,6
    je .Lonbfn_wrap
    lea rax,[rdi+1]
    ret
.Lonbfn_wrap:
    mov eax,1
    ret
.Lonbfn_fail:
    xor eax,eax
    ret
.size oldNextBowlFixedName,.-oldNextBowlFixedName

.type legacyNextBowlAdapter,@function
legacyNextBowlAdapter:
    # Ⲡrdi ϥϫⲓ ⲙⲡsauceResult, ⲁⲩⲱ ⲡrsi ϥϫⲓ ⲙⲡqueriedId. Ⲡlegacy ⲛϥϫⲓ ⲁⲛ ⲙⲡsauceResult.
    mov rdi,rsi
    jmp oldNextBowlFixedName
.size legacyNextBowlAdapter,.-legacyNextBowlAdapter

# Ⲃⲁⲑⲙⲟⲥ 25 — PATCH 12
# Ⲡscar `oldNextBowlFixedName` ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ. Ⲡpatch ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩdiagnostic ⲁⲩⲱ ⲛϥϫⲓ ⲙⲡsuccessor ⲉⲃⲟⲗ ϩⲙⲡqueryOrder ⲉⲧⲉ ⲡorderAt46Latch ⲡⲉ.
.type nextBowlQueryPatch,@function
nextBowlQueryPatch:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lnbqp_fail
    cmp r13,1
    jb .Lnbqp_fail
    cmp r13,6
    ja .Lnbqp_fail

    # Ⲡlegacy call ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲛⲟⲩCOPY_DIAGNOSTIC; ⲡⲉϥresult ⲛϥⲣ ⲁⲛ ⲛⲟⲩsemantic decision.
    mov rdi,r13
    call oldNextBowlFixedName
    test rax,rax
    je .Lnbqp_fail

    mov rdx,qword ptr [r12+S23_QUERY_ORDER]
    test rdx,rdx
    je .Lnbqp_fail
    xor ecx,ecx
.Lnbqp_find:
    cmp rcx,6
    jae .Lnbqp_fail
    mov rax,qword ptr [rdx+rcx*8]
    cmp rax,r13
    je .Lnbqp_found
    inc rcx
    jmp .Lnbqp_find
.Lnbqp_found:
    inc rcx
    cmp rcx,6
    jb .Lnbqp_load
    xor ecx,ecx
.Lnbqp_load:
    mov rax,qword ptr [rdx+rcx*8]
    test rax,rax
    je .Lnbqp_fail
    cmp rax,6
    ja .Lnbqp_fail
    jmp .Lnbqp_done
.Lnbqp_fail:
    xor eax,eax
.Lnbqp_done:
    pop r13
    pop r12
    leave
    ret
.size nextBowlQueryPatch,.-nextBowlQueryPatch

.type monster_stage25_next_bowl_patch_wrapper,@function
monster_stage25_next_bowl_patch_wrapper:
    jmp nextBowlQueryPatch
.size monster_stage25_next_bowl_patch_wrapper,.-monster_stage25_next_bowl_patch_wrapper

.type monster_next_bowl_route,@function
monster_next_bowl_route:
    jmp monster_stage25_next_bowl_patch_wrapper
.size monster_next_bowl_route,.-monster_next_bowl_route

.type monster_stage24_legacy_next_bowl_handler,@function
monster_stage24_legacy_next_bowl_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lms24_fail
    mov r13,qword ptr [r12+CTX_STAGE22_SAUCE_RESULT]
    test r13,r13
    je .Lms24_fail
    mov r14,qword ptr [r12+CTX_STAGE23_ORDER46_LATCH]
    test r14,r14
    je .Lms24_fail
    # Ⲡprobe ⲙⲡDISCOVERY ϫⲓ ⲙⲡID ⲉⲧϩⲙⲡposition ⲙⲙⲁϩ4 ⲙⲡlatch ⲛⲧⲟϣ.
    mov rdx,qword ptr [r14+24]
    cmp rdx,1
    jb .Lms24_fail
    cmp rdx,6
    ja .Lms24_fail
    mov qword ptr [r12+CTX_STAGE24_QUERIED_BOWL_ID],rdx

    mov rdi,rdx
    call oldNextBowlFixedName
    test rax,rax
    je .Lms24_fail
    mov qword ptr [r12+CTX_STAGE24_LEGACY_NEXT_BOWL_ID],rax
    inc qword ptr [r12+CTX_STAGE24_LEGACY_SEEN]

    mov rdi,r13
    mov rsi,qword ptr [r12+CTX_STAGE24_QUERIED_BOWL_ID]
    call monster_next_bowl_route
    test rax,rax
    je .Lms24_fail
    mov qword ptr [r12+CTX_STAGE24_ROUTE_NEXT_BOWL_ID],rax
    inc qword ptr [r12+CTX_STAGE24_ROUTE_SEEN]
    mov eax,1
    jmp .Lms24_done
.Lms24_fail:
    xor eax,eax
.Lms24_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage24_legacy_next_bowl_handler,.-monster_stage24_legacy_next_bowl_handler

.type monster_stage25_next_bowl_patch_handler,@function
monster_stage25_next_bowl_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lms25_fail
    mov r13,qword ptr [r12+CTX_STAGE22_SAUCE_RESULT]
    test r13,r13
    je .Lms25_fail
    mov r14,qword ptr [r12+CTX_STAGE24_QUERIED_BOWL_ID]
    cmp r14,1
    jb .Lms25_fail
    cmp r14,6
    ja .Lms25_fail

    mov rdx,qword ptr [r13+S23_QUERY_ORDER]
    test rdx,rdx
    je .Lms25_fail
    xor ecx,ecx
.Lms25_find:
    cmp rcx,6
    jae .Lms25_fail
    cmp qword ptr [rdx+rcx*8],r14
    je .Lms25_found
    inc rcx
    jmp .Lms25_find
.Lms25_found:
    lea rax,[rcx+1]
    mov qword ptr [r12+CTX_STAGE25_QUERIED_POSITION],rax

    mov rdi,r13
    mov rsi,r14
    call monster_next_bowl_route
    test rax,rax
    je .Lms25_fail
    mov qword ptr [r12+CTX_STAGE25_PATCHED_NEXT_BOWL_ID],rax
    inc qword ptr [r12+CTX_STAGE25_PATCH_SEEN]
    mov eax,1
    jmp .Lms25_done
.Lms25_fail:
    xor eax,eax
.Lms25_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage25_next_bowl_patch_handler,.-monster_stage25_next_bowl_patch_handler


# Ⲃⲁⲑⲙⲟⲥ 26 — DISCOVERY 13
# Ⲡanswer ring ⲡⲁⲓ ⲛⲏⲩ ⲉⲃⲟⲗ ϩⲛ ⲛfinal bowls ⲙⲛ ⲡnext-bowl ⲙⲡPATCH 12. Ⲡfirst ⲙⲛ ⲡdirection ⲥⲉⲟ ⲛinvocation-local.
.type answerRingThroughPatchedNextBowl,@function
answerRingThroughPatchedNextBowl:
    # rdi=sauceResult, rsi=queried bowl ID, rdx=seal. rax=LegacyAnswerRing*.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Larpnb_fail
    cmp r13,1
    jb .Larpnb_fail
    cmp r13,6
    ja .Larpnb_fail
    mov r15,qword ptr [r12+S23_FINAL_BOWLS]
    test r15,r15
    je .Larpnb_fail

    mov rdi,r12
    mov rsi,r13
    call nextBowlQueryPatch
    test rax,rax
    je .Larpnb_fail
    mov qword ptr [rbp-40],rax

    lea rcx,[r13-1]
    mov rdi,qword ptr [r15+rcx*8]
    test rdi,rdi
    je .Larpnb_fail
    lea rsi,[r14+181]
    call bi_add_u64
    test rax,rax
    je .Larpnb_fail
    mov qword ptr [rbp-48],rax
    mov rdi,rax
    mov rsi,rax
    call bi_mul_abs
    test rax,rax
    je .Larpnb_fail
    mov qword ptr [rbp-56],rax

    mov rcx,qword ptr [rbp-40]
    dec rcx
    mov rdi,qword ptr [r15+rcx*8]
    test rdi,rdi
    je .Larpnb_fail
    mov rsi,179
    call bi_mul_u64
    test rax,rax
    je .Larpnb_fail
    mov rsi,rax
    mov rdi,qword ptr [rbp-56]
    call bi_add_abs
    test rax,rax
    je .Larpnb_fail
    mov rdi,rax
    mov rsi,r14
    call bi_add_u64
    test rax,rax
    je .Larpnb_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Larpnb_fail
    mov qword ptr [rbp-64],rax

    mov rdi,rax
    lea rsi,[r14+194]
    call bi_add_u64
    test rax,rax
    je .Larpnb_fail
    mov rdi,rax
    mov rsi,rax
    call bi_mul_abs
    test rax,rax
    je .Larpnb_fail
    mov qword ptr [rbp-48],rax

    mov rdi,qword ptr [rbp-64]
    mov rsi,193
    call bi_mul_u64
    test rax,rax
    je .Larpnb_fail
    mov rsi,rax
    mov rdi,qword ptr [rbp-48]
    call bi_add_abs
    test rax,rax
    je .Larpnb_fail
    mov qword ptr [rbp-48],rax

    mov rdi,qword ptr [r15+40]
    mov rsi,197
    call bi_mul_u64
    test rax,rax
    je .Larpnb_fail
    mov rsi,rax
    mov rdi,qword ptr [rbp-48]
    call bi_add_abs
    test rax,rax
    je .Larpnb_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Larpnb_fail
    mov rdi,rax
    mov rsi,2
    call bi_divmod_u64_abs
    cmp rdx,1
    je .Larpnb_plus
    mov qword ptr [rbp-48],-1
    jmp .Larpnb_alloc
.Larpnb_plus:
    mov qword ptr [rbp-48],1
.Larpnb_alloc:
    mov edi,S26_RING_SIZE
    call arena_alloc
    test rax,rax
    je .Larpnb_fail
    mov rcx,qword ptr [rbp-64]
    mov qword ptr [rax+S26_RING_FIRST],rcx
    mov rcx,qword ptr [rbp-48]
    mov qword ptr [rax+S26_RING_STEP],rcx
    jmp .Larpnb_done
.Larpnb_fail:
    xor eax,eax
.Larpnb_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size answerRingThroughPatchedNextBowl,.-answerRingThroughPatchedNextBowl

# Ⲡring answer ⲟⲩⲏϩ ϩⲙⲡM-old ring ⲛⲟⲩⲱⲧ. Ⲡoffset ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡring ⲛⲧⲟϥ.
.type ringAnswer,@function
ringAnswer:
    # rdi=LegacyAnswerRing*, rsi=offset u64. rax=BigInt*.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lra_fail
    mov rax,qword ptr [r12+S26_RING_STEP]
    cmp rax,1
    je .Lra_step_ok
    cmp rax,-1
    jne .Lra_fail
.Lra_step_ok:
    mov rdi,1
    call bi_from_u64
    test rax,rax
    je .Lra_fail
    mov rsi,rax
    mov rdi,qword ptr [r12+S26_RING_FIRST]
    call bi_sub
    test rax,rax
    je .Lra_fail
    mov r14,rax
    cmp qword ptr [r12+S26_RING_STEP],1
    jne .Lra_minus
    mov rdi,r14
    mov rsi,r13
    call bi_add_u64
    jmp .Lra_mod
.Lra_minus:
    mov rdi,r13
    call bi_from_u64
    test rax,rax
    je .Lra_fail
    mov rsi,rax
    mov rdi,r14
    call bi_sub
.Lra_mod:
    test rax,rax
    je .Lra_fail
    mov rdi,rax
    call oldRemainder
    test rax,rax
    je .Lra_add_one
.Lra_add_one:
    mov rdi,rax
    mov rsi,1
    call bi_add_u64
    jmp .Lra_done
.Lra_fail:
    xor eax,eax
.Lra_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size ringAnswer,.-ringAnswer

# Ⲡselector legacy ⲙⲡDISCOVERY 13: regularMod(x-1,N)+1. Ⲙⲛ rejection ⲉϥϣⲟⲟⲡ ϩⲙⲡhelper ⲡⲁⲓ.
.type biasedLegacyPick,@function
biasedLegacyPick:
    # rdi=x BigInt*, rsi=N BigInt*.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lblp_fail
    test r13,r13
    je .Lblp_fail
    cmp qword ptr [r12+BI_SIGN],1
    jne .Lblp_fail
    cmp qword ptr [r13+BI_SIGN],1
    jne .Lblp_fail
    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,r12
    call bi_sub
    test rax,rax
    je .Lblp_fail
    mov rdi,rax
    mov rsi,r13
    call bi_mod_abs
    test rax,rax
    je .Lblp_fail
    mov rdi,rax
    mov rsi,1
    call bi_add_u64
    jmp .Lblp_done
.Lblp_fail:
    xor eax,eax
.Lblp_done:
    pop r13
    pop r12
    leave
    ret
.size biasedLegacyPick,.-biasedLegacyPick

.type legacyBiasedSelectionBeforeRejection,@function
legacyBiasedSelectionBeforeRejection:
    # rdi=LegacyAnswerRing*, rsi=N BigInt*.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    xor esi,esi
    mov rdi,r12
    call ringAnswer
    test rax,rax
    je .Llbsbr_fail
    mov rdi,rax
    mov rsi,r13
    call biasedLegacyPick
    jmp .Llbsbr_done
.Llbsbr_fail:
    xor eax,eax
.Llbsbr_done:
    pop r13
    pop r12
    leave
    ret
.size legacyBiasedSelectionBeforeRejection,.-legacyBiasedSelectionBeforeRejection


# Ⲃⲁⲑⲙⲟⲥ 27 — PATCH 13
# ⲠbiasedLegacyPick ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩscar. Ⲡdetour ⲙⲟⲩⲧⲉ ⲉⲡlegacy path ⲛⲟⲩCOPY_DIAGNOSTIC,
# ⲁⲩⲱ ⲙⲛⲛⲥⲱⲥ ⲛϥⲗⲟⲅⲓⲍⲉ ⲙⲡlimit=floor(M_OLD/N)*N. Ⲛϥⲙⲟⲟϣⲉ ϩⲙⲡanswer ring ⲛⲟⲩⲱⲧ
# ϣⲁⲛⲧⲉ x<=limit, ⲁⲩⲱ ⲛⲧⲉⲩⲛⲟⲩ ⲙⲙⲁⲧⲉ ⲛϥⲙⲟⲩⲧⲉ ⲉbiasedLegacyPick.
.type patchedSmallPick,@function
patchedSmallPick:
    # rdi=LegacyAnswerRing*, rsi=N BigInt*.
    # rax=rank BigInt*; rdx=accepted x BigInt*; rcx=accepted offset u64; r8=limit BigInt*.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lpsp_fail
    test r13,r13
    je .Lpsp_fail
    cmp qword ptr [r13+BI_SIGN],1
    jne .Lpsp_fail

    # Ⲡshort path ⲙⲡPATCH 13 ⲟ ⲛⲧⲟϣ ⲙⲙⲁⲧⲉ ⲉϣϫⲉ N<=M_OLD.
    mov rdi,r13
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    jg .Lpsp_fail

    # ⲞⲩCOPY_DIAGNOSTIC ⲛⲧⲉⲡDISCOVERY: ⲡlegacy call ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲁⲩⲱ ⲡresult ⲛϥⲧⲟϣ ⲁⲛ.
    mov rdi,r12
    mov rsi,r13
    call legacyBiasedSelectionBeforeRejection
    test rax,rax
    je .Lpsp_fail

    # limit=floor(M_OLD/N)*N
    lea rdi,[rip+legacy_remainder_M]
    mov rsi,r13
    call bi_divmod_abs
    test rax,rax
    je .Lpsp_fail
    mov rdi,rax
    mov rsi,r13
    call bi_mul_abs
    test rax,rax
    je .Lpsp_fail
    mov r14,rax
    xor r15d,r15d

.Lpsp_rejection_loop:
    mov rdi,r12
    mov rsi,r15
    call ringAnswer
    test rax,rax
    je .Lpsp_fail
    mov qword ptr [rbp-40],rax

    mov rdi,rax
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jle .Lpsp_accept

    inc r15
    jne .Lpsp_rejection_loop
    # Ⲡoffset u64 ⲛⲧⲉⲡlegacy ring API ⲁϥⲙⲟⲩϩ: deterministic fail, ⲙⲛ wide detour ϩⲙⲡStage ⲡⲁⲓ.
    jmp .Lpsp_fail

.Lpsp_accept:
    mov rdi,qword ptr [rbp-40]
    mov rsi,r13
    call biasedLegacyPick
    test rax,rax
    je .Lpsp_fail
    mov rdx,qword ptr [rbp-40]
    mov rcx,r15
    mov r8,r14
    jmp .Lpsp_done

.Lpsp_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
.Lpsp_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size patchedSmallPick,.-patchedSmallPick

.type monster_stage27_rejection_patch_wrapper,@function
monster_stage27_rejection_patch_wrapper:
    jmp patchedSmallPick
.size monster_stage27_rejection_patch_wrapper,.-monster_stage27_rejection_patch_wrapper

.type monster_biased_selection_route,@function
monster_biased_selection_route:
    jmp monster_stage27_rejection_patch_wrapper
.size monster_biased_selection_route,.-monster_biased_selection_route

.type monster_stage26_legacy_biased_selection_handler,@function
monster_stage26_legacy_biased_selection_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    test r12,r12
    je .Lms26_fail
    mov r13,qword ptr [r12+CTX_STAGE22_SAUCE_RESULT]
    test r13,r13
    je .Lms26_fail

    mov qword ptr [r12+CTX_STAGE26_QUERIED_BOWL_ID],1
    mov qword ptr [r12+CTX_STAGE26_SEAL],21
    mov rdi,r13
    mov esi,1
    call nextBowlQueryPatch
    test rax,rax
    je .Lms26_fail
    mov qword ptr [r12+CTX_STAGE26_NEXT_BOWL_ID],rax

    mov rdi,r13
    mov esi,1
    mov edx,21
    call answerRingThroughPatchedNextBowl
    test rax,rax
    je .Lms26_fail
    mov r14,rax
    mov qword ptr [r12+CTX_STAGE26_ANSWER_RING],r14
    mov rax,qword ptr [r14+S26_RING_STEP]
    mov qword ptr [r12+CTX_STAGE26_DIRECTION],rax

    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r14+S26_RING_FIRST]
    call bi_sub
    test rax,rax
    je .Lms26_fail
    cmp qword ptr [rax+BI_SIGN],1
    jne .Lms26_fail
    mov r15,rax
    mov qword ptr [r12+CTX_STAGE26_FAMILY_SIZE],r15

    mov rdi,r14
    xor esi,esi
    call ringAnswer
    test rax,rax
    je .Lms26_fail
    mov qword ptr [r12+CTX_STAGE26_FIRST_ANSWER],rax

    mov rdi,rax
    mov rsi,r15
    call biasedLegacyPick
    test rax,rax
    je .Lms26_fail
    mov qword ptr [r12+CTX_STAGE26_LEGACY_SELECTION],rax
    inc qword ptr [r12+CTX_STAGE26_LEGACY_SEEN]

    mov rdi,r14
    mov rsi,r15
    call monster_biased_selection_route
    test rax,rax
    je .Lms26_fail
    mov qword ptr [r12+CTX_STAGE26_ROUTE_SELECTION],rax
    inc qword ptr [r12+CTX_STAGE26_ROUTE_SEEN]
    mov eax,1
    jmp .Lms26_done
.Lms26_fail:
    xor eax,eax
.Lms26_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage26_legacy_biased_selection_handler,.-monster_stage26_legacy_biased_selection_handler

.type monster_stage27_rejection_patch_handler,@function
monster_stage27_rejection_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    test r12,r12
    je .Lms27_fail
    mov rdi,qword ptr [r12+CTX_STAGE26_ANSWER_RING]
    mov rsi,qword ptr [r12+CTX_STAGE26_FAMILY_SIZE]
    test rdi,rdi
    je .Lms27_fail
    test rsi,rsi
    je .Lms27_fail
    call patchedSmallPick
    test rax,rax
    je .Lms27_fail
    mov qword ptr [r12+CTX_STAGE27_PATCHED_SELECTION],rax
    mov qword ptr [r12+CTX_STAGE27_ACCEPTED_ANSWER],rdx
    mov qword ptr [r12+CTX_STAGE27_ACCEPTED_OFFSET],rcx
    mov qword ptr [r12+CTX_STAGE27_ACCEPTANCE_LIMIT],r8
    inc qword ptr [r12+CTX_STAGE27_PATCH_SEEN]
    mov eax,1
    jmp .Lms27_done
.Lms27_fail:
    xor eax,eax
.Lms27_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage27_rejection_patch_handler,.-monster_stage27_rejection_patch_handler


# Ⲃⲁⲑⲙⲟⲥ 28 — DISCOVERY 14
# Ⲡlegacy ⲡⲁⲓ ⲙⲉⲉⲩⲉ ϫⲉ ⲛfamily ⲧⲏⲣⲟⲩ ⲟ ⲛshort. Ⲛϥϫⲟⲟⲩ ⲙⲡN ⲧⲏⲣϥ ⲉpatchedSmallPick
# ⲁϫⲛ ⲟⲩdispatcher ⲛwide. Ⲉϣϫⲉ N>M_OLD, ⲡguard ⲛPATCH 13 ⲕⲱ ⲙⲡresult ⲉ0.
.type legacySelectionAssumingNLeM,@function
legacySelectionAssumingNLeM:
    jmp patchedSmallPick
.size legacySelectionAssumingNLeM,.-legacySelectionAssumingNLeM

# Ⲃⲁⲑⲙⲟⲥ 29 — PATCH 14
# ⲠlegacySelectionAssumingNLeM ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩscar. Ⲡdispatcher ⲙⲟⲟϣⲉ ⲉⲡshort path ⲉϣϫⲉ N<=M_OLD,
# ⲁⲩⲱ ⲉⲡwide detour ⲙⲙⲁⲧⲉ ⲉϣϫⲉ N>M_OLD. Ⲛdigits ⲥⲉϫⲓ ⲛⲟⲩⲥⲟⲡ ⲙⲙⲁⲧⲉ ϩⲙⲡanswer ring;
# ⲡrejection ⲙⲟⲟϣⲉ ϩⲓ ⲡcombined number ϩⲙⲡspace=M_OLD^places, ⲁⲛ ϩⲓ ⲟⲩnew digit read.
.type wideRingStepPatch14,@function
wideRingStepPatch14:
    # rdi=current BigInt*, rsi=step +/-1, rdx=space BigInt*. rax=next BigInt*.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Lwrsp14_fail
    test r14,r14
    je .Lwrsp14_fail
    cmp r13,1
    je .Lwrsp14_plus
    cmp r13,-1
    jne .Lwrsp14_fail

    mov rdi,r12
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lwrsp14_minus_plain
    mov rdi,r14
    call bi_clone
    jmp .Lwrsp14_done
.Lwrsp14_minus_plain:
    mov rdi,1
    call bi_from_u64
    test rax,rax
    je .Lwrsp14_fail
    mov rsi,rax
    mov rdi,r12
    call bi_sub
    jmp .Lwrsp14_done

.Lwrsp14_plus:
    mov rdi,r12
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lwrsp14_plus_plain
    mov rdi,1
    call bi_from_u64
    jmp .Lwrsp14_done
.Lwrsp14_plus_plain:
    mov rdi,r12
    mov rsi,1
    call bi_add_u64
    jmp .Lwrsp14_done

.Lwrsp14_fail:
    xor eax,eax
.Lwrsp14_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size wideRingStepPatch14,.-wideRingStepPatch14

.type wideDetour,@function
wideDetour:
    # rdi=LegacyAnswerRing*, rsi=N BigInt*.
    # rax=rank; rdx=accepted combined; rcx=places; r8=space; r9=limit; r10=initial combined; r11=rejection steps.
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,56
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lwd14_fail
    test r13,r13
    je .Lwd14_fail
    cmp qword ptr [r13+BI_SIGN],1
    jne .Lwd14_fail
    mov rdi,r13
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    jle .Lwd14_fail

    # ⲞⲩCOPY_DIAGNOSTIC: ⲡshort-only legacy scar ⲛϥϯ ⲁⲛ ⲛⲟⲩrank ϩⲓ wide N.
    mov rdi,r12
    mov rsi,r13
    call legacySelectionAssumingNLeM
    test rax,rax
    jne .Lwd14_fail

    # space=M_OLD^places, ⲙⲛ ⲡplaces ⲉϥⲥⲟⲃⲧⲉ ⲉⲧⲣⲉ space>=N.
    lea rdi,[rip+legacy_remainder_M]
    call bi_clone
    test rax,rax
    je .Lwd14_fail
    mov r14,rax
    mov ebx,1
.Lwd14_space_loop:
    mov rdi,r14
    mov rsi,r13
    call bi_cmp
    test eax,eax
    jge .Lwd14_space_done
    mov rdi,r14
    lea rsi,[rip+legacy_remainder_M]
    call bi_mul_abs
    test rax,rax
    je .Lwd14_fail
    mov r14,rax
    inc rbx
    jne .Lwd14_space_loop
    jmp .Lwd14_fail
.Lwd14_space_done:
    mov qword ptr [rbp-48],r14

    # combined=1; factor=1. Ⲡdigit ⲛposition k ⲡⲉ ringAnswer(k), ⲁⲩⲱ ⲡweight ⲡⲉ M_OLD^k.
    mov rdi,1
    call bi_from_u64
    test rax,rax
    je .Lwd14_fail
    mov r15,rax
    mov rdi,1
    call bi_from_u64
    test rax,rax
    je .Lwd14_fail
    mov qword ptr [rbp-56],rax
    xor ecx,ecx
.Lwd14_digit_loop:
    cmp rcx,rbx
    jae .Lwd14_digits_done
    mov qword ptr [rbp-64],rcx
    mov rdi,r12
    mov rsi,rcx
    call ringAnswer
    test rax,rax
    je .Lwd14_fail
    mov qword ptr [rbp-72],rax
    mov rdi,1
    call bi_from_u64
    test rax,rax
    je .Lwd14_fail
    mov rsi,rax
    mov rdi,qword ptr [rbp-72]
    call bi_sub
    test rax,rax
    je .Lwd14_fail
    mov rdi,rax
    mov rsi,qword ptr [rbp-56]
    call bi_mul_abs
    test rax,rax
    je .Lwd14_fail
    mov rsi,rax
    mov rdi,r15
    call bi_add_abs
    test rax,rax
    je .Lwd14_fail
    mov r15,rax
    mov rdi,qword ptr [rbp-56]
    lea rsi,[rip+legacy_remainder_M]
    call bi_mul_abs
    test rax,rax
    je .Lwd14_fail
    mov qword ptr [rbp-56],rax
    mov rcx,qword ptr [rbp-64]
    inc rcx
    jmp .Lwd14_digit_loop
.Lwd14_digits_done:
    mov qword ptr [rbp-80],r15
    # Ⲡfactor ⲙⲛ ⲡspace ϣⲉ ⲉⲧⲣⲉⲩⲧⲱⲛ.
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-48]
    call bi_cmp
    test eax,eax
    jne .Lwd14_fail

    # limit=floor(space/N)*N.
    mov rdi,qword ptr [rbp-48]
    mov rsi,r13
    call bi_divmod_abs
    test rax,rax
    je .Lwd14_fail
    mov rdi,rax
    mov rsi,r13
    call bi_mul_abs
    test rax,rax
    je .Lwd14_fail
    mov qword ptr [rbp-88],rax
    mov qword ptr [rbp-96],r15
    xor r11d,r11d

.Lwd14_reject:
    mov rdi,qword ptr [rbp-96]
    mov rsi,qword ptr [rbp-88]
    call bi_cmp
    test eax,eax
    jle .Lwd14_accept
    mov rdi,qword ptr [rbp-96]
    mov rsi,qword ptr [r12+S26_RING_STEP]
    mov rdx,qword ptr [rbp-48]
    call wideRingStepPatch14
    test rax,rax
    je .Lwd14_fail
    mov qword ptr [rbp-96],rax
    inc r11
    jne .Lwd14_reject
    jmp .Lwd14_fail

.Lwd14_accept:
    mov qword ptr [rbp-56],r11
    mov rdi,qword ptr [rbp-96]
    mov rsi,r13
    call biasedLegacyPick
    test rax,rax
    je .Lwd14_fail
    mov rdx,qword ptr [rbp-96]
    mov rcx,rbx
    mov r8,qword ptr [rbp-48]
    mov r9,qword ptr [rbp-88]
    mov r10,qword ptr [rbp-80]
    mov r11,qword ptr [rbp-56]
    jmp .Lwd14_done

.Lwd14_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    xor r10d,r10d
    xor r11d,r11d
.Lwd14_done:
    add rsp,56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size wideDetour,.-wideDetour

.type selectionPatch14,@function
selectionPatch14:
    # rdi=ring, rsi=N. Ⲡshort path ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡlegacy short wrapper.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lsp14_fail
    test r13,r13
    je .Lsp14_fail
    cmp qword ptr [r13+BI_SIGN],1
    jne .Lsp14_fail
    mov rdi,r13
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    jg .Lsp14_wide
    mov rdi,r12
    mov rsi,r13
    call legacySelectionAssumingNLeM
    jmp .Lsp14_done
.Lsp14_wide:
    mov rdi,r12
    mov rsi,r13
    call wideDetour
    jmp .Lsp14_done
.Lsp14_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    xor r10d,r10d
    xor r11d,r11d
.Lsp14_done:
    pop r13
    pop r12
    leave
    ret
.size selectionPatch14,.-selectionPatch14

.type monster_stage29_wide_patch_wrapper,@function
monster_stage29_wide_patch_wrapper:
    jmp selectionPatch14
.size monster_stage29_wide_patch_wrapper,.-monster_stage29_wide_patch_wrapper

.type monster_wide_selection_route,@function
monster_wide_selection_route:
    jmp monster_stage29_wide_patch_wrapper
.size monster_wide_selection_route,.-monster_wide_selection_route

.type monster_stage28_legacy_wide_assumption_handler,@function
monster_stage28_legacy_wide_assumption_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lms28_fail

    mov r13,qword ptr [r12+CTX_STAGE26_ANSWER_RING]
    test r13,r13
    je .Lms28_fail
    mov qword ptr [r12+CTX_STAGE28_WIDE_RING],r13

    lea rdi,[rip+legacy_remainder_M]
    mov rsi,1
    call bi_add_u64
    test rax,rax
    je .Lms28_fail
    mov r14,rax
    mov qword ptr [r12+CTX_STAGE28_WIDE_FAMILY_SIZE],r14
    mov qword ptr [r12+CTX_STAGE28_LEGACY_ASSUMED_SHORT],1

    # Ⲡlegacy scar ⲟⲩⲏϩ ⲉϥϯ null ϩⲓ N>M_OLD.
    mov rdi,r13
    mov rsi,r14
    call legacySelectionAssumingNLeM
    mov qword ptr [r12+CTX_STAGE28_LEGACY_RESULT],rax
    test rax,rax
    jne .Lms28_fail
    mov qword ptr [r12+CTX_STAGE28_LEGACY_UNSUPPORTED],1

    # Ⲡsemantic route ⲧⲉⲛⲟⲩ ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡPATCH 14.
    mov rdi,r13
    mov rsi,r14
    call monster_wide_selection_route
    test rax,rax
    je .Lms28_fail
    inc qword ptr [r12+CTX_STAGE28_ROUTE_SEEN]
    mov eax,1
    jmp .Lms28_done
.Lms28_fail:
    xor eax,eax
.Lms28_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage28_legacy_wide_assumption_handler,.-monster_stage28_legacy_wide_assumption_handler

.type monster_stage29_wide_patch_handler,@function
monster_stage29_wide_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lms29_fail
    mov r13,qword ptr [r12+CTX_STAGE28_WIDE_RING]
    mov r14,qword ptr [r12+CTX_STAGE28_WIDE_FAMILY_SIZE]
    test r13,r13
    je .Lms29_fail
    test r14,r14
    je .Lms29_fail
    mov rdi,r13
    mov rsi,r14
    call monster_wide_selection_route
    test rax,rax
    je .Lms29_fail
    mov qword ptr [r12+CTX_STAGE29_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_STAGE29_ACCEPTED_COMBINED],rdx
    mov qword ptr [r12+CTX_STAGE29_PLACES],rcx
    mov qword ptr [r12+CTX_STAGE29_SPACE],r8
    mov qword ptr [r12+CTX_STAGE29_ACCEPTANCE_LIMIT],r9
    mov qword ptr [r12+CTX_STAGE29_COMBINED_INITIAL],r10
    mov qword ptr [r12+CTX_STAGE29_REJECTION_STEPS],r11
    mov qword ptr [r12+CTX_STAGE29_USED_WIDE],1
    inc qword ptr [r12+CTX_STAGE29_PATCH_SEEN]
    mov eax,1
    jmp .Lms29_done
.Lms29_fail:
    xor eax,eax
.Lms29_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage29_wide_patch_handler,.-monster_stage29_wide_patch_handler


# Ⲃⲁⲑⲙⲟⲥ 30 — DISCOVERY 15
# Ⲡlegacy helper ϫⲓ ⲛⲟⲩn ⲉϥⲟ ⲛpositive magnitude ⲁⲩⲱ ⲛϥⲟⲩⲱϩ ⲙⲙⲟϥ ⲉⲡFOUNDATION.
# ⲠsignedStep ⲙⲡcaller ⲛϥϩⲁⲣⲉϩ ⲁⲛ ⲙⲡⲉϥsign: ⲛϥϫⲓ ⲙⲡabs(step) ⲉⲙⲡⲁⲧⲉ ⲡlegacy helper.
.type oldGateQuestionDay,@function
oldGateQuestionDay:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    test r12,r12
    je .Logqd_fail
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Logqd_fail
    mov rdi,rax
    mov rsi,r12
    call bi_add
    jmp .Logqd_done
.Logqd_fail:
    xor eax,eax
.Logqd_done:
    pop r12
    leave
    ret
.size oldGateQuestionDay,.-oldGateQuestionDay

.type legacyGateQuestionDayFromSignedStepWrong,@function
legacyGateQuestionDayFromSignedStepWrong:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    test r12,r12
    je .Llgqdfssw_fail
    mov rdi,r12
    call bi_abs
    test rax,rax
    je .Llgqdfssw_fail
    mov rdi,rax
    call oldGateQuestionDay
    jmp .Llgqdfssw_done
.Llgqdfssw_fail:
    xor eax,eax
.Llgqdfssw_done:
    pop r12
    leave
    ret
.size legacyGateQuestionDayFromSignedStepWrong,.-legacyGateQuestionDayFromSignedStepWrong

# Ⲃⲁⲑⲙⲟⲥ 31 — PATCH 15
# Ⲡlegacy path ⲟⲩⲏϩ ⲉϥⲙⲟⲩⲧⲉ ⲛⲟⲩⲙⲉ. Ⲉϣϫⲉ ⲡsignedStep ⲟ ⲛnegative, ⲡresult ⲛⲗⲉⲅⲁⲥⲓ ⲥⲏϩ ⲉⲃⲟⲗ ⲁⲩⲱ ⲁⲩⲕⲱ ⲉϫⲱϥ ⲙⲡFOUNDATION-abs(step).
.type gateQuestionDayPatch15,@function
gateQuestionDayPatch15:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lgqdp15_fail

    # COPY_DIAGNOSTIC: ⲡlegacy ⲙⲟⲩⲧⲉ ⲛⲟⲩⲙⲉ ϩⲓ signedStep ⲛⲓⲙ.
    mov rdi,r12
    call legacyGateQuestionDayFromSignedStepWrong
    test rax,rax
    je .Lgqdp15_fail
    mov r13,rax

    # Ⲛϥⲧⲱϣ ⲙⲡsign ⲙⲛ 0 ⲁϫⲛ ⲟⲩruntime ⲛϣⲙⲙⲟ.
    xor edi,edi
    call bi_from_i64
    test rax,rax
    je .Lgqdp15_fail
    mov rdi,r12
    mov rsi,rax
    call bi_cmp
    test eax,eax
    jge .Lgqdp15_legacy

    mov rdi,r12
    call bi_abs
    test rax,rax
    je .Lgqdp15_fail
    mov r14,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lgqdp15_fail
    mov rdi,rax
    mov rsi,r14
    call bi_sub
    test rax,rax
    je .Lgqdp15_fail
    jmp .Lgqdp15_done

.Lgqdp15_legacy:
    mov rax,r13
    jmp .Lgqdp15_done
.Lgqdp15_fail:
    xor eax,eax
.Lgqdp15_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size gateQuestionDayPatch15,.-gateQuestionDayPatch15

.type monster_stage31_gate_question_patch_wrapper,@function
monster_stage31_gate_question_patch_wrapper:
    jmp gateQuestionDayPatch15
.size monster_stage31_gate_question_patch_wrapper,.-monster_stage31_gate_question_patch_wrapper

.type monster_gate_question_day_route,@function
monster_gate_question_day_route:
    jmp monster_stage31_gate_question_patch_wrapper
.size monster_gate_question_day_route,.-monster_gate_question_day_route

.type monster_stage30_legacy_gate_question_handler,@function
monster_stage30_legacy_gate_question_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms30_fail

    mov rdi,qword ptr [r12+CTX_TARGET_DAY]
    call bi_from_i64
    test rax,rax
    je .Lms30_fail
    mov r13,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lms30_fail
    mov rsi,rax
    mov rdi,r13
    call bi_sub
    test rax,rax
    je .Lms30_fail
    mov r14,rax
    mov qword ptr [r12+CTX_STAGE30_SIGNED_STEP],r14

    mov rdi,r14
    call bi_abs
    test rax,rax
    je .Lms30_fail
    mov r15,rax
    mov qword ptr [r12+CTX_STAGE30_ABS_STEP],r15

    mov rdi,r15
    call oldGateQuestionDay
    test rax,rax
    je .Lms30_fail
    mov qword ptr [r12+CTX_STAGE30_LEGACY_RESULT],rax
    inc qword ptr [r12+CTX_STAGE30_LEGACY_SEEN]

    mov rdi,r14
    call monster_gate_question_day_route
    test rax,rax
    je .Lms30_fail
    mov qword ptr [r12+CTX_STAGE30_ROUTE_RESULT],rax
    inc qword ptr [r12+CTX_STAGE30_ROUTE_SEEN]

    mov eax,1
    jmp .Lms30_done
.Lms30_fail:
    xor eax,eax
.Lms30_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage30_legacy_gate_question_handler,.-monster_stage30_legacy_gate_question_handler


.type monster_stage31_gate_question_patch_handler,@function
monster_stage31_gate_question_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    test r12,r12
    je .Lms31_fail
    mov rdi,qword ptr [r12+CTX_STAGE30_SIGNED_STEP]
    test rdi,rdi
    je .Lms31_fail
    call monster_gate_question_day_route
    test rax,rax
    je .Lms31_fail
    mov qword ptr [r12+CTX_STAGE31_PATCHED_RESULT],rax
    inc qword ptr [r12+CTX_STAGE31_PATCH_SEEN]
    mov eax,1
    jmp .Lms31_done
.Lms31_fail:
    xor eax,eax
.Lms31_done:
    pop r12
    leave
    ret
.size monster_stage31_gate_question_patch_handler,.-monster_stage31_gate_question_patch_handler


# Ⲃⲁⲑⲙⲟⲥ 32 — DISCOVERY 16
# Ⲡlegacy ⲟⲩⲏϩ ⲉϥϩⲁⲣⲉϩ ⲉⲡyear maximum ⲛ5781. Ⲡcandidate predicate ⲟⲩⲱⲛϩ ⲛⲟⲩⲙⲉ ϩⲙⲡroute ⲁⲩⲱ ⲛϥϫⲓ ⲛ5779,5780,5781 ⲉϩⲟⲩⲛ ⲉⲡfamily.
.type oldYearCandidate,@function
oldYearCandidate:
    cmp rdi,6
    jb .Loyc_no
    cmp rsi,252
    jb .Loyc_no
    cmp rsi,LEGACY_YEAR_MAX
    ja .Loyc_no
    mov eax,1
    ret
.Loyc_no:
    xor eax,eax
    ret
.size oldYearCandidate,.-oldYearCandidate

.type yearCandidateAfterFootnotePatch,@function
yearCandidateAfterFootnotePatch:
    push rbp
    mov rbp,rsp
    sub rsp,16
    mov qword ptr [rbp-8],rsi
    call oldYearCandidate
    test eax,eax
    je .Lycafp_no
    mov rsi,qword ptr [rbp-8]
    cmp rsi,REAL_YEAR_MAX_PATCH
    ja .Lycafp_no
    mov eax,1
    leave
    ret
.Lycafp_no:
    xor eax,eax
    leave
    ret
.size yearCandidateAfterFootnotePatch,.-yearCandidateAfterFootnotePatch

# Ⲡraw family ⲙⲡlegacy ⲟⲩⲏϩ ⲉϥⲙⲟⲩⲧⲉ ⲉ oldYearCandidate ⲛⲟⲩⲙⲉ.
.type legacyYearCandidatesBeforeSortStage33,@function
legacyYearCandidatesBeforeSortStage33:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    xor r15d,r15d
    xor ebx,ebx
.Llycbs33_loop:
    cmp r15,r13
    jae .Llycbs33_done
    lea r10,[r15+r15*2]
    lea r10,[r12+r10*8]
    mov rdi,qword ptr [r10+YC_CLOSE]
    sub rdi,qword ptr [r10+YC_OPEN]
    mov rsi,qword ptr [r10+YC_LENGTH]
    call oldYearCandidate
    test eax,eax
    je .Llycbs33_next
    lea r10,[r15+r15*2]
    lea r10,[r12+r10*8]
    lea r11,[rbx+rbx*2]
    lea r11,[r14+r11*8]
    mov rax,qword ptr [r10+YC_OPEN]
    mov qword ptr [r11+YC_OPEN],rax
    mov rax,qword ptr [r10+YC_CLOSE]
    mov qword ptr [r11+YC_CLOSE],rax
    mov rax,qword ptr [r10+YC_LENGTH]
    mov qword ptr [r11+YC_LENGTH],rax
    inc rbx
.Llycbs33_next:
    inc r15
    jmp .Llycbs33_loop
.Llycbs33_done:
    mov rax,rbx
    add rsp,8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size legacyYearCandidatesBeforeSortStage33,.-legacyYearCandidatesBeforeSortStage33

# Ⲡfootnote filter ⲙⲟⲟϣⲉ ⲙⲛⲛⲥⲁ ⲡlegacy acceptance ⲁⲩⲱ ⲉⲙⲡⲁⲧⲉ ⲡsort.
.type yearCandidatesAfterFootnotePatchBeforeSort,@function
yearCandidatesAfterFootnotePatchBeforeSort:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    xor r15d,r15d
    xor ebx,ebx
.Lycafpbs_loop:
    cmp r15,r13
    jae .Lycafpbs_done
    lea r10,[r15+r15*2]
    lea r10,[r12+r10*8]
    mov rdi,qword ptr [r10+YC_CLOSE]
    sub rdi,qword ptr [r10+YC_OPEN]
    mov rsi,qword ptr [r10+YC_LENGTH]
    call yearCandidateAfterFootnotePatch
    test eax,eax
    je .Lycafpbs_next
    lea r10,[r15+r15*2]
    lea r10,[r12+r10*8]
    lea r11,[rbx+rbx*2]
    lea r11,[r14+r11*8]
    mov rax,qword ptr [r10+YC_OPEN]
    mov qword ptr [r11+YC_OPEN],rax
    mov rax,qword ptr [r10+YC_CLOSE]
    mov qword ptr [r11+YC_CLOSE],rax
    mov rax,qword ptr [r10+YC_LENGTH]
    mov qword ptr [r11+YC_LENGTH],rax
    inc rbx
.Lycafpbs_next:
    inc r15
    jmp .Lycafpbs_loop
.Lycafpbs_done:
    mov rax,rbx
    add rsp,8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size yearCandidatesAfterFootnotePatchBeforeSort,.-yearCandidatesAfterFootnotePatchBeforeSort

# Ⲡsort ⲟⲩⲏϩ stable ⲕⲁⲧⲁ ⲡlength ⲙⲙⲁⲧⲉ. Ⲙⲛ tie repair.
.type stableLengthOnlyPatchedYearCandidates,@function
stableLengthOnlyPatchedYearCandidates:
    mov r8,rdx
    mov r9,rsi
    xor ecx,ecx
.Lslopyc_copy:
    cmp rcx,r9
    jae .Lslopyc_sort_start
    lea r10,[rcx+rcx*2]
    lea r11,[rdi+r10*8]
    lea r10,[r8+r10*8]
    mov rax,qword ptr [r11+YC_OPEN]
    mov qword ptr [r10+YC_OPEN],rax
    mov rax,qword ptr [r11+YC_CLOSE]
    mov qword ptr [r10+YC_CLOSE],rax
    mov rax,qword ptr [r11+YC_LENGTH]
    mov qword ptr [r10+YC_LENGTH],rax
    inc rcx
    jmp .Lslopyc_copy
.Lslopyc_sort_start:
    cmp r9,2
    jb .Lslopyc_done
    mov r10,r9
    dec r10
.Lslopyc_outer:
    xor r11d,r11d
    xor edx,edx
.Lslopyc_inner:
    cmp r11,r10
    jae .Lslopyc_after_inner
    lea rax,[r11+r11*2]
    lea rax,[r8+rax*8]
    lea rcx,[rax+YC_SIZE]
    mov rsi,qword ptr [rax+YC_LENGTH]
    cmp rsi,qword ptr [rcx+YC_LENGTH]
    jbe .Lslopyc_noswap
    mov rsi,qword ptr [rax+YC_OPEN]
    mov rdi,qword ptr [rcx+YC_OPEN]
    mov qword ptr [rax+YC_OPEN],rdi
    mov qword ptr [rcx+YC_OPEN],rsi
    mov rsi,qword ptr [rax+YC_CLOSE]
    mov rdi,qword ptr [rcx+YC_CLOSE]
    mov qword ptr [rax+YC_CLOSE],rdi
    mov qword ptr [rcx+YC_CLOSE],rsi
    mov rsi,qword ptr [rax+YC_LENGTH]
    mov rdi,qword ptr [rcx+YC_LENGTH]
    mov qword ptr [rax+YC_LENGTH],rdi
    mov qword ptr [rcx+YC_LENGTH],rsi
    mov edx,1
.Lslopyc_noswap:
    inc r11
    jmp .Lslopyc_inner
.Lslopyc_after_inner:
    test edx,edx
    je .Lslopyc_done
    dec r10
    test r10,r10
    jne .Lslopyc_outer
.Lslopyc_done:
    mov rax,r9
    ret
.size stableLengthOnlyPatchedYearCandidates,.-stableLengthOnlyPatchedYearCandidates

.type legacyYearSelectFirst,@function
legacyYearSelectFirst:
    test rdi,rdi
    je .Llysf_no
    test rsi,rsi
    je .Llysf_no
    mov rax,rdi
    ret
.Llysf_no:
    xor eax,eax
    ret
.size legacyYearSelectFirst,.-legacyYearSelectFirst

.type monster_stage33_year_ceiling_patch_wrapper,@function
monster_stage33_year_ceiling_patch_wrapper:
    jmp yearCandidateAfterFootnotePatch
.size monster_stage33_year_ceiling_patch_wrapper,.-monster_stage33_year_ceiling_patch_wrapper

.type monster_year_candidate_route,@function
monster_year_candidate_route:
    jmp monster_stage33_year_ceiling_patch_wrapper
.size monster_year_candidate_route,.-monster_year_candidate_route

.type monster_stage32_legacy_year_max_handler,@function
monster_stage32_legacy_year_max_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    test r12,r12
    je .Lms32_fail
    mov qword ptr [r12+CTX_STAGE32_LEGACY_YEAR_MAX_OBSERVED],LEGACY_YEAR_MAX
    xor r13d,r13d

    mov edi,6
    mov esi,5778
    call oldYearCandidate
    test eax,eax
    je .Lms32_next_5779
    or r13,1
.Lms32_next_5779:
    mov edi,6
    mov esi,5779
    call oldYearCandidate
    test eax,eax
    je .Lms32_next_5780
    or r13,2
.Lms32_next_5780:
    mov edi,6
    mov esi,5780
    call oldYearCandidate
    test eax,eax
    je .Lms32_next_5781
    or r13,4
.Lms32_next_5781:
    mov edi,6
    mov esi,5781
    call oldYearCandidate
    test eax,eax
    je .Lms32_store
    or r13,8
.Lms32_store:
    mov qword ptr [r12+CTX_STAGE32_CANDIDATE_MASK],r13
    inc qword ptr [r12+CTX_STAGE32_LEGACY_SEEN]
    mov eax,1
    jmp .Lms32_done
.Lms32_fail:
    xor eax,eax
.Lms32_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage32_legacy_year_max_handler,.-monster_stage32_legacy_year_max_handler

# Ⲃⲁⲑⲙⲟⲥ 33 — PATCH 16
# Ⲡlegacy family ⲟⲩⲏϩ raw. Ⲡ5778 footnote filter ⲙⲟⲟϣⲉ ⲉⲙⲡⲁⲧⲉ ⲡstable sort ⲙⲛ ⲡselection.
.type monster_stage33_year_ceiling_patch_handler,@function
monster_stage33_year_ceiling_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lms33_fail
    mov qword ptr [r12+CTX_STAGE33_REAL_YEAR_MAX_OBSERVED],REAL_YEAR_MAX_PATCH

    mov edi,96
    call arena_alloc
    mov r13,rax
    mov qword ptr [r13+0],40
    mov qword ptr [r13+8],46
    mov qword ptr [r13+16],5781
    mov qword ptr [r13+24],20
    mov qword ptr [r13+32],26
    mov qword ptr [r13+40],5779
    mov qword ptr [r13+48],10
    mov qword ptr [r13+56],16
    mov qword ptr [r13+64],5778
    mov qword ptr [r13+72],30
    mov qword ptr [r13+80],36
    mov qword ptr [r13+88],5780

    mov edi,96
    call arena_alloc
    mov r14,rax
    mov rdi,r13
    mov esi,4
    mov rdx,r14
    call legacyYearCandidatesBeforeSortStage33
    mov qword ptr [r12+CTX_STAGE33_LEGACY_RAW_COUNT],rax

    mov edi,96
    call arena_alloc
    mov r15,rax
    mov rdi,r13
    mov esi,4
    mov rdx,r15
    call yearCandidatesAfterFootnotePatchBeforeSort
    mov qword ptr [r12+CTX_STAGE33_FILTERED_PRE_SORT_COUNT],rax
    mov rcx,qword ptr [r12+CTX_STAGE33_LEGACY_RAW_COUNT]
    sub rcx,rax
    mov qword ptr [r12+CTX_STAGE33_REJECTED_BEFORE_SORT_COUNT],rcx

    mov edi,96
    call arena_alloc
    mov rbx,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+CTX_STAGE33_FILTERED_PRE_SORT_COUNT]
    mov rdx,rbx
    call stableLengthOnlyPatchedYearCandidates
    mov qword ptr [r12+CTX_STAGE33_SORTED_COUNT],rax

    mov rdi,rbx
    mov rsi,rax
    call legacyYearSelectFirst
    test rax,rax
    je .Lms33_fail
    mov qword ptr [r12+CTX_STAGE33_SELECTION_CALLED],1
    mov rcx,qword ptr [rax+YC_LENGTH]
    mov qword ptr [r12+CTX_STAGE33_SELECTED_LENGTH],rcx
    inc qword ptr [r12+CTX_STAGE33_PATCH_SEEN]
    mov eax,1
    jmp .Lms33_done
.Lms33_fail:
    xor eax,eax
.Lms33_done:
    add rsp,8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage33_year_ceiling_patch_handler,.-monster_stage33_year_ceiling_patch_handler


# Ⲃⲁⲑⲙⲟⲥ 34 — DISCOVERY 17
# Ⲡlegacy stable sort ⲕⲁⲧⲁ ⲡlength ⲙⲙⲁⲧⲉ ϩⲁⲣⲉϩ ⲉⲡinput order ϩⲙⲡequal-length run ⲙⲡYear 5000.
.type legacyYear5000TieSelection,@function
legacyYear5000TieSelection:
    push rbp
    mov rbp,rsp
    sub rsp,32
    mov qword ptr [rbp-8],rdx
    call stableLengthOnlyPatchedYearCandidates
    mov rdi,qword ptr [rbp-8]
    mov rsi,rax
    call legacyYearSelectFirst
    leave
    ret
.size legacyYear5000TieSelection,.-legacyYear5000TieSelection

.type monster_stage34_legacy_year5000_tie_wrapper,@function
monster_stage34_legacy_year5000_tie_wrapper:
    jmp legacyYear5000TieSelection
.size monster_stage34_legacy_year5000_tie_wrapper,.-monster_stage34_legacy_year5000_tie_wrapper

.type monster_year5000_tie_route,@function
monster_year5000_tie_route:
    jmp monster_stage35_year5000_tie_patch_wrapper
.size monster_year5000_tie_route,.-monster_year5000_tie_route

# Ⲃⲁⲑⲙⲟⲥ 35 — PATCH 17
# Ⲙⲛⲛⲥⲁ ⲡstable length-only sort, ⲛequal-length run ⲙⲙⲁⲧⲉ ⲥⲉsort ⲕⲁⲧⲁ ⲡopening gate ⲉϥϣⲟⲣⲡ.
.type reorderEqualLengthRunsByOpeningAfterLegacySort,@function
reorderEqualLengthRunsByOpeningAfterLegacySort:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
.Lrelr_scan_run:
    cmp r14,r13
    jae .Lrelr_done
    mov r15,r14
    inc r15
.Lrelr_find_end:
    cmp r15,r13
    jae .Lrelr_have_end
    lea rax,[r14+r14*2]
    lea rax,[r12+rax*8]
    mov rcx,qword ptr [rax+YC_LENGTH]
    lea rdx,[r15+r15*2]
    lea rdx,[r12+rdx*8]
    cmp rcx,qword ptr [rdx+YC_LENGTH]
    jne .Lrelr_have_end
    inc r15
    jmp .Lrelr_find_end
.Lrelr_have_end:
    mov rax,r15
    sub rax,r14
    cmp rax,2
    jb .Lrelr_next_run
    mov rbx,r15
    dec rbx
.Lrelr_outer:
    mov r10,r14
    xor r11d,r11d
.Lrelr_inner:
    cmp r10,rbx
    jae .Lrelr_after_inner
    lea rax,[r10+r10*2]
    lea rax,[r12+rax*8]
    lea rcx,[rax+YC_SIZE]
    mov rdx,qword ptr [rax+YC_OPEN]
    cmp rdx,qword ptr [rcx+YC_OPEN]
    jle .Lrelr_no_swap
    mov rdx,qword ptr [rax+YC_OPEN]
    mov rsi,qword ptr [rcx+YC_OPEN]
    mov qword ptr [rax+YC_OPEN],rsi
    mov qword ptr [rcx+YC_OPEN],rdx
    mov rdx,qword ptr [rax+YC_CLOSE]
    mov rsi,qword ptr [rcx+YC_CLOSE]
    mov qword ptr [rax+YC_CLOSE],rsi
    mov qword ptr [rcx+YC_CLOSE],rdx
    mov rdx,qword ptr [rax+YC_LENGTH]
    mov rsi,qword ptr [rcx+YC_LENGTH]
    mov qword ptr [rax+YC_LENGTH],rsi
    mov qword ptr [rcx+YC_LENGTH],rdx
    mov r11d,1
.Lrelr_no_swap:
    inc r10
    jmp .Lrelr_inner
.Lrelr_after_inner:
    test r11d,r11d
    je .Lrelr_next_run
    dec rbx
    cmp rbx,r14
    ja .Lrelr_outer
.Lrelr_next_run:
    mov r14,r15
    jmp .Lrelr_scan_run
.Lrelr_done:
    mov rax,r13
    add rsp,8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size reorderEqualLengthRunsByOpeningAfterLegacySort,.-reorderEqualLengthRunsByOpeningAfterLegacySort

# Ⲡlegacy selector ⲙⲟⲟϣⲉ ⲛϣⲟⲣⲡ ϩⲓ ⲡbuffer ⲛⲧⲟϣ; ⲙⲛⲛⲥⲱϥ ⲙⲙⲁⲧⲉ ⲡequal-run repair ⲙⲟⲟϣⲉ.
.type year5000TieSelectionPatch17,@function
year5000TieSelectionPatch17:
    push rbp
    mov rbp,rsp
    sub rsp,32
    mov qword ptr [rbp-8],rsi
    mov qword ptr [rbp-16],rdx
    call legacyYear5000TieSelection
    test rax,rax
    je .Ly5tsp17_no
    mov rdi,qword ptr [rbp-16]
    mov rsi,qword ptr [rbp-8]
    call reorderEqualLengthRunsByOpeningAfterLegacySort
    mov rdi,qword ptr [rbp-16]
    mov rsi,qword ptr [rbp-8]
    call legacyYearSelectFirst
    leave
    ret
.Ly5tsp17_no:
    xor eax,eax
    leave
    ret
.size year5000TieSelectionPatch17,.-year5000TieSelectionPatch17

.type monster_stage35_year5000_tie_patch_wrapper,@function
monster_stage35_year5000_tie_patch_wrapper:
    jmp year5000TieSelectionPatch17
.size monster_stage35_year5000_tie_patch_wrapper,.-monster_stage35_year5000_tie_patch_wrapper

.type monster_stage34_legacy_year5000_tie_handler,@function
monster_stage34_legacy_year5000_tie_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms34_fail
    mov qword ptr [r12+CTX_STAGE34_YEAR_NUMBER],5000
    mov qword ptr [r12+CTX_STAGE34_TIE_LENGTH],490
    mov qword ptr [r12+CTX_STAGE34_TIE_COUNT],2

    mov edi,48
    call arena_alloc
    mov r13,rax
    mov qword ptr [r13+0],9
    mov qword ptr [r13+8],15
    mov qword ptr [r13+16],490
    mov qword ptr [r13+24],3
    mov qword ptr [r13+32],9
    mov qword ptr [r13+40],490

    mov edi,48
    call arena_alloc
    mov r14,rax
    mov rdi,r13
    mov esi,2
    mov rdx,r14
    call legacyYear5000TieSelection
    test rax,rax
    je .Lms34_fail
    mov rcx,qword ptr [rax+YC_OPEN]
    mov qword ptr [r12+CTX_STAGE34_LEGACY_SELECTED_OPEN],rcx
    inc qword ptr [r12+CTX_STAGE34_LEGACY_SEEN]

    mov edi,48
    call arena_alloc
    mov r15,rax
    mov rdi,r13
    mov esi,2
    mov rdx,r15
    call monster_year5000_tie_route
    test rax,rax
    je .Lms34_fail
    mov rcx,qword ptr [rax+YC_OPEN]
    mov qword ptr [r12+CTX_STAGE34_ROUTE_SELECTED_OPEN],rcx
    inc qword ptr [r12+CTX_STAGE34_ROUTE_SEEN]
    mov eax,1
    jmp .Lms34_done
.Lms34_fail:
    xor eax,eax
.Lms34_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage34_legacy_year5000_tie_handler,.-monster_stage34_legacy_year5000_tie_handler

# ⲠPATCH 17 handler ϩⲁⲣⲉϩ ⲉⲡsemantic selected opening ⲛⲧⲉⲡsame Year 5000 tie.
.type monster_stage35_year5000_tie_patch_handler,@function
monster_stage35_year5000_tie_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    test r12,r12
    je .Lms35_fail
    mov edi,48
    call arena_alloc
    mov r13,rax
    mov qword ptr [r13+0],9
    mov qword ptr [r13+8],15
    mov qword ptr [r13+16],490
    mov qword ptr [r13+24],3
    mov qword ptr [r13+32],9
    mov qword ptr [r13+40],490
    mov edi,48
    call arena_alloc
    mov r14,rax
    mov rdi,r13
    mov esi,2
    mov rdx,r14
    call monster_year5000_tie_route
    test rax,rax
    je .Lms35_fail
    mov rcx,qword ptr [rax+YC_OPEN]
    mov qword ptr [r12+CTX_STAGE35_PATCH_SELECTED_OPEN],rcx
    inc qword ptr [r12+CTX_STAGE35_PATCH_SEEN]
    mov eax,1
    jmp .Lms35_done
.Lms35_fail:
    xor eax,eax
.Lms35_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage35_year5000_tie_patch_handler,.-monster_stage35_year5000_tie_patch_handler


# Ⲡold jump ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡ365 ⲛⲟⲩlongore ⲛyear ⲉϥⲧⲁϫⲣⲏⲩ; ⲡfloor division ⲛⲧⲟϥ ⲟ ⲛexact ⲙⲛ negative delta.
.type oldJumpGuess,@function
oldJumpGuess:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lojg_fail
    test r13,r13
    je .Lojg_fail
    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_FIRST_DAY]
    call bi_sub
    mov r14,rax
    mov rdi,r14
    call bi_abs
    mov rdi,rax
    mov esi,365
    call bi_divmod_u64_abs
    mov rbx,rax
    mov qword ptr [rsp],rdx
    cmp qword ptr [r14+BI_SIGN],0
    jge .Lojg_have_floor
    cmp qword ptr [rsp],0
    je .Lojg_negate
    mov rdi,rbx
    mov esi,1
    call bi_add_u64
    mov rbx,rax
.Lojg_negate:
    mov rdi,rbx
    call bi_neg
    mov rbx,rax
.Lojg_have_floor:
    mov rdi,qword ptr [r12+YJ_NUMBER]
    mov rsi,rbx
    call bi_add
    jmp .Lojg_done
.Lojg_fail:
    xor eax,eax
.Lojg_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oldJumpGuess,.-oldJumpGuess

# Ⲡanchor ⲙⲡDISCOVERY 18 ⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙⲡpatched Year-5000 tie path; ⲡlength ⲙⲡselected candidate ⲡⲉ ⲡyear span ⲙⲡprobe.
.type stage36Year5000JumpAnchorFromPatchedTie,@function
stage36Year5000JumpAnchorFromPatchedTie:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov edi,48
    call arena_alloc
    mov r12,rax
    mov qword ptr [r12+0],9
    mov qword ptr [r12+8],15
    mov qword ptr [r12+16],490
    mov qword ptr [r12+24],3
    mov qword ptr [r12+32],9
    mov qword ptr [r12+40],490
    mov edi,48
    call arena_alloc
    mov r13,rax
    mov rdi,r12
    mov esi,2
    mov rdx,r13
    call monster_year5000_tie_route
    test rax,rax
    je .Ls36a_fail
    mov r14,qword ptr [rax+YC_LENGTH]
    cmp r14,252
    jb .Ls36a_fail
    cmp r14,REAL_YEAR_MAX_PATCH
    ja .Ls36a_fail
    mov edi,YJ_SIZE
    call arena_alloc
    mov r15,rax
    mov edi,5000
    call bi_from_u64
    mov qword ptr [r15+YJ_NUMBER],rax
    mov rdi,-15055671
    call bi_from_i64
    mov qword ptr [r15+YJ_OPEN_DAY],rax
    mov rdi,rax
    mov esi,1
    call bi_add_u64
    mov qword ptr [r15+YJ_FIRST_DAY],rax
    mov rdi,qword ptr [r15+YJ_OPEN_DAY]
    mov rsi,r14
    call bi_add_u64
    mov qword ptr [r15+YJ_CLOSE_DAY],rax
    mov rax,r15
    jmp .Ls36a_done
.Ls36a_fail:
    xor eax,eax
.Ls36a_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage36Year5000JumpAnchorFromPatchedTie,.-stage36Year5000JumpAnchorFromPatchedTie

# Ⲡadapter ⲙⲟⲩⲧⲉ ⲉⲡlegacy jump ⲛⲟⲩⲙⲉ; ⲙⲛ sequential walk ⲉϥϣⲟⲟⲡ ϩⲙⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ.
.type legacyYearJumpAdapter,@function
legacyYearJumpAdapter:
    jmp oldJumpGuess
.size legacyYearJumpAdapter,.-legacyYearJumpAdapter

# Ⲃⲁⲑⲙⲟⲥ 37 — PATCH 18
# ⲠoldJumpGuess ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲛⲟⲩtelemetry scar. Ⲡsemantic path ⲛϥϫⲓ ⲁⲛ ⲙⲡguess;
# ⲛϥⲙⲟⲟϣⲉ ⲉⲃⲟⲗ ϩⲙⲡYear 5000 ⲛⲟⲩyear ⲛⲟⲩyear, ⲙⲛⲟⲩtransition ⲛⲟⲩⲱⲧ ϩⲓ ⲧⲉⲓⲟⲩⲟⲉⲓϣ.
.type patchedNextYear,@function
patchedNextYear:
    # rdi=known YJ*, rax=new YJ*. Ⲡtransition span ⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙⲡknown interval ⲙⲡstaged Year model.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lpny_fail
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_sub
    test rax,rax
    je .Lpny_fail
    cmp qword ptr [rax+BI_SIGN],1
    jne .Lpny_fail
    mov r13,rax
    mov edi,YJ_SIZE
    call arena_alloc
    test rax,rax
    je .Lpny_fail
    mov r14,rax
    mov rdi,qword ptr [r12+YJ_NUMBER]
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Lpny_fail
    mov qword ptr [r14+YJ_NUMBER],rax
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    call bi_clone
    test rax,rax
    je .Lpny_fail
    mov qword ptr [r14+YJ_OPEN_DAY],rax
    mov rdi,rax
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Lpny_fail
    mov qword ptr [r14+YJ_FIRST_DAY],rax
    mov rdi,qword ptr [r14+YJ_OPEN_DAY]
    mov rsi,r13
    call bi_add
    test rax,rax
    je .Lpny_fail
    mov qword ptr [r14+YJ_CLOSE_DAY],rax
    mov rax,r14
    jmp .Lpny_done
.Lpny_fail:
    xor eax,eax
.Lpny_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size patchedNextYear,.-patchedNextYear

.type patchedPreviousYear,@function
patchedPreviousYear:
    # rdi=known YJ*, rax=new YJ*. Ⲡopen gate ⲛⲧⲉⲡknown year ⲟ ⲛclose gate ⲙⲡprevious year.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lppy_fail
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_sub
    test rax,rax
    je .Lppy_fail
    cmp qword ptr [rax+BI_SIGN],1
    jne .Lppy_fail
    mov r13,rax
    mov edi,YJ_SIZE
    call arena_alloc
    test rax,rax
    je .Lppy_fail
    mov r14,rax
    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r12+YJ_NUMBER]
    call bi_sub
    test rax,rax
    je .Lppy_fail
    mov qword ptr [r14+YJ_NUMBER],rax
    mov rdi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_clone
    test rax,rax
    je .Lppy_fail
    mov qword ptr [r14+YJ_CLOSE_DAY],rax
    mov rsi,r13
    mov rdi,rax
    call bi_sub
    test rax,rax
    je .Lppy_fail
    mov qword ptr [r14+YJ_OPEN_DAY],rax
    mov rdi,rax
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Lppy_fail
    mov qword ptr [r14+YJ_FIRST_DAY],rax
    mov rax,r14
    jmp .Lppy_done
.Lppy_fail:
    xor eax,eax
.Lppy_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size patchedPreviousYear,.-patchedPreviousYear

.type findYearByWalkPatch,@function
findYearByWalkPatch:
    # rdi=Year-5000 anchor YJ*, rsi=target BigInt*.
    # rax=semantic year-number BigInt*, rdx=final YJ*, rcx=forward steps, r8=backward steps, r9=legacy telemetry guess.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lfywp_fail
    test r13,r13
    je .Lfywp_fail

    # Ⲡscar /365 ⲙⲟⲟϣⲉ ⲛⲟⲩⲙⲉ ⲁⲩⲱ ⲡresult ⲥⲏϩ ⲙⲙⲁⲧⲉ ϩⲙ telemetry.
    mov rdi,r12
    mov rsi,r13
    call oldJumpGuess
    test rax,rax
    je .Lfywp_fail
    mov qword ptr [rbp-40],rax
    mov r14,r12
    xor r15d,r15d
    mov qword ptr [rbp-48],0

.Lfywp_forward:
    mov rdi,r13
    mov rsi,qword ptr [r14+YJ_CLOSE_DAY]
    call bi_cmp
    test eax,eax
    jle .Lfywp_backward
    mov rdi,r14
    call patchedNextYear
    test rax,rax
    je .Lfywp_fail
    mov r14,rax
    inc r15
    jne .Lfywp_forward
    jmp .Lfywp_fail

.Lfywp_backward:
    mov rdi,r13
    mov rsi,qword ptr [r14+YJ_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jg .Lfywp_found
    mov rdi,r14
    call patchedPreviousYear
    test rax,rax
    je .Lfywp_fail
    mov r14,rax
    inc qword ptr [rbp-48]
    jne .Lfywp_backward
    jmp .Lfywp_fail

.Lfywp_found:
    mov rax,qword ptr [r14+YJ_NUMBER]
    mov rdx,r14
    mov rcx,r15
    mov r8,qword ptr [rbp-48]
    mov r9,qword ptr [rbp-40]
    jmp .Lfywp_done
.Lfywp_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
.Lfywp_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size findYearByWalkPatch,.-findYearByWalkPatch

.type monster_stage37_year_walk_patch_wrapper,@function
monster_stage37_year_walk_patch_wrapper:
    jmp findYearByWalkPatch
.size monster_stage37_year_walk_patch_wrapper,.-monster_stage37_year_walk_patch_wrapper

.type monster_year_jump_route,@function
monster_year_jump_route:
    jmp monster_stage37_year_walk_patch_wrapper
.size monster_year_jump_route,.-monster_year_jump_route

# ⲠDISCOVERY 18 handler ⲕⲱ ⲙⲡguess /365 ⲛⲧⲟϥ ⲉⲣⲟϥ ⲛsemantic year number, ⲉⲧⲃⲉ ϫⲉ ⲡtarget ⲟⲩⲏϩ ϩⲙⲡanchor interval.
.type monster_stage36_legacy_year_jump_handler,@function
monster_stage36_legacy_year_jump_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms36_fail
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lms36_fail
    mov r13,rax
    mov qword ptr [r12+CTX_STAGE36_ANCHOR],r13
    mov rdi,qword ptr [r13+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    mov r14,rax
    mov qword ptr [r12+CTX_STAGE36_TARGET_DAY],r14
    mov rdi,r14
    mov rsi,qword ptr [r13+YJ_FIRST_DAY]
    call bi_sub
    mov qword ptr [r12+CTX_STAGE36_DELTA_FROM_FIRST],rax
    mov rdi,r13
    mov rsi,r14
    call oldJumpGuess
    test rax,rax
    je .Lms36_fail
    mov qword ptr [r12+CTX_STAGE36_LEGACY_GUESS],rax
    inc qword ptr [r12+CTX_STAGE36_LEGACY_SEEN]
    mov rdi,r13
    mov rsi,r14
    call monster_year_jump_route
    test rax,rax
    je .Lms36_fail
    mov qword ptr [r12+CTX_STAGE36_ROUTE_GUESS],rax
    inc qword ptr [r12+CTX_STAGE36_ROUTE_SEEN]
    mov qword ptr [r12+CTX_STAGE36_GUESS_USED_AS_SEMANTIC],1
    mov rdi,qword ptr [r13+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r13+YJ_OPEN_DAY]
    call bi_sub
    mov r15,rax
    mov rax,qword ptr [r15+BI_DATA]
    test rax,rax
    je .Lms36_fail
    mov rax,qword ptr [rax]
    mov qword ptr [r12+CTX_STAGE36_ANCHOR_LENGTH],rax
    mov eax,1
    jmp .Lms36_done
.Lms36_fail:
    xor eax,eax
.Lms36_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage36_legacy_year_jump_handler,.-monster_stage36_legacy_year_jump_handler


# ⲠPATCH 18 handler ϩⲁⲣⲉϩ ⲉⲡold guess ⲛtelemetry ⲁⲩⲱ ⲉⲡyear ⲉⲧⲁⲩϭⲓⲛⲉϥ ϩⲓⲧⲛ ⲡsequential walk.
.type monster_stage37_year_walk_patch_handler,@function
monster_stage37_year_walk_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms37_fail
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lms37_fail
    mov r13,rax
    mov rdi,qword ptr [r13+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    test rax,rax
    je .Lms37_fail
    mov r14,rax
    mov qword ptr [r12+CTX_STAGE37_TARGET_DAY],r14

    mov rdi,r13
    mov rsi,r14
    call oldJumpGuess
    test rax,rax
    je .Lms37_fail
    mov qword ptr [r12+CTX_STAGE37_TELEMETRY_GUESS],rax

    mov rdi,r13
    mov rsi,r14
    call monster_year_jump_route
    test rax,rax
    je .Lms37_fail
    mov qword ptr [r12+CTX_STAGE37_PATCHED_YEAR],rax
    mov qword ptr [r12+CTX_STAGE37_FINAL_YEAR],rdx
    mov qword ptr [r12+CTX_STAGE37_FORWARD_STEPS],rcx
    mov qword ptr [r12+CTX_STAGE37_BACKWARD_STEPS],r8
    mov qword ptr [r12+CTX_STAGE37_TELEMETRY_ONLY],1
    inc qword ptr [r12+CTX_STAGE37_PATCH_SEEN]
    mov eax,1
    jmp .Lms37_done
.Lms37_fail:
    xor eax,eax
.Lms37_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage37_year_walk_patch_handler,.-monster_stage37_year_walk_patch_handler



# Ⲃⲁⲑⲙⲟⲥ 38 — DISCOVERY 19
# Ⲡlegacy cache ⲙⲟⲩⲧⲉ ⲙⲙⲁⲧⲉ ⲉⲡyear.number; ⲛϥϫⲓ ⲁⲛ ⲙⲡcalculation day ⲏ ⲛgate ϩⲙⲡhit decision.
.type stage38NewLegacyYearCache,@function
stage38NewLegacyYearCache:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,L38_CACHE_SIZE
    call arena_alloc
    test rax,rax
    je .Ls38nc_fail
    mov r12,rax
    mov rdi,r12
    xor eax,eax
    mov ecx,L38_CACHE_SIZE/8
    rep stosq
    mov rax,r12
    jmp .Ls38nc_done
.Ls38nc_fail:
    xor eax,eax
.Ls38nc_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage38NewLegacyYearCache,.-stage38NewLegacyYearCache

# rdi=cache, rsi=year-number BigInt*, rdx=fresh opaque value BigInt*.
# rax=stored/cached value, rdx=1 HIT / 0 MISS.
.type legacyYearNumberOnlyCacheGetOrPut,@function
legacyYearNumberOnlyCacheGetOrPut:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Ll38cg_fail
    test r13,r13
    je .Ll38cg_fail
    test r14,r14
    je .Ll38cg_fail
    mov r15,qword ptr [r12+L38_CACHE_COUNT]
    xor ebx,ebx
.Ll38cg_scan:
    cmp rbx,r15
    jae .Ll38cg_miss
    mov rax,rbx
    shl rax,4
    lea rax,[r12+L38_CACHE_SLOTS+rax]
    mov rdi,qword ptr [rax]
    mov rsi,r13
    call bi_cmp
    test eax,eax
    jne .Ll38cg_next
    mov rax,rbx
    shl rax,4
    lea rax,[r12+L38_CACHE_SLOTS+rax]
    mov rax,qword ptr [rax+8]
    mov edx,1
    jmp .Ll38cg_done
.Ll38cg_next:
    inc rbx
    jmp .Ll38cg_scan
.Ll38cg_miss:
    cmp r15,L38_CACHE_CAPACITY
    jae .Ll38cg_fail
    mov rax,r15
    shl rax,4
    lea rax,[r12+L38_CACHE_SLOTS+rax]
    mov qword ptr [rax],r13
    mov qword ptr [rax+8],r14
    inc r15
    mov qword ptr [r12+L38_CACHE_COUNT],r15
    mov rax,r14
    xor edx,edx
    jmp .Ll38cg_done
.Ll38cg_fail:
    xor eax,eax
    xor edx,edx
.Ll38cg_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size legacyYearNumberOnlyCacheGetOrPut,.-legacyYearNumberOnlyCacheGetOrPut

# rdi=YJ*, rsi=calculation-day BigInt*. Ⲡvalue ⲟ ⲛopaque semantic token ⲙⲡDISCOVERY 19.
.type buildLegacyYearCacheValueStage38,@function
buildLegacyYearCacheValueStage38:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lblcv_fail
    test r13,r13
    je .Lblcv_fail
    mov rdi,qword ptr [r12+YJ_OPEN_DAY]
    mov esi,3
    call bi_mul_u64
    test rax,rax
    je .Lblcv_fail
    mov r14,rax
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov esi,5
    call bi_mul_u64
    test rax,rax
    je .Lblcv_fail
    mov rdi,r14
    mov rsi,rax
    call bi_add
    test rax,rax
    je .Lblcv_fail
    mov rdi,rax
    mov rsi,r13
    call bi_add
    jmp .Lblcv_done
.Lblcv_fail:
    xor eax,eax
.Lblcv_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size buildLegacyYearCacheValueStage38,.-buildLegacyYearCacheValueStage38

# rdi=YJ*, esi=1 open variant / 2 close variant. Ⲡnumber ⲟⲩⲏϩ ⲛⲟⲩⲱⲧ.
.type stage38YearVariant,@function
stage38YearVariant:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13d,esi
    test r12,r12
    je .Ls38yv_fail
    cmp r13d,1
    je .Ls38yv_mode_ok
    cmp r13d,2
    jne .Ls38yv_fail
.Ls38yv_mode_ok:
    mov edi,YJ_SIZE
    call arena_alloc
    test rax,rax
    je .Ls38yv_fail
    mov r14,rax
    mov rax,qword ptr [r12+YJ_NUMBER]
    mov qword ptr [r14+YJ_NUMBER],rax
    mov rax,qword ptr [r12+YJ_OPEN_DAY]
    mov qword ptr [r14+YJ_OPEN_DAY],rax
    mov rax,qword ptr [r12+YJ_FIRST_DAY]
    mov qword ptr [r14+YJ_FIRST_DAY],rax
    mov rax,qword ptr [r12+YJ_CLOSE_DAY]
    mov qword ptr [r14+YJ_CLOSE_DAY],rax
    cmp r13d,1
    jne .Ls38yv_close
    mov rdi,qword ptr [r12+YJ_OPEN_DAY]
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Ls38yv_fail
    mov qword ptr [r14+YJ_OPEN_DAY],rax
    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Ls38yv_fail
    mov qword ptr [r14+YJ_FIRST_DAY],rax
    mov rax,r14
    jmp .Ls38yv_done
.Ls38yv_close:
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Ls38yv_fail
    mov qword ptr [r14+YJ_CLOSE_DAY],rax
    mov rax,r14
    jmp .Ls38yv_done
.Ls38yv_fail:
    xor eax,eax
.Ls38yv_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage38YearVariant,.-stage38YearVariant

# rdi=cache, rsi=YJ*, rdx=calculation-day BigInt*.
# rax=semantic cache output, rdx=fresh value, rcx=legacy hit flag.
.type legacyYearNumberOnlyCacheRoute,@function
legacyYearNumberOnlyCacheRoute:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Ll38cr_fail
    test r13,r13
    je .Ll38cr_fail
    test r14,r14
    je .Ll38cr_fail
    mov rdi,r13
    mov rsi,r14
    call buildLegacyYearCacheValueStage38
    test rax,rax
    je .Ll38cr_fail
    mov r15,rax
    mov rdi,r12
    mov rsi,qword ptr [r13+YJ_NUMBER]
    mov rdx,r15
    call legacyYearNumberOnlyCacheGetOrPut
    test rax,rax
    je .Ll38cr_fail
    mov rcx,rdx
    mov rdx,r15
    jmp .Ll38cr_done
.Ll38cr_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
.Ll38cr_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size legacyYearNumberOnlyCacheRoute,.-legacyYearNumberOnlyCacheRoute

# Ⲃⲁⲑⲙⲟⲥ 39 — PATCH 19
# Ⲡfingerprint ⲟ ⲛexact clone ⲙⲡcalculation day; ⲙⲛ foreign hash ⲉϥⲣϩⲱⲃ.
.type calculationDayFingerprintPatch19,@function
calculationDayFingerprintPatch19:
    test rdi,rdi
    je .Lcdfp39_fail
    jmp bi_clone
.Lcdfp39_fail:
    xor eax,eax
    ret
.size calculationDayFingerprintPatch19,.-calculationDayFingerprintPatch19

# Ⲛregister: rdi=calculation-day, rsi=YJ*, rdx=value; rax=guarded entry.
.type stage39NewGuardedEntry,@function
stage39NewGuardedEntry:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Ls39nge_fail
    test r13,r13
    je .Ls39nge_fail
    test r14,r14
    je .Ls39nge_fail
    mov edi,G39_ENTRY_SIZE
    call arena_alloc
    test rax,rax
    je .Ls39nge_fail
    mov r15,rax
    mov rdi,r12
    call calculationDayFingerprintPatch19
    test rax,rax
    je .Ls39nge_fail
    mov qword ptr [r15+G39_ENTRY_CALC_FP],rax
    mov rax,qword ptr [r13+YJ_OPEN_DAY]
    mov qword ptr [r15+G39_ENTRY_OPEN_GATE],rax
    mov rax,qword ptr [r13+YJ_CLOSE_DAY]
    mov qword ptr [r15+G39_ENTRY_CLOSE_GATE],rax
    mov qword ptr [r15+G39_ENTRY_VALUE],r14
    mov rax,r15
    jmp .Ls39nge_done
.Ls39nge_fail:
    xor eax,eax
.Ls39nge_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage39NewGuardedEntry,.-stage39NewGuardedEntry

# Ⲛregister: rdi=cache, rsi=year.number, rdx=calculation-day, rcx=YJ*, r8=fresh value.
# Ⲡⲟⲩⲱϣⲃ: rax=semantic value, rdx=1 guarded HIT / 0 MISS, rcx=1 same-number guard replacement / 0.
.type guardedYearNumberOnlyCacheGetOrPut,@function
guardedYearNumberOnlyCacheGetOrPut:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    test r12,r12
    je .Lg39cg_fail
    test r13,r13
    je .Lg39cg_fail
    test r14,r14
    je .Lg39cg_fail
    test r15,r15
    je .Lg39cg_fail
    cmp qword ptr [rbp-48],0
    je .Lg39cg_fail
    mov rax,qword ptr [r12+L38_CACHE_COUNT]
    mov qword ptr [rbp-56],rax
    xor ebx,ebx
.Lg39cg_scan:
    cmp rbx,qword ptr [rbp-56]
    jae .Lg39cg_new_key
    mov rax,rbx
    shl rax,4
    lea rax,[r12+L38_CACHE_SLOTS+rax]
    mov qword ptr [rbp-64],rax
    mov rdi,qword ptr [rax]
    mov rsi,r13
    call bi_cmp
    test eax,eax
    jne .Lg39cg_next
    mov rax,qword ptr [rbp-64]
    mov rax,qword ptr [rax+8]
    test rax,rax
    je .Lg39cg_fail
    mov qword ptr [rbp-72],rax
    mov rdi,qword ptr [rax+G39_ENTRY_CALC_FP]
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lg39cg_replace
    mov rax,qword ptr [rbp-72]
    mov rdi,qword ptr [rax+G39_ENTRY_OPEN_GATE]
    mov rsi,qword ptr [r15+YJ_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jne .Lg39cg_replace
    mov rax,qword ptr [rbp-72]
    mov rdi,qword ptr [rax+G39_ENTRY_CLOSE_GATE]
    mov rsi,qword ptr [r15+YJ_CLOSE_DAY]
    call bi_cmp
    test eax,eax
    jne .Lg39cg_replace
    mov rax,qword ptr [rbp-72]
    mov rax,qword ptr [rax+G39_ENTRY_VALUE]
    mov edx,1
    xor ecx,ecx
    jmp .Lg39cg_done
.Lg39cg_replace:
    mov rdi,r14
    mov rsi,r15
    mov rdx,qword ptr [rbp-48]
    call stage39NewGuardedEntry
    test rax,rax
    je .Lg39cg_fail
    mov rdx,qword ptr [rbp-64]
    mov qword ptr [rdx+8],rax
    mov rax,qword ptr [rbp-48]
    xor edx,edx
    mov ecx,1
    jmp .Lg39cg_done
.Lg39cg_next:
    inc rbx
    jmp .Lg39cg_scan
.Lg39cg_new_key:
    mov rax,qword ptr [rbp-56]
    cmp rax,L38_CACHE_CAPACITY
    jae .Lg39cg_fail
    mov rdi,r14
    mov rsi,r15
    mov rdx,qword ptr [rbp-48]
    call stage39NewGuardedEntry
    test rax,rax
    je .Lg39cg_fail
    mov qword ptr [rbp-72],rax
    mov rax,qword ptr [rbp-56]
    shl rax,4
    lea rax,[r12+L38_CACHE_SLOTS+rax]
    mov qword ptr [rax],r13
    mov rdx,qword ptr [rbp-72]
    mov qword ptr [rax+8],rdx
    inc qword ptr [rbp-56]
    mov rdx,qword ptr [rbp-56]
    mov qword ptr [r12+L38_CACHE_COUNT],rdx
    mov rax,qword ptr [rbp-48]
    xor edx,edx
    xor ecx,ecx
    jmp .Lg39cg_done
.Lg39cg_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
.Lg39cg_done:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size guardedYearNumberOnlyCacheGetOrPut,.-guardedYearNumberOnlyCacheGetOrPut

# Ⲛregister: rdi=guarded cache, rsi=YJ*, rdx=calculation-day.
# Ⲡⲟⲩⲱϣⲃ: rax=semantic output, rdx=fresh value, rcx=guarded HIT, r8=guard-replacement flag.
.type guardedYearNumberOnlyCacheRoute,@function
guardedYearNumberOnlyCacheRoute:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Lg39cr_fail
    test r13,r13
    je .Lg39cr_fail
    test r14,r14
    je .Lg39cr_fail
    mov rdi,r13
    mov rsi,r14
    call buildLegacyYearCacheValueStage38
    test rax,rax
    je .Lg39cr_fail
    mov r15,rax
    mov rdi,r12
    mov rsi,qword ptr [r13+YJ_NUMBER]
    mov rdx,r14
    mov rcx,r13
    mov r8,r15
    call guardedYearNumberOnlyCacheGetOrPut
    test rax,rax
    je .Lg39cr_fail
    mov r8,rcx
    mov rcx,rdx
    mov rdx,r15
    jmp .Lg39cr_done
.Lg39cr_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
.Lg39cr_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size guardedYearNumberOnlyCacheRoute,.-guardedYearNumberOnlyCacheRoute

# Ⲡwrapper ⲙⲟⲩⲧⲉ ⲉⲡlegacy route ϩⲓ ⲟⲩcache ⲉϥϣⲟⲃⲉ, ⲙⲛⲛⲥⲱϥ ⲛϥϯ ⲙⲡguarded result.
.type monster_stage39_year_cache_guard_patch_wrapper,@function
monster_stage39_year_cache_guard_patch_wrapper:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    call stage38NewLegacyYearCache
    test rax,rax
    je .Lms39w_fail
    mov r15,rax
    mov rdi,r15
    mov rsi,r13
    mov rdx,r14
    call legacyYearNumberOnlyCacheRoute
    test rax,rax
    je .Lms39w_fail
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call guardedYearNumberOnlyCacheRoute
    jmp .Lms39w_done
.Lms39w_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
.Lms39w_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage39_year_cache_guard_patch_wrapper,.-monster_stage39_year_cache_guard_patch_wrapper

.type monster_year_cache_route,@function
monster_year_cache_route:
    jmp monster_stage39_year_cache_guard_patch_wrapper
.size monster_year_cache_route,.-monster_year_cache_route

# rdi=YJ*, rsi=calculation-day BigInt*, edx=1 calc / 2 open / 3 close.
# rax=1 ⲉϣϫⲉ ⲡroute ϯ ⲛstale output, 0 ⲉϣϫⲉ fresh, -1 ⲉϣϫⲉ invariant ⲁϥⲃⲱⲗ.
.type stage38LegacyCollisionCase,@function
stage38LegacyCollisionCase:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    test r12,r12
    je .Ls38cc_pattern
    test r13,r13
    je .Ls38cc_pattern
    cmp r14d,1
    jb .Ls38cc_pattern
    cmp r14d,3
    ja .Ls38cc_pattern
    call stage38NewLegacyYearCache
    test rax,rax
    je .Ls38cc_pattern
    mov r15,rax

    mov rdi,r15
    mov rsi,r12
    mov rdx,r13
    call monster_year_cache_route
    test rax,rax
    je .Ls38cc_pattern
    mov rbx,rax
    mov qword ptr [rbp-48],rdx
    mov rdi,rbx
    mov rsi,qword ptr [rbp-48]
    call bi_cmp
    test eax,eax
    jne .Ls38cc_pattern

    mov qword ptr [rbp-56],r12
    mov qword ptr [rbp-64],r13
    cmp r14d,1
    jne .Ls38cc_gate_variant
    mov rdi,r13
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Ls38cc_pattern
    mov qword ptr [rbp-64],rax
    jmp .Ls38cc_second
.Ls38cc_gate_variant:
    mov rdi,r12
    mov esi,r14d
    dec esi
    call stage38YearVariant
    test rax,rax
    je .Ls38cc_pattern
    mov qword ptr [rbp-56],rax

.Ls38cc_second:
    mov rdi,r15
    mov rsi,qword ptr [rbp-56]
    mov rdx,qword ptr [rbp-64]
    call monster_year_cache_route
    test rax,rax
    je .Ls38cc_pattern
    mov rbx,rax
    mov qword ptr [rbp-48],rdx
    mov rdi,rbx
    mov rsi,qword ptr [rbp-48]
    call bi_cmp
    test eax,eax
    setne al
    movzx eax,al
    jmp .Ls38cc_done

.Ls38cc_pattern:
    mov rax,-1
.Ls38cc_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage38LegacyCollisionCase,.-stage38LegacyCollisionCase

# Ⲡhandler ⲧⲁϫⲣⲟ ⲙⲡyear.number ⲉⲃⲟⲗ ϩⲙⲡPATCH 18 walk, ⲁⲩⲱ ⲛϥⲣⲉϥⲧⲁⲙⲓⲟ ⲛ3 ⲛstale collision ϩⲓ fresh caches.
.type monster_stage38_legacy_year_number_cache_handler,@function
monster_stage38_legacy_year_number_cache_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    test r12,r12
    je .Lms38_fail

    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lms38_fail
    mov r13,rax
    mov rdi,qword ptr [r13+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    test rax,rax
    je .Lms38_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call monster_year_jump_route
    test rax,rax
    je .Lms38_fail
    test rdx,rdx
    je .Lms38_fail
    mov r15,rdx
    mov qword ptr [r12+CTX_STAGE38_CACHE_KEY_YEAR],rax

    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    call bi_from_i64
    test rax,rax
    je .Lms38_fail
    mov qword ptr [rbp-40],rax

    mov rdi,r15
    mov rsi,qword ptr [rbp-40]
    mov edx,1
    call stage38LegacyCollisionCase
    cmp rax,-1
    je .Lms38_fail
    mov qword ptr [r12+CTX_STAGE38_CALCULATION_STALE],rax
    inc qword ptr [r12+CTX_STAGE38_ROUTE_CASES]

    mov rdi,r15
    mov rsi,qword ptr [rbp-40]
    mov edx,2
    call stage38LegacyCollisionCase
    cmp rax,-1
    je .Lms38_fail
    mov qword ptr [r12+CTX_STAGE38_OPEN_STALE],rax
    inc qword ptr [r12+CTX_STAGE38_ROUTE_CASES]

    mov rdi,r15
    mov rsi,qword ptr [rbp-40]
    mov edx,3
    call stage38LegacyCollisionCase
    cmp rax,-1
    je .Lms38_fail
    mov qword ptr [r12+CTX_STAGE38_CLOSE_STALE],rax
    inc qword ptr [r12+CTX_STAGE38_ROUTE_CASES]

    mov qword ptr [r12+CTX_STAGE38_NUMBER_ONLY_KEY],1
    inc qword ptr [r12+CTX_STAGE38_SEEN]
    mov eax,1
    jmp .Lms38_done
.Lms38_fail:
    xor eax,eax
.Lms38_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage38_legacy_year_number_cache_handler,.-monster_stage38_legacy_year_number_cache_handler

# Ⲛregister: rdi=YJ*, rsi=calculation-day, edx=1 calc / 2 open / 3 close.
# Ⲡⲟⲩⲱϣⲃ: rax=semantic mismatch 0/1, rdx=legacy stale flag, rcx=guard replacement flag; -1 ⲉϣϫⲉ invariant ⲁϥⲃⲱⲗ.
.type stage39GuardedCollisionCase,@function
stage39GuardedCollisionCase:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,56
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    test r12,r12
    je .Ls39cc_pattern
    test r13,r13
    je .Ls39cc_pattern
    cmp r14d,1
    jb .Ls39cc_pattern
    cmp r14d,3
    ja .Ls39cc_pattern
    call stage38NewLegacyYearCache
    test rax,rax
    je .Ls39cc_pattern
    mov r15,rax
    call stage38NewLegacyYearCache
    test rax,rax
    je .Ls39cc_pattern
    mov qword ptr [rbp-48],rax

    # Ⲡrequest ⲛϣⲟⲣⲡ — legacy cache.
    mov rdi,r15
    mov rsi,r12
    mov rdx,r13
    call legacyYearNumberOnlyCacheRoute
    test rax,rax
    je .Ls39cc_pattern
    mov qword ptr [rbp-56],rax
    mov qword ptr [rbp-64],rdx
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    test eax,eax
    jne .Ls39cc_pattern

    # Ⲡrequest ⲛϣⲟⲣⲡ — guarded route.
    mov rdi,qword ptr [rbp-48]
    mov rsi,r12
    mov rdx,r13
    call monster_year_cache_route
    test rax,rax
    je .Ls39cc_pattern
    mov qword ptr [rbp-56],rax
    mov qword ptr [rbp-64],rdx
    test rcx,rcx
    jne .Ls39cc_pattern
    test r8,r8
    jne .Ls39cc_pattern
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    test eax,eax
    jne .Ls39cc_pattern

    mov qword ptr [rbp-72],r12
    mov qword ptr [rbp-80],r13
    cmp r14d,1
    jne .Ls39cc_gate_variant
    mov rdi,r13
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Ls39cc_pattern
    mov qword ptr [rbp-80],rax
    jmp .Ls39cc_second
.Ls39cc_gate_variant:
    mov rdi,r12
    mov esi,r14d
    dec esi
    call stage38YearVariant
    test rax,rax
    je .Ls39cc_pattern
    mov qword ptr [rbp-72],rax
.Ls39cc_second:
    # Ⲡrequest ⲙⲙⲁϩ2 — ⲡdirect legacy ⲟⲩⲏϩ stale.
    mov rdi,r15
    mov rsi,qword ptr [rbp-72]
    mov rdx,qword ptr [rbp-80]
    call legacyYearNumberOnlyCacheRoute
    test rax,rax
    je .Ls39cc_pattern
    mov qword ptr [rbp-56],rax
    mov qword ptr [rbp-64],rdx
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    sete al
    xor al,1
    movzx ebx,al
    cmp ebx,1
    jne .Ls39cc_pattern

    # Ⲡrequest ⲙⲙⲁϩ2 — ⲡguarded route refresh ⲙⲡentry ϩⲁ ⲡsame bad key.
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-72]
    mov rdx,qword ptr [rbp-80]
    call monster_year_cache_route
    test rax,rax
    je .Ls39cc_pattern
    mov qword ptr [rbp-56],rax
    mov qword ptr [rbp-64],rdx
    test rcx,rcx
    jne .Ls39cc_pattern
    cmp r8,1
    jne .Ls39cc_pattern
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    setne al
    movzx eax,al
    mov edx,ebx
    mov ecx,1
    jmp .Ls39cc_done
.Ls39cc_pattern:
    mov rax,-1
    xor edx,edx
    xor ecx,ecx
.Ls39cc_done:
    add rsp,56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage39GuardedCollisionCase,.-stage39GuardedCollisionCase

# Ⲡhandler ⲧⲁϫⲣⲟ ⲙⲡ3 ⲛguard refresh ⲙⲛ ⲟⲩsame-state HIT, ⲉⲣⲉ ⲡkey ⲟⲩⲏϩ year.number ⲙⲙⲁⲧⲉ.
.type monster_stage39_year_cache_guard_patch_handler,@function
monster_stage39_year_cache_guard_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    test r12,r12
    je .Lms39_fail
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lms39_fail
    mov r13,rax
    mov rdi,qword ptr [r13+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    test rax,rax
    je .Lms39_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call monster_year_jump_route
    test rax,rax
    je .Lms39_fail
    test rdx,rdx
    je .Lms39_fail
    mov r15,rdx
    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    call bi_from_i64
    test rax,rax
    je .Lms39_fail
    mov qword ptr [rbp-40],rax

    mov qword ptr [rbp-56],0
    mov rdi,r15
    mov rsi,qword ptr [rbp-40]
    mov edx,1
    call stage39GuardedCollisionCase
    cmp rax,-1
    je .Lms39_fail
    mov qword ptr [r12+CTX_STAGE39_CALCULATION_REFRESH],rax
    add qword ptr [rbp-56],rdx

    mov rdi,r15
    mov rsi,qword ptr [rbp-40]
    mov edx,2
    call stage39GuardedCollisionCase
    cmp rax,-1
    je .Lms39_fail
    mov qword ptr [r12+CTX_STAGE39_OPEN_REFRESH],rax
    add qword ptr [rbp-56],rdx

    mov rdi,r15
    mov rsi,qword ptr [rbp-40]
    mov edx,3
    call stage39GuardedCollisionCase
    cmp rax,-1
    je .Lms39_fail
    mov qword ptr [r12+CTX_STAGE39_CLOSE_REFRESH],rax
    add qword ptr [rbp-56],rdx
    mov rax,qword ptr [rbp-56]
    mov qword ptr [r12+CTX_STAGE39_LEGACY_STALE_CASES],rax

    # Ⲡsame request ⲛⲥⲟⲡ2 ⲟⲩⲏϩ ⲉϥⲣ ⲛⲟⲩreal cache HIT.
    call stage38NewLegacyYearCache
    test rax,rax
    je .Lms39_fail
    mov qword ptr [rbp-48],rax
    mov rdi,rax
    mov rsi,r15
    mov rdx,qword ptr [rbp-40]
    call monster_year_cache_route
    test rax,rax
    je .Lms39_fail
    test rcx,rcx
    jne .Lms39_fail
    mov rdi,qword ptr [rbp-48]
    mov rsi,r15
    mov rdx,qword ptr [rbp-40]
    call monster_year_cache_route
    test rax,rax
    je .Lms39_fail
    cmp rcx,1
    jne .Lms39_fail
    test r8,r8
    jne .Lms39_fail
    mov qword ptr [r12+CTX_STAGE39_SAME_STATE_HIT],1
    mov qword ptr [r12+CTX_STAGE39_NUMBER_ONLY_KEY_KEPT],1
    inc qword ptr [r12+CTX_STAGE39_PATCH_SEEN]
    mov eax,1
    jmp .Lms39_done
.Lms39_fail:
    xor eax,eax
.Lms39_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage39_year_cache_guard_patch_handler,.-monster_stage39_year_cache_guard_patch_handler


# Ⲃⲁⲑⲙⲟⲥ 40 — DISCOVERY 20
# Ⲡghost ⲛstructure sauce ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡoriginal target day. Ⲡyear.firstDay ⲛϥϫⲓ ⲙⲙⲟϥ ⲁⲛ ϩⲙⲡroute ⲡⲁⲓ.
.type oldStructureSauce,@function
oldStructureSauce:
    jmp sauceWithOrderAt46Latch
.size oldStructureSauce,.-oldStructureSauce

# rdi=cDay i64, rsi=originalTargetDay i64, rdx=YJ* ⲉϥⲟ ⲛghost-only ignored year.
.type legacyStructureSauceUsingOriginalTarget,@function
legacyStructureSauceUsingOriginalTarget:
    jmp oldStructureSauce
.size legacyStructureSauceUsingOriginalTarget,.-legacyStructureSauceUsingOriginalTarget

# Ⲃⲁⲑⲙⲟⲥ 41 — PATCH 20. Ⲡghost ⲙⲟⲩⲧⲉ ⲉⲡold route ⲛⲟⲩⲙⲉ; ⲡauthoritative target ⲡⲉ year.firstDay ⲉϣϫⲉ ⲡoriginal target ϣⲟⲃⲉ.
# rdi=BigInt*. rax=i64, rdx=1 success / 0 fail.
.type stage41StructureDayToI64,@function
stage41StructureDayToI64:
    test rdi,rdi
    je .Ls41di_fail
    mov rcx,qword ptr [rdi+BI_LEN]
    test rcx,rcx
    je .Ls41di_zero
    cmp rcx,1
    jne .Ls41di_fail
    mov rdx,qword ptr [rdi+BI_DATA]
    test rdx,rdx
    je .Ls41di_fail
    mov rax,qword ptr [rdx]
    mov rcx,qword ptr [rdi+BI_SIGN]
    cmp rcx,1
    je .Ls41di_positive
    cmp rcx,-1
    jne .Ls41di_fail
    mov rcx,0x8000000000000000
    cmp rax,rcx
    ja .Ls41di_fail
    neg rax
    mov edx,1
    ret
.Ls41di_positive:
    test rax,rax
    js .Ls41di_fail
    mov edx,1
    ret
.Ls41di_zero:
    xor eax,eax
    mov edx,1
    ret
.Ls41di_fail:
    xor eax,eax
    xor edx,edx
    ret
.size stage41StructureDayToI64,.-stage41StructureDayToI64

# rdi=cDay i64, rsi=originalTargetDay i64, rdx=YJ*.
# rax=authoritative sauce; rdx=1 only when the returned sauce is the ghost; rcx=ghost sauce from this wrapper.
.type structureSaucePatch,@function
structureSaucePatch:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r14,r14
    je .Ls41ssp_fail

    # ⲠoldStructureSauce ⲣϩⲱⲃ ⲛⲟⲩⲙⲉ ϩⲙ call ⲛⲓⲙ; ⲡresult ⲡⲉ ⲡghost.
    mov rdi,r12
    mov rsi,r13
    call oldStructureSauce
    test rax,rax
    je .Ls41ssp_fail
    mov r15,rax

    mov rdi,r13
    call bi_from_i64
    test rax,rax
    je .Ls41ssp_fail
    mov rdi,rax
    mov rsi,qword ptr [r14+YJ_FIRST_DAY]
    call bi_cmp
    test eax,eax
    je .Ls41ssp_equal

    # Ⲡghost ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡselector: ⲡsauce ⲛⲙⲉ ⲗⲟⲅⲓⲍⲉ ⲙⲛ year.firstDay.
    mov rdi,qword ptr [r14+YJ_FIRST_DAY]
    call stage41StructureDayToI64
    test rdx,rdx
    je .Ls41ssp_fail
    mov rsi,rax
    mov rdi,r12
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Ls41ssp_fail
    mov rbx,rax
    mov rax,rbx
    xor edx,edx
    mov rcx,r15
    jmp .Ls41ssp_done

.Ls41ssp_equal:
    mov rax,r15
    mov edx,1
    mov rcx,r15
    jmp .Ls41ssp_done

.Ls41ssp_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
.Ls41ssp_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size structureSaucePatch,.-structureSaucePatch

.type monster_stage41_structure_sauce_patch_wrapper,@function
monster_stage41_structure_sauce_patch_wrapper:
    jmp structureSaucePatch
.size monster_stage41_structure_sauce_patch_wrapper,.-monster_stage41_structure_sauce_patch_wrapper

.type monster_structure_sauce_route,@function
monster_structure_sauce_route:
    jmp monster_stage41_structure_sauce_patch_wrapper
.size monster_structure_sauce_route,.-monster_structure_sauce_route

# Ⲡhandler ϭⲓⲛⲉ ⲙⲡyear ϩⲓⲧⲛ ⲡsequential walk; ⲡStage 41 route ⲙⲟⲩⲧⲉ ⲉghost ⲛϣⲟⲣⲡ ⲁⲩⲱ ⲕⲱ ⲙⲡyear.firstDay ⲛauthoritative ⲉϣϫⲉ ⲥⲉϣⲟⲃⲉ.
.type monster_stage40_legacy_structure_sauce_handler,@function
monster_stage40_legacy_structure_sauce_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    test r12,r12
    je .Lms40_fail

    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lms40_fail
    mov r13,rax

    mov rdi,qword ptr [r12+CTX_TARGET_DAY]
    call bi_from_i64
    test rax,rax
    je .Lms40_fail
    mov r14,rax

    mov rdi,r13
    mov rsi,r14
    call monster_year_jump_route
    test rax,rax
    je .Lms40_fail
    test rdx,rdx
    je .Lms40_fail
    mov r15,rdx
    mov qword ptr [r12+CTX_STAGE40_YEAR],r15
    mov rax,qword ptr [r15+YJ_FIRST_DAY]
    mov qword ptr [r12+CTX_STAGE40_YEAR_FIRST_DAY],rax
    mov rax,qword ptr [r12+CTX_TARGET_DAY]
    mov qword ptr [r12+CTX_STAGE40_ORIGINAL_TARGET],rax

    mov rdi,r14
    mov rsi,qword ptr [r15+YJ_FIRST_DAY]
    call bi_cmp
    sete al
    xor al,1
    movzx eax,al
    mov qword ptr [r12+CTX_STAGE40_TARGET_DIFFERS_FIRSTDAY],rax

    # ⲠStage 41 route ⲛⲧⲟϥ ⲙⲟⲩⲧⲉ ⲉoldStructureSauce ⲛghost; ⲡhandler ⲛϥⲣ ⲁⲛ ⲛⲟⲩthird sauce copy.
    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    mov rsi,qword ptr [r12+CTX_TARGET_DAY]
    mov rdx,r15
    call monster_structure_sauce_route
    test rax,rax
    je .Lms40_fail
    mov qword ptr [r12+CTX_STAGE40_ROUTE_SAUCE],rax
    mov qword ptr [r12+CTX_STAGE40_GHOST_SAUCE],rcx
    mov qword ptr [r12+CTX_STAGE41_ROUTE_GHOST],rcx
    test rcx,rcx
    setne al
    movzx eax,al
    mov qword ptr [r12+CTX_STAGE41_ROUTE_GHOST_SEEN],rax
    mov qword ptr [r12+CTX_STAGE40_GHOST_USED_AS_SEMANTIC],rdx
    mov qword ptr [r12+CTX_STAGE41_GHOST_REUSE_EQUAL],rdx
    inc qword ptr [r12+CTX_STAGE41_PATCH_SEEN]
    inc qword ptr [r12+CTX_STAGE40_SEEN]
    mov eax,1
    jmp .Lms40_done
.Lms40_fail:
    xor eax,eax
.Lms40_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage40_legacy_structure_sauce_handler,.-monster_stage40_legacy_structure_sauce_handler



# Ⲃⲁⲑⲙⲟⲥ 42 — DISCOVERY 21
# Ⲡlegacy family ⲛcutlet partition ⲡⲉ ⲛpositive compositions ⲧⲏⲣⲟⲩ ⲙⲡgap count.
# Ⲡoffset ⲙⲡcalculation-day gate ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ϩⲙⲡABI, ⲁⲗⲗⲁ ⲡlegacy ⲛϥϫⲓ ⲁⲛ ⲙⲙⲟϥ.

# rdi=n u64, rsi=k u64. rax=BigInt* C(n,k).
.type stage42LegacyBinomialU64,@function
stage42LegacyBinomialU64:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    cmp r13,r12
    ja .Ls42bin_zero
    mov r14,r12
    sub r14,r13
    cmp r13,r14
    jbe .Ls42bin_k_ok
    mov r13,r14
.Ls42bin_k_ok:
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls42bin_fail
    mov r15,rax
    mov rbx,1
.Ls42bin_loop:
    cmp rbx,r13
    ja .Ls42bin_return
    mov rsi,r12
    sub rsi,r13
    add rsi,rbx
    mov rdi,r15
    call bi_mul_u64
    test rax,rax
    je .Ls42bin_fail
    mov rdi,rax
    mov rsi,rbx
    call bi_divmod_u64_abs
    test rax,rax
    je .Ls42bin_fail
    test rdx,rdx
    jne .Ls42bin_fail
    mov r15,rax
    inc rbx
    jmp .Ls42bin_loop
.Ls42bin_return:
    mov rax,r15
    jmp .Ls42bin_done
.Ls42bin_zero:
    call bi_zero
    jmp .Ls42bin_done
.Ls42bin_fail:
    xor eax,eax
.Ls42bin_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage42LegacyBinomialU64,.-stage42LegacyBinomialU64

# rdi=gap count, rsi=cutlet count. rax=BigInt*.
# Ⲡscar ⲡⲁⲓ ⲗⲟⲅⲓⲍⲉ ⲛcompositions ⲧⲏⲣⲟⲩ: C(gap-1,cutlets-1).
.type oldCutletPartitionFamilyCount,@function
oldCutletPartitionFamilyCount:
    test rsi,rsi
    jne .Locpfc_slots
    test rdi,rdi
    jne .Locpfc_zero
    mov edi,1
    jmp bi_from_u64
.Locpfc_slots:
    cmp rdi,rsi
    jb .Locpfc_zero
    dec rdi
    dec rsi
    jmp stage42LegacyBinomialU64
.Locpfc_zero:
    jmp bi_zero
.size oldCutletPartitionFamilyCount,.-oldCutletPartitionFamilyCount

# rdi=gap, rsi=cutlets, rdx=rank1 BigInt*, rcx=out u64[cutlets].
# rax=out ⲉϣϫⲉ success; 0 ⲉϣϫⲉ fail. Ⲡorder ⲡⲉ lexicographic ⲛpositive compositions.
.type oldCutletPartitionFamilyUnrank,@function
oldCutletPartitionFamilyUnrank:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,72
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    test r14,r14
    je .Locpfu_fail
    test r15,r15
    je .Locpfu_fail
    cmp qword ptr [r14+BI_SIGN],1
    jne .Locpfu_fail

    mov rdi,r12
    mov rsi,r13
    call oldCutletPartitionFamilyCount
    test rax,rax
    je .Locpfu_fail
    mov qword ptr [rbp-48],rax
    mov rdi,r14
    mov rsi,rax
    call bi_cmp
    cmp eax,0
    jg .Locpfu_fail
    mov rdi,r14
    call bi_clone
    test rax,rax
    je .Locpfu_fail
    mov qword ptr [rbp-56],rax
    mov qword ptr [rbp-64],r12
    mov qword ptr [rbp-72],0

    test r13,r13
    jne .Locpfu_loop_check
    test r12,r12
    jne .Locpfu_fail
    mov rax,r15
    jmp .Locpfu_done

.Locpfu_loop_check:
    mov rax,qword ptr [rbp-72]
    inc rax
    cmp rax,r13
    jae .Locpfu_last
    mov qword ptr [rbp-80],1
.Locpfu_candidate:
    mov rax,r13
    sub rax,qword ptr [rbp-72]
    dec rax
    mov qword ptr [rbp-88],rax
    mov rbx,qword ptr [rbp-64]
    sub rbx,rax
    mov rax,qword ptr [rbp-80]
    cmp rax,rbx
    ja .Locpfu_fail

    mov rdi,qword ptr [rbp-64]
    sub rdi,qword ptr [rbp-80]
    mov rsi,qword ptr [rbp-88]
    call oldCutletPartitionFamilyCount
    test rax,rax
    je .Locpfu_fail
    mov qword ptr [rbp-96],rax
    mov rdi,qword ptr [rbp-56]
    mov rsi,rax
    call bi_cmp
    cmp eax,0
    jle .Locpfu_take
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-96]
    call bi_sub
    test rax,rax
    je .Locpfu_fail
    mov qword ptr [rbp-56],rax
    inc qword ptr [rbp-80]
    jmp .Locpfu_candidate

.Locpfu_take:
    mov rcx,qword ptr [rbp-72]
    mov rax,qword ptr [rbp-80]
    mov qword ptr [r15+rcx*8],rax
    sub qword ptr [rbp-64],rax
    inc qword ptr [rbp-72]
    jmp .Locpfu_loop_check

.Locpfu_last:
    mov rcx,qword ptr [rbp-72]
    mov rax,qword ptr [rbp-64]
    test rax,rax
    je .Locpfu_fail
    mov qword ptr [r15+rcx*8],rax
    mov rax,r15
    jmp .Locpfu_done

.Locpfu_fail:
    xor eax,eax
.Locpfu_done:
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oldCutletPartitionFamilyUnrank,.-oldCutletPartitionFamilyUnrank

# rdi=gap, rsi=cutlets, rdx=rank1 BigInt*, rcx=out.
# rax=legacy family count, rdx=1 success / 0 fail.
.type oldCutletPartitionFamily,@function
oldCutletPartitionFamily:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rdi,r12
    mov rsi,r13
    call oldCutletPartitionFamilyCount
    test rax,rax
    je .Locpf_fail
    mov rbx,rax
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    call oldCutletPartitionFamilyUnrank
    test rax,rax
    je .Locpf_fail
    mov rax,rbx
    mov edx,1
    jmp .Locpf_done
.Locpf_fail:
    xor eax,eax
    xor edx,edx
.Locpf_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oldCutletPartitionFamily,.-oldCutletPartitionFamily

# rdi=gap, rsi=cutlets, rdx=required internal-gate offset, rcx=rank1, r8=out.
# ⲠDISCOVERY 21 scar: rdx ⲛϥⲣϩⲱⲃ ⲁⲛ; ⲡfamily ⲟⲩⲏϩ all-positive.
.type legacyCutletPartitionWithoutCalculationGate,@function
legacyCutletPartitionWithoutCalculationGate:
    mov rdx,rcx
    mov rcx,r8
    jmp oldCutletPartitionFamily
.size legacyCutletPartitionWithoutCalculationGate,.-legacyCutletPartitionWithoutCalculationGate

# rdi=gap, rsi=cutlets, rdx=required boundary offset; 0 ⲡⲉ NONE. rax=BigInt*.
# Ⲡfamily ⲉⲧⲥⲟⲧⲡ ⲧⲁϫⲣⲟ ⲙⲡlegacy lexicographic order: ⲉϣϫⲉ required!=0, ⲡcut position required ⲡⲉ mandatory.
.type filteredCutletPartitionFamilyCount,@function
filteredCutletPartitionFamilyCount:
    test rdx,rdx
    je .Lfcpfc_old
    cmp rdx,rdi
    jae .Lfcpfc_zero
    cmp rsi,2
    jb .Lfcpfc_zero
    cmp rdi,rsi
    jb .Lfcpfc_zero
    sub rdi,2
    sub rsi,2
    jmp stage42LegacyBinomialU64
.Lfcpfc_old:
    jmp oldCutletPartitionFamilyCount
.Lfcpfc_zero:
    jmp bi_zero
.size filteredCutletPartitionFamilyCount,.-filteredCutletPartitionFamilyCount

# rdi=gap, rsi=cutlets, rdx=required, rcx=rank1 BigInt*, r8=out u64[cutlets].
# Ⲡunrank ⲙⲟⲟϣⲉ ⲕⲁⲧⲁ ⲡlegacy candidates 1..maxX; ⲡblock ⲛⲓⲙ ⲗⲟⲅⲓⲍⲉ ⲛfiltered descendants ⲛⲟⲩⲱⲧ.
.type filteredCutletPartitionFamilyUnrank,@function
filteredCutletPartitionFamilyUnrank:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,104
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    test r15,r15
    je .Lfcpu_fail
    test rbx,rbx
    je .Lfcpu_fail
    cmp qword ptr [r15+BI_SIGN],1
    jne .Lfcpu_fail

    test r14,r14
    jne .Lfcpu_filtered
    mov rdi,r12
    mov rsi,r13
    mov rdx,r15
    mov rcx,rbx
    call oldCutletPartitionFamilyUnrank
    jmp .Lfcpu_done

.Lfcpu_filtered:
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call filteredCutletPartitionFamilyCount
    test rax,rax
    je .Lfcpu_fail
    mov qword ptr [rbp-48],rax
    mov rdi,r15
    mov rsi,rax
    call bi_cmp
    cmp eax,0
    jg .Lfcpu_fail
    mov rdi,r15
    call bi_clone
    test rax,rax
    je .Lfcpu_fail
    mov qword ptr [rbp-56],rax
    mov qword ptr [rbp-64],r12
    mov qword ptr [rbp-72],r13
    mov qword ptr [rbp-80],0
    mov qword ptr [rbp-88],0
    mov qword ptr [rbp-96],0

.Lfcpu_slot_loop:
    mov rax,qword ptr [rbp-72]
    test rax,rax
    je .Lfcpu_fail
    cmp rax,1
    je .Lfcpu_last

    mov qword ptr [rbp-104],1
    mov rax,qword ptr [rbp-64]
    mov rcx,qword ptr [rbp-72]
    dec rcx
    sub rax,rcx
    mov qword ptr [rbp-112],rax

.Lfcpu_candidate:
    mov rax,qword ptr [rbp-104]
    cmp rax,qword ptr [rbp-112]
    ja .Lfcpu_fail
    mov rcx,qword ptr [rbp-80]
    add rcx,rax
    mov qword ptr [rbp-120],rcx

    cmp qword ptr [rbp-88],1
    je .Lfcpu_block_all
    cmp rcx,r14
    ja .Lfcpu_fail
    je .Lfcpu_block_hit

    # Ⲡboundary ⲟⲩⲏϩ ϩⲓⲧϩⲏ: among remaining cuts, one fixed cut is required.
    mov rdi,qword ptr [rbp-64]
    sub rdi,qword ptr [rbp-104]
    mov rsi,qword ptr [rbp-72]
    dec rsi
    cmp rsi,2
    jb .Lfcpu_next_candidate
    cmp rdi,2
    jb .Lfcpu_next_candidate
    sub rdi,2
    sub rsi,2
    call stage42LegacyBinomialU64
    test rax,rax
    je .Lfcpu_fail
    mov qword ptr [rbp-128],rax
    mov qword ptr [rbp-136],0
    jmp .Lfcpu_compare_block

.Lfcpu_block_hit:
    mov rdi,qword ptr [rbp-64]
    sub rdi,qword ptr [rbp-104]
    mov rsi,qword ptr [rbp-72]
    dec rsi
    call oldCutletPartitionFamilyCount
    test rax,rax
    je .Lfcpu_fail
    mov qword ptr [rbp-128],rax
    mov qword ptr [rbp-136],1
    jmp .Lfcpu_compare_block

.Lfcpu_block_all:
    mov rdi,qword ptr [rbp-64]
    sub rdi,qword ptr [rbp-104]
    mov rsi,qword ptr [rbp-72]
    dec rsi
    call oldCutletPartitionFamilyCount
    test rax,rax
    je .Lfcpu_fail
    mov qword ptr [rbp-128],rax
    mov qword ptr [rbp-136],1

.Lfcpu_compare_block:
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-128]
    call bi_cmp
    cmp eax,0
    jle .Lfcpu_take
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-128]
    call bi_sub
    test rax,rax
    je .Lfcpu_fail
    mov qword ptr [rbp-56],rax
.Lfcpu_next_candidate:
    inc qword ptr [rbp-104]
    jmp .Lfcpu_candidate

.Lfcpu_take:
    mov rcx,qword ptr [rbp-96]
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rbx+rcx*8],rax
    sub qword ptr [rbp-64],rax
    dec qword ptr [rbp-72]
    mov rax,qword ptr [rbp-120]
    mov qword ptr [rbp-80],rax
    mov rax,qword ptr [rbp-136]
    mov qword ptr [rbp-88],rax
    inc qword ptr [rbp-96]
    jmp .Lfcpu_slot_loop

.Lfcpu_last:
    cmp qword ptr [rbp-88],1
    jne .Lfcpu_fail
    mov rax,qword ptr [rbp-64]
    test rax,rax
    je .Lfcpu_fail
    mov rcx,qword ptr [rbp-96]
    mov qword ptr [rbx+rcx*8],rax
    mov rax,rbx
    jmp .Lfcpu_done

.Lfcpu_fail:
    xor eax,eax
.Lfcpu_done:
    add rsp,104
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size filteredCutletPartitionFamilyUnrank,.-filteredCutletPartitionFamilyUnrank

# rdi=gap, rsi=cutlets, rdx=required, rcx=rank1, r8=out. rax=count, rdx=1/0.
.type filteredCutletPartitionFamily,@function
filteredCutletPartitionFamily:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call filteredCutletPartitionFamilyCount
    test rax,rax
    je .Lfcpf_fail
    mov rbx,rax
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    mov r8,qword ptr [rbp-48]
    call filteredCutletPartitionFamilyUnrank
    test rax,rax
    je .Lfcpf_fail
    mov rax,rbx
    mov edx,1
    jmp .Lfcpf_done
.Lfcpf_fail:
    xor eax,eax
    xor edx,edx
.Lfcpf_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size filteredCutletPartitionFamily,.-filteredCutletPartitionFamily

# ⲠPatch 21 detour: ⲡlegacy all-positive scar ⲣϩⲱⲃ ⲛghost ⲛⲓⲙ; required==0 ⲙⲟⲛ ⲉϥϣⲟⲟⲡ authoritative.
# returns rax=authoritative count, rdx=success, rcx=ghost count, r8=ghost out, r9=1 iff ghost reused.
.type cutletPartitionPatch21,@function
cutletPartitionPatch21:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    test r8,r8
    je .Lcpp21_fail

    mov rdi,r13
    test rdi,rdi
    jne .Lcpp21_bytes
    mov edi,1
.Lcpp21_bytes:
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Lcpp21_fail
    mov qword ptr [rbp-56],rax

    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    mov r8,rax
    call legacyCutletPartitionWithoutCalculationGate
    test rax,rax
    je .Lcpp21_fail
    cmp rdx,1
    jne .Lcpp21_fail
    mov qword ptr [rbp-64],rax

    test r14,r14
    jne .Lcpp21_filtered
    xor ebx,ebx
.Lcpp21_copy_ghost:
    cmp rbx,r13
    jae .Lcpp21_reused
    mov rax,qword ptr [rbp-56]
    mov rax,qword ptr [rax+rbx*8]
    mov rcx,qword ptr [rbp-48]
    mov qword ptr [rcx+rbx*8],rax
    inc rbx
    jmp .Lcpp21_copy_ghost
.Lcpp21_reused:
    mov rax,qword ptr [rbp-64]
    mov edx,1
    mov rcx,qword ptr [rbp-64]
    mov r8,qword ptr [rbp-56]
    mov r9d,1
    jmp .Lcpp21_done

.Lcpp21_filtered:
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    mov r8,qword ptr [rbp-48]
    call filteredCutletPartitionFamily
    test rax,rax
    je .Lcpp21_fail
    cmp rdx,1
    jne .Lcpp21_fail
    mov rcx,qword ptr [rbp-64]
    mov r8,qword ptr [rbp-56]
    xor r9d,r9d
    jmp .Lcpp21_done

.Lcpp21_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
.Lcpp21_done:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size cutletPartitionPatch21,.-cutletPartitionPatch21

.type monster_stage43_cutlet_partition_patch_wrapper,@function
monster_stage43_cutlet_partition_patch_wrapper:
    jmp cutletPartitionPatch21
.size monster_stage43_cutlet_partition_patch_wrapper,.-monster_stage43_cutlet_partition_patch_wrapper

.type monster_cutlet_partition_route,@function
monster_cutlet_partition_route:
    jmp monster_stage43_cutlet_partition_patch_wrapper
.size monster_cutlet_partition_route,.-monster_cutlet_partition_route

# Ⲡhandler ⲧⲁϫⲣⲟ ⲛⲟⲩinternal-gate witness: gap=10, cutlets=3, offset=4, rank=1.
# Ⲡlegacy route ⲙⲟⲩⲧⲉ ⲉall-positive family ⲁⲩⲱ ⲛϥfilter ⲁⲛ ⲕⲁⲧⲁ ⲡoffset.
.type monster_stage42_legacy_cutlet_partition_handler,@function
monster_stage42_legacy_cutlet_partition_handler:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    test r12,r12
    je .Lms42_fail
    mov qword ptr [r12+CTX_STAGE42_GAP_COUNT],10
    mov qword ptr [r12+CTX_STAGE42_CUTLET_COUNT],3
    mov qword ptr [r12+CTX_STAGE42_CALC_GATE_OFFSET],4

    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Lms42_fail
    mov r13,rax
    mov qword ptr [r12+CTX_STAGE42_SELECTED_RANK],rax

    mov edi,24
    call arena_alloc
    test rax,rax
    je .Lms42_fail
    mov r14,rax
    mov qword ptr [r12+CTX_STAGE42_ROUTE_PARTITION],rax

    # Ⲡdirect scar ⲟⲩⲏϩ all-positive ⲙⲛ 36 ⲛmembers ϩⲙ witness ⲡⲁⲓ.
    mov edi,10
    mov esi,3
    call oldCutletPartitionFamilyCount
    test rax,rax
    je .Lms42_fail
    mov rdi,rax
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Lms42_fail
    mov qword ptr [r12+CTX_STAGE42_LEGACY_ALL_POSITIVE],1

    mov edi,10
    mov esi,3
    mov edx,4
    mov rcx,r13
    mov r8,r14
    call monster_cutlet_partition_route
    test rax,rax
    je .Lms42_fail
    cmp rdx,1
    jne .Lms42_fail
    mov qword ptr [r12+CTX_STAGE42_ROUTE_FAMILY_COUNT],rax
    mov qword ptr [r12+CTX_STAGE43_GHOST_FAMILY_COUNT],rcx
    mov qword ptr [r12+CTX_STAGE43_GHOST_PARTITION],r8
    test rcx,rcx
    jz .Lms42_no_ghost
    test r8,r8
    jz .Lms42_no_ghost
    mov qword ptr [r12+CTX_STAGE43_GHOST_SEEN],1
.Lms42_no_ghost:
    mov qword ptr [r12+CTX_STAGE43_GHOST_REUSED],r9
    xor eax,eax
    test r14,r14
    setne al
    movzx eax,al
    mov qword ptr [r12+CTX_STAGE43_FILTERED_USED],rax
    inc qword ptr [r12+CTX_STAGE43_PATCH_SEEN]

    mov qword ptr [r12+CTX_STAGE42_ROUTE_SEEN],1
    inc qword ptr [r12+CTX_STAGE42_SEEN]
    mov eax,1
    jmp .Lms42_done
.Lms42_fail:
    xor eax,eax
.Lms42_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size monster_stage42_legacy_cutlet_partition_handler,.-monster_stage42_legacy_cutlet_partition_handler


# Ⲃⲁⲑⲙⲟⲥ 44 — DISCOVERY 22
# Ⲡlegacy ⲛⲉϥⲙⲉⲉⲩⲉ ϫⲉ ⲟⲩrank ϣϭⲙϭⲟⲙ ⲉϥⲣ ⲛbase-17 digits ⲉⲩⲟⲩⲱϩ ⲉⲩⲕⲧⲟ ⲉⲡsame canonical name.
# rdi=rank1 u64, rsi=K, rdx=out u64[K] canonical indices. rax=out / 0.
.type oldCutletNameRowWithRepeats,@function
oldCutletNameRowWithRepeats:
    test rdi,rdi
    je .Locnr_fail
    test rsi,rsi
    je .Locnr_fail
    cmp rsi,17
    ja .Locnr_fail
    test rdx,rdx
    je .Locnr_fail
    mov r8,rdx
    dec rdi
    xor ecx,ecx
    mov r10d,17
.Locnr_loop:
    cmp rcx,rsi
    jae .Locnr_done
    mov rax,rdi
    xor edx,edx
    div r10
    inc rdx
    mov qword ptr [r8+rcx*8],rdx
    mov rdi,rax
    inc rcx
    jmp .Locnr_loop
.Locnr_done:
    mov rax,r8
    ret
.Locnr_fail:
    xor eax,eax
    ret
.size oldCutletNameRowWithRepeats,.-oldCutletNameRowWithRepeats

# Ⲡscar callable ⲟⲩⲏϩ ⲉϥⲧⲁⲙⲓⲟ ⲛⲟⲩrow ⲉⲣⲉ repeats ϣⲟⲟⲡ ⲛϩⲏⲧϥ.
.type legacyCutletNamesWithRepeats,@function
legacyCutletNamesWithRepeats:
    jmp oldCutletNameRowWithRepeats
.size legacyCutletNamesWithRepeats,.-legacyCutletNamesWithRepeats

# Ⲃⲁⲑⲙⲟⲥ 45 — PATCH 22
# ⲠABI: rdi=n, rsi=k; rax=P(n,k). Ⲉϣϫⲉ ⲡinput ⲛϥⲥⲏϩ ⲁⲛ ⲏ ⲟⲩoverflow ϣⲱⲡⲉ, rax=0.
.type stage45FallingU64,@function
stage45FallingU64:
    test rsi,rsi
    je .Ls45ff_one
    cmp rsi,rdi
    ja .Ls45ff_zero
    mov eax,1
    xor ecx,ecx
.Ls45ff_loop:
    cmp rcx,rsi
    jae .Ls45ff_done
    mov r8,rdi
    sub r8,rcx
    mul r8
    test rdx,rdx
    jne .Ls45ff_zero
    inc rcx
    jmp .Ls45ff_loop
.Ls45ff_one:
    mov eax,1
.Ls45ff_done:
    ret
.Ls45ff_zero:
    xor eax,eax
    ret
.size stage45FallingU64,.-stage45FallingU64

# ⲠABI: rdi=rank1, rsi=K, rdx=out canonical indices. Ⲡunrank ⲟ ⲛexact ⲕⲁⲧⲁ ⲡlexicographic partial-permutation order.
.type unrankDistinctCutletNames17,@function
unrankDistinctCutletNames17:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    test rdi,rdi
    je .Lucn17_fail
    test rsi,rsi
    je .Lucn17_fail
    cmp rsi,17
    ja .Lucn17_fail
    test rdx,rdx
    je .Lucn17_fail
    mov r15,rdi
    mov r13,rsi
    mov r14,rdx
    mov edi,17
    mov rsi,r13
    call stage45FallingU64
    test rax,rax
    je .Lucn17_fail
    cmp r15,rax
    ja .Lucn17_fail
    dec r15
    xor r12d,r12d
    xor ebx,ebx
.Lucn17_pos:
    cmp rbx,r13
    jae .Lucn17_done
    mov rdi,16
    sub rdi,rbx
    mov rsi,r13
    sub rsi,rbx
    dec rsi
    call stage45FallingU64
    test rax,rax
    je .Lucn17_fail
    mov r11,rax
    mov rax,r15
    xor edx,edx
    div r11
    mov r15,rdx
    mov r9,rax
    mov r8,17
    sub r8,rbx
    cmp r9,r8
    jae .Lucn17_fail
    mov ecx,1
.Lucn17_find:
    cmp ecx,17
    ja .Lucn17_fail
    mov rdx,rcx
    dec rdx
    bt r12,rdx
    jc .Lucn17_used
    test r9,r9
    je .Lucn17_choose
    dec r9
.Lucn17_used:
    inc rcx
    jmp .Lucn17_find
.Lucn17_choose:
    bts r12,rdx
    mov qword ptr [r14+rbx*8],rcx
    inc rbx
    jmp .Lucn17_pos
.Lucn17_done:
    mov rax,r14
    jmp .Lucn17_exit
.Lucn17_fail:
    xor eax,eax
.Lucn17_exit:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size unrankDistinctCutletNames17,.-unrankDistinctCutletNames17

# ⲠABI: rdi=a, rsi=b, rdx=K; eax=1 ⲉϣϫⲉ ⲥⲉⲧⲱⲛ, ⲉⲙⲙⲟⲛ eax=0.
.type stage45CutletNameRowsEqual,@function
stage45CutletNameRowsEqual:
    test rdi,rdi
    je .Ls45re_no
    test rsi,rsi
    je .Ls45re_no
    xor ecx,ecx
.Ls45re_loop:
    cmp rcx,rdx
    jae .Ls45re_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Ls45re_no
    inc rcx
    jmp .Ls45re_loop
.Ls45re_yes:
    mov eax,1
    ret
.Ls45re_no:
    xor eax,eax
    ret
.size stage45CutletNameRowsEqual,.-stage45CutletNameRowsEqual

# Ⲡdetour ⲙⲟⲩⲧⲉ ⲉⲡbad scar ⲛϣⲟⲣⲡ. Ⲡbad ⲃⲱⲕ ⲉⲡsemantic output ⲙⲙⲁⲧⲉ ⲉϣϫⲉ bad==correct.
# ⲠABI: rdi=rank1, rsi=K, rdx=out; rax=out, rdx=live ghost, rcx=1 ⲉϣϫⲉ ⲁⲩreuse ⲙⲡghost ϫⲉ bad==correct.
.type cutletNamesPatch22,@function
cutletNamesPatch22:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Lcnp22_fail
    test r13,r13
    je .Lcnp22_fail
    cmp r13,17
    ja .Lcnp22_fail
    test r14,r14
    je .Lcnp22_fail

    mov rdi,r13
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Lcnp22_fail
    mov r15,rax

    mov rdi,r12
    mov rsi,r13
    mov rdx,r15
    call legacyCutletNamesWithRepeats
    test rax,rax
    je .Lcnp22_fail

    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call unrankDistinctCutletNames17
    test rax,rax
    je .Lcnp22_fail

    mov rdi,r15
    mov rsi,r14
    mov rdx,r13
    call stage45CutletNameRowsEqual
    test eax,eax
    je .Lcnp22_correct

    xor ebx,ebx
.Lcnp22_copy_bad:
    cmp rbx,r13
    jae .Lcnp22_equal_done
    mov rax,qword ptr [r15+rbx*8]
    mov qword ptr [r14+rbx*8],rax
    inc rbx
    jmp .Lcnp22_copy_bad
.Lcnp22_equal_done:
    mov ecx,1
    jmp .Lcnp22_done
.Lcnp22_correct:
    xor ecx,ecx
.Lcnp22_done:
    mov rax,r14
    mov rdx,r15
    jmp .Lcnp22_exit
.Lcnp22_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
.Lcnp22_exit:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size cutletNamesPatch22,.-cutletNamesPatch22

.type monster_stage45_cutlet_names_patch_wrapper,@function
monster_stage45_cutlet_names_patch_wrapper:
    jmp cutletNamesPatch22
.size monster_stage45_cutlet_names_patch_wrapper,.-monster_stage45_cutlet_names_patch_wrapper

.type monster_cutlet_names_route,@function
monster_cutlet_names_route:
    jmp monster_stage45_cutlet_names_patch_wrapper
.size monster_cutlet_names_route,.-monster_cutlet_names_route

# rdi=MonsterContext*. Ⲡhandler ϫⲓ K=6, rank1=1 ⲉⲧⲣⲉⲡbase-17 scar ⲟⲩⲱⲛϩ ⲉⲃⲟⲗ.
# Ⲡrepeat scan ⲟ ⲛdiagnostic ⲙⲙⲁⲧⲉ; ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡrow ϩⲙⲡproduction ⲡⲁⲓ.
.type monster_stage44_legacy_repeated_names_handler,@function
monster_stage44_legacy_repeated_names_handler:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    mov r12,rdi
    test r12,r12
    je .Lms44_fail
    mov qword ptr [r12+CTX_STAGE44_CUTLET_COUNT],6
    mov qword ptr [r12+CTX_STAGE44_SELECTED_RANK],1
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms44_fail
    mov r13,rax
    mov qword ptr [r12+CTX_STAGE44_ROUTE_NAMES],rax

    mov edi,1
    mov esi,6
    mov rdx,r13
    call monster_cutlet_names_route
    test rax,rax
    je .Lms44_fail
    mov qword ptr [r12+CTX_STAGE44_ROUTE_SEEN],1

    xor ebx,ebx
.Lms44_outer:
    cmp rbx,6
    jae .Lms44_scanned
    mov r14,rbx
    inc r14
.Lms44_inner:
    cmp r14,6
    jae .Lms44_next
    mov rax,qword ptr [r13+rbx*8]
    cmp rax,qword ptr [r13+r14*8]
    je .Lms44_repeat
    inc r14
    jmp .Lms44_inner
.Lms44_next:
    inc rbx
    jmp .Lms44_outer
.Lms44_repeat:
    mov qword ptr [r12+CTX_STAGE44_REPEAT_SEEN],1
.Lms44_scanned:
    inc qword ptr [r12+CTX_STAGE44_SEEN]
    mov eax,1
    jmp .Lms44_done
.Lms44_fail:
    xor eax,eax
.Lms44_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size monster_stage44_legacy_repeated_names_handler,.-monster_stage44_legacy_repeated_names_handler

# rdi=MonsterContext*. Ⲡhandler ϩⲁⲣⲉϩ ⲉⲡbad ghost ⲉϥⲟⲛϩ ⲙⲛ ⲡreuse ⲙⲡrow ⲉⲧⲧⲱⲛ.
.type monster_stage45_cutlet_names_patch_handler,@function
monster_stage45_cutlet_names_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms45_fail

    # Ⲡcase ⲉⲧϣⲟⲃⲉ: K=6, rank1=1. Ⲡbad ⲕⲱ ⲛrepeats; ⲡcorrect ⲡⲉ 1..6.
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lms45_fail
    mov r13,rax
    mov edi,1
    mov esi,6
    mov rdx,r13
    call monster_cutlet_names_route
    test rax,rax
    je .Lms45_fail
    test rdx,rdx
    je .Lms45_fail
    mov r14,rdx
    mov qword ptr [r12+CTX_STAGE45_GHOST_NAMES],r14
    mov qword ptr [r12+CTX_STAGE45_GHOST_SEEN],1
    test rcx,rcx
    jne .Lms45_fail
    mov qword ptr [r12+CTX_STAGE45_CORRECT_USED_DIFFERENT],1

    # Ⲡcase ⲉⲧⲧⲱⲛ: K=2, rank1=P(17,2)=272. Ⲡbad ⲙⲛ ⲡcorrect ⲡⲉ [17,16]; ⲡbad ϣϭⲙϭⲟⲙ ⲉⲩreuse ⲙⲙⲟϥ.
    mov edi,16
    call arena_alloc
    test rax,rax
    je .Lms45_fail
    mov r15,rax
    mov edi,272
    mov esi,2
    mov rdx,r15
    call monster_cutlet_names_route
    test rax,rax
    je .Lms45_fail
    test rdx,rdx
    je .Lms45_fail
    cmp rcx,1
    jne .Lms45_fail
    mov qword ptr [r12+CTX_STAGE45_EQUAL_ROUTE_NAMES],r15
    mov qword ptr [r12+CTX_STAGE45_EQUAL_GHOST_NAMES],rdx
    mov qword ptr [r12+CTX_STAGE45_GHOST_REUSED_EQUAL],1
    inc qword ptr [r12+CTX_STAGE45_PATCH_SEEN]
    mov eax,1
    jmp .Lms45_done
.Lms45_fail:
    xor eax,eax
.Lms45_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage45_cutlet_names_patch_handler,.-monster_stage45_cutlet_names_patch_handler


# Ⲃⲁⲑⲙⲟⲥ 46 — DISCOVERY 23
# Ⲡlegacy backend ⲧⲁⲙⲓⲟ ⲛⲟⲩrow ⲛⲓⲙ ⲙⲡbounded month-length family ϩⲙⲡmemory.
# Ⲡpatched backend ⲙⲡⲁⲧϥϣⲟⲟⲡ ϩⲙⲡproduction ⲡⲁⲓ.

# ⲠABI: rdi=E46*, rsi=position, rdx=remaining. eax=1 ⲉϣϫⲉ ⲡenumeration ⲟⲩⲱϣⲃ.
.type stage46EnumerateMonthRowsRec,@function
stage46EnumerateMonthRowsRec:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Ls46emr_fail
    mov r15,qword ptr [r12+E46_SLOTS]
    cmp r13,r15
    jne .Ls46emr_branch
    test r14,r14
    jne .Ls46emr_ok

    mov rax,qword ptr [r12+E46_COUNT]
    cmp rax,-1
    je .Ls46emr_fail
    cmp qword ptr [r12+E46_FILL],0
    je .Ls46emr_leaf_inc
    mov r8,qword ptr [r12+E46_ROWS]
    mov r9,qword ptr [r12+E46_SCRATCH]
    test r8,r8
    je .Ls46emr_fail
    test r9,r9
    je .Ls46emr_fail
    mov rcx,rax
    imul rcx,r15
    jo .Ls46emr_fail
    shl rcx,3
    jc .Ls46emr_fail
    add r8,rcx
    jc .Ls46emr_fail
    xor ebx,ebx
.Ls46emr_copy:
    cmp rbx,r15
    jae .Ls46emr_leaf_inc
    mov r10,qword ptr [r9+rbx*8]
    mov qword ptr [r8+rbx*8],r10
    inc rbx
    jmp .Ls46emr_copy
.Ls46emr_leaf_inc:
    inc qword ptr [r12+E46_COUNT]
    jz .Ls46emr_fail
    jmp .Ls46emr_ok

.Ls46emr_branch:
    cmp r13,r15
    ja .Ls46emr_fail
    mov r11,r15
    sub r11,r13
    dec r11

    mov rax,r11
    imul rax,123
    jo .Ls46emr_fail
    mov r8,4
    cmp r14,rax
    jbe .Ls46emr_low_ready
    mov r8,r14
    sub r8,rax
    cmp r8,4
    jae .Ls46emr_low_ready
    mov r8,4
.Ls46emr_low_ready:

    mov rax,r11
    shl rax,2
    jc .Ls46emr_fail
    cmp r14,rax
    jb .Ls46emr_ok
    mov r9,r14
    sub r9,rax
    cmp r9,123
    jbe .Ls46emr_high_ready
    mov r9,123
.Ls46emr_high_ready:
    cmp r8,r9
    ja .Ls46emr_ok
    mov qword ptr [rbp-48],r9
    mov rbx,r8
.Ls46emr_loop:
    cmp rbx,qword ptr [rbp-48]
    ja .Ls46emr_ok
    mov rax,qword ptr [r12+E46_SCRATCH]
    test rax,rax
    je .Ls46emr_fail
    mov qword ptr [rax+r13*8],rbx
    mov rdi,r12
    lea rsi,[r13+1]
    mov rdx,r14
    sub rdx,rbx
    call stage46EnumerateMonthRowsRec
    test eax,eax
    je .Ls46emr_fail
    inc rbx
    jmp .Ls46emr_loop
.Ls46emr_ok:
    mov eax,1
    jmp .Ls46emr_done
.Ls46emr_fail:
    xor eax,eax
.Ls46emr_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage46EnumerateMonthRowsRec,.-stage46EnumerateMonthRowsRec

# ⲠABI: rdi=yearLength, rsi=monthCount. rax=ML46* ⲛmaterialized legacy list.
.type oldMonthLengthMaterializedList,@function
oldMonthLengthMaterializedList:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r12,rdi
    mov r13,rsi
    test r13,r13
    je .Lomlml_fail
    cmp r13,47
    ja .Lomlml_fail
    mov rax,r13
    shl rax,2
    jc .Lomlml_fail
    cmp r12,rax
    jb .Lomlml_fail
    mov rax,r13
    imul rax,123
    jo .Lomlml_fail
    cmp r12,rax
    ja .Lomlml_fail

    mov rdi,r13
    shl rdi,3
    jc .Lomlml_fail
    call arena_alloc
    test rax,rax
    je .Lomlml_fail
    mov r14,rax

    mov edi,E46_SIZE
    call arena_alloc
    test rax,rax
    je .Lomlml_fail
    mov r15,rax
    mov qword ptr [r15+E46_TOTAL],r12
    mov qword ptr [r15+E46_SLOTS],r13
    mov qword ptr [r15+E46_SCRATCH],r14
    mov qword ptr [r15+E46_ROWS],0
    mov qword ptr [r15+E46_COUNT],0
    mov qword ptr [r15+E46_FILL],0

    mov rdi,r15
    xor esi,esi
    mov rdx,r12
    call stage46EnumerateMonthRowsRec
    test eax,eax
    je .Lomlml_fail
    mov rbx,qword ptr [r15+E46_COUNT]
    test rbx,rbx
    je .Lomlml_fail
    mov qword ptr [rbp-48],rbx

    mov rax,r13
    shl rax,3
    jc .Lomlml_fail
    mov qword ptr [rbp-56],rax
    mul rbx
    test rdx,rdx
    jne .Lomlml_fail
    test rax,rax
    je .Lomlml_fail
    mov rdi,rax
    call arena_alloc
    test rax,rax
    je .Lomlml_fail
    mov qword ptr [rbp-64],rax
    mov qword ptr [r15+E46_ROWS],rax
    mov qword ptr [r15+E46_COUNT],0
    mov qword ptr [r15+E46_FILL],1

    mov rdi,r15
    xor esi,esi
    mov rdx,r12
    call stage46EnumerateMonthRowsRec
    test eax,eax
    je .Lomlml_fail
    mov rbx,qword ptr [rbp-48]
    cmp qword ptr [r15+E46_COUNT],rbx
    jne .Lomlml_fail

    mov rdi,rbx
    call bi_from_u64
    test rax,rax
    je .Lomlml_fail
    mov qword ptr [rbp-72],rax

    mov edi,ML46_SIZE
    call arena_alloc
    test rax,rax
    je .Lomlml_fail
    mov r10,rax
    mov r11,qword ptr [rbp-72]
    mov qword ptr [r10+ML46_COUNT_BIG],r11
    mov qword ptr [r10+ML46_COUNT_U64],rbx
    mov qword ptr [r10+ML46_TOTAL],r12
    mov qword ptr [r10+ML46_SLOTS],r13
    mov r11,qword ptr [rbp-64]
    mov qword ptr [r10+ML46_ROWS],r11
    mov qword ptr [r10+ML46_KIND],1
    mov r11,qword ptr [rbp-56]
    mov qword ptr [r10+ML46_ROW_BYTES],r11
    mov rax,r10
    jmp .Lomlml_done
.Lomlml_fail:
    xor eax,eax
.Lomlml_done:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oldMonthLengthMaterializedList,.-oldMonthLengthMaterializedList

.type legacyMonthLengthMaterializedList,@function
legacyMonthLengthMaterializedList:
    jmp oldMonthLengthMaterializedList
.size legacyMonthLengthMaterializedList,.-legacyMonthLengthMaterializedList

# ⲠABI: rdi=ML46*. rax=BigInt* count.
.type legacyMonthLengthListCount,@function
legacyMonthLengthListCount:
    test rdi,rdi
    je .Llmllc_fail
    mov rax,qword ptr [rdi+ML46_COUNT_BIG]
    ret
.Llmllc_fail:
    xor eax,eax
    ret
.size legacyMonthLengthListCount,.-legacyMonthLengthListCount

# ⲠABI: rdi=ML46*, rsi=rank1 u64, rdx=out[slots]. rax=out ⲉϣϫⲉ success.
.type legacyMonthLengthListItemAt1,@function
legacyMonthLengthListItemAt1:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rdx
    test r12,r12
    je .Llmllia_fail
    test r13,r13
    je .Llmllia_fail
    test rsi,rsi
    je .Llmllia_fail
    cmp qword ptr [r12+ML46_KIND],1
    jne .Llmllia_fail
    cmp rsi,qword ptr [r12+ML46_COUNT_U64]
    ja .Llmllia_fail
    dec rsi
    mov rax,qword ptr [r12+ML46_ROW_BYTES]
    mul rsi
    test rdx,rdx
    jne .Llmllia_fail
    mov r8,qword ptr [r12+ML46_ROWS]
    add r8,rax
    jc .Llmllia_fail
    mov r9,qword ptr [r12+ML46_SLOTS]
    xor ebx,ebx
.Llmllia_copy:
    cmp rbx,r9
    jae .Llmllia_ok
    mov rax,qword ptr [r8+rbx*8]
    mov qword ptr [r13+rbx*8],rax
    inc rbx
    jmp .Llmllia_copy
.Llmllia_ok:
    mov rax,r13
    jmp .Llmllia_done
.Llmllia_fail:
    xor eax,eax
.Llmllia_done:
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size legacyMonthLengthListItemAt1,.-legacyMonthLengthListItemAt1

.type monster_month_length_family_route,@function
monster_month_length_family_route:
    jmp monster_stage47_month_length_patch_wrapper
.size monster_month_length_family_route,.-monster_month_length_family_route

# Ⲡhandler ⲙⲟⲩⲧⲉ ⲉⲡlegacy route ϩⲓ ⲟⲩsmall family ⲉⲧⲣⲉⲡmaterialization ⲣϩⲱⲃ ⲛⲁⲙⲉ.
.type monster_stage46_legacy_month_materialization_handler,@function
monster_stage46_legacy_month_materialization_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lms46_fail
    mov qword ptr [r12+CTX_STAGE46_YEAR_LENGTH],15
    mov qword ptr [r12+CTX_STAGE46_MONTH_COUNT],3
    mov edi,15
    mov esi,3
    call legacyMonthLengthMaterializedList
    test rax,rax
    je .Lms46_fail
    mov r13,rax
    mov qword ptr [r12+CTX_STAGE46_ROUTE_LIST],r13
    mov rax,qword ptr [r13+ML46_KIND]
    mov qword ptr [r12+CTX_STAGE46_ROUTE_KIND],rax
    mov rax,qword ptr [r13+ML46_COUNT_U64]
    mov qword ptr [r12+CTX_STAGE46_ROUTE_COUNT_U64],rax
    mov rax,qword ptr [r13+ML46_ROWS]
    mov qword ptr [r12+CTX_STAGE46_ROUTE_ROWS],rax
    cmp qword ptr [r13+ML46_KIND],1
    jne .Lms46_fail
    mov qword ptr [r12+CTX_STAGE46_LEGACY_MATERIALIZED],1

    mov edi,24
    call arena_alloc
    test rax,rax
    je .Lms46_fail
    mov r14,rax
    mov rdi,r13
    mov esi,1
    mov rdx,r14
    call legacyMonthLengthListItemAt1
    test rax,rax
    je .Lms46_fail
    mov qword ptr [r12+CTX_STAGE46_FIRST_ROW],r14

    mov edi,24
    call arena_alloc
    test rax,rax
    je .Lms46_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,qword ptr [r13+ML46_COUNT_U64]
    mov rdx,r14
    call legacyMonthLengthListItemAt1
    test rax,rax
    je .Lms46_fail
    mov qword ptr [r12+CTX_STAGE46_LAST_ROW],r14
    inc qword ptr [r12+CTX_STAGE46_SEEN]
    mov eax,1
    jmp .Lms46_done
.Lms46_fail:
    xor eax,eax
.Lms46_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage46_legacy_month_materialization_handler,.-monster_stage46_legacy_month_materialization_handler


# Ⲃⲁⲑⲙⲟⲥ 47 — PATCH 23
# Ⲡlegacy materializer ⲟⲩⲏϩ callable. Ⲡdetour ⲕⲱ ⲛⲟⲩDP table ⲙⲙⲁⲧⲉ, ⲛϥⲧⲁⲙⲓⲟ ⲁⲛ ⲛⲛrows ⲧⲏⲣⲟⲩ.

# ⲠABI: rdi=yearLength, rsi=monthCount. rax=VirtualLegacyList*.
.type VirtualLegacyList,@function
VirtualLegacyList:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,88
    mov r12,rdi
    mov r13,rsi
    test r13,r13
    je .Lvll_fail
    cmp r13,47
    ja .Lvll_fail
    mov rax,r13
    shl rax,2
    jc .Lvll_fail
    cmp r12,rax
    jb .Lvll_fail
    mov rdx,r13
    imul rdx,123
    jo .Lvll_fail
    cmp r12,rdx
    ja .Lvll_fail
    mov r14,r12
    sub r14,rax
    mov r15,r14
    inc r15
    jz .Lvll_fail

    mov edi,ML47_SIZE
    call arena_alloc
    test rax,rax
    je .Lvll_fail
    mov qword ptr [rbp-72],rax
    mov qword ptr [rax+ML46_TOTAL],r12
    mov qword ptr [rax+ML46_SLOTS],r13
    mov qword ptr [rax+ML46_ROWS],0
    mov qword ptr [rax+ML46_KIND],2
    mov rcx,r13
    shl rcx,3
    jc .Lvll_fail
    mov qword ptr [rax+ML46_ROW_BYTES],rcx
    mov qword ptr [rax+ML47_RESIDUAL],r14
    mov qword ptr [rax+ML47_STRIDE],r15
    mov qword ptr [rax+ML47_GHOST_LIST],0
    mov qword ptr [rax+ML47_GHOST_SEEN],0
    mov qword ptr [rax+ML47_GHOST_SKIPPED],0

    mov rax,r13
    inc rax
    mul r15
    test rdx,rdx
    jne .Lvll_fail
    shl rax,3
    jc .Lvll_fail
    mov rdi,rax
    call arena_alloc
    test rax,rax
    je .Lvll_fail
    mov qword ptr [rbp-48],rax
    mov rcx,qword ptr [rbp-72]
    mov qword ptr [rcx+ML47_DP_TABLE],rax

    xor edi,edi
    call bi_from_u64
    test rax,rax
    je .Lvll_fail
    mov qword ptr [rbp-56],rax
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Lvll_fail
    mov qword ptr [rbp-64],rax

    mov rdi,qword ptr [rbp-48]
    mov rax,qword ptr [rbp-56]
    mov rcx,r15
    rep stosq
    mov rdx,qword ptr [rbp-48]
    mov rax,qword ptr [rbp-64]
    mov qword ptr [rdx],rax

    mov rbx,1
.Lvll_k_loop:
    cmp rbx,r13
    ja .Lvll_table_done
    mov qword ptr [rbp-80],0
    mov rax,qword ptr [rbp-56]
    mov qword ptr [rbp-88],rax
.Lvll_s_loop:
    mov rcx,qword ptr [rbp-80]
    cmp rcx,r14
    ja .Lvll_next_k
    mov rax,rbx
    dec rax
    imul rax,r15
    add rax,rcx
    mov rdx,qword ptr [rbp-48]
    mov rsi,qword ptr [rdx+rax*8]
    mov rdi,qword ptr [rbp-88]
    call bi_add_abs
    test rax,rax
    je .Lvll_fail
    mov qword ptr [rbp-88],rax

    mov rcx,qword ptr [rbp-80]
    cmp rcx,120
    jb .Lvll_store_cell
    mov rax,rbx
    dec rax
    imul rax,r15
    lea rax,[rax+rcx-120]
    mov rdx,qword ptr [rbp-48]
    mov rsi,qword ptr [rdx+rax*8]
    mov rdi,qword ptr [rbp-88]
    call bi_sub_abs
    test rax,rax
    je .Lvll_fail
    mov qword ptr [rbp-88],rax
.Lvll_store_cell:
    mov rcx,qword ptr [rbp-80]
    mov rax,rbx
    imul rax,r15
    add rax,rcx
    mov rdx,qword ptr [rbp-48]
    mov r9,qword ptr [rbp-88]
    mov qword ptr [rdx+rax*8],r9
    inc qword ptr [rbp-80]
    jmp .Lvll_s_loop
.Lvll_next_k:
    inc rbx
    jmp .Lvll_k_loop

.Lvll_table_done:
    mov rax,r13
    imul rax,r15
    add rax,r14
    mov rdx,qword ptr [rbp-48]
    mov rax,qword ptr [rdx+rax*8]
    test rax,rax
    je .Lvll_fail
    mov qword ptr [rbp-96],rax
    mov rdx,qword ptr [rbp-72]
    mov qword ptr [rdx+ML46_COUNT_BIG],rax
    mov qword ptr [rdx+ML46_COUNT_U64],0
    cmp qword ptr [rax+BI_LEN],1
    jne .Lvll_ready
    mov rcx,qword ptr [rax+BI_DATA]
    test rcx,rcx
    je .Lvll_ready
    mov rcx,qword ptr [rcx]
    mov qword ptr [rdx+ML46_COUNT_U64],rcx
.Lvll_ready:
    mov rax,qword ptr [rbp-72]
    jmp .Lvll_done
.Lvll_fail:
    xor eax,eax
.Lvll_done:
    add rsp,88
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size VirtualLegacyList,.-VirtualLegacyList

# ⲠABI: rdi=VirtualLegacyList*. rax=BigInt*.
.type virtualMonthLengthListCount,@function
virtualMonthLengthListCount:
    test rdi,rdi
    je .Lvmlc_fail
    cmp qword ptr [rdi+ML46_KIND],2
    jne .Lvmlc_fail
    mov rax,qword ptr [rdi+ML46_COUNT_BIG]
    ret
.Lvmlc_fail:
    xor eax,eax
    ret
.size virtualMonthLengthListCount,.-virtualMonthLengthListCount

# ⲠABI: rdi=VirtualLegacyList*, rsi=BigInt* rank1, rdx=out[slots]. rax=out ⲉϣϫⲉ success.
.type virtualMonthLengthListItemAt1Big,@function
virtualMonthLengthListItemAt1Big:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Lvmlib_fail
    test r13,r13
    je .Lvmlib_fail
    test r14,r14
    je .Lvmlib_fail
    cmp qword ptr [r12+ML46_KIND],2
    jne .Lvmlib_fail
    cmp qword ptr [r13+BI_SIGN],1
    jne .Lvmlib_fail
    mov rdi,r13
    call bi_is_zero
    test eax,eax
    jne .Lvmlib_fail
    mov rdi,r13
    mov rsi,qword ptr [r12+ML46_COUNT_BIG]
    call bi_cmp
    cmp eax,0
    jg .Lvmlib_fail
    mov rdi,r13
    call bi_clone
    test rax,rax
    je .Lvmlib_fail
    mov r15,rax
    mov qword ptr [rbp-48],0
    mov rax,qword ptr [r12+ML47_RESIDUAL]
    mov qword ptr [rbp-56],rax
    mov rbx,qword ptr [r12+ML46_SLOTS]

.Lvmlib_position:
    mov rcx,qword ptr [rbp-48]
    cmp rcx,rbx
    jae .Lvmlib_finish
    mov qword ptr [rbp-64],0
.Lvmlib_candidate:
    mov r8,qword ptr [rbp-64]
    cmp r8,119
    ja .Lvmlib_fail
    cmp r8,qword ptr [rbp-56]
    ja .Lvmlib_fail
    mov r9,rbx
    sub r9,qword ptr [rbp-48]
    dec r9
    mov r10,qword ptr [rbp-56]
    sub r10,r8
    mov rax,r9
    imul rax,qword ptr [r12+ML47_STRIDE]
    add rax,r10
    mov rdx,qword ptr [r12+ML47_DP_TABLE]
    mov r11,qword ptr [rdx+rax*8]
    test r11,r11
    je .Lvmlib_next_candidate
    cmp qword ptr [r11+BI_LEN],0
    je .Lvmlib_next_candidate
    mov qword ptr [rbp-72],r11
    mov rdi,r15
    mov rsi,r11
    call bi_cmp
    cmp eax,0
    jle .Lvmlib_choose
    mov rdi,r15
    mov rsi,qword ptr [rbp-72]
    call bi_sub_abs
    test rax,rax
    je .Lvmlib_fail
    mov r15,rax
.Lvmlib_next_candidate:
    inc qword ptr [rbp-64]
    jmp .Lvmlib_candidate
.Lvmlib_choose:
    mov rcx,qword ptr [rbp-48]
    mov r8,qword ptr [rbp-64]
    lea r9,[r8+4]
    mov qword ptr [r14+rcx*8],r9
    sub qword ptr [rbp-56],r8
    inc qword ptr [rbp-48]
    jmp .Lvmlib_position
.Lvmlib_finish:
    cmp qword ptr [rbp-56],0
    jne .Lvmlib_fail
    mov rax,r14
    jmp .Lvmlib_done
.Lvmlib_fail:
    xor eax,eax
.Lvmlib_done:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size virtualMonthLengthListItemAt1Big,.-virtualMonthLengthListItemAt1Big

# ⲠABI: rdi=VirtualLegacyList*, rsi=rank1 u64, rdx=out[slots].
.type virtualMonthLengthListItemAt1,@function
virtualMonthLengthListItemAt1:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov r12,rdi
    mov qword ptr [rbp-16],rdx
    mov rdi,rsi
    call bi_from_u64
    test rax,rax
    je .Lvmlia_fail
    mov rdi,r12
    mov rsi,rax
    mov rdx,qword ptr [rbp-16]
    call virtualMonthLengthListItemAt1Big
    jmp .Lvmlia_done
.Lvmlia_fail:
    xor eax,eax
.Lvmlia_done:
    add rsp,8
    pop r12
    leave
    ret
.size virtualMonthLengthListItemAt1,.-virtualMonthLengthListItemAt1

# Ⲡdetour ⲧⲁⲙⲓⲟ ⲙⲡvirtual list. Ⲉϣϫⲉ ⲡfamily ⲕⲟⲩⲓ, ⲛϥⲣⲉⲡlegacy scar ⲉⲣϩⲱⲃ ⲛghost; ⲡghost ⲛϥⲟ ⲁⲛ ⲛauthoritative rows.
.type monthLengthVirtualListPatch23,@function
monthLengthVirtualListPatch23:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    call VirtualLegacyList
    test rax,rax
    je .Lmlvlp_fail
    mov r14,rax
    mov r15,qword ptr [r14+ML46_COUNT_BIG]
    cmp qword ptr [r15+BI_LEN],1
    jne .Lmlvlp_skip_ghost
    mov rax,qword ptr [r15+BI_DATA]
    test rax,rax
    je .Lmlvlp_skip_ghost
    cmp qword ptr [rax],256
    ja .Lmlvlp_skip_ghost
    mov rdi,r12
    mov rsi,r13
    call legacyMonthLengthMaterializedList
    test rax,rax
    je .Lmlvlp_skip_ghost
    mov qword ptr [r14+ML47_GHOST_LIST],rax
    mov qword ptr [r14+ML47_GHOST_SEEN],1
    jmp .Lmlvlp_ok
.Lmlvlp_skip_ghost:
    mov qword ptr [r14+ML47_GHOST_SKIPPED],1
.Lmlvlp_ok:
    mov rax,r14
    jmp .Lmlvlp_done
.Lmlvlp_fail:
    xor eax,eax
.Lmlvlp_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size monthLengthVirtualListPatch23,.-monthLengthVirtualListPatch23

.type monster_stage47_month_length_patch_wrapper,@function
monster_stage47_month_length_patch_wrapper:
    jmp monthLengthVirtualListPatch23
.size monster_stage47_month_length_patch_wrapper,.-monster_stage47_month_length_patch_wrapper

# Ⲡhandler ⲕⲱ ⲙⲡsmall route ⲛvirtual, ⲡfirst/last row, ⲙⲛ ⲡlive small legacy ghost ϩⲙⲡinvocation-local context.
.type monster_stage47_virtual_month_length_patch_handler,@function
monster_stage47_virtual_month_length_patch_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms47_fail
    mov edi,15
    mov esi,3
    call monster_month_length_family_route
    test rax,rax
    je .Lms47_fail
    mov r13,rax
    cmp qword ptr [r13+ML46_KIND],2
    jne .Lms47_fail
    cmp qword ptr [r13+ML46_COUNT_U64],10
    jne .Lms47_fail
    cmp qword ptr [r13+ML46_ROWS],0
    jne .Lms47_fail
    mov qword ptr [r12+CTX_STAGE47_ROUTE_LIST],r13
    mov qword ptr [r12+CTX_STAGE47_ROUTE_KIND],2
    mov rax,qword ptr [r13+ML46_COUNT_BIG]
    mov qword ptr [r12+CTX_STAGE47_COUNT_BIG],rax
    mov rax,qword ptr [r13+ML46_ROWS]
    mov qword ptr [r12+CTX_STAGE47_ROUTE_ROWS],rax
    mov rax,qword ptr [r13+ML47_GHOST_LIST]
    mov qword ptr [r12+CTX_STAGE47_GHOST_LIST],rax
    cmp qword ptr [r13+ML47_GHOST_SEEN],1
    jne .Lms47_fail
    test rax,rax
    je .Lms47_fail
    mov qword ptr [r12+CTX_STAGE47_GHOST_SEEN],1

    mov edi,24
    call arena_alloc
    test rax,rax
    je .Lms47_fail
    mov r14,rax
    mov rdi,r13
    mov esi,1
    mov rdx,r14
    call virtualMonthLengthListItemAt1
    test rax,rax
    je .Lms47_fail
    mov qword ptr [r12+CTX_STAGE47_FIRST_ROW],r14

    mov edi,24
    call arena_alloc
    test rax,rax
    je .Lms47_fail
    mov r15,rax
    mov rdi,r13
    mov esi,10
    mov rdx,r15
    call virtualMonthLengthListItemAt1
    test rax,rax
    je .Lms47_fail
    mov qword ptr [r12+CTX_STAGE47_LAST_ROW],r15
    inc qword ptr [r12+CTX_STAGE47_PATCH_SEEN]
    inc qword ptr [r12+CTX_STAGE47_SEEN]
    mov eax,1
    jmp .Lms47_done
.Lms47_fail:
    xor eax,eax
.Lms47_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage47_virtual_month_length_patch_handler,.-monster_stage47_virtual_month_length_patch_handler

.type calendarDateSpaghetti,@function
calendarDateSpaghetti:
    push rbp
    mov rbp,rsp
    push r12
    call monster_context_new
    mov r12,rax
    mov rdi,r12
    call monster_validate_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage02_legacy_remainder_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage04_legacy_daytag_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage06_legacy_distance_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage08_legacy_stone_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage10_legacy_hidden_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage12_legacy_prior_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage14_legacy_grind_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage16_legacy_permutation_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage18_legacy_fixed_pour_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage20_legacy_inplace_bowl_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage22_overwritable_order_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage23_order46_latch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage24_legacy_next_bowl_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage25_next_bowl_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage26_legacy_biased_selection_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage27_rejection_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage28_legacy_wide_assumption_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage29_wide_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage30_legacy_gate_question_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage31_gate_question_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage32_legacy_year_max_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage33_year_ceiling_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage34_legacy_year5000_tie_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage35_year5000_tie_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage36_legacy_year_jump_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage37_year_walk_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage38_legacy_year_number_cache_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage39_year_cache_guard_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage40_legacy_structure_sauce_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage42_legacy_cutlet_partition_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage44_legacy_repeated_names_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage45_cutlet_names_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage46_legacy_month_materialization_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage47_virtual_month_length_patch_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov eax,2
    jmp .Lcds_done
.Lcds_fail:
    xor eax,eax
.Lcds_done:
    pop r12
    leave
    ret
.size calendarDateSpaghetti,.-calendarDateSpaghetti
