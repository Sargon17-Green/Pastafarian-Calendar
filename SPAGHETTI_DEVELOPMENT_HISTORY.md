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
