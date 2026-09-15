# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 17 — Patch 08

Nananatiling pisikal at sadyang mali ang Discovery 08 historical caller:

```text
oneBased = regularMod(drop - 1, 720) + 1
legacy rank0 input = oneBased
oldPermutationUnrank0(legacy rank0 input)
```

Ang Patch 08 wrapper ay talagang nagpapatakbo muna sa wrong caller at kino-capture ang raw wrong order o ang `rank0=720` undefined scar. Pagkatapos lamang nito isinasagawa ang authoritative chain:

```text
oneBased = regularMod(drop - 1, 720) + 1
legacyRank0 = oneBased - 1
corrected = oldPermutationUnrank0(legacyRank0)
```

Lahat ng 720 semantic ordinals ay GREEN sa corrected helper.

May order-table helper din para sa 46 supplied visible-drop values; hindi ito visible-drop builder at hindi pa nagsisimula ng pour logic.

Sa production probe:

```text
drop = 1
raw Discovery 08 = 1,2,3,4,6,5
corrected Patch 08 = 1,2,3,4,5,6
```

Inaasahang repository state: `GREEN`.

Wala pang Stage 18 fixed-bowl pour defect, `bowlAlias`, `patchedPours`, o Patch 09.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage17.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage17.ps1
```
