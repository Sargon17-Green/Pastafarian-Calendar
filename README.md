# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 12 — Discovery 06

Idinadagdag ng Stage 12 ang historical visible-history helper:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Ang helper na ito ay nakakakita lamang sa positive visible slots. Kapag ang `i-back` ay `0` o negatibo, wala itong alam tungkol sa hidden history.

Sa normative timeline:

```text
slot 0  -> hidden1
slot -1 -> hidden2
slot -2 -> hidden3
...
slot -6 -> hidden7
```

Ngunit wala pang fallback na ito sa Discovery 06.

Ang tunay na production route ay nagpapatakbo ng isang valid at semantically neutral probe:

```text
i=2
back=1
slot=1
```

Ginagamit lamang nito ang visible probe store upang patunayan na talagang nasa real production chain ang `legacyPrior`. Hindi pa sinisimulan ang visible-drop computation.

Ang exact discovery regression ay:

- `slot 0` laban sa `hidden1` — EXPECTED_RED
- `slot -2` laban sa `hidden3` — EXPECTED_RED
- `slot -6` laban sa `hidden7` — EXPECTED_RED

Inaasahang repository state: `EXPECTED_RED`.

Wala pang Stage 13 `priorPatch`, walang `hiddenK=1-slot` translation, at walang hidden fallback sa `Discovery06.ps1`.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage12.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage12.ps1
```
