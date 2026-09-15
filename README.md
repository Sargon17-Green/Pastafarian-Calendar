# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 15 — Patch 07

Hindi binabago ang Stage 14 raw table o raw helper:

```text
LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED
legacyGrindRow(grind)
    -> rawTable[grind]
```

Nananatili itong sadyang mali para sa semantic ordinals `1..11`.

Ang correction ay hiwalay:

```text
SENTINEL_GRIND_ROW = [0,0,0,0,NONE]

GRIND_TABLE_WITH_SENTINEL = [
    SENTINEL_GRIND_ROW,
    raw row 1,
    raw row 2,
    ...
    raw row 11
]

grindRowWithSentinel(grind)
    -> GRIND_TABLE_WITH_SENTINEL[grind]
```

Sa ganitong layout, eksaktong tumutugma ang semantic ordinals `1..11` sa historical rows `1..11`.

Ang `Invoke-Patch07GrindRowRepair` ay talagang nagpapatakbo muna ng Stage 14 `LegacyGrindTableAdapter` at kino-capture ang raw scar bago ibalik ang corrected row.

Sa production probe:

```text
grind = 1
raw legacy result = row 2
corrected result  = row 1
```

Inaasahang repository state: `GREEN`.

Wala pang `LegacyVisibleDropBuilder`, `visibleDropThroughCurrentLayers`, `oldPermutationUnrank0`, o anumang Stage 16+ logic.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage15.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage15.ps1
```
