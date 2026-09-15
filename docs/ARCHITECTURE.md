# Arkitektura hanggang Stage 15

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8/10/12/14 ay historical discovery layers. Ang Stage 3/5/7/9/11/13/15 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

- `src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.
- `src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.
- `src/Discovery03.ps1` / `src/Patch03.ps1` — distance.
- `src/Discovery04.ps1` / `src/Patch04.ps1` — stone table.
- `src/Discovery05.ps1` / `src/Patch05.ps1` — backward hidden storage at near-ness correction.
- `src/Discovery06.ps1` / `src/Patch06.ps1` — visible-only prior scar at hidden-history repair.
- `src/Discovery07.ps1` — raw zero-based visible-grind table at direct ordinal-index scar.
- `src/Patch07.ps1` — sentinel-index correction.
- `src/MonsterSkeleton.ps1` — production route at invocation-owned semantic state.

## Raw Stage 14 scar

```text
raw table indices = 0..10
semantic ordinals = 1..11

legacyGrindRow(g)
    -> rawTable[g]
```

Hindi binabago ng Stage 15 ang file na ito.

## Patch 07 sentinel layout

```text
index 0  = [0,0,0,0,NONE]
index 1  = raw row 1
...
index 11 = raw row 11
```

Ang corrected helper ay:

```text
grindRowWithSentinel(g)
    -> GRIND_TABLE_WITH_SENTINEL[g]
```

## Stage 15 production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> Patch 04
-> Discovery 05
-> Patch 05
-> Patch 06
-> Invoke-Patch07GrindRowRepair(grind=1)
   -> LegacyGrindTableAdapter
      -> Discovery07GrindIndexHandler
      -> legacyGrindRow(1)
      -> raw row 2
   -> grindRowWithSentinel(1)
      -> corrected row 1
```

Ang corrected row lamang ang authoritative probe value.

## Patch 07 state

Invocation-owned:

- `patch07RequestedGrind`
- `patch07SentinelIndex`
- `patch07RawLegacyRow`
- `patch07CorrectedRow`
- `patch07Applied`
- `patch07Status`
- `patch07InvocationCount`

Patuloy ding naka-record ang Stage 14 raw state.

## GREEN contract

- sentinel table physical row count = 12;
- raw Stage 14 RED count = 11;
- direct corrected translator GREEN count = 11;
- wrapper GREEN count = 11;
- production raw scar = row 2;
- production corrected value = row 1.

## Wala pang Stage 16

Walang `LegacyVisibleDropBuilder`, `visibleDropThroughCurrentLayers`, `oldPermutationUnrank0`, o `orderPatchFromValue`.
