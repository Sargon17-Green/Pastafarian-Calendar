# Magulang na Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Mga naunang stage

Napatunayan ang Stage 1 bootstrap, Discovery 01 at Patch 01 para sa save remainder, at Discovery 02 at Patch 02 para sa Foundation day tags. Nananatiling pisikal ang lahat ng raw historical scars.

## Stage 6 — Discovery 03

Idinadagdag ang ikatlong historical defect:

```text
oldDistance(calculationDay, targetDay) =
    abs(
        dayTagWithFoundationScar(calculationDay)
        - dayTagWithFoundationScar(targetDay)
    )
```

Ang maling palagay ay ang absolute difference ng patched day tags ay kapareho ng chronological inclusive distance.

Ang normative distance ay:

```text
abs(targetDay - calculationDay) + 1
```

Sa limang historical probes:

```text
F -> F       : legacy 0, normative 1   : EXPECTED_RED
F -> F+1     : legacy 2, normative 2   : MATCH
F -> F+3     : legacy 6, normative 4   : EXPECTED_RED
F-1 -> F     : legacy 1, normative 2   : EXPECTED_RED
F-3 -> F+3   : legacy 1, normative 7   : EXPECTED_RED
```

Ang production route ay talagang tumatawag sa `oldDistance` sa pamamagitan ng Discovery 03 adapter. Ang Patch 01 at Patch 02 state ay nananatiling GREEN at per-invocation.

Walang `patchedCounts`, chronological replacement guard, o final `+1` Patch 03 logic sa Stage 6.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage06.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage06.ps1
```

Sa matagumpay na Discovery 03 verification, kailangang lumitaw ang `STAGE06_RESULT=PASS` at `STAGE06_REPOSITORY_STATE=EXPECTED_RED`.
