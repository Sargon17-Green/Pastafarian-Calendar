# Kasaysayan ng Paglago ng Spaghetti Monster

## Stage 1 — Bootstrap

Nilikha mula sa wala ang PowerShell project tree, malinis na normative oracle, frozen source-language catalog, test harness, at neutral na per-invocation monster shell.

## Stage 2 — Discovery 01: legacy remainder

Ipinakilala at napatunayan ang:

```text
oldRemainder(x) = regularMod(x, M)
```

Ang mga multiple ng `M` ay nagbubunga ng `0` sa legacy path sa halip na normative `M`.

## Stage 3 — Patch 01: save correction

Idinagdag ang `savePatch`, na tanging nagmamapa sa legacy zero residue tungo sa `M`. Hindi binura ang `oldRemainder`; nanatili itong physical historical scar.

## Stage 4 — Discovery 02: maling day tag

### Natuklasang sugat

Idinagdag ang eksaktong historical function:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION)
```

kung saan:

```text
FOUNDATION = -15055671
```

### Eksaktong regression surface

Ang Discovery 02 verification ay nangangailangan ng:

- `FOUNDATION-2`: legacy `4`, normative `4`, tugma.
- `FOUNDATION-1`: legacy `2`, normative `2`, tugma.
- `FOUNDATION`: legacy `0`, normative `1`, `EXPECTED_RED`.
- `FOUNDATION+1`: legacy `2`, normative `3`, `EXPECTED_RED`.
- `FOUNDATION+2`: legacy `4`, normative `5`, `EXPECTED_RED`.

May eksaktong tatlong divergence sa limang pangunahing probe.

### Production route at state

Ang kasalukuyang route ay nagpapatakbo muna ng Patch 01 save adapter upang mapanatili ang naunang GREEN behavior. Pagkatapos, ang Discovery 02 legacy day-tag adapter ay kumukuwenta ng hiwalay na legacy action at target day tags at kino-commit ang mga ito sa sariling invocation context.

### Sadyang hindi pa inaayos

Walang `dayTagWithFoundationScar`, walang `+1` correction pagkatapos ng Foundation, at walang Stage 5/Patch 02 code sa Stage 4.
