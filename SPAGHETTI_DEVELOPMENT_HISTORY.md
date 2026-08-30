# Ⲡϩⲓⲥⲧⲟⲣⲓⲁ ⲙⲡϫⲓⲛⲁⲩⲝⲁⲛⲉ ⲙⲡⲙⲟⲛⲥⲧⲉⲣ

## Ⲃⲁⲑⲙⲟⲥ 1 — BOOTSTRAP

Ⲁⲩⲁⲣⲭⲓ ⲉⲃⲟⲗ ϩⲓⲧⲟⲟⲧⲟⲩ ⲛⲟⲩⲕⲱⲇⲓⲝ ⲛⲃⲣⲣⲉ. Ⲙⲡⲟⲩϥⲓ ⲕⲱⲇⲓⲝ, ⲇⲟⲕⲓⲙⲏ, `fixture`, `output` ⲏ `hash` ⲉⲃⲟⲗ ϩⲛⲟⲩⲕⲉⲙⲉⲧⲁⲥⲡⲉ.

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`SourceLanguageCatalog` ⲛⲧⲙⲉⲧⲣⲉⲙⲛⲕⲏⲙⲉ, ⲁⲩⲱ ⲁⲩⲧⲁϫⲣⲟ ⲛⲛ`canonicalIndex`.

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩⲕⲟⲛⲧⲉⲝⲧ ⲛⲁⲣⲭⲏ, ⲟⲩⲇⲓⲥⲡⲁⲧϣⲉⲣ, ⲟⲩⲃⲁⲗⲓⲇⲁⲧⲱⲣ ⲙⲛ ⲟⲩⲙⲉⲧⲣⲓⲕⲏ. Ⲛⲁⲓ ⲛⲉ ⲛϣⲟⲣⲡ ⲛⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ; ⲛⲥⲉϣⲓⲃⲉ ⲁⲛ ⲙⲡⲕⲁⲛⲱⲛ.

Ⲙⲛ ⲡⲁⲧϣ ⲛⲗⲉⲅⲁⲥⲓ ⲉϥϣⲟⲟⲡ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ.

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oracle` ⲛⲇⲟⲕⲓⲙⲏ ⲉⲃⲟⲗ ϩⲙⲡⲕⲁⲛⲱⲛ ⲉⲧⲥⲏϩ, ⲙⲛ ⲟⲩ`BigInt` ⲛⲁⲕⲣⲓⲃⲏⲥ ⲉⲙⲛ `overflow` ⲏ `floating point`. Ⲡⲇⲓⲡⲓ ⲛⲛϣⲁⲓ ⲛⲙⲏⲛ ⲧⲁϫⲣⲏⲩ ⲕⲁⲧⲁ ⲛⲃⲗⲟⲕ ⲛⲗⲉⲝⲓⲕⲟⲅⲣⲁⲫⲓⲕⲟⲛ, ⲙⲛ ⲟⲩ`memo` ⲛ`F_a(T)` ⲉϥϩⲁⲣⲉϩ ⲙⲙⲁⲧⲉ ⲉⲟⲩⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ ⲉϥⲧⲁϫⲣⲏⲩ.

Ⲡ`smoke` ⲛⲕⲁⲛⲱⲛ ⲉϫⲛ `FOUNDATION` ⲕⲱ ⲉϩⲣⲁⲓ ⲛ5 ⲙⲙⲉⲣⲟⲥ: 5000, `cutlet canonicalIndex=10`, 503, `month canonicalIndex=20`, 56. Ⲙⲛ ⲟⲩⲡⲁⲧϣ ⲛⲗⲉⲅⲁⲥⲓ ⲉϥϣⲟⲟⲡ ⲉⲧⲓ.

## Ⲃⲁⲑⲙⲟⲥ 2 — DISCOVERY 01

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ `regularMod(x,M)` ⲛⲧⲟϥ ⲡⲉ ⲡϫⲓⲛϩⲁⲣⲉϩ ⲉⲧϣⲟⲟⲡ ϩⲙⲡⲕⲁⲛⲱⲛ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`oldRemainder` ⲉϥⲕⲱ ⲉⲃⲟⲗ ⲛⲧⲉⲥⲧⲟⲗⲏ ⲙⲙⲟⲇⲟⲩⲗⲟⲥ ⲙⲙⲁⲧⲉ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ϩⲓ `M`, `2M` ⲙⲛ `3M` ⲡ`oldRemainder` ϯ `0`, ϩⲟⲡⲟⲩ ⲡϫⲓⲛϩⲁⲣⲉϩ ⲛⲕⲁⲛⲱⲛ ϯ `M`. Ϩⲓ `M+1` ⲡⲣⲱⲧⲉ ϯ `1`, ⲉϥⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ. Ⲡⲇⲟⲕⲓⲙⲏ ⲛⲃⲣⲣⲉ ⲟⲩⲱⲛϩ ⲉⲃⲟⲗ ⲛϣⲟⲙⲛⲧ ⲛⲇⲓⲁⲫⲟⲣⲁ ⲁⲩⲱ ⲟⲩⲣⲁϣⲉ ⲉϫⲛ `M+1`.

Ⲁⲩⲧⲁⲙⲓⲟ ⲛⲟⲩ`monster_remainder_route` ⲙⲛ ⲟⲩ`monster_stage02_legacy_remainder_handler`, ⲁⲩⲱ ⲡ`calendarDateSpaghetti` ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡⲉⲓⲣⲱⲧⲉ. Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡinput ⲙⲛ ⲡresult ⲛⲗⲉⲅⲁⲥⲓ. Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩⲡⲁⲧϣ ⲉⲧⲓ.

## Ⲃⲁⲑⲙⲟⲥ 3 — PATCH 01

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`oldRemainder`, ⲁⲩⲱ ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲡⲉϥⲗⲟⲅⲓⲥⲙⲟⲥ. Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲟⲩⲏϩ ⲉϥϯ `0` ϩⲓ `M`, `2M` ⲙⲛ `3M`.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`savePatch`. Ⲛⲧⲟϥ ⲙⲉⲛ ⲙⲟⲩⲧⲉ ⲉ`oldRemainder`; ⲉϣϫⲉ ⲡⲉϥⲟⲩⲱϣⲃ ⲟ ⲛ`0`, ⲛϥϯ ⲛⲟⲩ copy ⲛ`M`. Ⲉϣϫⲉ ⲙⲛ`0`, ⲛϥⲕⲱ ⲙⲡⲟⲩⲱϣⲃ ⲛⲗⲉⲅⲁⲥⲓ ⲛⲧⲟϥ.

`monster_remainder_route -> monster_stage03_save_patch_wrapper -> savePatch -> oldRemainder`

Ⲡ`monster_stage02_legacy_remainder_handler` ⲙⲟⲩⲧⲉ ⲉ`oldRemainder` ⲛϣⲟⲣⲡ ⲉⲧⲣⲉϥϩⲁⲣⲉϩ ⲉⲡⲟⲩⲱϣⲃ ⲛⲗⲉⲅⲁⲥⲓ, ⲙⲛⲛⲥⲱⲥ ⲛϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡⲣⲱⲧⲉ ⲙⲡⲁⲧϣ. Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡⲟⲩⲱϣⲃ ⲙⲡⲉⲩⲥⲛⲁⲩ ⲉⲩϣⲟⲃⲉ ⲙⲙⲟⲟⲩ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲡ`SAVE(x)` ⲕⲱ ⲛⲛⲟⲩⲙⲉⲣⲟⲥ ⲛ`1..M`; ⲛⲁⲓ ⲉⲧⲣⲉ`regularMod(x,M)` ϯ `0` ⲛⲁⲩ ⲛⲉ ⲛⲡⲟⲗⲗⲁⲡⲗⲁⲥⲓⲟⲛ ⲙⲡ`M`. Ⲡ`savePatch` ϣⲓⲃⲉ ⲙⲙⲁⲧⲉ ⲙⲡ`0` ⲉ`M`; ⲛϥϫⲱϩ ⲁⲛ ⲉⲟⲩⲕⲉⲟⲩⲱϣⲃ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲟⲩⲟⲛ ⲧⲱⲛ ⲙⲛ ⲡ`SAVE` ⲛⲕⲁⲛⲱⲛ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ ⲟⲩ`monster_stage03_save_patch_wrapper` ⲙⲛ ⲛϣⲟⲙⲛⲧ ⲙⲙⲁ ⲛ`state`: `legacy input`, `legacy result`, ⲙⲛ `patched result/seen`. Ⲡⲁⲓ ⲧⲁⲙⲓⲟ ⲛⲟⲩϫⲓⲛⲙⲟⲟϣⲉ ⲉϥⲟⲩⲏⲩ ⲁⲩⲱ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡⲕⲁⲛⲱⲛ.

## Ⲃⲁⲑⲙⲟⲥ 4 — DISCOVERY 02

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡⲙⲁ ⲙⲡϩⲟⲟⲩ ⲛⲧⲉⲥⲛⲧⲉ ⲛⲁϣⲱⲡⲉ ⲛⲟⲩⲕⲁⲛⲱⲛ ⲛⲕⲟⲧ ⲉⲃⲟⲗ ϩⲙⲡⲟⲩⲟⲛ ⲙⲡϩⲟⲟⲩ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oldDayTag(day)=2*abs(day-FOUNDATION)`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡⲕⲁⲛⲱⲛ ⲡⲱⲣϫ ⲙⲡⲥⲁ ⲉⲧϩⲏ ⲙⲛ ⲡⲥⲁ ⲉⲧⲙⲛⲛⲥⲁ ⲡ`FOUNDATION`. Ϩⲓ `FOUNDATION-1` ⲡ`oldDayTag` ϯ `2` ⲁⲩⲱ ⲡⲕⲁⲛⲱⲛ ϯ `2`. Ϩⲓ `FOUNDATION` ⲡⲣⲱⲧⲉ ϯ `0` ϩⲁ `1`; ϩⲓ `FOUNDATION+1` ⲛϥϯ `2` ϩⲁ `3`; ϩⲓ `FOUNDATION+2` ⲛϥϯ `4` ϩⲁ `5`.

Ⲁⲩⲧⲁⲙⲓⲟ ⲛⲟⲩ`monster_daytag_route` ⲙⲛ ⲟⲩ`monster_stage04_legacy_daytag_handler`. Ⲡ`calendarDateSpaghetti` ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡhandler ⲛⲃⲣⲣⲉ ⲙⲛⲛⲥⲁ ⲡⲣⲱⲧⲉ ⲙⲡⲁⲧϣ 01. Ⲡ`MonsterContext` ⲁϥⲁⲓⲁⲓ ϩⲓⲧⲛ ⲛinput ⲙⲛ ⲛresult ⲛⲧⲉ ⲡ`calculationDay` ⲙⲛ ⲡ`targetDay`, ⲙⲛ ⲟⲩcounter ⲛⲗⲉⲅⲁⲥⲓ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩⲡⲁⲧϣ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ; ⲡⲡⲗⲁⲛⲏ ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲙⲡⲣⲱⲧⲉ.

## Ⲃⲁⲑⲙⲟⲥ 5 — PATCH 02

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`oldDayTag`, ⲁⲩⲱ ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲡⲉϥⲗⲟⲅⲓⲥⲙⲟⲥ. Ⲛϥⲟⲩⲏϩ ⲉϥϯ `0` ϩⲓ `FOUNDATION`, `2` ϩⲓ `FOUNDATION+1`, ⲙⲛ `4` ϩⲓ `FOUNDATION+2`.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`dayTagWithFoundationScar`. Ⲛⲧⲟϥ ⲙⲟⲩⲧⲉ ⲉ`oldDayTag` ⲛϣⲟⲣⲡ. Ⲉϣϫⲉ `day >= FOUNDATION`, ⲛϥⲟⲩⲱϩ `1`. Ⲙⲛⲛⲥⲱⲥ ⲡ guard ⲛⲥⲛⲁⲩ ⲥⲁϩⲱϥ: ⲉϣϫⲉ `day == FOUNDATION` ⲁⲩⲱ `n != 1`, ⲛϥⲕⲱ `n=1`. Ⲡ guard ⲡⲁⲓ ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲕⲁⲧⲁ ⲡⲧⲱϣ ⲛⲧⲉⲡϩⲓⲥⲧⲟⲣⲓⲁ.

`monster_daytag_route -> monster_stage05_daytag_patch_wrapper -> dayTagWithFoundationScar -> oldDayTag`

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ϩⲁⲧϩⲏ ⲙⲡ`FOUNDATION`, ⲡ`oldDayTag` ⲧⲱⲛ ⲙⲛ `dayCount`, ⲁⲩⲱ ⲡⲡⲁⲧϣ ⲛϥⲟⲩⲱϩ ⲁⲛ ⲛⲗⲁⲁⲩ. Ϩⲓ `FOUNDATION` ⲙⲛ ⲙⲛⲛⲥⲱϥ, ⲡⲕⲁⲛⲱⲛ ϣⲓⲃⲉ ⲙⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ϩⲓⲧⲛ `+1`. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡⲡⲁⲧϣ ⲧⲱⲛ ⲙⲛ `oracle_day_count` ϩⲓ ⲛⲉϩⲟⲟⲩ ⲙⲡⲥⲁ ⲛⲥⲛⲁⲩ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ ⲟⲩ`monster_stage05_daytag_patch_wrapper`, ⲙⲛ `CTX_PATCHED_DAYTAG_CALC_RESULT`, `CTX_PATCHED_DAYTAG_TARGET_RESULT` ⲙⲛ `CTX_DAYTAG_PATCH_SEEN`. Ⲡhandler ⲙⲟⲩⲧⲉ ⲉ`oldDayTag` ⲛϣⲟⲣⲡ ⲛⲟⲩCOPY_DIAGNOSTIC, ⲙⲛⲛⲥⲱⲥ ⲛϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡⲣⲱⲧⲉ ⲙⲡⲁⲧϣ ⲛⲟⲩCOPY_AUTHORITATIVE. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ; ⲛⲥⲉϫⲓ ⲁⲛ ⲛⲟⲩⲁⲡⲟⲧⲉⲗⲉⲥⲙⲁ ⲉⲃⲟⲗ ϩⲙ logs ⲏ metrics.

## Ⲃⲁⲑⲙⲟⲥ 6 — DISCOVERY 03

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡⲙⲁⲕⲣⲟⲛ ⲛⲧⲉⲥⲛⲁⲩ ⲛϩⲟⲟⲩ ⲉϥϣⲟⲟⲡ ⲙⲡⲇⲓⲁⲫⲟⲣⲁ ⲛⲁⲡⲟⲗⲩⲧⲟⲛ ⲛⲛⲉⲩ`dayTag`. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oldDistance(c,t)=abs(dayTag(c)-dayTag(t))`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ϩⲓ `FOUNDATION,FOUNDATION` ⲡ`oldDistance` ϯ `0` ϩⲟⲡⲟⲩ ⲡⲙⲁⲕⲣⲟⲛ ⲛⲕⲁⲛⲱⲛ ϯ `1`. Ϩⲓ `FOUNDATION,FOUNDATION+1` ⲛϥϯ `2` ⲁⲩⲱ ⲡⲕⲁⲛⲱⲛ ϯ `2`; ϩⲓ `FOUNDATION+1,FOUNDATION+2` ⲡⲉⲓⲧⲱⲛ ⲟⲛ ⲧⲱⲛ. Ϩⲓ `FOUNDATION,FOUNDATION+2` ⲡⲣⲱⲧⲉ ϯ `4` ϩⲁ `3`, ⲁⲩⲱ ϩⲓ `FOUNDATION-1,FOUNDATION+1` ⲛϥϯ `1` ϩⲁ `3`.

Ⲁⲩⲧⲁⲙⲓⲟ ⲛⲟⲩ`monster_distance_route` ⲙⲛ ⲟⲩ`monster_stage06_legacy_distance_handler`. Ⲡhandler ⲙⲟⲩⲧⲉ ⲉ`oldDistance` ⲛⲟⲩCOPY_DIAGNOSTIC, ⲁⲩⲱ ⲛϥⲙⲟⲟϣⲉ ⲟⲛ ϩⲓⲧⲛ ⲡroute ⲛⲗⲉⲅⲁⲥⲓ. Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡlegacy result ⲙⲛ ⲡroute result ⲙⲛ ⲛcounter ⲙⲡⲉⲩⲥⲛⲁⲩ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩⲡⲁⲧϣ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ. Ⲡⲡⲗⲁⲛⲏ ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲙⲡⲣⲱⲧⲉ.

## Ⲃⲁⲑⲙⲟⲥ 7 — PATCH 03

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`oldDistance`, ⲁⲩⲱ ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲡⲉϥⲗⲟⲅⲓⲥⲙⲟⲥ. Ⲛϥⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡⲇⲓⲁⲫⲟⲣⲁ ⲛⲁⲡⲟⲗⲩⲧⲟⲛ ⲛⲛ`dayTagWithFoundationScar`.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`distanceWithChronologicalScar`. Ⲛⲧⲟϥ ⲙⲟⲩⲧⲉ ⲉ`oldDistance` ⲛϣⲟⲣⲡ, ⲛϥⲙⲉⲧⲣⲉ ⲙⲡ`abs(targetDay-calculationDay)`, ⲁⲩⲱ ⲉϣϫⲉ ⲡlegacy ⲙⲛ ⲡchronological ⲛⲥⲉⲧⲱⲛ ⲁⲛ, ⲛϥϫⲓ ⲙⲡchronological. Ⲙⲛⲛⲥⲱⲥ ⲛϥⲟⲩⲱϩ `1`.

`monster_distance_route -> monster_stage07_distance_patch_wrapper -> distanceWithChronologicalScar -> oldDistance`

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲡⲙⲁⲕⲣⲟⲛ ⲛⲕⲁⲛⲱⲛ ⲡⲉ `abs(targetDay-calculationDay)+1`. Ⲡⲡⲁⲧϣ ⲙⲉⲧⲣⲉ ⲙⲡⲇⲓⲁⲫⲟⲣⲁ ⲛⲛϩⲟⲟⲩ ⲛⲧⲉⲡⲧⲁⲝⲓⲥ ⲁⲩⲱ ⲛϥⲟⲩⲱϩ `1`; ⲡlegacy ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲛϣⲟⲣⲡ ⲁⲗⲗⲁ ⲛϥⲧⲙϫⲓ ⲛⲟⲩⲧⲟϣ ⲉϣϫⲉ ⲛϥϣⲟⲃⲉ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ ⲟⲩ`monster_stage07_distance_patch_wrapper`, ⲙⲛ `CTX_CHRONOLOGICAL_DISTANCE`, `CTX_PATCHED_DISTANCE_RESULT` ⲙⲛ `CTX_DISTANCE_PATCH_SEEN`. Ⲡhandler ϩⲁⲣⲉϩ ⲉⲡlegacy result ⲙⲛ ⲡchronological result ⲙⲛ ⲡpatched result ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ, ⲁⲩⲱ ⲛⲥⲉϣⲓⲃⲉ ⲁⲛ ⲙⲡⲕⲁⲛⲱⲛ.

## Ⲃⲁⲑⲙⲟⲥ 8 — DISCOVERY 04

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲉϣϫⲉ ⲧⲁⲝⲓⲥ ⲛⲛ5 ⲛⲱⲛⲉ ⲥⲏϩ ϩⲛⲟⲩⲃⲗⲟⲕ ⲛⲟⲩⲱⲧ, ⲟⲩⲛ ⲉϣϫⲉ ⲟⲩⲱⲛⲉ ⲥϩⲁⲓ ⲙⲡⲉϥⲧⲓⲙⲏ ⲛⲃⲣⲣⲉ ⲛϣⲟⲣⲡ ⲁⲩⲱ ⲡⲉⲧⲛⲏⲩ ϫⲓ ⲙⲙⲟⲥ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`mutateStonesWrong` ⲉϥϣⲓⲃⲉ ⲙⲡstate ϩⲛ ⲟⲩⲧⲁⲝⲓⲥ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ϩⲙ `i=2` ⲡ`w` ⲟⲩⲱϣⲃ ⲛ`378` ⲁⲩⲱ ⲛϥⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ. Ⲁⲗⲗⲁ ⲡ`b` ϫⲓ ⲙⲡ`w` ⲛⲃⲣⲣⲉ, ⲡ`s` ϫⲓ ⲙⲡ`b` ⲛⲃⲣⲣⲉ, ⲡ`m` ϫⲓ ⲙⲡ`s` ⲛⲃⲣⲣⲉ, ⲁⲩⲱ ⲡ`r` ϫⲓ ⲙⲡ`w` ⲙⲛ ⲡ`m` ⲛⲃⲣⲣⲉ. Ⲡⲣⲱⲧⲉ ϯ `378,1434,3780,9932,25047`, ϩⲟⲡⲟⲩ ⲡoracle ϯ `378,1073,2375,6195,10493`. Ⲟⲩⲛ 4 ⲛⲇⲓⲁⲫⲟⲣⲁ ⲉⲩⲧⲟϣ.

Ⲁⲩⲧⲁⲙⲓⲟ ⲛⲟⲩ`monster_stone_mutation_route` ⲙⲛ ⲟⲩ`monster_stage08_legacy_stone_handler`. Ⲡ`calendarDateSpaghetti` ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡlegacy ⲡⲁⲓ, ⲁⲩⲱ ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡrow ⲙⲛ ⲡiteration ⲙⲛ ⲛcounter. Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩsnapshot ⲏ ⲟⲩoverwrite ⲛⲕⲁⲛⲱⲛ ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ.


## Ⲃⲁⲑⲙⲟⲥ 9 — PATCH 04

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`mutateStonesWrong`. Ⲛϥⲟⲩⲏϩ ⲉϥϣⲓⲃⲉ ⲛ5 ⲛⲱⲛⲉ ϩⲛ ⲟⲩⲧⲁⲝⲓⲥ, ⲁⲩⲱ ⲛϥϫⲓ ⲛⲛⲧⲓⲙⲏ ⲛⲃⲣⲣⲉ ϩⲛ ⲛⲗⲟⲅⲓⲥⲙⲟⲥ ⲉⲧⲛⲏⲩ.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`stonePatch`. Ⲛϥϫⲓ ⲛⲟⲩ`old` snapshot ⲛϣⲟⲣⲡ. Ⲙⲛⲛⲥⲱⲥ ⲛϥⲧⲁⲙⲓⲟ ⲛⲟⲩclone ⲛⲕⲉⲥⲟⲡ ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉ`mutateStonesWrong` ϩⲓⲱⲱϥ. Ⲡgarbage ⲉⲧⲛⲏⲩ ⲉⲃⲟⲗ ⲥⲉⲥϩⲁⲓ ⲛⲕⲉⲥⲟⲡ ⲛ5 ⲛⲥⲟⲡ ⲕⲁⲧⲁ ⲛⲗⲟⲅⲓⲥⲙⲟⲥ ⲉⲧϫⲓ ⲙⲙⲁⲧⲉ ϩⲙⲡ`old`.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲡⲕⲁⲛⲱⲛ ϫⲱ ⲙⲙⲟⲥ ϫⲉ ⲛ5 ⲛⲱⲛⲉ ⲛⲃⲣⲣⲉ ⲥⲉⲛⲏⲩ ⲉⲃⲟⲗ ϩⲛ ⲟⲩsnapshot ⲛⲟⲩⲱⲧ. Ⲡ`stonePatch` ⲣ ⲡⲉⲓϩⲱⲃ ⲉϥⲕⲱ ⲙⲡlegacy call ϩⲙⲡⲣⲱⲧⲉ. Ⲡⲇⲟⲕⲓⲙⲏ ⲙⲡrow 2 ϯ `378,1073,2375,6195,10493`, ⲁⲩⲱ ⲡbuilder ⲧⲱⲛ ⲙⲛ ⲡoracle ϩⲓ ⲛ46 ⲛrows ⲧⲏⲣⲟⲩ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `stonePatch`, `monster_stage09_stone_patch_wrapper`, `getStoneTableThroughLegacyBuilder`, ⲙⲛ `CTX_STONE_PATCH_INPUT`, `CTX_PATCHED_STONE_ROW`, `CTX_STONE_PATCH_SEEN`. Ⲡhandler ⲣ ⲡlegacy call ⲛⲟⲩCOPY_DIAGNOSTIC ⲁⲩⲱ ⲡroute ⲣ ⲡpatched copy ⲛⲟⲩCOPY_AUTHORITATIVE. Ⲡwrapper ϩⲁⲣⲉϩ ⲉⲡpointer contract ⲛStage 8 ⲁϫⲛ ⲧⲣⲉϥϣⲓⲃⲉ ⲙⲡⲕⲁⲛⲱⲛ.

## Ⲃⲁⲑⲙⲟⲥ 10 — DISCOVERY 05

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲟⲩarray ⲙⲡhidden ⲛⲁϣϩⲁⲣⲉϩ ⲉⲡⲉϥⲙⲁ ⲕⲁⲧⲁ ⲡⲧⲱϣ ⲉⲧⲁⲩⲥϩⲁⲓ: ⲁⲩⲥϩⲁⲓ `hidden7, hidden6, ..., hidden1`, ⲁⲗⲗⲁ ⲡⲣⲱⲧⲉ ⲛⲧⲉⲡaccess ⲙⲟⲩⲧⲉ ⲉⲡⲙⲁ `k` ⲛⲧⲟϥ.

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`buildHiddenWithBackwardStorage`: ⲡⲧⲓⲙⲏ ⲛhidden ⲛⲓⲙ ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ, ⲁⲗⲗⲁ ⲡⲙⲁ ⲙⲡarray ⲟ ⲛⲥⲁϩⲟⲩ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡstorage ⲧⲱⲛ ϩⲓⲱⲱϥ ⲙⲛ `hidden7..hidden1`. Ⲁⲗⲗⲁ ⲡ`legacyHiddenAtNearnessWrong` ϫⲓ ⲙⲡposition `k` ⲁϫⲛ ⲟⲩⲙⲉⲧⲁⲅⲣⲁⲫⲏ. Ⲉⲧⲃⲉ ⲡⲁⲓ `k=1` ⲧⲱⲛ ⲙⲛ `hidden7`, `k=7` ⲧⲱⲛ ⲙⲛ `hidden1`, ⲁⲩⲱ `k=4` ⲧⲱⲛ ⲙⲛ `hidden4`. Ⲡⲇⲟⲕⲓⲙⲏ ⲥⲱⲡ ⲛ6 ⲛⲇⲓⲁⲫⲟⲣⲁ ⲉⲩⲧⲟϣ.

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `monster_stage10_legacy_hidden_handler`, `monster_hidden_route`, `CTX_HIDDEN_BACKWARD`, `CTX_HIDDEN_QUERY_K`, `CTX_LEGACY_HIDDEN_QUERY_RESULT`, ⲙⲛ ⲛcounter ⲛⲧⲉⲡstorage ⲙⲛ ⲡquery. Ⲡ`calendarDateSpaghetti` ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡhandler ⲡⲁⲓ ϩⲙⲡⲣⲱⲧⲉ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡⲙⲉⲧⲁⲅⲣⲁⲫⲉⲩⲥ ⲛⲧⲉⲡⲃⲁⲑⲙⲟⲥ ⲉⲧⲛⲏⲩ. Ⲡⲡⲗⲁⲛⲏ ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲙⲡⲣⲱⲧⲉ.

## Ⲃⲁⲑⲙⲟⲥ 11 — PATCH 05

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩⲕⲧⲟ ⲙⲡ`buildHiddenWithBackwardStorage`. Ⲡarray ⲟⲩⲏϩ ⲉϥⲥϩⲟⲩⲟⲣⲧ `hidden7..hidden1`. Ⲡ`legacyHiddenAtNearnessWrong` ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡslot `k` ⲁϫⲛ ⲟⲩⲙⲉⲧⲁⲅⲣⲁⲫⲏ, ⲁⲩⲱ ⲛϥⲣϩⲱⲃ ⲛⲟⲩCOPY_DIAGNOSTIC.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`hiddenByNearness`. Ⲡⲟⲩⲱϣⲃ ⲙⲡquery `k` ⲛϥⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙⲡslot `8-k`. Ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲡstorage; ⲡⲁⲧϣ ⲟ ⲙⲙⲁⲧⲉ ϩⲙⲡaccess.

`monster_hidden_route -> monster_stage11_hidden_nearness_patch_wrapper -> hiddenByNearness`

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ϩⲙⲡbackward storage ⲡ`hidden k` ⲥⲏϩ ϩⲙⲡposition `8-k`. Ⲡ`hiddenByNearness` ϫⲓ ⲙⲡposition ⲡⲁⲓ ⲛⲧⲟϥ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡⲟⲩⲱϣⲃ ⲧⲱⲛ ⲙⲛ ⲡoracle ϩⲓ `k=1..7`. ⲠStage 10 regression ⲁϥⲕⲧⲟϥ ⲉ`GREEN` ⲁϫⲛ ⲧⲣⲉⲩϣⲓⲃⲉ ⲙⲡⲉϥtest.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `hiddenByNearness`, `monster_stage11_hidden_nearness_patch_wrapper`, `CTX_PATCHED_HIDDEN_QUERY_RESULT` ⲙⲛ `CTX_HIDDEN_NEARNESS_PATCH_SEEN`. Ⲡhandler ϩⲁⲣⲉϩ ⲉⲡlegacy result ⲙⲛ ⲡpatched result ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ. Ⲡstate ⲡⲁⲓ ⲡⲉ ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ, ⲁⲩⲱ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡstorage ⲏ ⲙⲡsemantic input.


## Ⲃⲁⲑⲙⲟⲥ 12 — DISCOVERY 06

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡhistory ⲛⲧⲉⲛdrop ⲛⲁϣϣⲱⲡ ⲛⲛpredecessor ⲛⲓⲙ ϩⲙⲡ`dropStore` ⲛⲟⲩⲱⲧ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`legacyPrior(dropStore,i,back)` ⲉϥϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡ`dropStore[i-back]`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲉϣϫⲉ `i-back >= 1`, ⲡlegacy ϣⲁϥϫⲓ ⲙⲡvisible drop ⲉⲧⲥⲏϩ ϩⲙⲡstore. Ⲉϣϫⲉ `i-back <= 0`, ⲛhidden predecessor ⲥⲉϣⲟⲟⲡ ϩⲙⲡbackward hidden storage ⲉϥϣⲟⲃⲉ, ⲁⲗⲗⲁ ⲡ`legacyPrior` ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡslot ⲙⲡdropStore. Ⲡⲇⲟⲕⲓⲙⲏ ⲥⲱⲡ ⲛ5 ⲛⲇⲓⲁⲫⲟⲣⲁ ⲉⲩⲧⲟϣ ⲙⲛ 2 ⲛvisible query ⲉⲩⲧⲱⲛ.

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `monster_stage12_legacy_prior_handler`, `monster_prior_route`, ⲙⲛ state ⲛⲧⲉⲡdropStore ⲙⲛ ⲡquery ⲙⲛ ⲛresult. Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩdetour ϩⲙⲡⲉⲓⲃⲁⲑⲙⲟⲥ.


## Ⲃⲁⲑⲙⲟⲥ 13 — PATCH 06

Ⲡ`legacyPrior` ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲙⲟϥ. Ⲛϥⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡ`dropStore[i-back]`, ⲁⲩⲱ ⲡhandler ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩCOPY_DIAGNOSTIC ⲉϫⲛ ⲡslot 0.

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ ⲡ`priorPatch`. Ⲉϣϫⲉ `slot>=1`, ⲛϥⲙⲟⲩⲧⲉ ⲉ`legacyPrior` ⲙⲙⲁⲧⲉ. Ⲉϣϫⲉ `slot<=0`, ⲛϥⲧⲁⲙⲓⲟ ⲙⲡ`k=1-slot` ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉ`hiddenByNearness`; ⲡbackward storage ⲛϥⲕⲧⲟ ⲁⲛ.

`monster_prior_route -> monster_stage13_prior_patch_wrapper -> priorPatch`

Ⲡ`MonsterContext` ⲟⲩⲱϩ ⲉϫⲛ `CTX_PATCHED_PRIOR_RESULT` ⲙⲛ `CTX_PRIOR_PATCH_SEEN`. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ; ⲡlegacy result ⲙⲛ ⲡpatched result ⲛⲥⲉⲧⲱⲛ ⲁⲛ ϩⲛ ⲟⲩfield ⲛⲟⲩⲱⲧ.

### EQUIVALENCE

Ⲉϣϫⲉ `slot>=1`, ⲡnormative predecessor ⲡⲉ ⲡvisible `dropStore[slot]`, ⲁⲩⲱ ⲡ`legacyPrior` ϯ ⲙⲡpointer ⲛⲧⲟϥ. Ⲉϣϫⲉ `slot<=0`, ⲡformula `k=1-slot` ⲕⲱ ⲙⲡslot 0,-1,...,-6 ⲉ hidden1,hidden2,...,hidden7, ⲁⲩⲱ ⲡ`hiddenByNearness` ϩⲁⲣⲉϩ ⲉⲡstorage ⲛⲥⲁϩⲟⲩ ϩⲓⲧⲛ ⲡtranslation `8-k`.

### EDGE CASES

Ⲁⲩⲇⲟⲕⲓⲙⲁⲍⲉ ⲛslot 1,2,0,-1,-2,-5,-6. Ⲡlegacy scar ⲟⲩⲏϩ ⲉϥϯ 0 ⲉslot 0 ϩⲙⲡdropStore; ⲡpatched route ⲟ ⲛ0 ⲛmismatch ⲉϫⲛ ⲛ7 ⲛcase.

### WHY SAFE

Ⲡⲡⲁⲧϣ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡdropStore ⲏ ⲡhidden storage. Ⲛϥⲧⲟϣ ⲙⲙⲁⲧⲉ ⲙⲡsource ⲙⲡpredecessor ⲕⲁⲧⲁ ⲡslot, ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉⲛlegacy/patch ⲉⲧϣⲟⲟⲡ ⲏⲇⲏ. Ⲙⲛ log, metric, cache ⲏ environment ⲉϥⲧⲟϣ ⲙⲡⲟⲩⲱϣⲃ.

## Ⲃⲁⲑⲙⲟⲥ 14 — DISCOVERY 07

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲛ11 ⲛgrind row ⲛⲁϣⲁⲣⲭⲉⲓ ϩⲓ index 1, ⲁⲩⲱ ⲡloop ⲁϥⲙⲟⲟϣⲉ ⲕⲁⲧⲁ `g=1..11`. Ⲡdata table ⲇⲉ ⲁϥⲥϩⲁⲓ ⲛⲛrow ⲛⲙⲉ ϩⲓ `0..10`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡ`legacyGrindRowAtIndex` ϫⲓ ⲙⲡ`g` ⲛⲧⲟϥ ⲛⲟⲩindex ⲙⲡtable. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲛgrind 1..10 ⲥⲉϫⲓ ⲙⲡrow ⲉⲧⲛⲏⲩ ⲙⲛⲛⲥⲱⲟⲩ, ⲁⲩⲱ ⲡgrind 11 ϫⲓ ⲛⲟⲩfence ⲉϥϣⲟⲩⲓⲧ. Ⲡfence ⲡⲁⲓ ⲛϥⲟ ⲁⲛ ⲛⲟⲩgrind ⲛⲕⲁⲛⲱⲛ; ⲟⲩⲧⲱϣ ⲛⲇⲉⲧⲉⲣⲙⲓⲛⲓⲥⲧⲓⲕⲟⲛ ⲙⲙⲁⲧⲉ ⲡⲉ ⲛⲧⲉⲡlegacy ⲉⲧⲃⲉ ⲧⲙⲣ ⲟⲩundefined memory read.

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oneVisibleDropLegacyGrindIndexWrong`, ⲉϥϫⲓ ⲛpredecessor ϩⲓⲧⲛ `priorPatch` ⲁⲩⲱ ⲉϥⲣ ⲛ11 ⲛgrind ϩⲓⲧⲛ ⲡindex ⲛⲗⲉⲅⲁⲥⲓ. Ⲡ`monster_stage14_legacy_grind_handler` ⲁϥⲕⲱ ⲙⲡⲉⲓⲣⲱⲧⲉ ϩⲙ `calendarDateSpaghetti`.

Ⲡⲇⲟⲕⲓⲙⲏ ⲧⲁϫⲣⲟ ϫⲉ ⲛ11 ⲛrow ⲧⲏⲣⲟⲩ ⲥⲉϣⲟⲃⲉ ⲙⲛ ⲡrow ⲛⲕⲁⲛⲱⲛ, ⲁⲩⲱ ⲡvisible drop ⲛϣⲟⲣⲡ ⲛϥⲧⲱⲛ ⲁⲛ ⲙⲛ ⲡoracle. Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩⲡⲁⲧϣ ϩⲙⲡⲉⲓStage.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `legacyGrindRowAtIndex`, `oneVisibleDropLegacyGrindIndexWrong`, `monster_visible_drop_route`, `monster_stage14_legacy_grind_handler`, ⲙⲛ state ⲛⲧⲉⲡvisible-drop/grind ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ. Ⲡⲉⲓlayer ⲟ ⲛCOPY_AUTHORITATIVE ⲙⲡDISCOVERY ⲁⲩⲱ ⲛϥϫⲓ ⲁⲛ ⲙⲡoracle ϩⲙ runtime.

## Ⲃⲁⲑⲙⲟⲥ 15 — PATCH 07

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡlegacy indexing `g=1..11`. Ⲡ`legacyGrindRowAtIndex` ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡ`g` ⲛⲧⲟϥ ⲛⲟⲩindex, ⲁⲩⲱ ⲡ`oneVisibleDropLegacyGrindIndexWrong` ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ⲙⲛ ⲡloop ⲛ11 ⲛⲧⲁⲡ. Ⲡfence ⲉϥϣⲟⲩⲓⲧ ⲛStage 14 ⲟⲩⲏϩ ⲉϥⲥⲏϩ ⲙⲛⲛⲥⲁ ⲡtable.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲟⲩⲱϩ ⲛⲟⲩsentinel row ⲉϥϣⲟⲩⲓⲧ ϩⲁⲧϩⲏ ⲛⲛ11 ⲛgrind row. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡindex 0 ⲟ ⲛsentinel, ⲁⲩⲱ ⲛgrind ⲛⲙⲉ ⲥⲉⲕⲏ ϩⲓ 1..11. Ⲙⲡⲟⲩⲕⲧⲟ ⲙⲡlegacy loop ⲁⲩⲱ ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡsentinel.

`monster_visible_drop_route -> monster_stage15_grind_sentinel_patch_wrapper -> oneVisibleDropLegacyGrindIndexWrong -> legacyGrindRowAtIndex`

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲡgrind ⲛⲕⲁⲛⲱⲛ ⲙⲡ`g` ⲡⲉ ⲡrow ⲙⲡ`g` ϩⲛ ⲧⲁⲝⲓⲥ 1..11. Ⲙⲛⲛⲥⲁ ⲡsentinel ⲛindex 0, ⲡlegacy index `g` ϫⲓ ⲙⲡrow ⲙⲡ`g` ⲛⲧⲟϥ. Ⲙⲛ rank, state, input ⲏ side effect ⲛⲃⲣⲣⲉ ⲉϥϫⲓ ⲛⲟⲩⲧⲟϣ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ ⲟⲩ`monster_stage15_grind_sentinel_patch_wrapper` ⲁⲩⲱ `CTX_GRIND_SENTINEL_PATCH_SEEN`. Ⲡwrapper ⲛϥϣⲓⲃⲉ ⲁⲛ ⲛⲟⲩsemantic value; ⲛϥϩⲁⲣⲉϩ ⲙⲙⲁⲧⲉ ⲉⲡϩⲓⲥⲧⲟⲣⲓⲁ ⲙⲡroute. Ⲡcounter ⲟ ⲛobservability state ⲙⲡinvocation ⲁⲩⲱ ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡⲗⲟⲅⲓⲥⲙⲟⲥ.

ⲠStage 14 regression ⲁϥⲕⲧⲟϥ ⲉ`GREEN` ⲁϫⲛ ⲟⲩϣⲓⲃⲉ. ⲠStage 15 ⲧⲁϫⲣⲟ ϫⲉ ⲡlegacy API ⲟⲩⲏϩ ⲉϥⲁⲣⲛⲁ ⲙⲡindex 0, ⲡsentinel ⲟⲩⲏϩ ⲉϥⲥⲏϩ ϩⲙⲡtable, ⲛ11 ⲛrow ⲛⲙⲉ ⲥⲉⲧⲱⲛ, ⲁⲩⲱ ⲡvisible drop ⲧⲱⲛ ⲙⲛ ⲡoracle.


## Ⲃⲁⲑⲙⲟⲥ 16 — DISCOVERY 08

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡⲧⲟϣ ⲙⲡpermutation ⲡⲉ ⲟⲩrank ⲉϥⲁⲣⲭⲉⲓ ϩⲓ `0`, ⲁⲩⲱ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oldPermutationUnrank0(rank0)` ⲉϥϫⲓ `0..719`. Ⲡcaller ⲛⲗⲉⲅⲁⲥⲓ ⲁϥⲗⲟⲅⲓⲍⲉ ⲙⲡrank ⲛⲧⲟϥ ϩⲓⲧⲛ ⲡremainder ⲙⲡ`drop` ϩⲓ `720`, ⲁⲩⲱ ⲁϥϫⲟⲟⲩϥ ⲉⲡhelper ⲁϫⲛ ⲟⲩⲙⲉⲧⲁⲃⲟⲗⲏ ⲙⲡbase.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡ`oldPermutationUnrank0` ⲛⲧⲟϥ ⲧⲱⲛ ϩⲙⲡⲉϥdomain: `rank0=0` ϯ ⲙⲡϣⲟⲣⲡ permutation, ⲁⲩⲱ `rank0=719` ϯ ⲙⲡϩⲁⲉ. Ⲡⲡⲗⲁⲛⲏ ϣⲟⲟⲡ ϩⲙⲡcaller: `drop=1` ⲕⲱ ⲙⲡ`rank0=1`, `drop=719` ⲕⲱ ⲙⲡ`719`, `drop=720` ⲕⲱ ⲙⲡ`0`, ⲁⲩⲱ `drop=721` ⲕⲱ ⲙⲡ`1`.

Ⲡⲇⲟⲕⲓⲙⲏ ⲥⲙⲓⲛⲉ ⲙⲡ`monster_permutation_route` ⲙⲛ `oracle_bowl_order_from_value` ϩⲓ ⲛ4 ⲛdrop ⲛⲁⲓ. Ⲟⲩⲛ 4 ⲛmismatch ⲉⲩⲧⲟϣ.

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage16_legacy_permutation_handler -> monster_permutation_route -> legacyPermutationOrderFromDropWrong -> oldPermutationUnrank0`

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `oldPermutationUnrank0`, `legacyPermutationRank0FromDropWrong`, `legacyPermutationOrderFromDropWrong`, `monster_permutation_route`, `monster_stage16_legacy_permutation_handler`, ⲙⲛ state ⲛⲧⲉⲡdrop ⲙⲛ ⲡrank0 ⲙⲛ ⲛorder ⲛⲗⲉⲅⲁⲥⲓ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡdetour ⲙⲡⲃⲁⲑⲙⲟⲥ ⲉⲧⲛⲏⲩ. Ⲙⲛ `drop-1` ⲉϥϣⲟⲟⲡ ϩⲙⲡproduction ⲙⲡⲉⲓStage.

## Ⲃⲁⲑⲙⲟⲥ 17 — PATCH 08

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`oldPermutationUnrank0`. Ⲡcontract ⲛⲧⲟϥ ⲟⲩⲏϩ ⲉϥϫⲓ `rank0=0..719`. Ⲡcaller ⲛStage 16 ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲙⲛ ⲡⲉϥmapping ⲛⲗⲉⲅⲁⲥⲓ, ⲁⲩⲱ ⲡhandler ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩCOPY_DIAGNOSTIC.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`permutationOneBasedFromDropPatch08`: ⲛϥϫⲓ ⲙⲡ`drop-1`, ⲛϥⲗⲟⲅⲓⲍⲉ ⲙⲡregular modulo ϩⲓ 720 ϩⲙⲡBigInt ⲛⲧⲉⲡⲉⲓline, ⲁⲩⲱ ⲛϥⲟⲩⲱϩ `1`. Ⲡ`orderPatchFromValue` ϫⲓ ⲙⲡoneBased ⲡⲁⲓ, ⲛϥⲥⲉⲕ `1` ⲉⲧⲣⲉϥⲧⲁⲙⲓⲟ ⲙⲡlegacyRank0, ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉ`oldPermutationUnrank0`.

`monster_permutation_route -> monster_stage17_permutation_patch_wrapper -> orderPatchFromValue -> oldPermutationUnrank0`

### EQUIVALENCE

Ⲡchain ⲟⲩⲏϩ ⲉϥⲟⲩⲟⲛϩ ⲁϫⲛ ⲟⲩsimplification: `drop-1 -> regularMod(...,720) -> +1 -> -1 -> oldPermutationUnrank0`. Ⲡⲇⲟⲕⲓⲙⲏ ⲥⲙⲓⲛⲉ ⲙⲛ `oracle_bowl_order_from_value` ϩⲓ `-1440,-721,-720,-719,-1,0,1,2,719,720,721,1440,1441`, ⲁⲩⲱ ⲟⲩⲛ 0 ⲛmismatch.

### EDGE CASES

`drop=1 -> oneBased=1 -> rank0=0`.

`drop=720 -> oneBased=720 -> rank0=719`.

`drop=721 -> oneBased=1 -> rank0=0`.

`drop=0 -> oneBased=720 -> rank0=719`.

`drop=-1 -> oneBased=719 -> rank0=718`.

Ⲡlegacy scar ⲟⲩⲏϩ ⲉϥⲟⲩⲟⲛϩ: `legacyPermutationOrderFromDropWrong(1)` ⲛϥⲧⲱⲛ ⲁⲛ ⲙⲛ ⲡoracle.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `permutationOneBasedFromDropPatch08`, `orderPatchFromValue`, `monster_stage17_permutation_patch_wrapper`, `CTX_PATCHED_PERMUTATION_ONE_BASED`, `CTX_PATCHED_PERMUTATION_RANK0`, `CTX_PATCHED_PERMUTATION_ORDER`, ⲙⲛ `CTX_PERMUTATION_PATCH_SEEN`. Ⲛⲁⲓ ⲛⲉ ⲛstate ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ.


## Ⲃⲁⲑⲙⲟⲥ 18 — DISCOVERY 09

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲛposition ⲛϣⲟⲣⲡ ⲙⲡorder ⲛⲉ ⲛbowl ID `1,2,3` ⲛⲧⲟⲩⲱⲧ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`legacyPoursToFixedBowlIds`: ⲛϥⲗⲟⲅⲓⲍⲉ ⲙⲡorder ⲛⲧⲟϣ ϩⲓⲧⲛ `orderPatchFromValue`, ⲁⲗⲗⲁ ⲛϥϫⲓ ⲛbowl ⲛⲧⲉⲡpour ϩⲓⲧⲛ ⲛID ⲉⲧⲟⲩⲏϩ `1,2,3`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲉϣϫⲉ ⲡorder ⲟ ⲛidentity, ⲡⲡⲗⲁⲛⲏ ⲛϥⲟⲩⲱⲛϩ ⲁⲛ. Ⲉϣϫⲉ ⲡorder ϣⲓⲃⲉ ⲛⲛposition ⲛ1..3, ⲡlegacy ϫⲓ ⲙⲡbowl ⲛⲗⲁⲑⲟⲥ.

Ⲡⲇⲟⲕⲓⲙⲏ ⲕⲱ ⲛⲟⲩcase ⲉϥⲧⲟϣ: `drop=121`, `i=4`, order `[2,1,3,4,5,6]`. Ⲡlegacy output ⲡⲉ `14675,14700,14754`; ⲡoutput ⲛposition ⲙⲡorder ⲡⲉ `14679,14694,14754`. Ⲛpour 1 ⲙⲛ 2 ⲥⲉϣⲟⲃⲉ; ⲡpour 3 ⲧⲱⲛ ϫⲉ ⲡID ⲙⲡposition 3 ⲟⲩⲏϩ ⲉϥⲟ ⲛ3.

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage18_legacy_fixed_pour_handler -> monster_pour_route -> legacyPoursToFixedBowlIds`

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `legacyPoursToFixedBowlIds`, `monster_pour_route`, `monster_stage18_legacy_fixed_pour_handler`, ⲙⲛ state ⲛⲧⲉⲡdrop/index/order/fixed IDs/old bowls/stone row/pours ⲛⲟⲩinvocation ⲛⲟⲩⲱⲧ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩdetour ϩⲙⲡⲉⲓDISCOVERY. Ⲡ`monster_pour_route` ⲟ ⲛCOPY_AUTHORITATIVE ⲙⲡlegacy ⲡⲁⲓ, ⲁⲩⲱ ⲛϥϫⲓ ⲁⲛ ⲙⲡoracle ϩⲙ runtime.
