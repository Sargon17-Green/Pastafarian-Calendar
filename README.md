# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 14 — Discovery 07

Ang historical visible-grind table ay may eksaktong labing-isang totoong row at pisikal na zero-based:

```text
index 0  = grind row 1
index 1  = grind row 2
...
index 10 = grind row 11
```

Ngunit ang raw helper ay tumatanggap ng semantic grind ordinal `1..11` at ginagamit iyon nang diretso bilang physical index:

```text
legacyGrindRow(grind)
    -> LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED[grind]
```

Kaya:

- grind 1 -> row 2;
- grind 2 -> row 3;
- ...
- grind 10 -> row 11;
- grind 11 -> undefined.

Lahat ng labing-isang ordinals ay `EXPECTED_RED` laban sa normative one-based row semantics.

Ang production route ay nagpapatakbo ng isang semantically neutral raw probe sa `grind=1`, sa pamamagitan ng:

```text
LegacyGrindTableAdapter
-> Discovery07GrindIndexHandler
-> legacyGrindRow
```

Hindi pa sinisimulan ang visible-drop builder.

Inaasahang repository state: `EXPECTED_RED`.

Wala pang Stage 15 sentinel row, `GRIND_TABLE_WITH_SENTINEL`, `grindRowWithSentinel`, o `LegacyVisibleDropBuilder`.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage14.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage14.ps1
```
