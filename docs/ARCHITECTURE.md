# Arkitektura hanggang Stage 14

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8/10/12/14 ay historical discovery layers. Ang Stage 3/5/7/9/11/13 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

- `src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.
- `src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.
- `src/Discovery03.ps1` / `src/Patch03.ps1` — distance.
- `src/Discovery04.ps1` / `src/Patch04.ps1` — stone table.
- `src/Discovery05.ps1` / `src/Patch05.ps1` — backward hidden storage at near-ness correction.
- `src/Discovery06.ps1` / `src/Patch06.ps1` — visible-only prior scar at hidden-history repair.
- `src/Discovery07.ps1` — zero-based visible-grind table at direct one-based ordinal indexing scar.
- `src/MonsterSkeleton.ps1` — production route at invocation-owned semantic state.

## Raw Stage 14 table

```text
physical indices = 0..10
semantic grind ordinals = 1..11
```

Ang raw helper ay:

```text
legacyGrindRow(grind)
    -> LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED[grind]
```

Kaya ang direct physical index ay palaging katumbas ng one-based semantic ordinal, sa halip na `grind-1`.

## Stage 14 production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> Patch 04
-> Discovery 05
-> Patch 05
-> Patch 06 visible production probe
-> LegacyGrindTableAdapter(grind=1)
   -> Discovery07GrindIndexHandler
   -> legacyGrindRow(1)
   -> physical index 1
   -> wrong row 2
```

Ang Discovery 07 probe ay telemetry/scar lamang at hindi pa visible-drop computation.

## Discovery 07 state

Invocation-owned:

- `legacyGrindRequestedOrdinal`
- `legacyGrindDirectIndex`
- `legacyGrindRowValue`
- `legacyGrindUndefined`
- `legacyGrindProbeRow`
- `discovery07Status`
- `discovery07InvocationCount`

## EXPECTED_RED contract

Ang ordinals `1..10` ay nakakakuha ng susunod na physical row.

Ang ordinal `11` ay undefined dahil walang physical index 11.

Samakatuwid:

```text
EXPECTED_RED = 11
MATCH = 0
```

## Wala pang Stage 15

Walang sentinel row, `GRIND_TABLE_WITH_SENTINEL`, `grindRowWithSentinel`, `LegacyVisibleDropBuilder`, o `visibleDropThroughCurrentLayers`.
