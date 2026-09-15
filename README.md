# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 13 — Patch 06

Nananatiling pisikal at sadyang mali ang Stage 12 helper:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Ang correction ay nasa hiwalay na layer:

```text
slot = i - back

if slot >= 1:
    return legacyPrior(dropStore, i, back)

hiddenK = 1 - slot
return hiddenByNearness(legacyHidden, hiddenK)
```

Ibig sabihin:

- positive visible slot: talagang ginagamit pa rin ang raw `legacyPrior`;
- walang hidden storage na kailangan sa positive branch;
- nonpositive slot: ginagamit ang `hiddenK=1-slot`;
- ang hidden branch ay dumadaan sa Stage 11 `hiddenByNearness`.

Ang tatlong Stage 12 cases ay GREEN na ngayon:

```text
slot 0  -> hidden1
slot -2 -> hidden3
slot -6 -> hidden7
```

Ang production route ay nagpapanatili ng parehong neutral probe:

```text
i=2
back=1
slot=1
```

Dahil visible branch ito, ang production probe ay patuloy na nagpapatunay na aktuwal na tinatawag ang raw `legacyPrior`.

Inaasahang repository state: `GREEN`.

Wala pang Stage 14 `legacyGrindRow`, zero-based visible-grind table, sentinel row, o visible-drop builder.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage13.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage13.ps1
```
