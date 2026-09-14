# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 10 — Discovery 05

Idinadagdag ng Stage 10 ang ikalimang historical defect: backward hidden-drop storage na maling ina-access bilang normal near-ness order.

Ang pitong hidden value ay tunay na kinakalkula mula sa:

- patched action/target/distance counts;
- connection at direction;
- GREEN Patch 04 stone table;
- historical reversed coefficient storage;
- `savePatch`;
- pitong hidden grinds.

Pagkatapos, pisikal silang iniimbak nang pabaliktad:

```text
slot 1 = hidden7
slot 2 = hidden6
slot 3 = hidden5
slot 4 = hidden4
slot 5 = hidden3
slot 6 = hidden2
slot 7 = hidden1
```

Ang historical access defect ay:

```text
legacyHiddenDirectByAssumedNearness(storage, k)
    -> storage[k]
```

Kaya sa normatibong near-ness probes na `k=1,2,4,6,7`, inaasahan ang:

- `k=1` — EXPECTED_RED
- `k=2` — EXPECTED_RED
- `k=4` — MATCH
- `k=6` — EXPECTED_RED
- `k=7` — EXPECTED_RED

Ang `k=4` lamang ang nananatiling tama dahil ito ang midpoint ng pitong-slot reversal.

Ang production route ay talagang gumagawa ng backward storage at pagkatapos ay gumagawa ng maling direct read para sa `k=1`.

Wala pang Patch 05. Hindi idinadagdag ang `hiddenByNearness(storage,k) -> storage[8-k]`, at hindi binabaligtad ang physical storage.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage10.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage10.ps1
```

Ang Stage 10 ay dapat magtapos sa `STAGE10_RESULT=PASS` habang ang repository state ay `EXPECTED_RED`.
