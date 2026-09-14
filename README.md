# Magulang na Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Mga naunang stage

Natapos ang Bootstrap, ang save remainder discovery/patch pair, ang Foundation day-tag discovery/patch pair, at ang legacy distance discovery.

## Stage 7 — Patch 03

Hindi binabago ang `oldDistance`. Ang bagong helper ay:

```text
legacy = oldDistance(calculationDay, targetDay)
chronological = abs(targetDay - calculationDay)

if legacy != chronological:
    legacy = chronological

distance = legacy + 1
```

Mahalaga ang huling `+1` kahit sa branch na hindi nangangailangan ng replacement. Ito ang nagbabalik ng inclusive normative distance.

Ang production route ay nagpapatakbo ng Patch 01, Patch 02, at saka Patch 03. Itinatago nang hiwalay ang:

- raw legacy distance;
- chronological distance;
- final patched distance;
- kung pinalitan ang raw legacy value;
- kung inilapat ang Patch 03.

Ang `oldDistance` historical scar ay nananatiling pisikal at direktang nasusubok.

Walang `mutateStonesWrong` o anumang Stage 8 Discovery 04 logic sa Stage 7.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage07.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage07.ps1
```

Sa matagumpay na verification, kailangang lumitaw ang `STAGE07_RESULT=PASS` at `STAGE07_REPOSITORY_STATE=GREEN`.
