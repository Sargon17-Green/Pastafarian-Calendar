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
