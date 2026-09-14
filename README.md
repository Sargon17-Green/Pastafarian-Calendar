# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 11 — Patch 05

Hindi binabago ng Stage 11 ang historical physical hidden storage. Nananatili itong:

```text
slot 1 = hidden7
slot 2 = hidden6
slot 3 = hidden5
slot 4 = hidden4
slot 5 = hidden3
slot 6 = hidden2
slot 7 = hidden1
```

Nananatili rin ang raw historical defect:

```text
legacyHiddenDirectByAssumedNearness(storage, k)
    -> storage[k]
```

Ang bagong correction layer lamang ang nagdadagdag ng tamang near-ness translation:

```text
hiddenByNearness(storage, k)
    -> storage[8-k]
```

Bago ibalik ang corrected value, ang Patch 05 wrapper ay talagang nagpapatakbo muna ng maling direct accessor at nagtatago ng raw legacy value bilang scar.

Ang invocation context ay hiwalay na nagtatago ng requested `k`, translated physical slot, raw direct value, corrected value, applied state, at invocation count.

Ang production route para sa `k=1` ay kaya talagang nakikita muna ang physical slot 1 (`hidden7`) at pagkatapos ay nagbabalik ng authoritative physical slot 7 (`hidden1`).

Inaasahang repository state: `GREEN`.

Wala pang Stage 12 `legacyPrior` / visible-history defect.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage11.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage11.ps1
```
