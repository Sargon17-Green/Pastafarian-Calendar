# Arkitektura hanggang Stage 7

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6 ay historical discovery layers. Ang Stage 3/5/7 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only.

`src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.

`src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.

`src/Discovery03.ps1` — raw legacy distance.

`src/Patch03.ps1` — `patchedCounts` at production Patch 03 adapter.

`src/MonsterSkeleton.ps1` — dispatcher host.

## Stage 7 production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> patchedCounts
-> oldDistance
-> compare raw legacy distance with abs(target-calculation)
-> replace only when unequal
-> add final inclusive +1
```

## Semantic state

Patch 03 commits:

- `legacyDistanceCalculationDay`
- `legacyDistanceTargetDay`
- `legacyDistanceValue`
- `patch03ChronologicalDistance`
- `patch03DistanceValue`
- `patch03LegacyReplaced`
- `patch03Applied`

Observability state is not used to compute the result.

## GREEN contract

The patched distance must equal normative `abs(target-calculation)+1` on all required edges while direct `oldDistance` retains the Stage 6 historical values.

Walang Stage 8 Discovery 04 logic.
