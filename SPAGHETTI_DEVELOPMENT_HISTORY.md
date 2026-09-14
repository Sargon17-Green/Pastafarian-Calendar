# Kasaysayan ng Paglago ng Spaghetti Monster

## Stage 1 — Bootstrap

Nilikha mula sa wala ang PowerShell tree, test-only normative oracle, frozen source-language catalog, test harness, at neutral na per-invocation monster shell.

## Stage 2 — Discovery 01: legacy remainder

Ipinakilala ang `oldRemainder(x)=regularMod(x,M)`. Ang mga multiple ng `M` ay naging `0` sa legacy path sa halip na normative `M`.

## Stage 3 — Patch 01: save correction

Idinagdag ang `savePatch` sa ibabaw ng raw legacy remainder. Ang `oldRemainder` mismo ay hindi binago.

## Stage 4 — Discovery 02: maling day tag

Ipinakilala ang:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION)
```

Napatunayang tama lamang ito bago ang Foundation. Sa Foundation at pagkatapos nito, kulang ito ng isa.

## Stage 5 — Patch 02: ibalik ang odd day tags mula Foundation pasulong

### Correction

Hindi binago ang `oldDayTag`. Ang patch ay:

```text
n = oldDayTag(day)
if day >= FOUNDATION:
    n += 1
if day == FOUNDATION and n != 1:
    n = 1
```

Ang ikalawang guard ay hindi kailangan upang makuha ang tamang resulta sa kasalukuyang formula, ngunit ito ay historical scar at hindi inaalis.

### Normative equivalence

Bago ang Foundation, ang raw legacy value ay normative na at hindi binabago.

Sa Foundation, ang raw `0` ay nagiging `1`. Pagkatapos ng Foundation, ang raw `2*d` ay nagiging normative `2*d+1`.

### Historical scar retention

Ang direct tests ng `oldDayTag` ay patuloy na umaasang makuha ang lumang maling values. Ang Patch 02 tests ay hiwalay na nagpapatunay na ang public adapter output ay normative.

### State ownership

Para sa action at target path, hiwalay na itinatago ang raw legacy value, patched value, applied status, at kung nakita ang Foundation guard. Walang state na ibinabahagi sa ibang invocation.

### Hindi pa kasama

Walang `oldDistance`, walang chronological distance guard, at walang Stage 6/7 code.
