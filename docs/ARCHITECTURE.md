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

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡⲕⲱⲇⲓⲝ ⲥⲟⲡⲥⲡ ⲛⲟⲩϩⲱⲃ ⲛⲟⲩⲱⲧ: ⲡⲡⲱϣ ⲛⲁⲡⲟⲗⲩⲧⲟⲛ. Ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡ`rank` ⲏ ⲙⲡⲧⲱϣ.

## OPTIMIZATION — Ⲡⲙⲉⲙⲟ ⲛⲧϣⲁⲓ ⲛⲛⲙⲏⲛ

Ⲡⲇⲓⲡⲓ ⲛⲧϣⲁⲓ ⲥⲁϩⲱϥ ⲙⲡⲙⲉⲣⲟⲥ `F_a(T)` ⲕⲁⲧⲁ `openedUpTo=a` ⲙⲛ `activeTotal=T`. Ⲡ`activeProduct` ⲥⲉⲗⲟⲅⲓⲍⲉ ⲙⲙⲟϥ ϩⲓⲧⲟⲟⲧϥ ⲙⲡⲉⲣⲓⲥⲧⲁⲥⲓⲥ ⲉⲧϣⲟⲟⲡ.

### EQUIVALENCE

Ⲡⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ ⲛⲟⲩ `state` ⲡⲉ `activeProduct × F_a(T)`. Ⲡ`F_a(T)` ⲉϥⲧⲁϫⲣⲏⲩ ϩⲓⲧⲛ `F_a(T-1) + C(T+L-2,L-2) × F_(a+1)(T+L-1)`, ⲁⲩⲱ `F_m(T)=1`. Ⲧⲉⲓⲁⲡⲟⲇⲉⲓⲝⲓⲥ ⲧⲉ ⲧⲡⲱϣ ⲛⲛⲃⲗⲟⲕ ⲛⲧⲉⲡⲧⲱϣ ⲛⲗⲉⲝⲓⲕⲟⲅⲣⲁⲫⲓⲕⲟⲛ; ⲙⲛ ⲟⲩⲥⲱⲧⲡ ⲛⲃⲣⲣⲉ.

### EDGE CASES

Ⲁⲩⲇⲟⲕⲓⲙⲁⲍⲉ `[2,2] = 2`, `[2,2,2] = 5`, `[2,3] = 3`, ⲙⲛ ⲡ`unrank` ⲛ1 ⲛ`[2,2]`. Ⲡ`smoke` ⲙⲡⲏⲓ ⲛ5000 ⲟⲩⲱϣⲃ ⲛⲧⲁⲡⲟⲕⲣⲓⲥⲓⲥ ⲛ5 ⲙⲙⲉⲣⲟⲥ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

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

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

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

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

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

## Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡⲃⲁⲑⲙⲟⲥ 14

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage14_legacy_grind_handler -> monster_visible_drop_route -> oneVisibleDropLegacyGrindIndexWrong -> legacyGrindRowAtIndex`

Ⲡgrind table ⲙⲡDISCOVERY ϩⲁⲣⲉϩ ⲛ11 ⲛrow ⲛⲙⲉ ϩⲓ index `0..10`. Ⲡlegacy loop ⲙⲟⲟϣⲉ ⲙⲛ `g=1..11`, ⲁⲩⲱ `legacyGrindRowAtIndex` ϫⲓ ⲙⲡ`g` ⲛⲧⲟϥ ⲉϥⲟ ⲛindex. Ⲡrow ⲛⲥⲁ ⲛ11 ⲛrow ⲛⲙⲉ ⲟⲩfence ⲉϥϣⲟⲩⲓⲧ ⲡⲉ; ⲛϥⲟ ⲁⲛ ⲛsentinel ⲙⲡindex 0.

Ⲡ`oneVisibleDropLegacyGrindIndexWrong` ⲟⲩⲏϩ ⲉϥϫⲓ ⲛ1/3/7 predecessor ϩⲓⲧⲛ `priorPatch`, ⲁⲩⲱ ⲛϥϫⲓ ⲛstone ϩⲓⲧⲛ ⲡbuilder ⲙⲡPatch 04. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡⲡⲗⲁⲛⲏ ⲙⲡⲉⲓStage ⲟ ⲙⲙⲁⲧⲉ ⲛⲟⲩgrind-indexing divergence, ⲛϥⲧⲱⲙⲛⲧ ⲁⲛ ⲙⲛ ⲛscar ⲛϣⲟⲣⲡ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_VISIBLE_DROP_RESULT`, `CTX_VISIBLE_DROP_ROUTE_RESULT`, `CTX_LEGACY_GRIND_ROW1`, `CTX_LEGACY_GRIND_TABLE_SEEN`, `CTX_LEGACY_VISIBLE_DROP_SEEN` ⲙⲛ `CTX_VISIBLE_DROP_I`. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ; ⲙⲛ logs, metrics ⲏ global mutable semantic state ⲉⲩⲧⲟϣ ⲙⲡvisible drop.

## Ⲡgrind sentinel detour ⲙⲡⲃⲁⲑⲙⲟⲥ 15

Ⲡtable ⲙⲡproduction ϩⲁⲣⲉϩ ⲧⲉⲛⲟⲩ ⲛⲟⲩsentinel row ⲉϥϣⲟⲩⲓⲧ ϩⲓ index 0, ⲙⲛ 11 ⲛgrind row ⲛⲙⲉ ϩⲓ 1..11. Ⲡ`legacyGrindRowAtIndex` ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲙⲟϥ: ⲛϥϫⲓ ⲙⲡindex 1..11 ⲛⲧⲟϥ, ⲁⲩⲱ ⲛϥⲁⲣⲛⲁ ⲙⲡ0.

`monster_visible_drop_route -> monster_stage15_grind_sentinel_patch_wrapper -> oneVisibleDropLegacyGrindIndexWrong -> legacyGrindRowAtIndex`

Ⲡ`grindSentinelRow0` ⲟ ⲛVALIDATION_COPY ⲙⲙⲁⲧⲉ ⲉⲧⲣⲉⲡtest ⲧⲁϫⲣⲟ ⲙⲡsentinel; ⲛϥϫⲓ ⲁⲛ ⲛⲟⲩsemantic decision. Ⲡfence ⲛStage 14 ⲟⲩⲏϩ ⲉϥⲟⲩⲟϩ ⲙⲛⲛⲥⲁ ⲡtable ⲛⲟⲩscar ⲛⲟⲩⲱⲧ.

Ⲡ`CTX_GRIND_SENTINEL_PATCH_SEEN` ⲡⲉ ⲟⲩobservability state ⲙⲡinvocation. Ⲙⲛ ⲟⲩbranch ⲛⲕⲁⲛⲱⲛ ⲉϥⲱϣ ⲙⲙⲟϥ; ⲙⲛ logs, metrics ⲏ environment ⲉⲩϫⲓ ⲛⲟⲩⲧⲟϣ ⲙⲡvisible drop.


## Ⲡⲣⲱⲧⲉ ⲛpermutation ⲙⲡⲃⲁⲑⲙⲟⲥ 16

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage16_legacy_permutation_handler -> monster_permutation_route -> legacyPermutationOrderFromDropWrong -> oldPermutationUnrank0`

Ⲡ`oldPermutationUnrank0` ⲡⲉ ⲟⲩCOPY_AUTHORITATIVE ⲛⲗⲉⲅⲁⲥⲓ ⲙⲡDISCOVERY ⲡⲁⲓ, ⲉϥϫⲓ ⲙⲡrank `0..719`. Ⲡ`legacyPermutationRank0FromDropWrong` ⲧⲁⲙⲓⲟ ⲙⲡ`drop mod 720` ⲛⲟⲩrank0; ⲛϥⲟⲩⲱϩ ⲁⲛ ⲙⲡ`-1`.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_PERMUTATION_DROP`, `CTX_LEGACY_PERMUTATION_RANK0`, `CTX_LEGACY_PERMUTATION_ORDER`, `CTX_PERMUTATION_ROUTE_ORDER`, ⲙⲛ ⲛcounter ⲛⲧⲉⲡlegacy/route. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ.

## Ⲡpermutation-rank detour ⲙⲡⲃⲁⲑⲙⲟⲥ 17

Ⲡ`oldPermutationUnrank0` ⲟⲩⲏϩ ⲉϥⲟ ⲛCOPY_LEGACY ⲙⲛ ⲡcontract `0..719`. Ⲡ`legacyPermutationOrderFromDropWrong` ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ϩⲙⲡhandler ⲛStage 16 ⲛⲟⲩCOPY_DIAGNOSTIC; ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡsemantic output ⲙⲡroute ⲧⲉⲛⲟⲩ.

ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_permutation_route -> monster_stage17_permutation_patch_wrapper -> orderPatchFromValue -> oldPermutationUnrank0`

Ⲡ`permutationOneBasedFromDropPatch08` ⲧⲁⲙⲓⲟ ⲙⲡ`oneBased=regularMod(drop-1,720)+1` ϩⲓⲧⲛ ⲛBigInt helper ⲛⲧⲉⲡline ⲛⲟⲩⲱⲧ. Ⲡ`orderPatchFromValue` ⲧⲁⲙⲓⲟ ⲙⲡ`legacyRank0=oneBased-1` ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉⲡlegacy unranker ⲛⲧⲟϥ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ ⲉⲡlegacy drop/rank/order, ⲡpatched oneBased/rank0/order, ⲙⲛ ⲛcounter ⲛⲧⲉⲡroute/patch. Ⲙⲛ global mutable semantic state ⲉϥⲟⲩⲱϩ.

### EQUIVALENCE

Ⲡregular modulo ⲙⲡhelper ⲟ ⲛ0..719 ⲟⲛ ϩⲓ ⲛnegative inputs; ⲡ`+1` ⲕⲱ ⲙⲡordinal ⲉ1..720; ⲡ`-1` ⲙⲡ`orderPatchFromValue` ⲕⲧⲟ ⲙⲡordinal ⲉⲡdomain ⲛ0..719 ⲙⲡ`oldPermutationUnrank0`.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲡlegacy unranker ⲏ ⲡlegacy caller. Ⲡⲡⲁⲧϣ ⲟ ⲙⲙⲁⲧⲉ ⲛⲟⲩbridge ⲛbase ⲙⲡrank. Ⲙⲛ `bowlAlias` ⲏ pour-position patch ⲙⲡⲃⲁⲑⲙⲟⲥ ⲉⲧⲛⲏⲩ ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓlayer.


## Ⲡⲣⲱⲧⲉ ⲛfixed-pour ⲙⲡⲃⲁⲑⲙⲟⲥ 18

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage18_legacy_fixed_pour_handler -> monster_pour_route -> legacyPoursToFixedBowlIds`

Ⲡ`legacyPoursToFixedBowlIds` ⲙⲟⲩⲧⲉ ⲉ`orderPatchFromValue`, ϩⲟⲡⲟⲩ ⲛ3 ⲛbowl read ⲛⲧⲉⲡpour ⲟⲩⲏϩ ⲉⲩⲙⲟⲟϣⲉ ϩⲓ fixed IDs `1,2,3`. Ⲡorder ⲥⲏϩ ⲉⲃⲟⲗ ⲉⲧⲣⲉⲡscar ⲟⲩⲱⲛϩ, ⲁⲗⲗⲁ ⲛϥⲧⲟϣ ⲁⲛ ⲙⲡsource ⲙⲡbowl ϩⲙⲡⲉⲓStage.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_LEGACY_POUR_DROP`, `CTX_LEGACY_POUR_I`, `CTX_LEGACY_POUR_ORDER`, `CTX_LEGACY_POUR_FIXED_IDS`, `CTX_LEGACY_POUR_OLD_BOWLS`, `CTX_LEGACY_POUR_STONE_ROW`, `CTX_LEGACY_POUR_RESULT`, `CTX_POUR_ROUTE_RESULT`, ⲙⲛ ⲛcounter ⲛⲧⲉⲡlegacy/route.

Ⲡfixed bowl array ⲙⲡhandler ⲟ ⲛdiagnostic state ⲉϥⲧⲟϣ ⲛⲟⲩinvocation; ⲛϥⲟ ⲁⲛ ⲛglobal semantic state. Ⲙⲛ `bowlAlias` ⲏ vault/pending ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓlayer.


## Ⲡbowl-alias detour ⲙⲡⲃⲁⲑⲙⲟⲥ 19

Ⲡ`legacyPoursToFixedBowlIds` ⲟⲩⲏϩ ⲉϥⲟ ⲛCOPY_DIAGNOSTIC ⲙⲛ ⲡfixed-ID scar ⲛStage 18. ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_pour_route -> monster_stage19_bowl_alias_patch_wrapper -> patchedPours -> {installOrderAliases, bowlByLegacyPosition}`

Ⲡ`installOrderAliases` ⲧⲁⲙⲓⲟ ⲛ6 ⲛmapping ⲉⲩⲧⲟϣ ϩⲙⲡinvocation: position ⲕⲧⲟ ⲉbowl ID. Ⲡ`bowlByLegacyPosition` ⲡⲉ ⲡⲣⲱⲧⲉ ⲛⲟⲩⲱⲧ ⲙⲡsemantic bowl read ⲙⲡ3 ⲛpour.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡpatched order, ⲡalias, ⲡpatched pour pointer ⲙⲛ ⲡcounter ⲙⲡpatch. Ⲛlegacy trace ⲙⲡStage 18 ⲟⲩⲏϩ ⲉϥⲥⲏϩ ϩⲛ ⲛfield ⲛϣⲟⲣⲡ.

### EQUIVALENCE

`alias[position]=order[position]`, ⲁⲩⲱ `bowlByLegacyPosition(B,alias,position)=B[order[position]]`. Ⲡpour formula ⲛϥϣⲓⲃⲉ ⲁⲛ; ⲡsource ⲙⲡbowl ⲙⲙⲁⲧⲉ ⲡⲉ ⲡⲉⲛⲧⲁϥⲕⲧⲟ ⲉⲡⲕⲁⲛⲱⲛ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡalias ⲙⲛ ⲡpatched pour buffers ⲥⲉϣⲟⲟⲡ ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ. Ⲙⲛ global mutable semantic state, cache, environment ⲏ observability value ⲉϥϫⲓ ⲛⲟⲩⲧⲟϣ ⲙⲡpour.


## Ⲡⲣⲱⲧⲉ ⲛin-place bowl ⲙⲡⲃⲁⲑⲙⲟⲥ 20

ⲠCOPY_AUTHORITATIVE ⲙⲡDISCOVERY ⲡⲉ:

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage20_legacy_inplace_bowl_handler -> monster_bowl_stir_route -> legacyStirOneDropInPlace`

Ⲡ`legacyStirOneDropInPlace` ϫⲓ ⲙⲡorder ⲙⲛ ⲛpour ⲙⲡPatch 09, ⲁⲗⲗⲁ ⲛϥⲥϩⲁⲓ ⲙⲡbowl output ⲙⲡposition ⲛⲓⲙ ⲉϩⲟⲩⲛ ⲉⲡB ⲛⲧⲉⲩⲛⲟⲩ. Ⲛread ⲙⲡ`id`, `prev`, `next` ⲉⲧⲛⲏⲩ ⲙⲙⲛⲛⲥⲱⲟⲩ ⲥⲉϫⲓ ⲙⲡB ⲡⲁⲓ ⲉⲧⲟⲩⲥϩⲁⲓ ⲉⲣⲟϥ.

Ⲡ`monster_stage20_legacy_inplace_bowl_handler` ⲕⲱ ⲙⲡinput bowls ⲛⲧⲉⲡlayer ⲛϣⲟⲣⲡ ⲉⲃⲟⲗ ⲁϫⲛ ⲟⲩϣⲓⲃⲉ ⲁⲩⲱ ⲛϥⲧⲁⲙⲓⲟ ⲛⲟⲩpointer-vector ⲛworking ⲛⲧⲉⲡinvocation. Ⲡlegacy ⲙⲟⲩⲧⲉ ⲉⲡworking ⲛⲧⲟϥ ⲁⲩⲱ ⲛϥϩⲁⲣⲉϩ ⲉⲡresult ϩⲙⲡ`MonsterContext`.

Ⲡcontext ⲟⲩⲱϩ ⲛ`CTX_LEGACY_BOWL_STIR_DROP`, `CTX_LEGACY_BOWL_STIR_I`, `CTX_LEGACY_BOWL_STIR_INPUT`, `CTX_LEGACY_BOWL_STIR_STONE_ROW`, `CTX_LEGACY_BOWL_STIR_ORDER`, `CTX_LEGACY_BOWL_STIR_POURS`, `CTX_LEGACY_BOWL_STIR_OUTPUT`, `CTX_LEGACY_BOWL_STIR_SEEN`, `CTX_BOWL_STIR_ROUTE_RESULT` ⲙⲛ `CTX_BOWL_STIR_ROUTE_SEEN`.

Ⲙⲛ global mutable semantic state ⲉϥⲟⲩⲱϩ. Ⲡfailure ⲙⲡStage 20 ⲟ ⲛⲟⲩfailure ⲉϥⲧⲟϣ ⲙⲡDISCOVERY; ⲛregression ⲛStage 1–19 ⲟⲩⲏϩ ⲉⲩⲟ ⲛ`GREEN`.


## Ⲡshadow bowl detour ⲙⲡⲃⲁⲑⲙⲟⲥ 21

ⲠCOPY_DIAGNOSTIC ⲟⲩⲏϩ ⲉϥⲟ ⲛ`legacyStirOneDropInPlace`, ⲉϥⲙⲟⲟϣⲉ ϩⲓ clone ⲉϥϣⲟⲃⲉ ϩⲛ `stirOneDropViaShadow`. ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_bowl_stir_route -> monster_stage21_bowl_shadow_patch_wrapper -> stirOneDropViaShadow`

Ⲡdetour ϩⲁⲣⲉϩ ⲛⲟⲩsnapshot ⲛpointer-vector ⲛⲥⲟⲟⲩ ϩⲙⲡarena ⲙⲡinvocation. ⲚBigInt ⲙⲙⲓⲛ ⲙⲙⲟⲟⲩ ⲟ ⲛimmutable ϩⲙⲡruntime; ⲉⲧⲃⲉ ⲡⲁⲓ ⲡvector clone ⲡⲉ ⲡphysical snapshot ⲙⲡsemantic B-state.

Ⲡ`pending` ⲟ ⲛⲟⲩvector ⲛⲥⲟⲟⲩ ⲉϥϣⲟⲩⲓⲧ ⲛϣⲟⲣⲡ. Ⲛwrite ⲧⲏⲣⲟⲩ ⲙⲟⲟϣⲉ ⲉⲣⲟϥ. ⲠB ⲛⲧⲟϥ ⲛϥϣⲓⲃⲉ ⲁⲛ ϣⲁⲛⲧⲉⲡpending ⲙⲟⲩϩ ⲛ6 ⲛvalue, ⲁⲩⲱ ⲡcommit ⲕⲧⲟ ⲛ6 ⲛpointer ⲉⲡB ⲙⲛⲛⲥⲁ ⲡround.

Ⲡroute ⲟⲩⲏϩ ⲉϥϩⲁⲣⲉϩ ⲙⲡpointer contract ⲙⲡStage 20: ⲡB pointer ⲛⲧⲟϥ ⲡⲉ ⲡreturn pointer. Ⲙⲛ global mutable semantic state ⲉϥⲟⲩⲱϩ; `CTX_BOWL_SHADOW_PATCH_SEEN` ⲡⲉ ⲟⲩcounter ⲙⲡinvocation ⲙⲙⲁⲧⲉ.


## Ⲡoverwritable order-memory route ⲙⲡⲃⲁⲑⲙⲟⲥ 22

ⲠCOPY_AUTHORITATIVE ⲙⲡDISCOVERY ⲡⲉ:

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage22_overwritable_order_handler -> monster_order46_memory_route -> legacySauceWithOverwritableOrderMemory`

Ⲡ`legacySauceWithOverwritableOrderMemory` ⲧⲁⲙⲓⲟ ⲛcounts, stones, backward hidden storage, 46 visible drops, alias-based pours, shadow bowl rounds, ⲙⲛ 12 post-stirs. Ⲡsemantic bowl state ⲙⲟⲟϣⲉ ⲕⲁⲧⲁ snapshot/compute/commit; ⲡdefect ⲛStage 22 ⲟ ⲙⲙⲁⲧⲉ ϩⲙⲡorder memory.

Ⲡlegacy order memory ⲥⲏϩ 58 ⲛⲥⲟⲡ. Ⲡdrop46 order ⲥⲏϩ ⲛⲟⲩCOPY_DIAGNOSTIC, ⲁⲗⲗⲁ ⲡ`S22_QUERY_ORDER` ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡ`S22_LEGACY_ORDER_MEMORY` ⲙⲛⲛⲥⲁ ⲡpost-stir 12.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉ`CTX_STAGE22_SAUCE_RESULT`, `CTX_STAGE22_DROP46_DIAGNOSTIC`, `CTX_STAGE22_LEGACY_ORDER_MEMORY`, `CTX_STAGE22_QUERY_ORDER`, `CTX_STAGE22_ORDER_WRITE_COUNT`, `CTX_STAGE22_LAST_SOURCE_KIND`, `CTX_STAGE22_LAST_SOURCE_ORDINAL` ⲙⲛ `CTX_STAGE22_SEEN`.

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲛ6 ⲛfinal bowls ⲙⲛ ⲡdrop46 diagnostic ⲥⲉⲧⲱⲛ ⲙⲛ ⲡsame-line oracle. Ⲡquery ⲙⲙⲁⲧⲉ ⲡⲉ ⲡvalue ⲉϥϣⲟⲃⲉ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡ`EXPECTED_RED` ⲛϥⲛⲁϣ ⲉⲧⲁⲙⲓⲟ ⲁⲛ ⲛⲟⲩsuccess ϩⲓⲧⲛ ⲟⲩbowl ⲏ drop ⲉϥϣⲟⲃⲉ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲛstate ⲧⲏⲣⲟⲩ ⲟ ⲛinvocation-local ϩⲙⲡarena. Ⲙⲛ global mutable semantic state. Ⲙⲛ latch ⲏ cache ⲉϥϫⲓ ⲙⲡorder ⲙⲡdrop 46.


## Ⲡsingle-write order latch ⲙⲡⲃⲁⲑⲙⲟⲥ 23

ⲠCOPY_DIAGNOSTIC ⲡⲉ `legacySauceWithOverwritableOrderMemory`: ⲛϥⲙⲟⲟϣⲉ ⲛⲟⲩⲙⲉ ⲁⲩⲱ ⲛϥϫⲱⲕ ⲙⲡlegacy order memory ϩⲙⲡpost-stir 12.

ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_order46_memory_route -> monster_stage23_order46_latch_patch_wrapper -> sauceWithOrderAt46Latch`

Ⲡ`S23_ORDER46_LATCH` ⲟ ⲛⲟⲩarena buffer ⲛ48 byte ⲙⲡinvocation. Ⲡwrite-site ⲛⲟⲩⲱⲧ ⲟⲩⲱⲛϩ ⲙⲛⲛⲥⲁ ⲡdrop 46 round ⲁⲩⲱ ⲙⲡⲉⲙⲧⲟ ⲙⲡbranch ⲉⲧⲁⲣⲭⲉⲓ ⲙⲡpost-stir loop. Ⲡlatch ⲛϥⲛⲁⲥϩⲁⲓ ⲁⲛ ⲛⲕⲉⲥⲟⲡ.

Ⲡlegacy order memory ⲛⲧⲉⲡCOPY_AUTHORITATIVE ⲟⲩⲏϩ ⲉϥϫⲓ 58 ⲛwrite ⲉⲧⲣⲉⲡscar ⲙⲡStage 22 ⲟⲩⲱⲛϩ. Ⲡquery pointer ⲇⲉ ⲟ ⲛalias ⲙⲡlatch ⲙⲙⲁⲧⲉ.

Ⲡ`monster_stage23_order46_latch_handler` ⲛϥⲣ ⲁⲛ ⲛⲟⲩsecond sauce execution. Ⲛϥϫⲓ ⲙⲙⲁⲧⲉ ⲛStage 23 fields ⲉⲃⲟⲗ ϩⲙⲡresult pointer ⲉⲧⲁⲡStage 22 handler ⲕⲁⲁϥ ϩⲙ `CTX_STAGE22_SAUCE_RESULT`.

### EQUIVALENCE

Ⲡlatch ⲟ ⲛphysical clone ⲛⲧⲉ ⲛ6 ⲛbowl IDs ⲙⲡorder ⲙⲡdrop 46. Ⲛpost-stir ⲛϥⲧⲟϣ ⲁⲛ ⲙⲙⲟϥ. Ⲉⲧⲃⲉ ⲡⲁⲓ `queryOrder == order(drop46)` ⲙⲛⲛⲥⲁ ⲡfull sauce, ϩⲟⲡⲟⲩ ⲡlegacy memory ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡpost-stir 12.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡlatch, ⲡlegacy memory, ⲛbowls ⲙⲛ ⲛdiagnostic ⲧⲏⲣⲟⲩ ⲟ ⲛinvocation-local ϩⲙⲡarena. Ⲙⲛ global mutable semantic state. ⲠCOPY_DIAGNOSTIC ⲛϥⲧⲟϣ ⲁⲛ ⲙⲡquery; ⲡCOPY_AUTHORITATIVE ⲙⲙⲁⲧⲉ ⲡⲉ ⲡsource ⲙⲡsemantic result.


## Ⲡfixed-name next-bowl route ⲙⲡⲃⲁⲑⲙⲟⲥ 24

ⲠCOPY_AUTHORITATIVE ⲙⲡDISCOVERY ⲡⲉ:

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage24_legacy_next_bowl_handler -> monster_next_bowl_route -> legacyNextBowlAdapter -> oldNextBowlFixedName`

Ⲡ`oldNextBowlFixedName` ⲟ ⲛⲟⲩhelper ⲛpure deterministic ⲉϥϩⲁⲣⲉϩ ⲉⲡring ⲛID `1→2→3→4→5→6→1`. Ⲡ`legacyNextBowlAdapter` ϫⲓ ⲙⲡsauceResult pointer ⲉⲧⲣⲉⲡcontract ⲟⲩⲱϩ, ⲁⲗⲗⲁ ⲛϥⲱϣ ⲁⲛ ⲙⲡ`orderAt46Latch`.

Ⲡhandler ϫⲓ ⲙⲡlatch pointer ⲙⲡPATCH 11 ⲉⲃⲟⲗ ϩⲙⲡ`MonsterContext`, ⲛϥϫⲓ ⲙⲡqueried ID ⲙⲡposition ⲙⲙⲁϩ4, ⲁⲩⲱ ⲛϥϩⲁⲣⲉϩ ⲛⲟⲩdirect legacy result ⲙⲛ ⲟⲩroute result ϩⲛ state ⲉⲩϣⲟⲃⲉ.

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲡtest-only VALIDATION_COPY ϭⲓⲛⲉ ⲙⲡqueried ID ϩⲙⲡlatch ⲁⲩⲱ ⲛϥϫⲓ ⲙⲡcircular successor. ϨⲙⲡFoundation latch `[4,5,2,3,6,1]`, ⲡqueried ID `3` ϩⲁ ⲡlegacy successor `4`, ϩⲟⲡⲟⲩ ⲡlatch successor ⲡⲉ `6`. Ⲡⲉⲓdivergence ⲡⲉ ⲡ`EXPECTED_RED` ⲙⲡStage 24.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡstate ⲧⲏⲣϥ ⲟ ⲛinvocation-local. Ⲙⲛ global mutable semantic state. Ⲙⲛ lookup repair ⲏ future patch code ⲉϥϣⲟⲟⲡ ϩⲙⲡroute ⲙⲡDISCOVERY.


## Ⲡcircular next-bowl detour ⲙⲡⲃⲁⲑⲙⲟⲥ 25

ⲠCOPY_DIAGNOSTIC ⲟⲩⲏϩ ⲉϥⲟ ⲛ`oldNextBowlFixedName`, ⲉϥⲙⲟⲟϣⲉ ϩⲓ ⲡfixed numeric ring. ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_next_bowl_route -> monster_stage25_next_bowl_patch_wrapper -> nextBowlQueryPatch`

Ⲡ`nextBowlQueryPatch` ϫⲓ ⲙⲡ`sauceResult.queryOrder` ⲙⲡPATCH 11, ⲉⲧⲉ ⲟⲩalias ⲙⲡsingle-write `orderAt46Latch` ⲡⲉ. Ⲡqueried ID ϫⲓ ⲛⲟⲩposition ⲛⲟⲩⲱⲧ ϩⲙⲡpermutation; ⲡsuccessor ⲡⲉ ⲡelement ⲉⲧⲛⲏⲩ, ⲙⲛ wrap ⲙⲡposition 6 ⲉⲡposition 1.

### EQUIVALENCE

Ⲉⲡⲉⲓⲇⲏ ⲡ`queryOrder` ⲟ ⲛⲟⲩpermutation ⲛⲛID `1..6`, ⲡlookup ⲛqueried ID ⲉϥϣⲟⲟⲡ ⲛⲟⲩⲱⲧ. Ⲡcircular successor ⲡⲁⲓ ⲡⲉ ⲡnext bowl ⲉⲧⲧⲟϣ ϩⲙⲡlatched order. Ⲡfixed-name legacy result ⲟ ⲛdiagnostic ⲙⲙⲁⲧⲉ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡpatch ⲛϥⲥϩⲁⲓ ⲁⲛ ⲉⲡlatch ⲁⲩⲱ ⲛϥⲧⲁⲙⲓⲟ ⲁⲛ ⲛⲟⲩglobal state. Ⲡposition ⲙⲛ ⲡpatched output ⲥⲉϩⲁⲣⲉϩ ϩⲙⲡ`MonsterContext` ⲙⲡinvocation ⲙⲙⲁⲧⲉ. Ⲡlegacy scar ⲟⲩⲏϩ callable ⲁⲩⲱ ⲉϥⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩⲙⲉ.


## Ⲡbiased-selection legacy route ⲙⲡⲃⲁⲑⲙⲟⲥ 26

ⲠCOPY_AUTHORITATIVE ⲙⲡDISCOVERY ⲡⲉ:

`calendarDateSpaghetti -> monster_stage26_legacy_biased_selection_handler -> monster_biased_selection_route -> legacyBiasedSelectionBeforeRejection -> biasedLegacyPick`

Ⲡ`answerRingThroughPatchedNextBowl` ϫⲓ ⲙⲡfinal bowl state ⲙⲡsingle-write-latch sauce ⲙⲛ ⲡcircular next-bowl ⲙⲡPATCH 12. Ⲡring state ⲟ ⲛⲟⲩarena struct ⲙⲛ `first` BigInt pointer ⲙⲛ `direction` signed qword.

Ⲡ`ringAnswer` ⲕⲱ ⲉⲃⲟⲗ ⲙⲡ`1 + regularMod(first-1 + direction*offset, M_OLD)` ϩⲓⲧⲛ ⲛBigInt helpers ⲙⲡruntime ⲛAssembly.

Ⲡ`biasedLegacyPick` ϫⲓ ⲙⲡanswer ⲙⲡoffset 0 ⲁⲩⲱ ⲛϥⲕⲧⲟ ⲙⲡ`regularMod(x-1,N)+1` ⲛⲧⲉⲩⲛⲟⲩ. Ⲙⲛ semantic branch ⲉϥϫⲓ ⲛⲟⲩacceptance limit ⲏ ⲟⲩoffset ⲛrejection.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡEXPECTED_RED ⲧⲁϫⲣⲏⲩ

Ⲛ3 ⲛFoundation ring ⲛⲧⲉⲡtest ⲥⲉⲧⲱⲛ ⲙⲛ ⲡsame-line oracle ϩⲓ first/direction. Ⲛⲧⲟⲟⲩ ⲧⲏⲣⲟⲩ ⲟ ⲛdescending ring ⲙⲛ `N=first-1`, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡlegacy direct modulo ϯ `1` ⲁⲗⲗⲁ ⲡfirst accepted answer ⲙⲡsame ring ⲟ ⲛ`N`.

Ⲡstate ⲧⲏⲣϥ ⲟ ⲛinvocation-local. Ⲙⲛ global mutable semantic state, ⲙⲛ oracle call ϩⲙⲡproduction, ⲁⲩⲱ ⲙⲛ future rejection code.


## Ⲡshort rejection detour ⲙⲡⲃⲁⲑⲙⲟⲥ 27

ⲠCOPY_DIAGNOSTIC ⲟ ⲛ`legacyBiasedSelectionBeforeRejection -> biasedLegacyPick`, ⲉϥϫⲓ ⲙⲡanswer ⲛoffset 0 ⲁϫⲛ rejection. ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_biased_selection_route -> monster_stage27_rejection_patch_wrapper -> patchedSmallPick`

Ⲡ`patchedSmallPick` ⲧⲁϫⲣⲟ ⲙⲡshort domain `1<=N<=M_OLD`. Ⲡlimit ⲡⲉ `floor(M_OLD/N)*N`. Ⲡoffset ⲁⲣⲭⲉⲓ ϩⲓ 0; ⲡ`ringAnswer` ⲛⲧⲉⲡoffset ⲡⲁⲓ ⲟⲩⲏϩ ⲉϥⲣrejection ⲉϣϫⲉ `x>limit`. Ⲡoffset ⲟⲩⲱϩ ⲙⲙⲁⲧⲉ ϩⲙⲡring ⲛⲟⲩⲱⲧ. Ⲙⲛⲛⲥⲁ ⲡϣⲟⲣⲡ `x<=limit`, ⲡselector ⲛⲗⲉⲅⲁⲥⲓ ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲧⲉⲩⲛⲟⲩ.

### EQUIVALENCE

Ϩⲙⲡshort domain, ⲡacceptance interval ⲡⲉ `1..limit` ⲉⲣⲉ ⲡlength ⲟ ⲛmultiple ⲙⲡN. Ⲉⲧⲃⲉ ⲡⲁⲓ `biasedLegacyPick` ⲙⲛⲛⲥⲁ rejection ⲕⲱ ⲛⲟⲩuniform rank ϩⲛ `1..N`. Ⲡanswer sequence ⲛϥⲧⲟϣ ⲁⲛ ⲛⲕⲉstream; ⲡdetour ⲟⲩⲏϩ ϩⲙⲡsame ring ⲙⲙⲁⲧⲉ.

Ⲡ`N=M_OLD` ⲣ ⲛⲟⲩboundary: `limit=M_OLD`, ⲡoffset 0 ⲟ ⲛaccepted ⲛⲧⲉⲩⲛⲟⲩ. Ⲡ`N=0` ⲙⲛ null ring ⲟ ⲛdeterministic failures. Ⲡ`N>M_OLD` ⲛϥⲧⲟϣ ⲁⲛ ϩⲙⲡshort detour ⲡⲁⲓ, ⲁⲩⲱ ⲙⲛ wide detour ϩⲙⲡStage 27.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡlegacy helper ⲟⲩⲏϩ callable ⲁⲩⲱ ⲉϥⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩⲙⲉ. Ⲡacceptance trace ⲟ ⲛinvocation-local ϩⲙⲡ`MonsterContext`; ⲙⲛ global mutable semantic state. Ⲙⲛ oracle call ϩⲙⲡproduction.


## Ⲡshort-only wide-family scar ⲙⲡⲃⲁⲑⲙⲟⲥ 28

ⲠCOPY_AUTHORITATIVE ⲙⲡDISCOVERY ⲡⲉ:

`calendarDateSpaghetti -> monster_stage28_legacy_wide_assumption_handler -> monster_wide_selection_route -> legacySelectionAssumingNLeM -> patchedSmallPick`

Ⲡ`legacySelectionAssumingNLeM` ⲛϥⲧⲁⲙⲓⲟ ⲁⲛ ⲛⲟⲩnew selection arithmetic; ⲛϥϫⲟⲟⲩ ⲙⲙⲁⲧⲉ ⲙⲡN ⲉⲡshort helper ⲙⲡPATCH 13. Ⲉⲧⲃⲉ ⲡguard `N<=M_OLD`, ⲡroute ⲟ ⲛunsupported ϩⲓ wide families.

ⲠStage 28 handler ϫⲓ ⲙⲡexisting answer-ring pointer ⲙⲡinvocation, ⲕⲱ ⲙⲡ`N=M_OLD+1`, ⲙⲟⲩⲧⲉ ⲉⲡroute, ⲁⲩⲱ ϩⲁⲣⲉϩ ⲉⲡunsupported state ⲁϫⲛ ⲧⲣⲉϥⲕⲧⲟ ⲛⲟⲩfake semantic rank.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡEXPECTED_RED ⲧⲁϫⲣⲏⲩ

Ⲡtest-only validation ϫⲓ ⲙⲡ`oracle_choose_rank_wide` ⲙⲡsame-line Assembly ⲙⲙⲁⲧⲉ. Ⲛfamily `M_OLD+1`, `M_OLD^2`, `M_OLD^3` ⲥⲉⲟ ⲛnormative wide families ⲙⲛ rank ⲉϥϣⲟⲟⲡ, ϩⲟⲡⲟⲩ ⲡshort-only route ϯ null.

Ⲙⲛ wide semantic path ⲉϥϣⲟⲟⲡ ϩⲙⲡproduction. Ⲡstate ⲧⲏⲣϥ ⲟ ⲛinvocation-local ⲁⲩⲱ ⲙⲛ global mutable semantic state.


## Ⲡwide-family detour ⲙⲡⲃⲁⲑⲙⲟⲥ 29

ⲠCOPY_DIAGNOSTIC ⲟ ⲛ`legacySelectionAssumingNLeM -> patchedSmallPick`. Ϩⲓ `N>M_OLD` ⲡlegacy scar ⲕⲧⲟ ⲛnull. ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_wide_selection_route -> monster_stage29_wide_patch_wrapper -> selectionPatch14`

Ⲡ`selectionPatch14` ϯ ⲛⲟⲩbranch ⲉⲃⲟⲗ ϩⲙⲡcomparison ⲙⲛ `M_OLD`. Ⲡshort branch ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡlegacy short wrapper; ⲡwide branch ⲙⲟⲩⲧⲉ ⲉ`wideDetour`.

Ⲡ`wideDetour` ϫⲓ ⲙⲡplaces ⲉⲧⲉ ⲡϣⲟⲣⲡ exponent ⲡⲉ ⲉⲧⲣⲉ `M_OLD^places>=N`. Ⲡdigit list ⲛϥϫⲓ ⲙⲙⲟϥ ⲛⲟⲩⲥⲟⲡ ⲙⲙⲁⲧⲉ ϩⲓ offsets `0..places-1`. Ⲡcombined number ⲟ ⲛ`1+Σ((digit_k-1)M_OLD^k)` ⲁⲩⲱ ⲉϥϣⲟⲟⲡ ϩⲛ `1..space`.

Ⲡacceptance limit ⲡⲉ `floor(space/N)*N`. Ⲡ`wideRingStepPatch14` ⲙⲟⲟϣⲉ ⲙⲡcombined number ⲛⲟⲩstep `+1` ⲏ `-1` ϩⲙⲡspace ring. Ⲡrejection ⲙⲟⲟϣⲉ ϩⲙⲡring ⲡⲁⲓ ϣⲁⲛⲧⲉ `combined<=limit`, ⲁⲩⲱ ⲙⲛⲛⲥⲱⲥ `biasedLegacyPick` ϯ ⲙⲡrank.

### EQUIVALENCE

Ⲛdigits ⲥⲉⲟ ⲛbase-`M_OLD` digits ⲛⲧⲉ ⲟⲩnumber ϩⲛ `1..space`. Ⲡacceptance interval ⲟ ⲛmultiple ⲙⲡN, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡlegacy modulo ⲙⲛⲛⲥⲁ rejection ⲟ ⲛuniform ϩⲛ `1..N`. Ⲡrejection ⲛϥϫⲓ ⲁⲛ ⲛⲕⲉdigits; ⲛϥⲙⲟⲟϣⲉ ⲙⲙⲁⲧⲉ ϩⲓ ⲡcombined ring ⲉⲧⲁⲩⲧⲁⲙⲓⲟϥ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡshort scar ⲟⲩⲏϩ callable. Ⲡwide state ⲧⲏⲣϥ — places, space, initial combined, limit, accepted combined, rejection steps ⲙⲛ rank — ⲟ ⲛinvocation-local. Ⲙⲛ global mutable semantic state ⲁⲩⲱ ⲙⲛ oracle call ϩⲙⲡproduction.


## Ⲡnegative gate-question scar ⲙⲡⲃⲁⲑⲙⲟⲥ 30

ⲠCOPY_AUTHORITATIVE ⲙⲡDISCOVERY ⲡⲉ:

`monster_gate_question_day_route -> legacyGateQuestionDayFromSignedStepWrong -> oldGateQuestionDay`

Ⲡ`oldGateQuestionDay` ϫⲓ ⲛⲟⲩpositive magnitude ⲁⲩⲱ ⲛϥⲟⲩⲱϩ ⲙⲙⲟϥ ⲉⲡFOUNDATION. Ⲡadapter ⲛⲗⲉⲅⲁⲥⲓ ⲧⲁⲙⲓⲟ ⲙⲡ`abs(signedStep)` ⲉⲙⲡⲁⲧⲉ ⲡcall, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡsign ⲛnegative ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡhelper.

Ⲡstate ⲛⲧⲉⲡinvocation ϩⲁⲣⲉϩ ⲉ signed step, absolute step, direct legacy result, route result ⲙⲛ counters. Ⲙⲛ global mutable semantic state ⲁⲩⲱ ⲙⲛ oracle call ϩⲙⲡproduction.

Ⲡtest-only normative side ⲗⲟⲅⲓⲍⲉ ⲙⲡ`FOUNDATION+signedStep` ϩⲓ ⲛsmall signed witnesses. Ⲙⲛ repair ⲙⲡnegative side ⲉϥϣⲟⲟⲡ ϩⲙⲡStage 30.


## Ⲡnegative gate-question detour ⲙⲡⲃⲁⲑⲙⲟⲥ 31

ⲠCOPY_DIAGNOSTIC ⲟ ⲛ:

`legacyGateQuestionDayFromSignedStepWrong -> oldGateQuestionDay`

ⲠCOPY_AUTHORITATIVE ⲡⲉ:

`monster_gate_question_day_route -> monster_stage31_gate_question_patch_wrapper -> gateQuestionDayPatch15`

Ⲡ`gateQuestionDayPatch15` ⲙⲟⲩⲧⲉ ⲉⲡlegacy path ⲛϣⲟⲣⲡ. Ⲉϣϫⲉ ⲡsigned step ⲟ ⲛzero ⲏ positive, ⲡlegacy result ⲟ ⲛexact ⲁⲩⲱ ⲛϥⲕⲧⲟ ⲙⲙⲟϥ. Ⲉϣϫⲉ ⲡstep ⲟ ⲛnegative, ⲡpatch ⲧⲁⲙⲓⲟ ⲙⲡabsolute magnitude ⲁⲩⲱ ⲛϥⲗⲟⲅⲓⲍⲉ ⲙⲡ`FOUNDATION-abs(step)`.

### EQUIVALENCE

Ϩⲓ `signedStep>=0`, `abs(step)=step`, ⲉⲧⲃⲉ ⲡⲁⲓ `oldGateQuestionDay(abs(step))=FOUNDATION+signedStep`. Ϩⲓ `signedStep<0`, `FOUNDATION-abs(step)=FOUNDATION+signedStep`. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡdetour ⲧⲱⲛ ⲙⲛ ⲡsigned normative question day ϩⲓ ⲡdomain ⲧⲏⲣϥ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡlegacy scar ⲟⲩⲏϩ callable ⲁⲩⲱ ⲉϥⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩⲙⲉ. Ⲡpatched result ⲙⲛ ⲡseen counter ⲟ ⲛinvocation-local. Ⲙⲛ global mutable semantic state, ⲙⲛ oracle call ϩⲙⲡproduction, ⲁⲩⲱ ⲙⲛ future patch code.
