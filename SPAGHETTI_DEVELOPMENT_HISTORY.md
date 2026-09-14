# Kasaysayan ng Paglago ng Spaghetti Monster

## Stage 1 — Bootstrap

Nilikha ang neutral na PowerShell foundation, test-only normative oracle, frozen source-language catalog, at per-invocation semantic state.

## Stage 2 — Discovery 01

Ipinakilala ang raw `oldRemainder` defect.

## Stage 3 — Patch 01

Idinagdag ang `savePatch` nang hindi binubura ang raw remainder scar.

## Stage 4 — Discovery 02

Ipinakilala ang raw `oldDayTag(day)=2*abs(day-FOUNDATION)` defect.

## Stage 5 — Patch 02

Idinagdag ang `dayTagWithFoundationScar`, kasama ang pisikal na redundant Foundation guard, habang nananatili ang raw `oldDayTag`.

## Stage 6 — Discovery 03: day-tag difference bilang distance

### Historical assumption

Ang lumang distance helper ay:

```text
oldDistance(c,t) =
    abs(dayTagWithFoundationScar(c) - dayTagWithFoundationScar(t))
```

Ibig sabihin, ginagamit nito ang naunang patched day-tag layer, ngunit maling ipinapalagay na ang tag difference ay chronological distance.

### Bakit mali

Ang patched day tags ay hindi tumataas nang tig-iisang unit sa chronological axis. Sa Foundation at pagkatapos nito, isang araw na galaw ay karaniwang dalawang tag units. Bukod dito, inclusive ang normative distance at kailangang may final `+1`.

### Historical regression surface

Limang probe ang ginagamit:

- `F -> F`: legacy `0`, normative `1`, `EXPECTED_RED`.
- `F -> F+1`: legacy `2`, normative `2`, `MATCH`.
- `F -> F+3`: legacy `6`, normative `4`, `EXPECTED_RED`.
- `F-1 -> F`: legacy `1`, normative `2`, `EXPECTED_RED`.
- `F-3 -> F+3`: legacy `1`, normative `7`, `EXPECTED_RED`.

Kaya eksaktong apat ang expected-red at isa ang match.

### State ownership

Ang Discovery 03 adapter ay nagko-commit ng calculation day, target day, at raw legacy distance sa sariling invocation context lamang.

### Hindi pa kasama

Walang `patchedCounts`, walang chronological replacement, at walang final `+1` correction ng Stage 7/Patch 03.
