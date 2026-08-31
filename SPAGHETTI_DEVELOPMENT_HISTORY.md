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


## Ⲃⲁⲑⲙⲟⲥ 19 — PATCH 09

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`legacyPoursToFixedBowlIds`. Ⲡhelper ⲛStage 18 ⲟⲩⲏϩ ⲉϥⲗⲟⲅⲓⲍⲉ ⲙⲡorder ⲛⲧⲟϣ ⲁⲗⲗⲁ ⲛϥϫⲓ ⲛbowl ID `1,2,3` ϩⲛ ⲛ3 ⲛpour ⲛϣⲟⲣⲡ. Ⲡdirect call ⲉⲣⲟϥ ⲟⲩⲏϩ ⲉϥⲟⲩⲱⲛϩ ⲙⲡscar ⲛⲗⲉⲅⲁⲥⲓ.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`installOrderAliases(order,alias)`. Ⲡalias ⲟ ⲛⲟⲩmap ⲛⲧⲟϣ: `alias[position]=order[position]` ⲛposition `1..6`. Ⲡhelper ⲧⲁϫⲣⲟ ⲟⲛ ϫⲉ ⲡorder ⲟ ⲛpermutation ⲛID `1..6`.

Ⲡ`bowlByLegacyPosition(oldBowls,alias,position)` ⲗⲟⲅⲓⲍⲉ ⲙⲡbowl ID ϩⲓⲧⲛ ⲡalias ⲛⲧⲟϥ, ⲁⲩⲱ ⲙⲛⲛⲥⲱⲥ ⲛϥϫⲓ ⲙⲡBigInt pointer ϩⲙⲡoldBowls.

Ⲡ`patchedPours` ⲙⲟⲩⲧⲉ ⲉ`orderPatchFromValue`, ⲛϥⲧⲁⲙⲓⲟ ⲙⲡalias, ⲁⲩⲱ ⲛϥⲗⲟⲅⲓⲍⲉ ⲛ3 ⲛpour ⲛϣⲟⲣⲡ ϩⲓⲧⲛ ⲛformula ⲛⲧⲟϣ ⲙⲛ bowl read ⲉϥⲙⲟⲟϣⲉ ⲙⲙⲁⲧⲉ ϩⲓⲧⲛ `bowlByLegacyPosition`.

`monster_pour_route -> monster_stage19_bowl_alias_patch_wrapper -> patchedPours`

### EQUIVALENCE

Ⲉϣϫⲉ `alias[position]=order[position]`, ⲧⲟⲧⲉ `bowlByLegacyPosition(oldBowls,alias,position)` ⲧⲱⲛ ⲙⲛ `oldBowls[order[position]]`. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲛformula ⲙⲡpour ⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ ⲁϫⲛ ⲧⲣⲉⲩϥⲱϫⲉ ⲙⲡlegacy helper.

### EDGE CASES

Ⲡwitness `drop=145`, `i=4` ϯ order `[2,3,1,4,5,6]`. Ⲡalias ⲛⲧⲟϥ ⲟ ⲙⲡⲉⲓorder. Ⲛ3 ⲛbowl read ⲛϣⲟⲣⲡ ⲕⲧⲟ ⲉ`13,17,11`, ⲁⲩⲱ ⲛpatched pours ⲛⲉ `21063,21096,21108`.

Ⲡtest ⲙⲟⲟϣⲉ ⲟⲛ ϩⲓ `drop=1..720`, ⲛϥⲥⲙⲓⲛⲉ ⲙⲡorder ⲙⲛ `oracle_bowl_order_from_value`, ⲁⲩⲱ ⲛϥⲥⲙⲓⲛⲉ ⲙⲡ3 ⲛpour ⲙⲛ ⲟⲩVALIDATION_COPY ⲉϥϫⲓ ⲙⲡoracle order ⲙⲛ `oracle_SAVE`. Ⲟⲩⲛ 0 ⲛmismatch.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `installOrderAliases`, `bowlByLegacyPosition`, `patchedPours`, `monster_stage19_bowl_alias_patch_wrapper`, `CTX_PATCHED_POUR_ORDER`, `CTX_BOWL_ALIAS`, `CTX_PATCHED_POUR_RESULT` ⲙⲛ `CTX_BOWL_ALIAS_PATCH_SEEN`.

Ⲡlegacy result ⲙⲛ ⲡpatched result ⲥⲉϣⲟⲟⲡ ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ ϩⲙⲡ`MonsterContext`. Ⲙⲛ global mutable semantic state ⲉϥⲟⲩⲱϩ ϩⲙⲡⲉⲓⲡⲁⲧϣ.


## Ⲃⲁⲑⲙⲟⲥ 20 — DISCOVERY 10

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲟⲩⲛ ϣϭⲟⲙ ⲉⲥϩⲁⲓ ⲙⲡbowl ⲛⲧⲉ position ⲛⲓⲙ ⲉϩⲟⲩⲛ ⲉⲡB ⲛⲟⲩⲱⲧ ⲛⲧⲉⲩⲛⲟⲩ, ϫⲉ ⲡorder ⲛⲧⲟϥ ⲧⲁϫⲣⲏⲩ. Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`legacyStirOneDropInPlace` ⲉϥⲟⲩⲱϩ ⲛⲥⲁ ⲛposition 1..6 ⲁⲩⲱ ⲉϥⲥϩⲁⲓ ⲙⲡresult ⲉⲡB ⲛⲧⲉⲩⲛⲟⲩ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡorder ⲉϥⲧⲁϫⲣⲏⲩ ⲛϥⲧⲁϫⲣⲟ ⲁⲛ ⲙⲡsource ⲙⲡread. Ⲙⲛⲛⲥⲁ ⲧⲣⲉⲡposition ⲛϣⲟⲣⲡ ⲥϩⲁⲓ ⲙⲡB[id], ⲟⲩposition ⲉⲧⲛⲏⲩ ϣϭⲙϭⲟⲙ ⲉϫⲓ ⲙⲡⲉⲓvalue ⲛⲃⲣⲣⲉ ϩⲱⲥ `prev` ⲏ `next`.

Ⲡwitness ⲙⲡ`drop=1`, `i=4` ⲕⲱ ⲙⲡorder ⲉidentity ⲉⲧⲣⲉⲡⲡⲗⲁⲛⲏ ⲙⲡbowlAlias ⲧⲙⲧⲱⲙⲛⲧ ⲙⲛ ⲡⲡⲗⲁⲛⲏ ⲛⲧⲉⲡⲉⲓStage. Ⲡϣⲟⲣⲡ bowl ⲧⲱⲛ; ⲛ5 ⲉⲧⲛⲏⲩ ⲥⲉϣⲟⲃⲉ ⲙⲛ ⲟⲩVALIDATION_COPY ⲉϥϫⲓ ⲛread ⲧⲏⲣⲟⲩ ⲉⲃⲟⲗ ϩⲙⲡoldB ⲛⲟⲩⲱⲧ.

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage20_legacy_inplace_bowl_handler -> monster_bowl_stir_route -> legacyStirOneDropInPlace`

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `legacyStirOneDropInPlace`, `monster_bowl_stir_route`, `monster_stage20_legacy_inplace_bowl_handler`, ⲙⲛ state ⲛⲧⲉⲡdrop/index/input bowls/stone row/order/pours/output.

Ⲡhandler ⲧⲁⲙⲓⲟ ⲛⲟⲩworking pointer-vector ⲛⲧⲉⲡinvocation ⲉⲧⲣⲉⲡlegacy ⲧⲙϣⲓⲃⲉ ⲙⲡinput ⲙⲡlayer ⲛϣⲟⲣⲡ. Ⲡworking state ⲛⲧⲟϥ ⲇⲉ ⲟ ⲛsemantic state ⲙⲡDISCOVERY, ⲁⲩⲱ ⲡroute ⲙⲟⲟϣⲉ ⲉⲡlegacy ⲛⲧⲟϥ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩrepair ϩⲙⲡⲉⲓDISCOVERY.


## Ⲃⲁⲑⲙⲟⲥ 21 — PATCH 10

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`legacyStirOneDropInPlace`. Ⲡhelper ⲛStage 20 ⲟⲩⲏϩ ⲉϥⲥϩⲁⲓ ⲉⲡB ⲛⲧⲉⲩⲛⲟⲩ, ⲁⲩⲱ ⲡdirect test ⲟⲩⲏϩ ⲉϥⲟⲩⲱⲛϩ ⲙⲡ5 ⲛmismatch.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`stirOneDropViaShadow`. Ⲛϥⲧⲁⲙⲓⲟ ⲛⲟⲩclone ⲉϥϣⲟⲃⲉ ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉⲡlegacy ϩⲓⲱⲱϥ ⲛⲟⲩⲙⲉ. Ⲙⲛⲛⲥⲱⲥ ⲛϥⲧⲁⲙⲓⲟ ⲙⲡ`vaultOld` ⲉⲃⲟⲗ ϩⲙⲡB ⲛϣⲟⲣⲡ ⲙⲛ ⲟⲩ`pending` ⲉϥϣⲟⲩⲓⲧ.

Ⲛ6 ⲛcalculation ⲧⲏⲣⲟⲩ ⲥⲉϫⲓ ⲛbowl read ⲙⲙⲁⲧⲉ ϩⲙⲡ`vaultOld`. Ⲡresult ⲛⲓⲙ ⲃⲱⲕ ⲉ`pending`; ⲙⲛ ⲟⲩwrite ⲉⲡB ϣⲁⲛⲧⲉⲡround ⲙⲟⲩϩ ⲛⲥⲟⲟⲩ. Ⲡcommit ⲟⲩⲱⲛϩ ⲙⲙⲁⲧⲉ ⲙⲛⲛⲥⲁ ⲡvalidation ⲛⲧⲉ ⲛ6 ⲛpending slot.

`monster_bowl_stir_route -> monster_stage21_bowl_shadow_patch_wrapper -> stirOneDropViaShadow`

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲉⲡⲉⲓⲇⲏ ⲛread ⲧⲏⲣⲟⲩ ⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙⲡsnapshot ⲛⲟⲩⲱⲧ, ⲡresult ⲙⲡposition ⲛⲓⲙ ⲛϥⲛⲁϫⲓ ⲁⲛ ⲛⲟⲩneighbor ⲉⲁⲩϣⲓⲃⲉ ⲙⲙⲟϥ ϩⲙⲡround ⲛⲟⲩⲱⲧ. Ⲡ`pending` ⲛϥⲧⲟϣ ⲁⲛ ⲛⲟⲩread source.

ⲠStage 20 test ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ; ⲁϥⲕⲧⲟϥ ⲉ`STAGE20_REGRESSION_GREEN`. ⲠStage 21 test ⲟ ⲛ`STAGE21_PATCH10_GREEN`.


## Ⲃⲁⲑⲙⲟⲥ 22 — DISCOVERY 11

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲟⲩmemory ⲛorder ⲛⲟⲩⲱⲧ ⲣⲱϣⲉ ⲉⲧⲣⲉϥϩⲁⲣⲉϩ ⲉⲡorder ⲉⲧⲉⲣⲉⲡsauce ϫⲓ ⲙⲙⲟϥ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡlegacy ⲥϩⲁⲓ ⲉⲡmemory ⲡⲁⲓ ⲙⲛⲛⲥⲁ drop ⲛⲓⲙ ⲁⲩⲱ ⲙⲛⲛⲥⲁ post-stir ⲛⲓⲙ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡorder ⲙⲡdrop 46 ⲟ ⲛⲧⲟϣ ϩⲛ ⲧⲉϥⲟⲩⲛⲟⲩ, ⲁⲗⲗⲁ ⲛ12 ⲛpost-stir ⲥⲉⲥϩⲁⲓ ⲉⲡmemory ⲛⲟⲩⲱⲧ ⲙⲛⲛⲥⲱϥ. Ⲙⲛⲛⲥⲁ ⲡpost-stir 12, ⲡquery ⲛⲗⲉⲅⲁⲥⲓ ϫⲓ ⲙⲡorder ⲙⲡpost-stir 12 ⲁⲛⲧⲓ ⲡorder ⲙⲡdrop 46.

ⲠFoundation witness ⲧⲁϫⲣⲟ ⲙⲡdrop46 `[4,5,2,3,6,1]` ⲙⲛ ⲡquery `[1,6,5,2,4,3]`. Ⲛposition 1,2,6 ⲥⲉϣⲟⲃⲉ. Ⲡwrite count ⲟ ⲛ58, ⲁⲩⲱ ⲡlast source ⲡⲉ post-stir 12.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `initialBowlsThroughStage22OldFactory`, `postStirOneOverwritingOrderMemoryStage22`, `legacySauceWithOverwritableOrderMemory`, `monster_order46_memory_route`, `monster_stage22_overwritable_order_handler`, ⲙⲛ state ⲛⲧⲉ drop46 diagnostic/legacy order/query/write count/last source.

Ⲡfull path ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲛscar ⲙⲛ ⲛpatch ⲛStage 1–21. Ⲡoracle ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡproduction; ⲡtest ⲙⲙⲁⲧⲉ ⲥⲙⲓⲛⲉ ⲛⲛfinal bowls ⲙⲛ ⲡdrop46 order ⲙⲛ `oracle_sauce` ⲙⲡline ⲛⲟⲩⲱⲧ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩ`orderAt46Latch` ⲏ ⲟⲩrepair ϩⲙⲡⲉⲓDISCOVERY.


## Ⲃⲁⲑⲙⲟⲥ 23 — PATCH 11

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`legacySauceWithOverwritableOrderMemory`. ⲠCOPY_DIAGNOSTIC ⲛⲧⲟϥ ⲟⲩⲏϩ ⲉϥⲥϩⲁⲓ ⲙⲡorder memory 58 ⲛⲥⲟⲡ ⲁⲩⲱ ⲡlegacy query ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡorder ⲙⲡpost-stir 12.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`sauceWithOrderAt46Latch`. ⲠCOPY_AUTHORITATIVE ⲡⲁⲓ ⲣ ⲛⲟⲩfull sauce path ⲛⲕⲉⲥⲟⲡ, ⲁⲩⲱ ⲛϥϩⲁⲣⲉϩ ⲙⲡlegacy order memory ⲛⲟⲩⲱⲧ ⲉϥⲥⲏϩ 58 ⲛⲥⲟⲡ.

Ⲙⲛⲛⲥⲁ ⲡdrop 46 bowl round ⲛⲧⲉⲩⲛⲟⲩ, ⲉⲙⲡⲁⲧⲉ ⲡpost-stir 1 ⲁⲣⲭⲉⲓ, ⲡorder ⲥⲏϩ ⲉⲟⲩbuffer ⲉϥϣⲟⲃⲉ: `S23_ORDER46_LATCH`. Ⲡguard ⲁⲛⲁⲅⲕⲁⲍⲉ ϫⲉ ⲡwrite count ⲟ ⲛ0 ⲙⲡⲉⲙⲧⲟ ⲙⲡwrite, ⲁⲩⲱ ⲙⲛⲛⲥⲱϥ ⲛϥⲟ ⲛ1 ⲙⲙⲁⲧⲉ.

Ⲛ12 ⲛpost-stir ⲟⲩⲏϩ ⲉⲩⲥϩⲁⲓ ⲉⲡlegacy memory ⲁⲗⲗⲁ ⲙⲛ ⲟⲩwrite ⲉⲡlatch. Ⲡ`S23_QUERY_ORDER` ϫⲓ ⲙⲡlatch ⲙⲙⲁⲧⲉ.

`monster_order46_memory_route -> monster_stage23_order46_latch_patch_wrapper -> sauceWithOrderAt46Latch`

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

ⲠStage 22 test ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ; ⲁϥⲕⲧⲟϥ ⲉ`STAGE22_REGRESSION_GREEN`. ⲠStage 23 test ⲧⲁϫⲣⲟ ϫⲉ ⲡCOPY_DIAGNOSTIC ⲟⲩⲏϩ ⲉϥϣⲟⲃⲉ ⲙⲛ ⲡdrop46 order, ⲁⲗⲗⲁ ⲡlatch ⲙⲛ ⲡquery ⲧⲱⲛ ⲙⲛ `oracle_sauce`.

Ⲡ`monster_stage23_order46_latch_handler` ϫⲓ ⲛⲟⲩstate ⲙⲡresult ⲉⲧⲁⲡStage 22 handler ⲧⲁⲙⲓⲟ ⲙⲙⲟϥ; ⲛϥⲙⲟⲩⲧⲉ ⲁⲛ ⲛⲕⲉⲥⲟⲡ ⲉⲡsauce. Ⲡcontext ϩⲁⲣⲉϩ ⲉⲡlatch pointer, ⲡwrite count, ⲡsource ordinal, ⲡlegacy diagnostic result ⲙⲛ ⲡseen counter.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩ`oldNextBowlFixedName` ⲏ ⲟⲩcode ⲙⲡDISCOVERY 12.


## Ⲃⲁⲑⲙⲟⲥ 24 — DISCOVERY 12

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡnext bowl ϣϭⲙϭⲟⲙ ⲉϥⲟⲩⲱϩ ⲛⲥⲁ ⲡID ⲙⲙⲓⲛ ⲙⲙⲟϥ ϩⲓ ⲡring `1..6`. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oldNextBowlFixedName(id)` ⲉϥϯ `id+1`, ⲏ `1` ⲉϣϫⲉ ⲡid ⲟ ⲛ6.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

ⲠPATCH 11 ⲁϥⲧⲁϫⲣⲟ ⲛⲟⲩ`orderAt46Latch` ⲉϥϣⲟⲃⲉ ⲙⲛ ⲡring ⲛⲛID ⲛⲛⲟⲩⲙⲉⲣⲟⲛ. Ⲡsuccessor ⲛⲧⲟϣ ⲛⲧⲉ ⲟⲩqueried bowl ⲡⲉ ⲡID ⲉⲧⲛⲏⲩ ⲙⲛⲛⲥⲱϥ ϩⲙⲡlatch, ⲁⲛ ⲡID ⲉⲧⲛⲏⲩ ϩⲙⲡring ⲛⲛⲟⲩⲙⲉⲣⲟⲛ.

ϨⲙⲡFoundation witness, `orderAt46Latch=[4,5,2,3,6,1]`. Ⲡqueried ID ⲉⲧϩⲙⲡposition ⲙⲙⲁϩ4 ⲡⲉ `3`. Ⲡ`oldNextBowlFixedName(3)` ϯ `4`, ϩⲟⲡⲟⲩ ⲡsuccessor ⲙⲡlatch ⲡⲉ `6`.

`calendarDateSpaghetti -> monster_dispatch_base -> monster_stage24_legacy_next_bowl_handler -> monster_next_bowl_route -> legacyNextBowlAdapter -> oldNextBowlFixedName`

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `oldNextBowlFixedName`, `legacyNextBowlAdapter`, `monster_next_bowl_route`, `monster_stage24_legacy_next_bowl_handler`, ⲙⲛ state ⲛⲧⲉ queried ID/direct legacy result/route result/seen counters.

Ⲡ`legacyNextBowlAdapter` ϫⲓ ⲙⲡsauce result ϩⲙⲡcontract ⲁⲗⲗⲁ ⲛϥϫⲓ ⲙⲙⲟϥ ⲁⲛ ϩⲙⲡdecision; ⲡⲉⲓscar ⲡⲉ ⲡⲡⲗⲁⲛⲏ ⲙⲡDISCOVERY. Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩlookup ⲏ circular-successor repair ϩⲙⲡⲉⲓStage.


## Ⲃⲁⲑⲙⲟⲥ 25 — PATCH 12

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`oldNextBowlFixedName`. Ⲡhelper ⲛⲗⲉⲅⲁⲥⲓ ⲟⲩⲏϩ ⲉϥϯ ⲙⲡsuccessor ⲙⲡfixed numeric ring, ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲉⲧⲓ ⲛⲟⲩdiagnostic.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`nextBowlQueryPatch`. Ⲙⲛⲛⲥⲁ ⲡlegacy call, ⲡpatch ϫⲓ ⲙⲡ`S23_QUERY_ORDER`, ⲛϥϣⲓⲛⲉ ⲛⲥⲁ ⲡqueried ID, ⲁⲩⲱ ⲛϥⲕⲧⲟ ⲙⲡcircular successor. Ⲡlegacy output ⲛϥⲧⲟϣ ⲁⲛ ⲙⲡsemantic output.

`monster_next_bowl_route -> monster_stage25_next_bowl_patch_wrapper -> nextBowlQueryPatch`

Ⲡ`monster_stage25_next_bowl_patch_handler` ϩⲁⲣⲉϩ ⲉ`CTX_STAGE25_QUERIED_POSITION`, `CTX_STAGE25_PATCHED_NEXT_BOWL_ID` ⲙⲛ `CTX_STAGE25_PATCH_SEEN`.

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

ϨⲙⲡFoundation `orderAt46Latch=[4,5,2,3,6,1]`. Ⲛcircular successor ⲛⲉ `4→5`, `5→2`, `2→3`, `3→6`, `6→1`, `1→4`. Ⲡfixed-name scar ϣⲟⲃⲉ ϩⲓ queried IDs `1,3,5`, ⲁⲩⲱ ⲛϥⲧⲱⲛ ϩⲓ `2,4,6`.

ⲠStage 24 test ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ; ⲁϥⲕⲧⲟϥ ⲉ`STAGE24_REGRESSION_GREEN`. ⲠStage 25 test ⲧⲁϫⲣⲟ ⲛ6 ⲛID ⲧⲏⲣⲟⲩ, ⲡwrap, ⲙⲛ ⲛinvalid boundaries, ⲁⲩⲱ ⲛϥϯ `STAGE25_PATCH12_GREEN`.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩ`biasedLegacyPick` ⲏ ⲟⲩcode ⲙⲡPATCH 13.


## Ⲃⲁⲑⲙⲟⲥ 26 — DISCOVERY 13

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡanswer ⲛϣⲟⲣⲡ ϣϭⲙϭⲟⲙ ⲉϥⲃⲱⲕ ⲛⲧⲉⲩⲛⲟⲩ ⲉⲡfamily ϩⲓⲧⲛ ⲟⲩmodulo. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡlegacy helper `biasedLegacyPick(x,N)` ⲕⲧⲟ ⲙⲡ`regularMod(x-1,N)+1` ⲁϫⲛ ⲟⲩrejection ⲉⲙⲡⲁⲧϥ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡ`M_OLD` ⲛϥⲛⲁϣ ⲁⲛ ⲉϣⲁϫⲉ ⲙⲛ family size ⲛⲓⲙ ⲛⲟⲩⲙⲉⲧⲧⲱⲛ ⲛⲟⲩⲱⲧ ϩⲓⲧⲛ direct modulo. Ϩⲛ ⲛwitness ⲙⲡFoundation ⲉⲧⲟⲩⲧⲟϣ, ⲡ`first` ⲟ ⲉϩⲣⲁⲓ ⲉ`M_OLD/2`, ⲡdirection ⲟ ⲛ`-1`, ⲁⲩⲱ ⲡ`N` ⲡⲉ `first-1`. Ⲡanswer ⲛϣⲟⲣⲡ ⲟ ⲛ`N+1`; ⲡanswer ⲉⲧⲛⲏⲩ ⲟ ⲛ`N`. Ⲡlegacy ϯ `1` ⲁϫⲛ rejection, ⲁⲗⲗⲁ ⲡsame-line reference ⲙⲛ rejection ϯ `N`.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `answerRingThroughPatchedNextBowl`, `ringAnswer`, `biasedLegacyPick`, `legacyBiasedSelectionBeforeRejection`, `monster_biased_selection_route` ⲙⲛ `monster_stage26_legacy_biased_selection_handler`.

Ⲡhandler ⲕⲱ ⲛⲟⲩreal ring ⲉⲃⲟⲗ ϩⲙⲡStage 23 sauce result ⲙⲛ Stage 25 next-bowl semantics, ⲛϥⲧⲁⲙⲓⲟ ⲙⲡ`N=first-1`, ⲁⲩⲱ ⲛϥⲙⲟⲩⲧⲉ ⲉⲡlegacy selector ⲉⲙⲡⲁⲧⲉ ⲟⲩrejection ⲟⲩⲱⲛϩ.

Ⲡtest ⲥⲙⲓⲛⲉ ⲛanswer ring ⲛⲓⲙ ⲙⲛ `oracle_ask_bowl` ⲙⲡsame-line Assembly, ⲁⲩⲱ ⲛϥϫⲓ ⲙⲡnormative short choice ϩⲓⲧⲛ `oracle_choose_rank_short`. Ⲟⲩⲛ 3 ⲛmismatch ⲉⲩⲧⲟϣ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩacceptance limit, rejection progression, `patchedSmallPick`, `wideDetour` ⲏ code ⲙⲡStage 27/28.


## Ⲃⲁⲑⲙⲟⲥ 27 — PATCH 13

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`biasedLegacyPick` ⲏ ⲡ`legacyBiasedSelectionBeforeRejection`. Ⲡdirect legacy call ⲟⲩⲏϩ ⲉϥⲟⲩⲱⲛϩ ⲙⲡbiased modulo ⲁϫⲛ rejection.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`patchedSmallPick`. Ⲛϣⲟⲣⲡ ⲛϥⲙⲟⲩⲧⲉ ⲉⲡlegacy path ⲛⲟⲩCOPY_DIAGNOSTIC. Ⲙⲛⲛⲥⲱⲥ ⲛϥⲧⲁϫⲣⲟ ⲙⲡshort-domain `1<=N<=M_OLD`, ⲛϥⲗⲟⲅⲓⲍⲉ ⲙⲡacceptance limit `floor(M_OLD/N)*N`, ⲁⲩⲱ ⲛϥⲙⲟⲟϣⲉ ϩⲙⲡring ⲛⲟⲩⲱⲧ ϩⲓⲧⲛ offset ⲉϥⲟⲩⲱϩ ϣⲁⲛⲧⲉ `x<=limit`.

Ⲡ`biasedLegacyPick` ⲛϥⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛsemantic purpose ⲙⲙⲁⲧⲉ ⲙⲛⲛⲥⲁ acceptance. Ⲡroute ⲟ ⲛ:

`monster_biased_selection_route -> monster_stage27_rejection_patch_wrapper -> patchedSmallPick`

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

Ⲛ3 ⲛwitness ⲙⲡDISCOVERY 13 ⲥⲉⲟ ⲛdescending ring ⲙⲛ `N=first-1`. ⲠPATCH 13 rejecte ⲙⲡ`first=N+1`, ⲛϥϫⲓ ⲙⲡ`ringAnswer(1)=N`, ⲁⲩⲱ ⲛϥⲕⲧⲟ ⲙⲡrank `N`. Ⲡsame-line `oracle_choose_rank_short` ϯ ⲙⲡvalue ⲛⲟⲩⲱⲧ.

Ⲡ`MonsterContext` ϩⲁⲣⲉϩ ⲉⲡacceptance limit, ⲡaccepted answer, ⲡaccepted offset, ⲡpatched selection ⲙⲛ ⲡpatch seen counter. Ⲛstate ⲧⲏⲣⲟⲩ ⲟ ⲛinvocation-local.

### Ⲡharness scar ⲉⲧⲁⲩⲧⲁϫⲣⲟϥ

ⲠStage 26 test ⲛⲁϥⲁⲛⲁⲅⲕⲁⲍⲉ ⲙⲡsemantic route ⲉⲧⲣⲉϥⲟ ⲛ`1`, ⲉⲧⲉ ⲟⲩcontract ⲉϥⲥⲏϩ ⲙⲡbug ⲡⲉ ⲁⲛⲧⲓ ⲟⲩregression contract. Ⲁⲩⲕⲱ ⲙⲡassert ⲡⲁⲓ ⲉⲡdirect `legacyBiasedSelectionBeforeRejection`; ⲡroute ⲟⲩⲏϩ ⲉϥⲥⲙⲓⲛⲉ ⲙⲛ ⲡoracle. Ⲁⲩⲇⲟⲕⲓⲙⲁⲍⲉ ⲙⲡtest ⲉϥⲧⲟⲩⲛⲟⲥ ⲙⲛ ⲡStage 26 production: ⲛϥϯ `STAGE26_DISCOVERY13_EXPECTED_RED`; ⲙⲛ ⲡStage 27 production ⲛϥϯ `STAGE26_REGRESSION_GREEN`.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩwide selection ⲏ code ⲙⲡPATCH 14.


## Ⲃⲁⲑⲙⲟⲥ 28 — DISCOVERY 14

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲛfamily size ⲧⲏⲣⲟⲩ ϣϭⲙϭⲟⲙ ⲉⲩⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡshort rejection ⲙⲡPATCH 13. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡscar `legacySelectionAssumingNLeM` ⲙⲟⲩⲧⲉ ⲉ`patchedSmallPick` ⲁϫⲛ ⲟⲩbranch ⲛfamily width.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡ`patchedSmallPick` ⲧⲁϫⲣⲟ ⲙⲡguard `N<=M_OLD`; ⲉϣϫⲉ `N>M_OLD` ⲛϥϯ ⲁⲛ ⲛⲟⲩsemantic rank. Ⲡsame-line wide oracle ⲇⲉ ϯ ⲛⲟⲩrank ⲛⲧⲟϣ ⲛⲧⲉ family ⲛⲓⲙ. Ⲛ3 ⲛfamily `M_OLD+1`, `M_OLD^2`, `M_OLD^3` ⲧⲁϫⲣⲟ ⲙⲡdivergence ⲙⲛ 3 ⲛmismatch ⲉⲩⲧⲟϣ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `legacySelectionAssumingNLeM`, `monster_wide_selection_route` ⲙⲛ `monster_stage28_legacy_wide_assumption_handler`. Ⲡhandler ⲙⲟⲩⲧⲉ ⲉⲡroute ⲛⲟⲩⲙⲉ ϩⲓ `N=M_OLD+1`, ⲛϥϩⲁⲣⲉϩ ⲉⲡring, family size, null result, assumed-short flag, unsupported flag ⲙⲛ seen counter ϩⲙⲡinvocation context.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩ`wideDetour`, ⲟⲩbase-M digit builder, ⲟⲩwide-number rejection ⲏ code ⲙⲡPATCH 14.


## Ⲃⲁⲑⲙⲟⲥ 29 — PATCH 14

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`legacySelectionAssumingNLeM`. Ⲡscar ⲟⲩⲏϩ ⲉϥⲙⲉⲉⲩⲉ ϫⲉ family ⲛⲓⲙ ⲟ ⲛshort, ⲁⲩⲱ ϩⲓ `N>M_OLD` ⲛϥϯ ⲁⲛ ⲛⲟⲩrank.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲛ`wideRingStepPatch14`, `wideDetour`, `selectionPatch14` ⲙⲛ `monster_stage29_wide_patch_wrapper`.

Ⲡdispatcher ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡshort legacy path ⲉϣϫⲉ `N<=M_OLD`; ⲡwide detour ⲙⲙⲁⲧⲉ ⲡⲉ ⲡⲙⲁ ⲉϥⲙⲟⲟϣⲉ ⲉⲣⲟϥ ⲉϣϫⲉ `N>M_OLD`.

Ⲡwide path ⲧⲁⲙⲓⲟ ⲙⲡ`space=M_OLD^places` ⲉϥⲥⲟⲃⲧⲉ ⲉⲧⲣⲉϥⲟ ⲛ`>=N`. Ⲛdigits ⲛⲧⲉⲡanswer ring ⲥⲉϫⲓ ⲛⲟⲩⲥⲟⲡ ⲙⲙⲁⲧⲉ, ⲁⲩⲱ ⲥⲉⲧⲁⲙⲓⲟ ⲙⲡcombined base-M number. Ⲡrejection ⲙⲟⲟϣⲉ ϩⲓ ⲡcombined-number ring ⲛⲧⲟϣ; ⲛϥⲕⲧⲟ ⲁⲛ ⲉⲡdigit stream.

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

ⲠStage 28 test ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ; ⲁϥⲕⲧⲟϥ ⲉ`STAGE28_REGRESSION_GREEN`. ⲠStage 29 test ⲧⲁϫⲣⲟ ⲙⲡshort boundary ⲙⲛ ⲛwide family `M_OLD+1`, `M_OLD^2`, `M_OLD^3` ⲙⲛ ⲡsame-line oracle. Ⲡrank, `space`, `limit`, accepted combined number ⲙⲛ places ⲥⲉⲧⲱⲛ ⲙⲛ ⲛinvariant ⲛⲧⲟϣ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲉⲓⲣⲱⲧⲉ ⲧⲁϫⲣⲏⲩ

Ⲡlegacy scar ⲟⲩⲏϩ callable ⲁⲩⲱ ⲉϥⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩⲙⲉ ϩⲙⲡwide detour. Ⲡwide trace ⲟ ⲛinvocation-local ϩⲙⲡ`MonsterContext`. Ⲙⲛ oracle call ϩⲙⲡproduction, ⲙⲛ global mutable semantic state, ⲁⲩⲱ ⲙⲛ future patch code.


## Ⲃⲁⲑⲙⲟⲥ 30 — DISCOVERY 15

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡgate question step ϣϭⲙϭⲟⲙ ⲉⲩⲕⲱ ⲙⲙⲟϥ ⲛⲟⲩpositive magnitude ⲁⲩⲱ ⲉⲩⲙⲟⲩⲧⲉ ⲉ `oldGateQuestionDay(n)=FOUNDATION+n`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡsigned step ⲛnegative ⲥⲱⲣⲙ ⲙⲡⲉϥsign ϩⲓⲧⲛ `abs(step)`. Ⲡlegacy ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡnegative side; ⲛϥⲟⲩⲱϩ ⲙⲡmagnitude ⲉⲡFOUNDATION.

Ⲛwitness:

`step=-1  -> legacy=-15055670 ; normative=-15055672`
`step=-2  -> legacy=-15055669 ; normative=-15055673`
`step=-10 -> legacy=-15055661 ; normative=-15055681`

Ⲡ`step=0` ⲙⲛ `step=+1` ⲧⲱⲛ ⲛⲟⲩcoincidence.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `oldGateQuestionDay`, `legacyGateQuestionDayFromSignedStepWrong`, `monster_gate_question_day_route` ⲙⲛ `monster_stage30_legacy_gate_question_handler`.

Ⲡhandler ⲧⲁⲙⲓⲟ ⲙⲡ`signedStep=targetDay-FOUNDATION`, ϩⲁⲣⲉϩ ⲉⲡsigned step ⲙⲛ ⲡabsolute magnitude, ⲁⲩⲱ ⲕⲱ ⲙⲡlegacy result ⲙⲛ ⲡroute result ϩⲛ ⲙⲁ ⲉⲩϣⲟⲃⲉ.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩnegative detour. Ⲙⲛ `LEGACY_YEAR_MAX`, ⲙⲛ code ⲙⲡPATCH 16, ⲁⲩⲱ ⲙⲛ future gate-selection code.


## Ⲃⲁⲑⲙⲟⲥ 31 — PATCH 15

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`oldGateQuestionDay` ⲏ ⲡ`legacyGateQuestionDayFromSignedStepWrong`. Ⲡnegative scar ⲟⲩⲏϩ callable ⲁⲩⲱ ⲉϥⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲟⲩⲙⲉ.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`gateQuestionDayPatch15` ⲙⲛ `monster_stage31_gate_question_patch_wrapper`. Ⲡpatch ⲙⲟⲩⲧⲉ ⲛϣⲟⲣⲡ ⲉⲡlegacy helper. Ⲡsign comparison ⲙⲛ zero ⲧⲱϣ ⲙⲡsemantic branch: `signedStep>=0` ⲕⲁ ⲙⲡlegacy result; `signedStep<0` ϯ ⲙⲡ`FOUNDATION-abs(step)`.

`monster_gate_question_day_route -> monster_stage31_gate_question_patch_wrapper -> gateQuestionDayPatch15`

Ⲁⲩⲟⲩⲱϩ ⲟⲛ ⲉϫⲛ `monster_stage31_gate_question_patch_handler` ⲉϥϩⲁⲣⲉϩ ⲉⲡpatched result ⲙⲛ ⲡseen counter ϩⲙⲡ`MonsterContext`.

### Ⲡⲧⲱⲛ ⲙⲛ ⲡⲕⲁⲛⲱⲛ

ⲠStage 30 test ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ; ⲁϥⲕⲧⲟϥ ⲉ`STAGE30_REGRESSION_GREEN`. ⲠStage 31 test ⲧⲁϫⲣⲟ ⲙⲡdirect legacy scar ⲙⲛ ⲛsigned cases `-1,-2,-10,0,+1`, ⲁⲩⲱ ⲛϥⲥⲙⲓⲛⲉ ⲙⲡcontext legacy result ⲉⲡpatched route result.

### Ⲡharness ⲉⲧⲁⲩⲧⲁϫⲣⲟϥ

Ⲡtest ⲛStage 31 ⲛⲁϥⲕⲱ ⲙⲡ`-10` ϩⲓⲧⲛ `edi`, ⲉⲧⲉ ⲛϥϩⲁⲣⲉϩ ⲁⲛ ⲙⲡ64-bit negative sign. Ⲁⲩϣⲓⲃⲉ ⲙⲙⲟϥ ⲉ`rdi` ⲁϫⲛ ⲟⲩϣⲓⲃⲉ ⲙⲡproduction. Ⲁⲩⲧⲁϫⲣⲟ ⲟⲛ ⲙⲡstack alignment ⲛⲧⲉ ⲛtest helpers.

Ⲙⲛ code ⲙⲡPATCH 16 ⲏ future gate-selection code ⲉⲁϥⲃⲱⲕ ⲉϩⲟⲩⲛ.


## Ⲃⲁⲑⲙⲟⲥ 32 — DISCOVERY 16

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡyear-length ceiling ⲟ ⲛ`5781`, ⲁⲩⲱ ⲡcandidate predicate ϣϭⲙϭⲟⲙ ⲉϥϫⲓ ⲛⲟⲩyear ⲉϣϫⲉ `gaps>=6` ⲙⲛ `252<=length<=5781`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡlegacy ceiling ⲕⲱ ⲛ`5779`, `5780`, `5781` ⲉϩⲟⲩⲛ ⲉⲡcandidate family, ϩⲟⲡⲟⲩ ⲡboundary ⲛⲕⲁⲛⲱⲛ ⲟ ⲛ`5778`. Ⲡregression ⲧⲁϫⲣⲟ ⲙⲡ`251,252,5778,5779,5780,5781,5782` ⲁⲩⲱ ⲟⲩⲛ 3 ⲛmismatch ⲉⲩⲧⲟϣ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `LEGACY_YEAR_MAX=5781`, `oldYearCandidate`, `monster_year_candidate_route` ⲙⲛ `monster_stage32_legacy_year_max_handler`. Ⲡhandler ⲙⲟⲩⲧⲉ ⲉⲡlegacy route ⲛⲟⲩⲙⲉ ⲁⲩⲱ ϩⲁⲣⲉϩ ⲉⲡobserved legacy maximum, ⲡcandidate mask ⲙⲛ ⲡseen counter ϩⲙⲡinvocation context.

Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩlate filter ⲙⲡ`5778`, ⲁⲩⲱ ⲙⲛ code ⲙⲡPATCH 16 ⲉϥϣⲟⲟⲡ ϩⲙⲡproduction ⲙⲡⲉⲓStage.


## Ⲃⲁⲑⲙⲟⲥ 33 — PATCH 16

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`LEGACY_YEAR_MAX=5781` ⲏ ⲡ`oldYearCandidate`. Ⲡlegacy scar ⲟⲩⲏϩ callable ⲁⲩⲱ ⲡStage 32 handler ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛⲧⲟϥ ⲉⲧⲣⲉ `5779..5781` ⲟⲩⲏϩ ϩⲙⲡraw diagnostic family.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲕⲱ ⲉϩⲣⲁⲓ ⲙⲡ`REAL_YEAR_MAX_PATCH=5778` ⲙⲛ `yearCandidateAfterFootnotePatch`. Ⲡpatch helper ⲙⲟⲩⲧⲉ ⲉⲡlegacy predicate ⲛϣⲟⲣⲡ, ⲁⲩⲱ ⲙⲛⲛⲥⲁ ⲡlegacy accept ⲛϥrejecte ⲙⲙⲁⲧⲉ ⲉϣϫⲉ `length>5778`.

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `legacyYearCandidatesBeforeSortStage33`, `yearCandidatesAfterFootnotePatchBeforeSort`, `stableLengthOnlyPatchedYearCandidates`, `legacyYearSelectFirst`, `monster_stage33_year_ceiling_patch_wrapper` ⲙⲛ `monster_stage33_year_ceiling_patch_handler`.

### Ⲡorder ⲙⲡpipeline

Ⲡhandler ⲧⲁⲙⲓⲟ ⲛϣⲟⲣⲡ ⲙⲡraw legacy family ϩⲙⲡinput order `5781,5779,5778,5780`. Ⲙⲛⲛⲥⲱⲥ ⲡfootnote filter ⲕⲱ ⲙⲡsemantic pre-sort family ⲉ`5778` ⲙⲙⲁⲧⲉ. Ⲡstable sort ⲙⲛ ⲡselection ⲙⲟⲟϣⲉ ⲙⲛⲛⲥⲁ ⲡfilter ⲙⲙⲁⲧⲉ.

Ⲡcontext trace ⲟ ⲛ:

`legacy_raw_count=4`
`rejected_before_sort=3`
`filtered_pre_sort=1`
`sorted_count=1`
`selection_called=1`
`selected_length=5778`

### Ⲡfuture scar ⲉⲙⲡⲁⲧⲉϥⲓ

Ⲡsort ⲟⲩⲏϩ stable ⲕⲁⲧⲁ ⲡlength ⲙⲙⲁⲧⲉ. Ⲡtie probe ⲛlength `490` ϩⲁⲣⲉϩ ⲉⲡopening order `9,3`; ⲙⲛ reorder ⲙⲡequal-length run. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡPATCH 17 ⲙⲡⲟⲩanticipate ⲙⲙⲟϥ.


## Ⲃⲁⲑⲙⲟⲥ 34 — DISCOVERY 17

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲡstable sort ⲙⲡlegacy ϫⲓ ⲙⲡ`length` ⲙⲙⲁⲧⲉ. Ⲉϣϫⲉ ⲟⲩrun ⲟ ⲛequal-length, ⲡinput order ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲁϫⲛ ⲟⲩⲕⲉcomparison ⲙⲛ ⲡopening gate.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

ϨⲙⲡYear 5000 tie witness, ⲛcandidate ⲥⲛⲁⲩ ⲉⲩⲟ ⲛ`length=490` ⲛⲏⲩ ϩⲙⲡinput order ⲛopening gates `9,3`. Ⲡ`stableLengthOnlyPatchedYearCandidates` ϩⲁⲣⲉϩ ⲉ`9,3`, ⲁⲩⲱ ⲡ`legacyYearSelectFirst` ϫⲓ ⲙⲡopening `9`. Ⲡtest reference, ⲕⲁⲧⲁ ⲡscroll, ϫⲓ ⲙⲡopening ⲉⲧⲟ ⲛϣⲟⲣⲡ ϩⲙⲡequal-length run, ⲉⲧⲉ `3` ⲡⲉ.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ ⲉⲛⲧⲁϥⲟⲩⲱϩ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `legacyYear5000TieSelection`, `monster_stage34_legacy_year5000_tie_wrapper`, `monster_year5000_tie_route` ⲙⲛ `monster_stage34_legacy_year5000_tie_handler`. Ⲡhandler ⲣ ⲛⲟⲩdirect legacy copy ⲙⲛ ⲟⲩroute copy ϩⲓ buffer ⲉⲩϣⲟⲃⲉ, ⲁⲩⲱ ϩⲁⲣⲉϩ ⲉ`year=5000`, `tieLength=490`, `tieCount=2`, `legacySelectedOpen=9`, `routeSelectedOpen=9`.

Ⲡroute ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ⲙⲛ ⲡlegacy selection. Ⲙⲛ reorder ⲙⲡequal-length run ⲉϥϣⲟⲟⲡ ϩⲙⲡproduction ⲙⲡStage 34. Ⲡregression ⲟ ⲛ`EXPECTED_RED` ⲙⲛ 2 ⲛroute/context mismatch ⲉⲩⲧⲟϣ.

Ⲙⲛ code ⲙⲡPATCH 17 ⲉⲁϥⲃⲱⲕ ⲉϩⲟⲩⲛ.


## Ⲃⲁⲑⲙⲟⲥ 35 — PATCH 17

### Ⲡⲉⲛⲧⲁⲩⲕⲁⲁϥ ⲛⲥⲱⲟⲩ

Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ`stableLengthOnlyPatchedYearCandidates`, ⲡ`legacyYear5000TieSelection`, ⲏ ⲡ`legacyYearSelectFirst`. Ⲡlength-only stable sort ⲟⲩⲏϩ callable ⲁⲩⲱ ⲡdirect Stage 34 legacy scar ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡopening `9` ϩⲙⲡYear 5000 witness.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`reorderEqualLengthRunsByOpeningAfterLegacySort`. Ⲡhelper ⲛϥⲧⲁⲙⲓⲟ ⲁⲛ ⲛⲟⲩglobal `(length,opening)` sort. Ⲛϣⲟⲣⲡ ⲡlegacy sort ⲙⲟⲟϣⲉ. Ⲙⲛⲛⲥⲱϥ ⲡhelper scan ⲛⲛrun ⲉⲩⲟ ⲛcontiguous ⲁⲩⲱ ⲉⲩⲉⲓⲣⲉ ⲙⲡsame `YC_LENGTH`. Ⲙⲙⲁⲧⲉ ϩⲛ ⲡrun ⲛⲧⲟϣ ⲛϥsort ⲕⲁⲧⲁ `YC_OPEN` ascending.

Ⲁⲩⲧⲁⲙⲓⲟ ⲟⲛ ⲙⲡ`year5000TieSelectionPatch17` ⲙⲛ `monster_stage35_year5000_tie_patch_wrapper`. Ⲡpatch ⲙⲟⲩⲧⲉ ⲉ`legacyYear5000TieSelection` ⲛϣⲟⲣⲡ ⲁⲩⲱ ⲙⲛⲛⲥⲱϥ ⲙⲙⲁⲧⲉ ⲛϥⲙⲟⲩⲧⲉ ⲉⲡrun repair.

`monster_year5000_tie_route -> monster_stage35_year5000_tie_patch_wrapper -> year5000TieSelectionPatch17`

### Ⲡregression

ⲠStage 34 test ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ ⲁⲩⲱ ⲧⲉⲛⲟⲩ ⲟ ⲛ`GREEN`. ⲠStage 35 test ⲧⲁϫⲣⲟ ⲙⲡdirect legacy scar `9,3 -> 9`, ⲡpatched witness `9,3 -> 3,9 -> 3`, ⲥⲛⲁⲩ ⲛequal-length run ϩⲙⲡsame family, ⲛsingleton run, ⲁⲩⲱ ⲡinvocation-local context trace.

Ⲙⲛ `oldJumpGuess` ⲏ year-by-year traversal ⲙⲡPATCH 18 ⲉⲁϥⲃⲱⲕ ⲉϩⲟⲩⲛ.


## Ⲃⲁⲑⲙⲟⲥ 36 — DISCOVERY 18

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲙⲛⲛⲥⲁ ⲡYear 5000 tie ⲉⲧⲁⲩⲧⲁϫⲣⲟϥ, ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡnumber ⲙⲡyear ⲉⲧⲉ ⲡtarget ⲛⲁⲃⲱⲕ ⲉⲣⲟϥ ϣϭⲙϭⲟⲙ ⲉⲁⲩestimate ⲙⲙⲟϥ ⲕⲁⲧⲁ 365 ⲛday ⲛyear.

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oldJumpGuess` ⲉϥⲣ ⲛⲟⲩexact BigInt floor division:

`anchor.number + floorDiv(targetDay-anchor.firstDay,365)`

Ⲡnegative remainder ⲛⲧⲉⲡhardware division ⲙⲡⲟⲩⲕⲁⲁϥ ⲛⲟⲩtruncation scar; ⲡhelper ⲕⲧⲟ ⲙⲙⲟϥ ⲉⲡmathematical floor ⲛⲟⲩⲙⲉ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡdefect ⲛϥⲟ ⲁⲛ ϩⲙⲡdivision. Ⲡdefect ⲡⲉ ϫⲉ ⲡ365 guess ⲟ ⲛsemantic authority.

Ⲡ`stage36Year5000JumpAnchorFromPatchedTie` ⲙⲟⲩⲧⲉ ⲉⲡStage 35 `monster_year5000_tie_route`, ϫⲓ ⲙⲡpatched selected candidate ⲙⲛ `length=490`, ⲁⲩⲱ ⲛϥⲧⲁⲙⲓⲟ ⲛⲟⲩinvocation-local Year-5000 probe anchor. Ⲡanchor interval ϩⲁⲣⲉϩ ⲉⲡscroll ownership `(openDay,closeDay]`.

Ⲛtargets ⲛⲧⲉⲡtest:

`openDay -> expected 4999, legacy 4999`
`firstDay -> expected 5000, legacy 5000`
`firstDay+364 -> expected 5000, legacy 5000`
`firstDay+365 -> expected 5000, legacy 5001`
`closeDay -> expected 5000, legacy 5001`
`closeDay+1 -> expected 5001, legacy 5001`

Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡdirect scar ⲧⲁϫⲣⲟ, ⲁⲗⲗⲁ ⲡsemantic route ⲟ ⲛ`EXPECTED_RED`.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ

`legacyYearJumpAdapter` ⲙⲟⲩⲧⲉ ⲉ`oldJumpGuess` ⲛⲟⲩⲙⲉ. `monster_year_jump_route` ⲙⲟⲟϣⲉ ⲉⲡadapter ⲛⲧⲟϥ ϩⲙⲡDISCOVERY 18. `monster_stage36_legacy_year_jump_handler` ⲣ ⲛⲟⲩdirect copy ⲙⲛ ⲟⲩroute copy ⲁⲩⲱ ϩⲁⲣⲉϩ ⲉⲡtrace ⲧⲏⲣϥ ϩⲙⲡMonsterContext ⲛⲧⲉⲡinvocation.

Ⲙⲡⲟⲩⲧⲁⲙⲓⲟ ⲙⲡ`patchedNextYear`, `patchedPreviousYear`, `findYearByWalkPatch`, sequential transition trace, year cache, ⲏ code ⲙⲡPATCH 19.


## Ⲃⲁⲑⲙⲟⲥ 37 — PATCH 18

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲡ`oldJumpGuess` ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲙⲟϥ. Ⲡpatched path ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ⲛtelemetry ⲛϣⲟⲣⲡ, ⲁⲗⲗⲁ ⲛϥϫⲓ ⲁⲛ ⲙⲡⲉϥresult ⲛⲟⲩsemantic year.

`findYearByWalkPatch` ⲁⲣⲭⲉⲓ ϩⲙⲡYear-5000 anchor. Ⲡforward loop ⲙⲟⲩⲧⲉ ⲉ`patchedNextYear` ⲛⲟⲩⲥⲟⲡ ϩⲓ iteration ⲛⲓⲙ; ⲡbackward loop ⲙⲟⲩⲧⲉ ⲉ`patchedPreviousYear` ⲛⲧⲉⲓϩⲉ ⲛⲟⲩⲱⲧ.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡPATCH ⲧⲱⲛ

Ⲡtarget ownership ⲟ ⲛ`openDay < target <= closeDay`. Ⲡwalk ⲛϥⲕⲧⲟ ⲁⲛ ⲉⲟⲩguess; ⲛϥⲕⲧⲟ ⲙⲙⲁⲧⲉ ⲉⲟⲩYear ⲉⲁⲩⲡⲱϩ ⲉⲣⲟϥ ϩⲓⲧⲛ adjacent transitions.

Ⲡregression ⲧⲁϫⲣⲟ ⲙⲡ0/1/2 transition ⲛⲧⲉⲡside ⲡⲟⲩⲁ. Ⲡ`oldJumpGuess(firstDay+365)` ⲟⲩⲏϩ ⲉϥϯ `5001`, ϩⲟⲡⲟⲩ ⲡpatched route ϯ `5000`.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ

ⲠStage 36 historic flag `GUESS_USED_AS_SEMANTIC` ⲟⲩⲏϩ ⲉϥⲥϩⲁⲓ ⲙⲡlegacy belief. ⲠStage 37 state ⲉϥϣⲟⲃⲉ ϩⲁⲣⲉϩ ⲉ`telemetryGuess`, `patchedYear`, final Year pointer, forward/backward step counts ⲙⲛ `TELEMETRY_ONLY=1`.

Ⲙⲛ cache, ⲙⲛ global mutable semantic year state, ⲁⲩⲱ ⲙⲛ code ⲙⲡPATCH 19.


## Ⲃⲁⲑⲙⲟⲥ 38 — DISCOVERY 19

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲙⲛⲛⲥⲁ ⲡsequential Year walk, ⲁⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡnumber ⲙⲡYear ⲣⲁϣⲉ ⲉⲣⲟϥ ⲛⲟⲩcache identity ⲛⲧⲟϥ. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`legacyYearNumberOnlyCacheGetOrPut` ⲙⲛ map ⲉϥkeyed ⲙⲙⲁⲧⲉ ⲕⲁⲧⲁ `year.number`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡsame number ⲛϥⲧⲁϫⲣⲟ ⲁⲛ ϫⲉ ⲡrequest semantic state ⲟ ⲛsame. Ⲟⲩcalculation day ⲉϥϣⲟⲃⲉ, ⲟⲩopen gate ⲉϥϣⲟⲃⲉ, ⲏ ⲟⲩclose gate ⲉϥϣⲟⲃⲉ ϣϭⲙϭⲟⲙ ⲉⲩⲧⲁⲙⲓⲟ ⲛⲟⲩfresh value ⲉϥϣⲟⲃⲉ, ⲁⲗⲗⲁ ⲡlegacy HIT ⲕⲧⲟ ⲙⲙⲁⲧⲉ ⲉⲡvalue ⲛϣⲟⲣⲡ.

ⲠStage 38 regression ⲧⲁϫⲣⲟ ⲛ3 ⲛcollision ϩⲓ fresh caches. Ⲡdirect scar test ⲕⲱ ⲙⲡlegacy lookup ⲉϥⲣϩⲱⲃ ⲁⲩⲱ ⲛϥϫⲓ ⲁⲛ ⲛⲟⲩguard.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `stage38NewLegacyYearCache`, `legacyYearNumberOnlyCacheGetOrPut`, `buildLegacyYearCacheValueStage38`, `stage38YearVariant`, `legacyYearNumberOnlyCacheRoute`, `monster_year_cache_route`, `stage38LegacyCollisionCase` ⲙⲛ `monster_stage38_legacy_year_number_cache_handler`.

Ⲡhandler ⲙⲟⲩⲧⲉ ⲉⲡStage 37 route ⲛϣⲟⲣⲡ ⲉⲧⲣⲉϥϫⲓ ⲙⲡsemantic Year 5000. Ⲡcache objects ⲟ ⲛinvocation-local ⲙⲛ explicit owner ϩⲙⲡhandler; ⲙⲛ shared semantic context ⲙⲛ ⲕⲉinvocation.

ⲠStage 38 ⲟ ⲛ`EXPECTED_RED`; ⲛStage 1–37 ⲥⲉⲟ ⲛ`GREEN`.

Ⲙⲡⲟⲩⲧⲁⲙⲓⲟ ⲙⲡ`calculationDayFingerprint`, `openGate/closeGate` guarded entry, semantic HIT guard, ⲏ `oldStructureSauce` ⲙⲡPATCH 20.


## Ⲃⲁⲑⲙⲟⲥ 39 — PATCH 19

Ⲡmap ⲟⲩⲏϩ keyed ⲙⲙⲁⲧⲉ ⲕⲁⲧⲁ `year.number`. Ⲙⲡⲟⲩⲟⲩⲱϩ ⲛⲟⲩⲕⲉfield ⲉⲡkey, ⲁⲩⲱ ⲡphysical slot ⲟⲩⲏϩ `year.number -> pointer`.

Ⲡpointer ⲙⲡpatched route ⲧⲉⲛⲟⲩ ϫⲟⲟⲥ ⲉⲟⲩentry ⲙⲛ 4 ⲛfield:

`calculationDayFingerprint`
`openGate`
`closeGate`
`value`

Ⲡ`calculationDayFingerprintPatch19` ⲟ ⲛexact BigInt clone ⲙⲡcalculation day; ⲙⲛ foreign hash ⲏ foreign runtime. Ⲡ`guardedYearNumberOnlyCacheGetOrPut` ϭⲓⲛⲉ ⲙⲡslot ⲕⲁⲧⲁ `year.number` ⲙⲙⲁⲧⲉ. Ⲉϣϫⲉ ⲡkey ⲧⲱⲛ, ⲡHIT ⲟ ⲛsemantic HIT ⲙⲙⲁⲧⲉ ⲉϣϫⲉ ⲡ3 ⲛguard ⲧⲱⲛ.

Ⲉϣϫⲉ ⲟⲩguard ϣⲟⲃⲉ, ⲡsame bad key ⲟⲩⲏϩ ϩⲙⲡsame slot; ⲡentry ⲙⲙⲁⲧⲉ ⲧⲉ ⲉⲧⲟⲩϣⲓⲃⲉ ⲙⲛ ⲟⲩfresh entry, ⲁⲩⲱ ⲡrequest ⲟ ⲛMISS.

`monster_year_cache_route -> monster_stage39_year_cache_guard_patch_wrapper -> guardedYearNumberOnlyCacheRoute -> guardedYearNumberOnlyCacheGetOrPut`

Ⲡwrapper ⲙⲟⲩⲧⲉ ⲉ`legacyYearNumberOnlyCacheRoute` ⲛⲟⲩⲙⲉ ϩⲓ ⲟⲩdiagnostic cache ⲉϥϣⲟⲃⲉ, ⲙⲛⲛⲥⲱϥ ⲛϥⲙⲟⲟϣⲉ ⲉⲡguarded cache. Ⲡdirect legacy scar ⲟⲩⲏϩ ⲉϥreturn ⲙⲡstale value ⲕⲁⲧⲁ year.number ⲙⲙⲁⲧⲉ.

ⲠStage 39 regression ⲧⲁϫⲣⲟ ⲙⲡcalculation-day, open-gate ⲙⲛ close-gate mismatch. Ⲛ3 ⲛcase ⲧⲏⲣⲟⲩ ⲣ ⲛMISS+replace ϩⲁ ⲡsame key ⲁⲩⲱ ϯ ⲙⲡfresh value. Ⲟⲩsame-state request ⲙⲙⲁϩ2 ⲣ ⲛreal HIT.

ⲠStage 38 test ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ; ⲁϥⲕⲧⲟϥ ⲉ`STAGE38_REGRESSION_GREEN`. ⲠStage 39 ⲟ ⲛ`STAGE39_PATCH19_GREEN`.

Ⲙⲛ `oldStructureSauce` ⲏ code ⲙⲡPATCH 20 ⲉϥϣⲟⲟⲡ ⲉⲧⲓ.


## Ⲃⲁⲑⲙⲟⲥ 40 — DISCOVERY 20

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲙⲛⲛⲥⲁ ⲡYear walk ⲙⲛ ⲡguarded bad-key cache, ⲁⲩⲕⲱ ⲙⲡ`oldStructureSauce(cDay, originalTargetDay)` ⲛⲟⲩghost helper. ⲠYear ⲉⲧⲁⲩϭⲓⲛⲉϥ ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ϩⲙⲡABI, ⲁⲗⲗⲁ ⲡlegacy structure-sauce route ⲛϥϫⲓ ⲁⲛ ⲙⲡ`year.firstDay`.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

ⲠFOUNDATION target ϭⲓⲛⲉ ⲙⲡYear 4999 ⲙⲛ `firstDay=-15056160` ⲙⲛ `closeDay=-15055671`. Ⲡoriginal target ⲟ ⲛcloseDay, ⲁⲩⲱ ⲛϥⲧⲱⲛ ⲁⲛ ⲙⲛ firstDay.

Ⲡold ghost ⲗⲟⲅⲓⲍⲉ ⲙⲡsauce ⲙⲛ `target=-15055671`; ⲡsame-line normative probe ⲗⲟⲅⲓⲍⲉ ⲙⲡsauce ⲙⲛ `target=-15056160`. Ⲛ6 ⲛfinal bowl ⲧⲏⲣⲟⲩ ⲙⲛ 5/6 ⲙⲡquery-order position ϣⲟⲃⲉ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡghost ⲛϥϣϭⲙϭⲟⲙ ⲁⲛ ⲉϥⲟ ⲛsemantic structure sauce.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ

Ⲁⲩⲟⲩⲱϩ ⲉϫⲛ `oldStructureSauce`, `legacyStructureSauceUsingOriginalTarget`, `monster_structure_sauce_route` ⲙⲛ `monster_stage40_legacy_structure_sauce_handler`.

Ⲡhandler ⲟ ⲛinvocation-local ⲁⲩⲱ ⲟⲩⲏϩ ϩⲙⲡmain dispatcher chain. Ⲡdirect ghost ⲙⲛ ⲡroute ⲥⲉⲣϩⲱⲃ ⲛⲟⲩⲙⲉ, ⲁⲩⲱ ⲡroute ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡghost ⲛsemantic result ϩⲙⲡDISCOVERY.

ⲠStage 40 test ϯ `STAGE40_DISCOVERY20_EXPECTED_RED`; ⲛStage 1–39 ⲧⲏⲣⲟⲩ ⲥⲉⲟ ⲛ`GREEN`.

Ⲙⲡⲟⲩⲧⲁⲙⲓⲟ ⲙⲡ`structureSaucePatch`, year-first-day authoritative selector route, cutlet filtered family, ⲏ code ⲙⲡPATCH 21.


## Ⲃⲁⲑⲙⲟⲥ 41 — PATCH 20

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲡghost ⲙⲡStage 40 ⲙⲡⲟⲩⲃⲟⲗϥ ⲉⲃⲟⲗ. `oldStructureSauce` ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲙⲛ ⲡoriginal target, ⲁⲩⲱ `legacyStructureSauceUsingOriginalTarget` ⲟⲩⲏϩ callable.

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`structureSaucePatch` ⲛⲟⲩdetour ⲉϫⲛ ⲡlegacy route. Ⲛϥⲙⲟⲩⲧⲉ ⲉⲡghost ⲛϣⲟⲣⲡ ϩⲙ call ⲛⲓⲙ. Ⲉϣϫⲉ ⲡoriginal target ϣⲟⲃⲉ ⲙⲛ `year.firstDay`, ⲛϥⲗⲟⲅⲓⲍⲉ ⲛⲕⲉsauce ⲙⲛ `year.firstDay` ⲁⲩⲱ ⲛⲧⲟϥ ⲡⲉ ⲡauthoritative result. Ⲉϣϫⲉ ⲥⲉⲧⲱⲛ, ⲛϥreturn ⲙⲡghost.

`monster_structure_sauce_route -> monster_stage41_structure_sauce_patch_wrapper -> structureSaucePatch`

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ

Ⲁⲩⲟⲩⲱϩ ⲛ4 ⲛtrace field ⲉⲡMonsterContext ⲛⲧⲉⲡsame invocation: route ghost pointer, ghost-seen flag, patch-seen count ⲙⲛ equal-target reuse flag. Ⲙⲛ global semantic state ⲉϥⲟⲩⲱϩ.

ⲠStage 40 source ⲙⲡⲟⲩϣⲓⲃⲉ. Ⲡequal comparison ⲁϥⲟⲩⲱⲛϩ ⲛⲟⲩlatent stack fault ϩⲙⲡStage 40 comparator: ⲡsecond array pointer ⲛⲉϥⲕⲏ ϩⲁ ⲡrsp ⲉⲧⲁⲩreserve ⲙⲙⲟϥ, ⲁⲩⲱ ⲡ`call bi_cmp` ⲛⲉϥⲥϩⲁⲓ ⲙⲡreturn address ⲉϫⲛ ⲡsame slot. Ⲁⲩϩⲁⲣⲉϩ ⲉⲡbyte contract ϩⲓⲧⲛ ⲟⲩtest-only Assembly ABI bridge ⲉϥⲙⲟⲩⲧⲉ ⲉ`__real_bi_cmp` ⲁⲩⲱ ⲕⲧⲟ ⲙⲡcaller red-zone value. Ⲡbridge ⲛϥⲟ ⲁⲛ ⲙⲙⲉⲣⲟⲥ ⲙⲡproduction route.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

ⲠFOUNDATION witness ⲟⲩⲏϩ ⲉϥϯ ⲛYear 4999 ⲙⲛ `firstDay=-15056160`. Ⲡold ghost ⲙⲛ original target `-15055671` ⲟⲩⲏϩ ⲉϥϣⲟⲃⲉ ⲙⲛ ⲡfirst-day sauce, ⲁⲗⲗⲁ ⲡpatched route ⲧⲱⲛ ⲙⲛ ⲡfirst-day sauce. Ⲡflag `GHOST_USED_AS_SEMANTIC` ⲟ ⲛ0 ϩⲙⲡdifferent-target case ⲁⲩⲱ 1 ϩⲙⲡequal-target case.

`STAGE40_REGRESSION_GREEN`

`STAGE41_PATCH20_GREEN`

Ⲙⲛ Patch 21 ⲏ cutlet filtered-family code ⲉϥⲟⲩⲱϩ ϩⲙⲡStage 41.


## Ⲃⲁⲑⲙⲟⲥ 42 — DISCOVERY 21

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲙⲛⲛⲥⲁ ⲡstructure-sauce detour, ⲁⲩⲙⲉⲉⲩⲉ ϫⲉ ⲟⲩpartition ⲙⲡYear gap ⲉcutlets ϣϭⲙϭⲟⲙ ⲉϥⲛⲏⲩ ⲉⲃⲟⲗ ϩⲛ positive compositions ⲧⲏⲣⲟⲩ. Ⲡlegacy generator ⲛϥⲱϣ ⲁⲛ ϫⲉ ⲡcalculation day ⲟ ⲛinternal gate ⲏ ⲁⲛ.

Ⲁⲩⲟⲩⲱϩ ⲛ`stage42LegacyBinomialU64`, `oldCutletPartitionFamilyCount`, `oldCutletPartitionFamilyUnrank`, `oldCutletPartitionFamily`, `legacyCutletPartitionWithoutCalculationGate` ⲙⲛ `monster_cutlet_partition_route`. Ⲡcount ⲟ ⲛarbitrary-precision BigInt; ⲡunrank ⲟ ⲛexact lexicographic positive-composition unrank.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ϩⲙ `gap=10, cutlets=3, offset=4, rank=1`, ⲡdirect scar ⲙⲛ ⲡsemantic route ⲧⲱⲛ ⲉ`count=36`, `[1,1,8]`. Ⲡrequired internal-gate offset ⲥⲏϩ ϩⲙⲡABI ⲁⲗⲗⲁ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲛⲟⲩdecision.

Ⲡtest-only normative reference ⲧⲁϫⲣⲟ ⲙⲡfiltered family: `count=8`, rank 1 = `[1,3,6]`. Ⲡtest-only prefix diagnostic ϫⲓ ⲙⲡproper prefix `4`; ⲙⲛ such predicate ⲉϥⲃⲱⲕ ⲉⲡproduction route.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ

ⲠStage 42 handler ⲟⲩⲏϩ ϩⲙⲡmain dispatcher chain. Ⲛϥⲧⲁⲙⲓⲟ ⲙⲡrank-1 witness, ⲛϥⲕⲱ ⲙⲡroute output ϩⲙⲡMonsterContext, ⲁⲩⲱ ⲛϥⲧⲁϫⲣⲟ ⲙⲡdirect all-positive scar.

`monster_cutlet_partition_route -> legacyCutletPartitionWithoutCalculationGate -> oldCutletPartitionFamily`

Ⲙⲡⲟⲩⲧⲁⲙⲓⲟ ⲙⲡfiltered-family detour, prefix-required DP count/unrank, ⲏ selector ⲙⲡPATCH 21. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡrepository state ⲟ ⲛ`EXPECTED_RED`.

`STAGE42_DISCOVERY21_EXPECTED_RED`

ⲚStage 1–41 ⲧⲏⲣⲟⲩ ⲥⲉⲟ ⲛ`GREEN`.


## Ⲃⲁⲑⲙⲟⲥ 43 — PATCH 21

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲙⲡⲟⲩⲃⲟⲗ ⲉⲃⲟⲗ ⲙⲡall-positive generator ⲙⲡStage 42. `oldCutletPartitionFamily` ⲙⲛ `legacyCutletPartitionWithoutCalculationGate` ⲟⲩⲏϩ callable ⲁⲩⲱ ⲡdetour ⲙⲟⲩⲧⲉ ⲉⲣⲟⲟⲩ ⲛghost ⲛⲟⲩⲙⲉ.

Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`filteredCutletPartitionFamilyCount`, `filteredCutletPartitionFamilyUnrank` ⲙⲛ `filteredCutletPartitionFamily`. Ⲉϣϫⲉ ⲟⲩinternal calculation gate ⲥⲏϩ ϩⲙ `requiredOffset`, ⲡfamily ⲡⲉ ⲛpositive compositions ⲉⲧⲉ ⲟⲩproper prefix ⲧⲱⲛ ⲙⲛ ⲡoffset. Ⲡunrank ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲡlegacy lexicographic order.

`monster_cutlet_partition_route -> monster_stage43_cutlet_partition_patch_wrapper -> cutletPartitionPatch21`

### Ⲡghost ⲙⲛ ⲡauthoritative route

Ⲡwrapper ⲧⲁⲙⲓⲟ ⲛⲟⲩseparate ghost buffer, ⲙⲟⲩⲧⲉ ⲉⲡlegacy adapter, ⲁⲩⲱ ϩⲁⲣⲉϩ ⲉⲡghost count ⲙⲛ partition. Ⲉϣϫⲉ `requiredOffset=0`, ⲡghost ⲟ ⲛauthoritative ⲁⲩⲱ ⲁⲩreuse ⲙⲙⲟϥ. Ⲉϣϫⲉ `requiredOffset!=0`, ⲡghost ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡsemantic output.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

ⲠStage 42 source ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ ⲁⲩⲱ ⲁϥⲕⲧⲟϥ ⲉ`STAGE42_REGRESSION_GREEN`. ⲠStage 43 ϯ `STAGE43_PATCH21_GREEN`.

Ⲁⲩⲣ ⲛⲟⲩ32-case vector sweep ϩⲓ filtered ranks ⲉⲩϣⲟⲃⲉ, ⲁⲩⲱ ⲟⲩwide witness `gap=5778, cutlets=17, requiredOffset=1000` ⲧⲁϫⲣⲟ ϫⲉ ⲡcount ⲟ ⲛmulti-limb BigInt ⲁⲩⲱ ⲡrank-1 prefix ⲙⲟⲩϩ ⲙⲡrequired boundary.

## Ⲃⲁⲑⲙⲟⲥ 44 — DISCOVERY 22

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲙⲛⲛⲥⲁ ⲡcutlet-partition route, ⲁⲩⲕⲱ ⲙⲡlegacy name generator ϫⲉ ⲡrank ϣϭⲙϭⲟⲙ ⲉⲩⲱϣ ⲙⲙⲟϥ ⲛdigits ⲛbase 17 ⲙⲙⲁⲧⲉ. Ⲡdigit ⲛposition ⲛⲓⲙ ϫⲓ ⲛⲟⲩcanonical cutlet-name index `1..17`, ⲁⲩⲱ ⲙⲛ state ⲉϥⲙⲉⲩⲉ ⲛⲛⲉⲛⲧⲁⲩϫⲓ ⲛϣⲟⲣⲡ.

`oldCutletNameRowWithRepeats(rank1,K,out)`

Ⲡlegacy rule ⲡⲉ:

`q = rank1 - 1`

`out[p] = (q mod 17) + 1; q = floor(q/17)`

Ⲡ`legacyCutletNamesWithRepeats` ⲕⲱ ⲙⲡscar callable. Ⲡsemantic route ⲙⲡDISCOVERY 22 ⲡⲉ:

`monster_cutlet_names_route -> legacyCutletNamesWithRepeats -> oldCutletNameRowWithRepeats`

Ⲛcanonical indices ⲧⲱⲛ ⲙⲛ ⲡfrozen `SOURCE_LANGUAGE_CATALOG.tsv`; ⲙⲡⲟⲩϣⲓⲃⲉ ⲛⲟⲩname ϩⲙⲡcatalog.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡwitness ⲡⲉ `K=6`, `rank1=1`.

Ⲡlegacy route ϯ:

`[1,1,1,1,1,1]`

Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡsame Sahidic cutlet name ⲣ ⲛ6 ⲛposition. Ⲡtest-only normative reference ⲛⲧⲉⲡsame Assembly test ϯ ⲙⲡrank 1 ⲙⲡordered distinct-name family:

`[1,2,3,4,5,6]`

Ⲡdirect scar ⲟⲩⲏϩ repeated ⲁⲩⲱ ⲡsemantic route ⲟⲩⲏϩ ⲉϥⲧⲱⲛ ⲙⲙⲟϥ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡDISCOVERY ⲟ ⲛ`EXPECTED_RED`.

### Ⲡⲧⲁⲡ ⲙⲙⲟⲛⲥⲧⲉⲣ

`calendarDateSpaghetti -> monster_stage44_legacy_repeated_names_handler -> monster_cutlet_names_route -> legacyCutletNamesWithRepeats -> oldCutletNameRowWithRepeats`

ⲠMonsterContext ϩⲁⲣⲉϩ ⲉ`cutletCount`, `selectedRank`, route-name row pointer, repeat-seen flag, route-seen flag ⲙⲛ seen counter. Ⲛfield ⲛⲁⲓ ⲟ ⲛinvocation-local trace state ⲙⲙⲁⲧⲉ.

Ⲡcorrect distinct-name unrank ⲥⲏϩ ⲙⲙⲁⲧⲉ ϩⲙ `tests/stage44_discovery22.s` ⲛtest reference. Ⲙⲛ selector/detour ⲙⲡPATCH 22 ⲉϥϣⲟⲟⲡ ϩⲙⲡproduction.

ⲚStage 1–43 ⲧⲏⲣⲟⲩ ⲥⲉⲟ ⲛ`GREEN`; ⲡStage 44 ϯ `STAGE44_DISCOVERY22_EXPECTED_RED`.


## Ⲃⲁⲑⲙⲟⲥ 45 — PATCH 22

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲡbase-17 generator ⲙⲡStage 44 ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲛⲟⲩⲙⲉ. `oldCutletNameRowWithRepeats` ⲙⲛ `legacyCutletNamesWithRepeats` ⲙⲡⲟⲩϣⲓⲃⲉ ⲛⲟⲩbyte. Ⲁⲩⲟⲩⲱϩ ⲙⲡ`cutletNamesPatch22` ⲛdetour ⲉϫⲛ ⲡscar.

Ⲡdetour ⲧⲁⲙⲓⲟ ⲛⲟⲩghost buffer, ⲙⲟⲩⲧⲉ ⲉⲡlegacy row, ⲁⲩⲱ ⲧⲁⲙⲓⲟ ⲛⲟⲩcorrect row ϩⲓⲧⲛ `unrankDistinctCutletNames17`. Ⲡunrank ⲕⲱ ⲙⲡfalling-factorial block size ⲕⲁⲧⲁ position ⲁⲩⲱ ⲃⲱⲗ ⲉⲃⲟⲗ ⲙⲡchosen canonical index ϩⲛ ⲛremaining indices.

### Ⲡscar selector

`bad=legacy candidate`

`correct=partial-permutation unrank`

Ⲉϣϫⲉ `bad==correct`, ⲡbad copy ⲃⲱⲕ ⲉⲡoutput ⲁⲩⲱ ⲡtrace ⲥϩⲁⲓ `ghost-reused=1`. Ⲉϣϫⲉ ⲥⲉϣⲟⲃⲉ, ⲡbad ⲟⲩⲏϩ ghost-only ⲁⲩⲱ ⲡcorrect row ⲡⲉ ⲡsemantic output.

ⲠStage 44 source ⲙⲡⲟⲩϣⲓⲃⲉ ⲁⲩⲱ ⲁϥⲕⲧⲟϥ ⲉ`STAGE44_REGRESSION_GREEN`. ⲠStage 45 ϯ `STAGE45_PATCH22_GREEN`.

Ⲡ68-case sweep ⲧⲁϫⲣⲟ ⲙⲡfull `K=1..17` range ϩⲓ boundary ⲙⲛ middle ranks. Ⲡequal multi-name witness `K=2, rank=272` ϯ `[17,16]` ϩⲙ bad ⲙⲛ correct ⲙⲡⲉⲥⲛⲁⲩ.

Ⲙⲛ month-length materialization / VirtualLegacyList / Patch 23 code ⲉϥⲟⲩⲱϩ ϩⲙⲡStage 45.


## Ⲃⲁⲑⲙⲟⲥ 46 — DISCOVERY 23

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲁⲩⲕⲱ ⲙⲡmonth-length family ϫⲉ ⲟⲩlegacy list ⲛrows ⲧⲏⲣⲟⲩ ⲉϥϣϭⲙϭⲟⲙ ⲉϥⲧⲁⲙⲓⲟ ⲙⲙⲟⲟⲩ ⲉⲩⲥⲟⲡ. Ⲁⲩⲧⲁⲙⲓⲟ ⲙⲡ`oldMonthLengthMaterializedList` ⲉϥⲱϣ ⲙⲡbounded compositions ϩⲙ lexicographic order, ⲛϥⲗⲟⲅⲓⲍⲉ ⲙⲡrow count, ⲛϥallocate ⲙⲡfull row array, ⲁⲩⲱ ⲛϥⲥϩⲁⲓ ⲛⲟⲩrow ⲛⲓⲙ ⲉⲣⲟϥ.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡsmall witness `L=15,K=3` ⲧⲁϫⲣⲟ ϫⲉ ⲡlegacy scar ⲣϩⲱⲃ ⲛⲁⲙⲉ ⲁⲩⲱ ⲧⲁⲙⲓⲟ ⲛ10 ⲛrows. Ⲡlarge proof ⲙⲡⲟⲩⲣ ⲙⲙⲟϥ ϩⲓⲧⲛ allocation. Ϩⲙ `L=252,K=47`, ⲡupper bound ⲛϥⲣϩⲱⲃ ⲁⲛ, ⲁⲩⲱ ⲡexact count ⲡⲉ `C(110,46)=22747362824110665179416185383175`, ⲟⲩ105-bit BigInt. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡmaterialized-list backend ⲟ ⲛregression ⲙⲡDISCOVERY 23.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲛⲥⲁ Patch 23

Ⲙⲡⲟⲩⲧⲁⲙⲓⲟ ⲛ`VirtualLegacyList`. Ⲙⲡⲟⲩⲕⲱ ⲛexact bounded-DP `count` ⲏ `itemAt1` backend ϩⲙⲡproduction. Ⲡtest ⲙⲙⲁⲧⲉ ⲧⲁϫⲣⲟ ⲙⲡhuge cardinality without OOM.

`STAGE46_DISCOVERY23_EXPECTED_RED`


## Ⲃⲁⲑⲙⲟⲥ 47 — PATCH 23

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲙⲡⲟⲩⲃⲟⲗ ⲉⲃⲟⲗ ⲙⲡeager scar ⲙⲡStage 46. `oldMonthLengthMaterializedList` ⲙⲛ `legacyMonthLengthMaterializedList` ⲟⲩⲏϩ callable ⲙⲛ ⲡsame full-row enumeration. Ⲁⲩⲟⲩⲱϩ ⲙⲡ`VirtualLegacyList` backend ⲉϫⲛ ⲡscar.

Ⲡvirtual object ⲛϥϩⲁⲣⲉϩ ⲁⲛ ⲉrows. Ⲛϥϩⲁⲣⲉϩ ⲉexact BigInt count ⲙⲛ ⲟⲩDP table ⲉⲧⲱϣ ⲙⲡbounded residual compositions. Ⲡtable ⲟ ⲛpolynomial storage ⲕⲁⲧⲁ `monthCount*(residual+1)`, ⲛϥⲟ ⲁⲛ ⲛstorage ⲕⲁⲧⲁ family cardinality.

### Ⲡlexicographic equivalence

Ⲡlegacy materializer ⲙⲟⲟϣⲉ ⲛⲥⲁ month length candidates ϩⲙ ascending order. Ⲡ`virtualMonthLengthListItemAt1Big` ⲙⲟⲟϣⲉ ⲛⲥⲁ ⲡsame candidates ϩⲙ ⲡsame order, ⲁⲩⲱ ⲡDP suffix count ⲙⲙⲁⲧⲉ ⲃⲱⲗ ⲉⲃⲟⲗ ϫⲉ ⲟⲩblock ⲛⲓⲙ ϣⲁϫⲉ ⲛⲟⲩⲏⲣ ⲛrows. Ⲉⲧⲃⲉ ⲡⲁⲓ ⲡunrank ⲧⲱⲛ row-for-row ⲙⲛ ⲡlegacy lexicographic list.

ⲠAssembly sweep ⲧⲁϫⲣⲟ ⲙⲡrow-for-row equivalence ϩⲓ small families, ⲛⲕⲉⲥⲟⲡ ϩⲙ families ⲉⲧⲉ ⲡupper bound 123 ⲣϩⲱⲃ. Ⲡlarge `L=252,K=47` test ⲧⲁϫⲣⲟ ⲙⲡfirst rank ⲙⲛ ⲡfull-BigInt last rank without materialization.

### Ⲡghost ⲉⲧⲟ ⲛsafe

Ⲡdetour ⲙⲟⲩⲧⲉ ⲉⲡeager legacy scar ⲛghost ⲉϣϫⲉ ⲡfamily count `<=256`. Ⲡghost ⲟ ⲛdiagnostic invocation-local list ⲁⲩⲱ ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡauthoritative rows. Ⲉϣϫⲉ ⲡcount ⲛⲁⲁⲁ ⲏ multi-limb, ⲡdetour ⲥϩⲁⲓ ⲙⲡskip flag ⲁⲩⲱ ⲛϥⲣ ⲁⲛ ⲙⲡeager call, ⲉⲧⲣⲉϥⲁⲣⲉϩ ⲉⲡOOM boundary ⲉⲧⲁⲡDiscovery 23 ⲟⲩⲱⲛϩ ⲙⲙⲟϥ.

`STAGE46_REGRESSION_GREEN`

`STAGE47_PATCH23_GREEN`

Ⲙⲛ `legacyChooseEachDaySeparately`, `DPUnrankLegalWeaving`, ⲏ Stage 48 semantic code ⲉϥⲟⲩⲱϩ ϩⲙⲡStage 47.


## Ⲃⲁⲑⲙⲟⲥ 48 — DISCOVERY 24

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲁⲩⲕⲱ ⲙⲡmonth weaving ϫⲉ ⲥϣϭⲙϭⲟⲙ ⲉⲥⲧⲁⲙⲓⲟ day-by-day: ϩⲙ day ⲛⲓⲙ ⲡanswer ⲥⲱⲧⲡ ⲛⲟⲩmonth, ⲁⲩⲱ ⲉϣϫⲉ ⲡmonth ⲙⲟⲩϩ ⲡlegacy ϥⲕⲱⲧⲉ ⲉⲡnext ⲉϥⲟⲩⲱϣ ⲛⲟⲩremaining slot. Ⲡⲁⲓ ⲧⲁϫⲣⲟ ⲙⲡmultiplicities ⲁⲩⲱ ϥⲧⲁⲙⲓⲟ ⲛⲟⲩfull row.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲡlocal choice ⲛϥⲧⲁϫⲣⲟ ⲁⲛ ⲙⲡwhole-weave first/last ordering. Ϩⲙ `lengths=[4,4]` ⲙⲛ `answers=[2]`, ⲡlegacy row ⲡⲉ `[2,2,2,2,1,1,1,1]`. Ⲡmonth 2 ⲟⲩⲱⲛ ⲛϣⲟⲣⲡ ⲁⲩⲱ ⲙⲟⲩϩ ⲛϣⲟⲣⲡ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡrow ⲛϥⲟ ⲁⲛ ⲛⲟⲩlegal weaving.

Ⲡ`wantedRank=1` ⲃⲱⲕ ϩⲓⲧⲛ ⲡroute ABI ⲁⲗⲗⲁ ⲡlegacy ⲛϥⲱϣ ⲙⲙⲟϥ ⲁⲛ. Ⲡtest-only rank-1 witness ⲡⲉ `[1,1,1,1,2,2,2,2]`, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡDISCOVERY 24 ⲟ ⲛEXPECTED_RED.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲛⲥⲁ Patch 24

Ⲙⲡⲟⲩⲧⲁⲙⲓⲟ ⲛlegal-weaving DP ⲏ whole-weave unrank ϩⲙⲡproduction. Ⲙⲡⲟⲩⲕⲱ ⲛghost/correct equality selector. Ⲡlegacy chooser ⲙⲙⲁⲧⲉ ⲡⲉ ⲡauthoritative route ⲙⲡStage 48.

`STAGE48_DISCOVERY24_EXPECTED_RED`


## Ⲃⲁⲑⲙⲟⲥ 49 — PATCH 24

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲙⲡⲟⲩⲃⲟⲗ ⲉⲃⲟⲗ ⲙⲡdaily chooser scar ⲙⲡStage 48. `oldMonthWeavingEachDaySeparately` ⲙⲛ `legacyChooseEachDaySeparately` ⲟⲩⲏϩ callable ⲙⲛ ⲡsame local-choice semantics. Ⲁⲩⲟⲩⲱϩ ⲙⲡ`monthWeavingPatch24` ⲛdetour ⲉϫⲛ ⲡscar.

Ⲡdetour ⲙⲟⲩⲧⲉ ⲉⲡlegacy ⲛϣⲟⲣⲡ ⲉⲧⲣⲉϥⲧⲁⲙⲓⲟ ⲛⲟⲩlive ghost. Ⲙⲛⲛⲥⲱⲥ `CountWeavingsByDP` ⲙⲛ `DPUnrankLegalWeaving` ⲕⲱ ⲙⲡwhole-weave legality ⲙⲛ exact BigInt rank.

### ⲠDP state ⲙⲛ lexicographic rank

ⲠDP state ϩⲁⲣⲉϩ ⲉ`remaining[]`, `openedUpTo` ⲙⲛ `closedUpTo`. Ⲡmove legality ⲧⲱⲛ ⲙⲛ ⲡAppendix invariant: ⲟⲩnew month ⲙⲟⲛⲟⲛ `openedUpTo+1`, ⲁⲩⲱ ⲟⲩclosing month ⲙⲟⲛⲟⲛ `closedUpTo+1`. Ⲡcount ⲟ ⲛBigInt ⲛⲙⲉ, ⲁⲩⲱ ⲡunrank ⲙⲟⲟϣⲉ ⲛⲥⲁ legal month ids ϩⲙ ascending order ⲉⲧⲣⲉϥⲧⲁϫⲣⲟ ⲙⲡcanonical lexicographic family.

### Ⲡscar selector

`ghost=legacy daily row`

`correct=whole-weave DP unrank`

Ⲉϣϫⲉ `ghost==correct`, ⲡghost ϣϭⲙϭⲟⲙ ⲉϥⲃⲱⲕ ⲉⲡsemantic output. Ⲉϣϫⲉ `ghost!=correct`, ⲡghost ⲟ ⲛinvocation-local diagnostic row ⲙⲙⲁⲧⲉ.

ⲠStage 48 source ⲙⲡⲟⲩϣⲓⲃⲉ ⲁⲩⲱ ⲁϥⲕⲧⲟϥ ⲉ`STAGE48_REGRESSION_GREEN`. ⲠStage 49 ϯ `STAGE49_PATCH24_GREEN`.

Ⲡ15-case Assembly sweep ⲧⲁϫⲣⲟ ⲙⲡgeneral count/unrank. Ⲡ12-month test ⲣ ⲙⲡ`rank=count` ⲙⲛ multi-limb BigInt. Ⲡ47-month test ⲣ ⲙⲡmax supported month-count path.

Ⲙⲛ contiguous day-in-month guess ⲏ Patch 25 / Stage 50 code ⲉϥⲟⲩⲱϩ ϩⲙⲡStage 49.


## Ⲃⲁⲑⲙⲟⲥ 50 — DISCOVERY 25

Ⲁⲩⲕⲱ ⲙⲡ`oldContiguousMonthDayGuess` ⲉϥⲱϣ ⲙⲡtarget offset ⲛⲧⲟϥ ⲛday-in-month. Ⲡwitness ⲙⲛ separated occurrences ⲧⲁϫⲣⲟ ϫⲉ 5 ϣⲟⲃⲉ ⲙⲛ ⲡcorrect occurrence count 3. Ⲡroute ⲟⲩⲏϩ legacy, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡrepository ⲟ ⲛEXPECTED_RED.


## Ⲃⲁⲑⲙⲟⲥ 51 — PATCH 25

Ⲡcontiguous ghost ⲣϩⲱⲃ ⲛϣⲟⲣⲡ. Ⲡauthoritative dayInMonth ⲧⲉⲛⲟⲩ ⲡⲉ ⲡoccurrence count ⲙⲡtarget month thread ⲉⲃⲟⲗ ϩⲙⲡϣⲟⲣⲡ ⲛⲧⲉⲡyear ϣⲁ ⲡtarget ⲛⲉⲙⲁϥ. Ⲉϣϫⲉ ghost==correct ⲡghost ϣϭⲙϭⲟⲙ ⲉϥⲟ ⲛsemantic value; ⲉⲙⲙⲟⲛ ϥⲟ ⲛdiagnostic ⲙⲙⲁⲧⲉ.


## Ⲃⲁⲑⲙⲟⲥ 52 — DISCOVERY 26

Ⲁⲩⲟⲩⲱϩ ⲙⲡlate ownership layer ⲉϥⲭⲣⲁⲱ ⲙⲡ`[open,close]` legacy interval. Ⲡstrict backward comparison ⲕⲱ ⲙⲡopening gate ⲉⲡyear ⲉⲧⲟⲩⲱⲛ, ⲉⲣⲉ ⲡearlier sequential walk scar ⲟⲩⲏϩ ⲉϥcallable ⲛⲕⲉⲥⲟⲡ. ⲠStage 52 ⲟ ⲛEXPECTED_RED ⲙⲙⲁⲧⲉ.


## Ⲡⲥⲱⲧⲙ ⲙⲡPATCH 22 — ⲛⲣⲁⲛ ⲛⲛⲉⲃⲟⲧ

Ⲡauthoritative specification ⲕⲱ ⲙⲡrepeated-name scar ⲉϫⲛ ⲛcutlet names ⲙⲛ ⲛmonth names ⲛⲥⲉⲛⲁϣⲱⲡⲉ distinct ϩⲙⲡsame year. Ⲡmonth-name branch ⲉⲧⲁϥϣⲱϣ ⲙⲡStage 45 ⲁⲩⲕⲧⲟϥ ⲉⲡPATCH 22: `legacyMonthNamesWithRepeats` ⲣϩⲱⲃ ⲛlive ghost, ⲁⲩⲱ `monthNamesPatch22` / `monthNamesPatch22Big` ϯ ⲙⲡexact lexicographic partial-permutation row ⲛ47 canonical names. Ⲡwide path ⲟ ⲛBigInt ⲁⲩⲱ ϥϣϭⲙϭⲟⲙ ⲉϥϫⲓ ⲙⲡrank ϣⲁ `47!`.

`PATCH22_MONTH_NAMES_CORRECTION_GREEN`


## Ⲃⲁⲑⲙⲟⲥ 53 — PATCH 26

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲉϫⲱϥ

Ⲙⲡⲟⲩⲃⲟⲗ ⲉⲃⲟⲗ ⲙⲡclosed-interval scar. `oldYearOwnsClosedInterval` ⲙⲛ `legacyFindYearByClosedIntervalWalk` ⲟⲩⲏϩ ϩⲙⲡsource ⲛⲥⲉϣⲓⲃⲉ ⲁⲛ, ⲁⲩⲱ ⲡlegacy walk ⲣϩⲱⲃ ⲛϣⲟⲣⲡ ϩⲙ invocation ⲛⲓⲙ ⲛlive ghost.

### Ⲡhalf-open detour

`findYearByHalfOpenIntervalWalkPatch26` ⲕⲱ ⲙⲡsame sequential `nextYear`/`previousYear` walk, ⲁⲗⲗⲁ ⲡbackward equality ⲧⲉⲛⲟⲩ ⲡⲉ `target<=open`. Ⲡfound year ⲧⲁϫⲣⲟ ⲙⲡ`open<target<=close`.

`yearOwnershipPatch26` ⲥⲱⲧⲡ ⲙⲡcorrect year ⲉϣϫⲉ ⲡghost ϣⲟⲃⲉ; ⲉϣϫⲉ ⲡyear number ⲟⲩⲱⲧ, ⲡghost pointer ⲛⲧⲟϥ ⲕⲧⲟ ⲉⲡout. Ⲡopening-gate witness ⲧⲁϫⲣⲟ `5000 -> 4999`; ⲡclosing-gate witness ⲧⲁϫⲣⲟ ⲙⲡghost reuse ϩⲓ 5000.

`STAGE52_REGRESSION_GREEN`

`STAGE53_PATCH26_GREEN`


## Ⲃⲁⲑⲙⲟⲥ 54 — FINAL SPAGHETTI-MONSTER INTEGRATION

### Ⲛⲉⲩⲙⲉⲉⲩⲉ

Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲟⲩ`arena_mark` ⲙⲛ `arena_reset` ⲛⲁⲣ ⲙⲡlegacy manager ⲉϥⲟ ⲛⲟⲩghost transaction ⲉϥⲧⲁϫⲣⲏⲩ, ϫⲉ ⲡsemantic pointers ⲛⲥⲉⲟⲩⲏϩ ⲁⲛ ϩⲙⲡghost region.

### Ⲡⲉⲛⲧⲁⲩⲛⲁⲩ ⲉⲣⲟϥ

Ⲁⲩⲛⲁⲩ ϫⲉ `arena_reset` ⲕⲧⲟ ⲙⲡallocation pointer ⲁⲗⲗⲁ ⲛϥⲥⲱϥ ⲁⲛ ⲛⲛbytes. Ⲡlegacy diagnostics ⲁⲩⲥϩⲁⲓ ϩⲙⲡregion ⲁⲩⲱ ⲡauthoritative year-candidate table ⲁϥⲱϣ ⲙⲡold bytes ϩⲙⲡⲙⲁ ⲛzero. Ⲡwitness ⲛϣⲟⲣⲡ ⲁϥϣⲓⲃⲉ ⲙⲡcutlet canonical index `10 -> 11` ⲙⲛⲛⲥⲁ ⲡghost chain.

### Ⲡⲉⲛⲧⲁⲩⲕⲱ ⲛⲥⲱϥ

Ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲡlegacy chain ⲏ ⲛscar. Ⲁⲩⲟⲩⲱϩ ⲙⲡ`stage54ScrubGhostArena` ⲉϥⲥϩⲁⲓ ⲛ0 ⲉ`[start,end)` ϩⲁⲑⲏ ⲙⲡrollback. Ⲁⲩⲕⲱ ⲟⲛ ⲙⲡexplicit zero initialization ⲙⲡyear-candidate table. Ⲡⲁⲓ ⲕⲱ ⲙⲡghost ⲉϥⲣϩⲱⲃ ⲛⲁⲙⲉ, ⲁⲗⲗⲁ ⲛϥⲕⲱ ⲁⲛ ⲛⲟⲩsemantic residue.

### Ⲉⲧⲃⲉ ⲟⲩ ⲡⲁⲓ ⲧⲱⲛ

Ⲡscrub ⲙⲛ zero-init ⲛⲥⲉϣⲓⲃⲉ ⲁⲛ ⲙⲡnormative calculation; ⲥⲉϥⲓ ⲙⲙⲁⲧⲉ ⲙⲡallocation-history input ⲉⲧⲉ ⲛϥϣⲟⲟⲡ ⲁⲛ ϩⲙⲡscroll. Ⲡ`pending -> validate -> committed` chain ⲕⲱ ⲙⲡsemantic owner ⲉϥⲟⲩⲱⲛϩ.

### Ⲡlayer ⲛⲧⲁⲩⲟⲩⲟϩⲥ

Ⲁⲩⲟⲩⲱϩ ⲛ`stage54_integration.s`, `sauceWithScars`, gate/year managers, structure manager, validation manager, result manager, retry states, metrics/log counters, compatibility bridge ⲛⲛtests ⲉⲧϩⲁⲑⲏ, ghost scrub ⲙⲛ exact five-field commit.

`STAGE54_INTEGRATION_GREEN`


## Ⲃⲁⲑⲙⲟⲥ 55 — AUDIT candidate / ⲡverification ⲁϥⲟⲩⲱ

Ⲁⲡfinal audit ϭⲓⲛⲉ ⲛϩⲟⲩⲟ ⲛscar ⲛreliability ϩⲙⲡStage 54 integration. Ⲙⲡⲟⲩⲣ cleanup ⲙⲡlegacy architecture; ⲛrepair ⲁⲩⲕⲱ ⲙⲙⲟⲟⲩ ⲉϫⲛ ⲛscar ⲛⲧⲟⲟⲩ.

`patchedSmallPickSlowPatch13` ⲟⲩⲏϩ callable. `patchedSmallPickReliability55` ⲕⲱ ⲛⲟⲩexact direct rejection offset/accepted-value path. Ⲡoptimization ⲕⲱ ⲙⲡsame answer ring, ⲡsame acceptance predicate ⲙⲛ ⲡsame `biasedLegacyPick`; ⲙⲛ probabilistic shortcut.

Ⲡyear walk ⲁϥⲣbounded ⲙⲡscratch lifetime ϩⲓ gate extension ⲙⲛ candidate selection. Ⲡpersistent gate/year data ⲟⲩⲏϩ, ⲁⲩⲱ scratch bytes ⲥⲉscrub ⲙⲛ reset ⲙⲛⲛⲥⲁ commit.

Ⲡrecovery state machine ⲧⲉⲛⲟⲩ ⲕⲧⲟ ⲉⲡsame failed phase ⲙⲛ ⲡlast committed state. Ⲡresult/final-validation retry ⲛϥⲕⲧⲟ ⲁⲛ ⲉyear/structure. Ⲡretry exhaustion ϯ ⲛexplicit error.

Ⲛ`stage54_bucket_select` ⲙⲛ `stage54_year5000` internal failures ⲧⲉⲛⲟⲩ ⲕⲧⲟ `NULL` ⲉⲡstate machine; ⲙⲛ internal process abort ϩⲙⲡproduction.

Ⲛaudit tests ⲥⲉⲕⲱ ⲛend-to-end cold cases, far-year cases, observability, recovery 0/1/2/exhaustion, error-cleanup, history A-B-A, SAVE edges, short/wide selection edges ⲙⲛ locale/catalog invariance. Ⲡstrict verification ⲙⲡⲁⲧϥⲟⲩⲱ, ⲉⲧⲃⲉ ⲡⲁⲓ `LAST_COMPLETED_STAGE=54` ⲙⲛ `SPAGHETTI_MONSTER_IMPLEMENTATION_COMPLETE=NO` ⲟⲩⲏϩ.


## Ⲃⲁⲑⲙⲟⲥ 56 — corrective raw bowl sum / ⲡverification ⲁϥⲟⲩⲱ

### Ⲡscar ⲉⲧⲟⲩⲏϩ

`postStirOneOverwritingOrderMemoryStage22` ⲛϥⲃⲟⲗ ⲁⲛ ⲉⲃⲟⲗ. Ⲡlegacy `u` ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡ`savedOrderNumber`. Ⲁⲩⲟⲩⲱϩ ⲙⲙⲁⲧⲉ ⲛⲟⲩdiagnostic witness ⲉⲡsaved order ⲙⲛ ⲟⲩcall counter; ⲙⲛ semantic operand ⲉⲁϥϣⲓⲃⲉ ϩⲙⲡscar.

### Ⲡdetour ⲉⲧⲟⲩⲟⲛϩ

`stage56SauceRawBowlSumCorrective` ⲥⲱⲟⲩϩ ⲙⲡsame 46-drop chain ϩⲓⲧⲛ ⲛroute ⲉⲧϣⲟⲟⲡ. Ⲙⲛⲛⲥⲁ drop 46, stir 1..12 ⲛⲓⲙ ⲣ ⲙⲡold scar ⲛϣⲟⲣⲡ ⲉϫⲛ ⲟⲩghost copy ⲙⲡauthoritative old bowls. Ⲙⲛⲛⲥⲱϥ `stage56PostStirRawBowlSumDetour` ⲕⲧⲟ ⲛⲟⲩⲱⲧ ⲙⲡnew bowls ⲉⲃⲟⲗ ϩⲙ `rawBowlSum`.

Ⲡsix-bowl update ⲟ ⲛsimultaneous: ⲛold/previous/next ⲧⲏⲣⲟⲩ ⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙⲡsnapshot ⲛⲟⲩⲱⲧ, ⲁⲩⲱ ⲡcommit ⲣ ϩⲙⲡⲁϩⲟⲩ.

### Ⲡorder guard

Ⲡactual saved order number ⲙⲡlegacy scar ⲥⲏϩ ϩⲙ `stage56_LEGACY_SAVED_ORDER_WITNESS`. Ⲡdetour ⲕⲱ ⲛⲕⲉ`SAVE(rawBowlSum+149*stir)` ⲁⲩⲱ ϥⲥⲙⲓⲛⲉ ⲙⲙⲟⲟⲩ ϩⲓⲧⲛ `bi_cmp`. Ⲙⲛⲛⲥⲱⲥ ⲛ6 ⲛpermutation IDs ⲥⲉⲥⲙⲓⲛⲉ ⲟⲩⲁ ⲟⲩⲁ. Ⲉϣϫⲉ ⲟⲩguard ϩⲉ, ⲡcorrective sauce ⲕⲧⲟ `NULL`; ⲙⲛ alternate semantic answer.

### Ⲡhistorical isolation

Ⲡfinal `calendarDateSpaghetti` ⲣϩⲱⲃ ⲙⲡStage 56 sauce. ⲚStage 54/55 regression binaries ⲉⲧϩⲁⲑⲏ ⲥⲉlink ⲛ`stage56_historical_sauce_bridge.s` ⲙⲛ `--wrap=stage56SauceRawBowlSumCorrective`, ⲉⲧⲣⲉⲡhistorical outputs ⲟⲩⲏϩ ϩⲓ ⲡscar ⲛϣⲟⲣⲡ.

Ⲡstrict Stage 56 tests ⲙⲡⲁⲧⲟⲩⲱ; ⲡpackage ⲡⲁⲓ ⲟ ⲛimplementation candidate ⲉϥϣϭⲙϭⲟⲙ ⲉⲩⲧⲁⲗⲟϥ ϩⲁⲑⲏ ⲙⲡverification.


## Ⲡledger ⲛϩⲁⲏ — Stage 55 + corrective Stage 56 GREEN

Ⲡstrict verification ⲁϥⲟⲩⲱ ϩⲓ x86-64 GNU/Linux ⲙⲛ GNU `as`/`ld`. Ⲡbuild, ⲛhistorical scars, ⲡsmoke suite, ⲛStage 55 helpers, ⲡfull Stage 55 matrix, ⲡStage 56 semantic/runtime audit ⲙⲛ ⲡstatic/scar audit ⲧⲏⲣⲟⲩ ⲁⲩϯ `RC=0`.

Ⲛ14 ⲛStage 55 end-to-end cases ⲁⲩϯ `STAGE55_E2E_GREEN`. Ⲛ3 ⲛfar-year cases ⲁⲩϯ `STAGE55_FAR_E2E_GREEN`. Recovery `0/1/2/exhaustion`, error-cleanup, observability, history `A-B-A`, SAVE edges, short/wide edges ⲙⲛ locale/catalog invariance ⲁⲩⲟⲩⲱ ⲛ`GREEN`.

ⲠStage 56 semantic audit ⲧⲁϫⲣⲟ ⲙⲡdiscriminator, ⲛ12 ⲛpost-stirs, ⲡlegacy saved-order witness, ⲡpermutation guard, ⲛ6 ⲛcorrected bowls, ⲡcontext `A-B-A`, ⲛcorrective vectors ⲙⲛ ⲛsauce witnesses. `STAGE56_SEMANTIC_AUDIT_GREEN`.

### Ⲡfirst-day ghost scar

Ⲁⲩϭⲓⲛⲉ ⲛⲟⲩstale shortcut ϩⲙ `stage54StructureSauce`: ⲡequal-target branch ⲛⲉϥϫⲱⲣⲙ ⲉ`.Ls54ss_done` ⲁⲩⲱ ϥϣϭⲙϭⲟⲙ ⲉϥreuse ⲙⲡStage 41 ghost. Ⲙⲡⲟⲩⲃⲟⲗ ⲉⲃⲟⲗ ⲙⲡghost. Ⲁⲩⲕⲱ ⲙⲡlive branch ⲉ`.Ls54ss_correct`, ⲉⲧⲣⲉⲡauthoritative structure sauce ⲙⲟⲟϣⲉ ϩⲓⲧⲛ Stage 56 detour.

### Ⲛruntime abort scars

Ⲁⲡaudit ϭⲓⲛⲉ ⲛ5 ⲛinternal `sys_exit` scars: `.Larena_fail`, `.Larena_reset_fail`, `.Lbires_fail`, `.Lbd64_fail`, `.Lbda_fail`. Ⲙⲡⲟⲩⲃⲟⲗⲟⲩ ⲉⲃⲟⲗ. Ⲛlabels ⲙⲛ ⲛold exit instructions ⲟⲩⲏϩ ϩⲙⲡsource ⲛarchaeological scars, ⲁⲗⲗⲁ ⲛlive branches ⲧⲉⲛⲟⲩ ⲡⲉ `.Larena_soft_fail`, `.Larena_reset_soft_fail`, `.Lbires_soft_fail`, `.Lbd64_soft_fail`, `.Lbda_soft_fail`.

ⲠAssembly-only `stage56_runtime_soft_failure_audit.s` ⲁϥforcing ⲙⲡ5 ⲛfailure paths ⲁⲩⲱ ⲁϥⲧⲁϫⲣⲟ ϫⲉ ⲡprocess ⲛϥⲙⲟⲩ ⲁⲛ. `STAGE56_RUNTIME_SOFT_FAILURE_GREEN`.

### Ⲡfinal state

`TOTAL_STAGES=55`

`LATEST_CORRECTIVE_STAGE=56`

`LAST_COMPLETED_STAGE=56`

`STAGE55_VERIFICATION_PENDING=NO`

`STAGE56_VERIFICATION_PENDING=NO`

`KNOWN_PRODUCTION_BUGS=NONE`

`SPAGHETTI_MONSTER_IMPLEMENTATION_COMPLETE=YES`

Ⲡfinal GitHub Actions audit ⲟ ⲛread-only (`contents: read`). Ⲛdiagnostic/write workflows ⲛⲧⲁⲩⲣϩⲱⲃ ϩⲙⲡverification ⲛⲁⲩⲕⲱ ⲉⲃⲟⲗ ϩⲙⲡfinal repository state.
