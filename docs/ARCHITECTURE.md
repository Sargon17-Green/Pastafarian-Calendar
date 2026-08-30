# Ⲧⲁⲣⲭⲓⲧⲉⲕⲧⲟⲛⲓⲕⲏ ⲛⲧⲉⲡϣⲟⲣⲡ ⲃⲁⲑⲙⲟⲥ

`MonsterContext` ⲡⲉ ⲡϫⲟⲉⲓⲥ ⲙⲡ `semantic_state` ⲛⲟⲩⲱⲧ ⲛⲧⲉ ⲟⲩ `invocation`. Ⲙⲛ `shared_mutable_semantic_state`.

`MonsterDispatcher` ⲥⲱⲧⲡ ⲛⲟⲩ `handler` ⲕⲁⲧⲁ `phase`. `ValidationManager` ⲥⲱⲧⲙ ⲉⲛ `invariant` ⲁⲩⲱ ⲛϥⲧⲁⲙⲓⲟ ⲁⲛ ⲛⲟⲩⲁⲡⲟⲕⲣⲓⲥⲓⲥ ⲛⲕⲁⲛⲱⲛ. `MetricsShell` ⲥϩⲁⲓ ⲛⲙⲁⲉⲓⲛ ⲙⲙⲁⲧⲉ; ⲛⲥⲉⲃⲱⲕ ⲁⲛ ⲉϩⲟⲩⲛ ⲉⲡⲗⲟⲅⲓⲥⲙⲟⲥ.

Ⲡ `semantic_state` ⲃⲱⲕ ϩⲓⲧⲛ `snapshot -> validate -> commit`. Ⲙⲛ `retry` ⲙⲛ `fallback` ⲛⲡⲁⲧϣ ⲉϥϣⲟⲟⲡ ⲉⲧⲓ.

## OPTIMIZATION — Ⲡϫⲓⲛⲡⲱϣ ⲙⲡⲁⲣⲓⲑⲙⲟⲥ ⲉⲧⲕⲟⲩⲓ

Ⲡ`bi_divmod_u64_abs` ⲡⲱϣ ⲟⲩ `BigInt` ⲛⲁⲡⲟⲗⲩⲧⲟⲛ ϩⲓⲧⲛ ⲟⲩⲁⲣⲓⲑⲙⲟⲥ ⲛ64 `bit` ϩⲛⲟⲩϫⲓⲛⲡⲱϣ ⲛⲛ`limb` ⲁⲩⲱ ⲉϥϩⲁⲣⲉϩ ⲉⲧⲡⲉⲣⲓⲥⲥⲉⲓⲁ.

### EQUIVALENCE

Ⲡⲡⲱϣ ⲉϥⲥϩⲟⲩⲟⲣⲧ ⲙⲛ ⲡⲡⲱϣ ⲛ`BigInt` ⲉⲩϯ ⲛⲟⲩⲕⲟⲩⲟⲧⲁ ⲛⲟⲩⲱⲧ ⲙⲛ ⲟⲩⲡⲉⲣⲓⲥⲥⲉⲓⲁ ⲛⲟⲩⲱⲧ. Ⲙⲛ `floating point`, ⲙⲛ ⲟⲩⲕⲟⲩⲛⲓ ⲛⲁⲣⲓⲑⲙⲟⲥ.

### EDGE CASES

Ⲁⲩⲇⲟⲕⲓⲙⲁⲍⲉ ⲛ0, 1, ⲛⲕⲟⲩⲟⲧⲁ ⲉⲩⲟⲩⲟⲛ ϩⲁϩ ⲛ`limb`, ⲙⲛ ⲛⲡⲱϣ ⲉⲧⲉⲧⲡⲉⲣⲓⲥⲥⲉⲓⲁ ⲛ0 ⲧⲉ ϩⲛⲛⲃⲓⲛⲟⲙⲓⲟⲛ.

### WHY SAFE

Ⲡⲕⲱⲇⲓⲝ ⲥⲟⲡⲥⲡ ⲛⲟⲩϩⲱⲃ ⲛⲟⲩⲱⲧ: ⲡⲡⲱϣ ⲛⲁⲡⲟⲗⲩⲧⲟⲛ. Ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡ`rank` ⲏ ⲙⲡⲧⲱϣ.

## OPTIMIZATION — Ⲡⲙⲉⲙⲟ ⲛⲧϣⲁⲓ ⲛⲛⲙⲏⲛ

Ⲡⲇⲓⲡⲓ ⲛⲧϣⲁⲓ ⲥⲁϩⲱϥ ⲙⲡⲙⲉⲣⲟⲥ `F_a(T)` ⲕⲁⲧⲁ `openedUpTo=a` ⲙⲛ `activeTotal=T`. Ⲡ`activeProduct` ⲥⲉⲗⲟⲅⲓⲍⲉ ⲙⲙⲟϥ ϩⲓⲧⲟⲟⲧϥ ⲙⲡⲉⲣⲓⲥⲧⲁⲥⲓⲥ ⲉⲧϣⲟⲟⲡ.

### EQUIVALENCE

Ⲡⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ ⲛⲟⲩ `state` ⲡⲉ `activeProduct × F_a(T)`. Ⲡ`F_a(T)` ⲉϥⲧⲁϫⲣⲏⲩ ϩⲓⲧⲛ `F_a(T-1) + C(T+L-2,L-2) × F_(a+1)(T+L-1)`, ⲁⲩⲱ `F_m(T)=1`. Ⲧⲉⲓⲁⲡⲟⲇⲉⲓⲝⲓⲥ ⲧⲉ ⲧⲡⲱϣ ⲛⲛⲃⲗⲟⲕ ⲛⲧⲉⲡⲧⲱϣ ⲛⲗⲉⲝⲓⲕⲟⲅⲣⲁⲫⲓⲕⲟⲛ; ⲙⲛ ⲟⲩⲥⲱⲧⲡ ⲛⲃⲣⲣⲉ.

### EDGE CASES

Ⲁⲩⲇⲟⲕⲓⲙⲁⲍⲉ `[2,2] = 2`, `[2,2,2] = 5`, `[2,3] = 3`, ⲙⲛ ⲡ`unrank` ⲛ1 ⲛ`[2,2]`. Ⲡ`smoke` ⲙⲡⲏⲓ ⲛ5000 ⲟⲩⲱϣⲃ ⲛⲧⲁⲡⲟⲕⲣⲓⲥⲓⲥ ⲛ5 ⲙⲙⲉⲣⲟⲥ.

### WHY SAFE

Ⲛⲉ`memo` ⲥⲉϩⲁⲣⲉϩ ⲙⲙⲁⲧⲉ ⲉⲛⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ ⲛⲧⲉⲟⲩ `state` ⲛⲕⲁⲛⲱⲛ. Ⲡ`scratch` ⲥⲉⲕⲟⲧϥ ⲙⲛⲛⲥⲁ ⲡ`copy` ⲛⲟⲩ`BigInt` ⲉϥⲙⲏⲛ. Ⲙⲛ ⲟⲩ`cache hit` ⲉϥⲧⲟϣ ⲕⲁⲧⲁ ⲟⲩⲥϩⲁⲓ ⲛⲣⲁⲛ ⲏ ⲕⲁⲧⲁ ⲟⲩ`locale`.

Ⲡⲧⲱϣ ⲛ560 `limb` ϩⲙⲡ`copy` ⲛ`scratch` ⲟⲩⲧⲱϣ ⲛⲕⲁⲛⲱⲛ ⲉϥⲣⲟⲉⲓⲥ ⲡⲉ: ⲡϩⲁϩ ⲛⲛϣⲁⲓ ⲛϥⲟⲩⲱⲧ ⲁⲛ ⲉ47^5778, ⲁⲩⲱ `47^5778 < 2^(6*5778)`. Ⲡⲁⲓ ⲟⲩⲟⲛϩ ⲉⲃⲟⲗ ϫⲉ 542 `limb` ⲛ64 `bit` ⲣⲱϣⲉ; 560 ⲟⲩⲟⲛ ⲛⲟⲩⲥⲉⲉⲡⲉ ⲁⲩⲱ ⲙⲛ `truncation`.

## Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲃⲁⲑⲙⲟⲥ 2

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage02_legacy_remainder_handler -> monster_remainder_route -> oldRemainder`

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_REMAINDER_INPUT`, `CTX_LEGACY_REMAINDER_RESULT` ⲙⲛ `CTX_LEGACY_REMAINDER_SEEN`. Ⲛⲁⲓ ⲛⲉ ⲛⲧⲉⲡⲉⲓⲣⲱⲧⲉ ⲙⲙⲁⲧⲉ; Ⲙⲛ `savePatch` ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ.

## Ⲡⲡⲁⲧϣ ⲛ`SAVE` ⲙⲡⲃⲁⲑⲙⲟⲥ 3

`oldRemainder` ⲡⲉ ⲡ COPY_COMPATIBILITY ⲛⲗⲉⲅⲁⲥⲓ ⲉϥϣⲟⲟⲡ ⲉⲧⲓ. Ⲛϥⲉϣϣⲱⲡⲉ ⲁⲛ ⲛⲧⲟϥ ⲡⲉ ⲡⲟⲩⲱϣⲃ ⲛⲕⲁⲛⲱⲛ ϩⲓ ⲛⲡⲟⲗⲗⲁⲡⲗⲁⲥⲓⲟⲛ ⲙⲡ`M`.

`monster_remainder_route -> monster_stage03_save_patch_wrapper -> savePatch -> oldRemainder`

Ⲡ`savePatch` ⲡⲉ ⲡ COPY_AUTHORITATIVE ⲙⲡⲉⲓⲙⲉⲣⲟⲥ. Ⲡϫⲓⲛϣⲓⲃⲉ ⲙⲙⲁⲧⲉ ⲡⲉ `0 -> M`. Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_REMAINDER_RESULT` ⲁⲩⲱ ⲉ`CTX_PATCHED_REMAINDER_RESULT` ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ, ⲉⲧⲣⲉⲡⲟⲩⲱϣⲃ ⲛⲗⲉⲅⲁⲥⲓ ⲧⲙⲧⲱⲙⲛⲧ ⲙⲛ ⲡⲟⲩⲱϣⲃ ⲙⲡⲁⲧϣ.

Ⲡ`oldRemainder` ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛϣⲟⲣⲡ ⲛⲟⲩCOPY_DIAGNOSTIC ϩⲙⲡhandler; ⲡⲉϥⲟⲩⲱϣⲃ ⲛϥⲃⲱⲕ ⲁⲛ ⲉϩⲟⲩⲛ ⲉⲡⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ ⲛⲕⲁⲛⲱⲛ. Ⲙⲛ retry ⲏ fallback ⲛⲃⲣⲣⲉ ⲉⲁⲩⲟⲩⲱϩ ⲉϫⲛ ⲡⲉⲓⲃⲁⲑⲙⲟⲥ.

## Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲃⲁⲑⲙⲟⲥ 4

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage04_legacy_daytag_handler -> monster_daytag_route -> oldDayTag`

Ⲡ`oldDayTag` ⲡⲉ ⲡCOPY_AUTHORITATIVE ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ; ⲡⲁⲓ ⲡⲉ ⲡⲡⲗⲁⲛⲏ ⲉⲧⲉⲣⲉⲡⲇⲟⲕⲓⲙⲏ ⲟⲩⲱⲛϩ ⲙⲙⲟϥ. Ⲡ`monster_daytag_route` ⲙⲛ ⲡhandler ⲛⲉ ⲟⲩⲧⲁⲡ ⲉϥⲧⲱⲛ ⲙⲛ ⲡⲗⲉⲅⲁⲥⲓ; ⲙⲛ normalization ⲏ fallback ⲉⲩⲟⲩⲱϩ ⲉϫⲱⲟⲩ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_DAYTAG_CALC_INPUT`, `CTX_LEGACY_DAYTAG_CALC_RESULT`, `CTX_DAYTAG_TARGET_INPUT`, `CTX_LEGACY_DAYTAG_TARGET_RESULT` ⲙⲛ `CTX_LEGACY_DAYTAG_SEEN`. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲙⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ; ⲙⲛ ⲡstate ⲙⲡⲁⲧϣ 02 ⲉϥϣⲟⲟⲡ ⲉⲧⲓ.

## Ⲡⲡⲁⲧϣ ⲙⲡ`dayTag` ⲙⲡⲃⲁⲑⲙⲟⲥ 5

Ⲡ`oldDayTag` ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩCOPY_DIAGNOSTIC ⲛⲗⲉⲅⲁⲥⲓ ϩⲙⲡhandler. Ⲡ`dayTagWithFoundationScar` ⲡⲉ ⲡCOPY_AUTHORITATIVE ⲙⲡⲉⲓⲙⲉⲣⲟⲥ.

`monster_daytag_route -> monster_stage05_daytag_patch_wrapper -> dayTagWithFoundationScar -> oldDayTag`

Ⲡ`dayTagWithFoundationScar` ⲕⲁⲁϥ ⲛⲥⲁ ⲡresult ⲛ`oldDayTag` ϩⲁⲧϩⲏ ⲙⲡ`FOUNDATION`. Ϩⲓ `FOUNDATION` ⲙⲛ ⲙⲛⲛⲥⲱϥ ⲛϥⲟⲩⲱϩ `1`. Ⲡ guard `day == FOUNDATION && n != 1 -> n=1` ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩϣⲟⲩⲱⲃⲉ; ⲙⲡⲟⲩⲧⲁⲕⲟϥ ⲉⲧⲃⲉ ϫⲉ ⲡ`+1` ⲧⲁⲙⲓⲟ ⲙⲡ`1` ϩⲙⲡⲣⲱⲧⲉ ⲛⲧⲉⲛⲟⲩ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡlegacy result ⲙⲛ ⲡpatched result ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ ⲙⲡ`calculationDay` ⲙⲛ ⲡ`targetDay`. Ⲡpatched result ⲙⲙⲁⲧⲉ ⲡⲉ ⲡⲣⲱⲧⲉ ⲛCOPY_AUTHORITATIVE; ⲡlegacy result ⲛϥⲧⲙϫⲓ ⲛⲟⲩⲧⲟϣ ⲛⲕⲁⲛⲱⲛ.

## Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲃⲁⲑⲙⲟⲥ 6

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage06_legacy_distance_handler -> monster_distance_route -> oldDistance`

Ⲡ`oldDistance` ⲡⲉ ⲡCOPY_AUTHORITATIVE ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ. Ⲛϥϫⲓ ⲙⲡⲇⲓⲁⲫⲟⲣⲁ ⲛⲁⲡⲟⲗⲩⲧⲟⲛ ⲛⲛ`dayTagWithFoundationScar` ⲙⲡⲉⲩⲥⲛⲁⲩ, ⲁⲗⲗⲁ ⲛϥϫⲓ ⲁⲛ ⲙⲡⲇⲓⲁⲫⲟⲣⲁ ⲛⲛϩⲟⲟⲩ ⲛⲧⲉⲡⲧⲁⲝⲓⲥ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_DISTANCE_RESULT`, `CTX_DISTANCE_ROUTE_RESULT`, `CTX_LEGACY_DISTANCE_SEEN` ⲙⲛ `CTX_DISTANCE_ROUTE_SEEN`. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ. Ⲙⲛ normalization, wrapper ⲏ fallback ⲙⲡ Patch 03 ⲉϥϣⲟⲟⲡ ⲉⲧⲓ.

## Ⲡⲡⲁⲧϣ ⲙⲡ distance ⲙⲡⲃⲁⲑⲙⲟⲥ 7

Ⲡ`oldDistance` ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩCOPY_DIAGNOSTIC ⲛⲗⲉⲅⲁⲥⲓ ϩⲙⲡhandler. Ⲡ`distanceWithChronologicalScar` ⲡⲉ ⲡCOPY_AUTHORITATIVE ⲙⲡⲉⲓⲙⲉⲣⲟⲥ.

`monster_distance_route -> monster_stage07_distance_patch_wrapper -> distanceWithChronologicalScar -> oldDistance`

ⲠCOPY_AUTHORITATIVE ⲙⲉⲧⲣⲉ ⲙⲡ`abs(targetDay-calculationDay)`, ⲛϥϣⲓⲃⲉ ⲙⲡlegacy ⲙⲙⲁⲧⲉ ⲉϣϫⲉ ⲛϥϣⲟⲃⲉ, ⲁⲩⲱ ⲛϥⲟⲩⲱϩ `1`. Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_CHRONOLOGICAL_DISTANCE`, `CTX_PATCHED_DISTANCE_RESULT` ⲙⲛ `CTX_DISTANCE_PATCH_SEEN`; ⲙⲛ logs ⲏ metrics ⲉⲩⲣϩⲱⲃ ϩⲙⲡⲉⲓⲧⲟϣ.

## Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲃⲁⲑⲙⲟⲥ 8

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage08_legacy_stone_handler -> monster_stone_mutation_route -> mutateStonesWrong`

Ⲡ`mutateStonesWrong` ⲡⲉ ⲡCOPY_AUTHORITATIVE ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ. Ⲛϥϣⲓⲃⲉ ⲙⲡarray ⲛ5 ⲛⲱⲛⲉ ϩⲛ ⲡⲉϥⲙⲁ, ⲁⲩⲱ ⲛⲗⲟⲅⲓⲥⲙⲟⲥ ⲉⲧⲛⲏⲩ ⲥⲉϫⲓ ⲛⲧⲓⲙⲏ ⲉⲁⲩⲥϩⲁⲓⲟⲩ ⲏⲇⲏ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_STONE_ROW`, `CTX_STONE_ROUTE_RESULT`, `CTX_LEGACY_STONE_SEEN`, `CTX_STONE_ROUTE_SEEN` ⲙⲛ `CTX_STONE_ITERATION`. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ. Ⲙⲛ `stonePatch`, `vaultOld`, `garbage overwrite` ⲏ snapshot ⲙⲡ Patch 04 ⲉϥϣⲟⲟⲡ ⲉⲧⲓ.


## Ⲡⲡⲁⲧϣ ⲛⲛⲱⲛⲉ ⲙⲡⲃⲁⲑⲙⲟⲥ 9

Ⲡ`mutateStonesWrong` ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩCOPY_DIAGNOSTIC ⲛⲗⲉⲅⲁⲥⲓ ϩⲙⲡhandler ⲁⲩⲱ ⲛⲟⲩcall ⲛⲁⲅⲕⲁⲓⲟⲛ ϩⲙⲡ`stonePatch`. Ⲙⲡⲟⲩⲧⲁⲕⲟϥ.

`monster_stone_mutation_route -> monster_stage09_stone_patch_wrapper -> stonePatch -> mutateStonesWrong`

Ⲡ`stonePatch` ⲣ `old = clone(S)` ⲁⲩⲱ `garbage = mutateStonesWrong(i, clone(S))`. Ⲙⲛⲛⲥⲱⲥ ⲛϥⲥϩⲁⲓ ⲛ5 ⲛⲧⲓⲙⲏ ⲙⲡgarbage ϩⲓⲧⲛ ⲛⲗⲟⲅⲓⲥⲙⲟⲥ ⲉⲧϫⲓ ⲙⲙⲁⲧⲉ ϩⲙⲡ`old`. Ⲉⲧⲃⲉ ϫⲉ ⲛBigInt ⲙⲡrow ⲛⲉ immutable, ⲡsnapshot ⲛ40 bytes ⲛpointer ⲧⲁϫⲣⲏⲩ ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲁⲛ ⲉⲟⲩstate ⲛⲃⲣⲣⲉ.

Ⲡ`monster_stage09_stone_patch_wrapper` ⲕⲱ ⲛ5 ⲛpointer ⲙⲡpatched garbage ⲉϩⲟⲩⲛ ⲉⲡrow ⲉⲧⲁϥϫⲓ ⲁⲩⲱ ⲛϥⲕⲧⲟ ⲙⲡpointer ⲛⲟⲩⲱⲧ. Ⲡⲁⲓ ⲡⲉ ⲟⲩCOPY_COMPATIBILITY ⲉϥⲧⲱⲛ ⲙⲛ ⲡCOPY_AUTHORITATIVE ϩⲛ ⲛ5 ⲛⲧⲓⲙⲏ.

Ⲡ`getStoneTableThroughLegacyBuilder` ⲕⲱ ⲉϩⲣⲁⲓ ⲛ46 ⲛrows ⲛⲧⲉⲡtable, ⲁⲩⲱ row ⲛⲓⲙ ⲙⲛⲛⲥⲁ ⲡϣⲟⲣⲡ ⲃⲱⲕ ϩⲓⲧⲛ `stonePatch`. Ⲡvalidation ⲙⲡStage 9 ⲥⲙⲓⲛⲉ ⲛ230 ⲛBigInt ⲙⲛ ⲡoracle ⲛⲧⲉⲡⲉⲓⲕⲱⲇⲓⲝ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡlegacy garbage row ⲙⲛ ⲡpatch input ⲙⲛ ⲡpatched row ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ; ⲙⲛ logs ⲏ metrics ⲉⲩⲧⲟϣ ⲙⲡⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ.

## Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲃⲁⲑⲙⲟⲥ 10

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage10_legacy_hidden_handler -> monster_hidden_route -> legacyHiddenAtNearnessWrong`

Ⲡ`buildHiddenWithBackwardStorage` ⲗⲟⲅⲓⲍⲉ ⲛ7 ⲛhidden ⲕⲁⲧⲁ ⲛcoefficient ⲙⲛ ⲛ7 ⲛgrind ⲛⲕⲁⲛⲱⲛ, ⲁⲩⲱ ⲛϥⲕⲱ ⲙⲙⲟⲟⲩ ϩⲛ ⲡarray ⲕⲁⲧⲁ `hidden7..hidden1`. Ⲡ`legacyHiddenAtNearnessWrong` ⲡⲉ ⲡCOPY_AUTHORITATIVE ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ; ⲛϥϫⲓ ⲙⲡslot `k` ⲁϫⲛ ⲟⲩtranslation.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡpointer ⲙⲡbackward storage, ⲡ`k` ⲛⲧⲉⲡquery, ⲡlegacy result, ⲙⲛ ⲛcounter ⲙⲡstorage ⲙⲛ ⲡquery. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ.

## OPTIMIZATION — Ⲡprefix ⲛ7 ⲛrow ⲛⲧⲉⲛⲱⲛⲉ

Ⲡ`getHiddenStonePrefixThroughLegacyBuilder` ⲕⲱ ⲉϩⲣⲁⲓ ⲙⲙⲁⲧⲉ ⲛrow 1..7, ϫⲉ ⲛhidden ⲙⲡⲉⲓⲧⲟϣ ⲛⲥⲉⲙⲟⲩⲧⲉ ⲁⲛ ⲉrow 8..46. Ⲛrow 2..7 ⲥⲉⲛⲏⲩ ⲟⲛ ϩⲓⲧⲛ `stonePatch`, ⲉⲣⲉ `mutateStonesWrong` ⲙⲟⲟϣⲉ ϩⲙⲡⲣⲱⲧⲉ.

### EQUIVALENCE

Ⲡprefix ⲡⲉ ⲛ7 ⲛrow ⲛϣⲟⲣⲡ ⲛⲧⲉ `getStoneTableThroughLegacyBuilder`. Ⲙⲛ row ⲛⲃⲣⲣⲉ, ⲙⲛ formula ⲛⲃⲣⲣⲉ, ⲁⲩⲱ ⲙⲛ ⲟⲩⲧⲱϣ ⲉϥϣⲟⲃⲉ.

### EDGE CASES

Ⲁⲩⲇⲟⲕⲓⲙⲁⲍⲉ ⲙⲡStage 9 ⲉϫⲛ 46 ⲛrow ⲧⲏⲣⲟⲩ, ⲁⲩⲱ ⲡStage 10 ⲥⲙⲓⲛⲉ ⲛhidden ⲉⲧⲉⲣⲉⲩϫⲓ ⲙⲙⲁⲩ ⲛrow 1..7 ⲙⲛ ⲡoracle.

### WHY SAFE

Ⲡⲕⲱⲇⲓⲝ ⲧⲱϣ ⲙⲙⲁⲧⲉ ⲛⲛrow ⲉⲧⲉⲣⲉⲡhidden calculation ⲁⲛⲁⲅⲕⲁⲍⲉ ⲙⲙⲟⲟⲩ. Ⲛrow ⲉⲧⲟⲩⲏⲩ ⲛⲥⲉϫⲓ ⲁⲛ ⲙⲡⲉⲓⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡϫⲓⲛⲧⲙⲧⲁⲙⲓⲟ ⲙⲙⲟⲟⲩ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡsemantic result.

## Ⲡⲡⲁⲧϣ ⲙⲡhidden access ⲙⲡⲃⲁⲑⲙⲟⲥ 11

Ⲡ`buildHiddenWithBackwardStorage` ⲟⲩⲏϩ ⲉϥⲕⲱ ⲛⲛhidden ϩⲛ ⲧⲁⲝⲓⲥ `hidden7..hidden1`. Ⲡ`legacyHiddenAtNearnessWrong` ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲛⲟⲩCOPY_DIAGNOSTIC ⲁⲩⲱ ⲛϥϫⲓ ⲙⲡslot `k` ⲛⲧⲟϥ.

ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_hidden_route -> monster_stage11_hidden_nearness_patch_wrapper -> hiddenByNearness`

Ⲡ`hiddenByNearness` ⲣ `slot = 8-k` ϩⲙⲡⲧⲱϣ ⲛⲟⲩⲱⲧ. Ⲙⲛ allocation, mutation, sorting ⲏ copy ⲙⲡarray ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓⲡⲁⲧϣ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_HIDDEN_QUERY_RESULT` ⲙⲛ `CTX_PATCHED_HIDDEN_QUERY_RESULT` ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ. Ⲡlegacy result ⲛϥⲧⲙⲃⲱⲕ ⲉϩⲟⲩⲛ ⲉⲡsemantic result; ⲡpatched result ⲡⲉ ⲡⲣⲱⲧⲉ ⲛCOPY_AUTHORITATIVE.

### EQUIVALENCE

Ⲉϣϫⲉ ⲡ`buildHiddenWithBackwardStorage` ⲥϩⲁⲓ ⲙⲡ`hidden k` ϩⲙⲡslot `8-k`, ⲧⲟⲧⲉ ⲡaccess ⲙⲡslot `8-k` ⲕⲧⲟ ⲙⲡ`hidden k` ⲛⲧⲟϥ. Ⲙⲛ ⲟⲩⲧⲓⲙⲏ ⲛⲃⲣⲣⲉ ⲉⲩⲗⲟⲅⲓⲍⲉ ⲙⲙⲟⲥ; ⲡⲁⲧϣ ⲟ ⲙⲙⲁⲧⲉ ⲛⲟⲩtranslation ⲙⲡindex.

### EDGE CASES

Ⲁⲩⲇⲟⲕⲓⲙⲁⲍⲉ ⲙⲡ`k=1`, `k=4`, `k=7` ⲁⲩⲱ ⲛ7 ⲛ`k` ⲧⲏⲣⲟⲩ. Ⲡstorage ⲧⲱⲛ ⲙⲛ `hidden7..hidden1`; ⲡlegacy access ⲟⲩⲏϩ ⲉϥⲟ ⲛ6 ⲛmismatch; ⲡpatched access ⲟ ⲛ0 ⲛmismatch.

### WHY SAFE

Ⲡⲡⲁⲧϣ ⲛϥⲣ ⲁⲛ ⲟⲩmutation ⲙⲡsemantic state. Ⲛϥϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡpointer ⲉⲧⲕⲏ ⲉϩⲣⲁⲓ ϩⲙⲡbackward array ⲕⲁⲧⲁ ⲟⲩformula ⲛⲧⲟϣ. Ⲙⲛ logs, metrics, cache ⲏ environment ⲉⲩⲧⲟϣ ⲙⲡⲟⲩⲱϣⲃ.


## Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲃⲁⲑⲙⲟⲥ 12

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage12_legacy_prior_handler -> monster_prior_route -> legacyPrior`

Ⲡ`legacyPrior` ⲡⲉ ⲡCOPY_AUTHORITATIVE ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡDISCOVERY ⲡⲁⲓ. Ⲛϥⲗⲟⲅⲓⲍⲉ ⲙⲡ`slot=i-back` ⲁⲩⲱ ⲛϥϫⲓ ⲙⲡpointer ⲙⲡ`dropStore[slot]` ⲙⲙⲁⲧⲉ. Ⲡargument ⲙⲡhidden ⲥⲏϩ ϩⲙⲡcontract ⲙⲡ`monster_prior_route`, ⲁⲗⲗⲁ ⲡlegacy ⲛϥϫⲓ ⲙⲙⲟϥ ⲁⲛ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_DROP_STORE`, `CTX_PRIOR_I`, `CTX_PRIOR_BACK`, `CTX_LEGACY_PRIOR_RESULT`, `CTX_PRIOR_ROUTE_RESULT`, `CTX_LEGACY_PRIOR_SEEN` ⲙⲛ `CTX_PRIOR_ROUTE_SEEN`. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ.

Ⲡhandler ⲧⲁⲙⲓⲟ ⲛⲟⲩdropStore ⲉϥⲕⲱ ⲛlogical slot -6..8. Ⲛslot 0..-6 ⲥⲉⲟ ⲛ0 ϩⲙⲡlegacy store, ϩⲟⲡⲟⲩ ⲡhidden storage ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ϩⲛ ⲟⲩstate ⲉϥϣⲟⲃⲉ. Ⲙⲛ normalization ⲏ fallback ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ.


## Ⲡprior detour ⲙⲡⲃⲁⲑⲙⲟⲥ 13

Ⲡ`legacyPrior` ⲟⲩⲏϩ ⲉϥⲟ ⲛCOPY_DIAGNOSTIC ⲁⲩⲱ ⲟⲛ ⲡⲣⲱⲧⲉ ⲛvisible predecessor ϩⲙⲡCOPY_AUTHORITATIVE. Ⲡ`priorPatch` ⲡⲉ ⲡresolver ⲙⲡslot: `slot>=1` ⲕⲧⲟ ⲉ`legacyPrior`; `slot<=0` ⲕⲧⲟ ⲉ`hiddenByNearness` ϩⲓⲧⲛ `k=1-slot`.

`monster_prior_route -> monster_stage13_prior_patch_wrapper -> priorPatch -> {legacyPrior | hiddenByNearness}`

Ⲡ`CTX_LEGACY_PRIOR_RESULT` ⲙⲛ ⲡ`CTX_PATCHED_PRIOR_RESULT` ⲥⲉϣⲟⲟⲡ ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ. Ⲡroute ⲙⲡpatch ⲡⲉ ⲡCOPY_AUTHORITATIVE; ⲡlegacy call ⲙⲡslot 0 ⲡⲉ ⲡCOPY_DIAGNOSTIC.
