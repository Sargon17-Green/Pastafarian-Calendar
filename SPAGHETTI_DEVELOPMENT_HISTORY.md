# Kasaysayan ng Paglago ng Spaghetti Monster

## Stage 1 — Bootstrap

Neutral na PowerShell base, test-only normative oracle, frozen source-language catalog, at per-invocation semantic state.

## Stage 2 — Discovery 01

Raw `oldRemainder` defect.

## Stage 3 — Patch 01

`savePatch` correction sa ibabaw ng raw remainder scar.

## Stage 4 — Discovery 02

Raw `oldDayTag` defect.

## Stage 5 — Patch 02

`dayTagWithFoundationScar` correction, kasama ang historical redundant Foundation guard.

## Stage 6 — Discovery 03

Raw `oldDistance(c,t)=abs(dayTagWithFoundationScar(c)-dayTagWithFoundationScar(t))` defect.

## Stage 7 — Patch 03: chronological inclusive distance

### Historical repair

Ang Patch 03 ay hindi nag-eedit sa `oldDistance`. Sa halip:

```text
raw = oldDistance(c,t)
chronological = abs(t-c)
if raw != chronological:
    raw = chronological
return raw + 1
```

### Dalawang branch

Kapag mali ang raw tag-difference distance, pinapalitan ito ng chronological difference bago idagdag ang inclusive `+1`.

Kapag pareho na ang raw at chronological difference, walang replacement, ngunit idinadagdag pa rin ang `+1`.

### Required edges

Pitong probe ang kailangang maging GREEN:

- `F -> F`
- `F -> F+1`
- `F -> F+3`
- `F-1 -> F`
- `F-3 -> F+3`
- `F+9 -> F+2`
- `F-9 -> F-2`

Sa mga ito, limang probe ang nangangailangan ng legacy replacement at dalawa ang hindi; lahat ay nagtatapos sa normative inclusive distance.

### State ownership

Ang raw legacy distance, chronological distance, final patched distance, replacement flag, at applied flag ay sariling state ng bawat invocation.

### Hindi pa kasama

Walang `mutateStonesWrong` at walang Stage 8 Discovery 04 code.
