# Magulang na Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 1 — Bootstrap

Napatunayan sa Windows PowerShell 5.1 ang neutral na base, malinis na test-only normative oracle, frozen source-language catalog, at per-invocation semantic state.

## Stage 2 — Discovery 01

Napatunayan ang historical `oldRemainder(x)=regularMod(x,M)` defect.

## Stage 3 — Patch 01

Idinagdag ang `savePatch`, na nagmamapa lamang ng legacy zero residue sa `M`; nananatili ang raw `oldRemainder` scar.

## Stage 4 — Discovery 02

Napatunayan ang historical:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION)
```

Bago ang Foundation ay tumutugma ito sa normative count; sa Foundation at pagkatapos nito ay kulang ito ng isa.

## Stage 5 — Patch 02

Hindi binabago ang `oldDayTag`. Ang patch ay hiwalay na wrapper:

```text
n = oldDayTag(day)
if day >= FOUNDATION:
    n += 1
if day == FOUNDATION and n != 1:
    n = 1
```

Ang ikalawang Foundation guard ay kalabisan para sa kasalukuyang `oldDayTag`, ngunit sadyang nananatili bilang pisikal na historical scar.

Ang production route ay nagpapatakbo muna ng Patch 01 at saka ng Patch 02. Ang raw legacy action/target day tags at ang patched action/target day tags ay parehong itinatago sa sariling invocation context.

Walang `oldDistance` o Stage 6 Discovery 03 logic sa Stage 5.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage05.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage05.ps1
```

Sa matagumpay na verification, kailangang lumitaw ang `STAGE05_RESULT=PASS` at `STAGE05_REPOSITORY_STATE=GREEN`.

## Wika

Ang Filipino ang nag-iisang wikang pantao ng implementasyong ito. Ang mga identifier at machine-readable key ay maaaring manatili sa teknikal na anyo.
