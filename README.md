# Magulang na Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 1 — Bootstrap

Natapos at napatunayan sa aktuwal na Windows PowerShell 5.1 ang neutral na base, normative oracle, frozen source-language catalog, at per-invocation state shell.

## Stage 2 — Discovery 01

Napatunayan ang historical `oldRemainder(x)=regularMod(x,M)` defect bilang eksaktong `EXPECTED_RED`.

## Stage 3 — Patch 01

Idinagdag ang `savePatch`, na nagmamapa lamang ng legacy zero residue sa `M`. Napatunayang GREEN ang public Patch 01 route habang nananatili ang historical `oldRemainder`.

## Stage 4 — Discovery 02

Idinadagdag ngayon ang ikalawang historical scar:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION)
```

Kung ang araw ay bago ang Foundation, tumutugma ito sa normative day count. Sa Foundation at pagkatapos nito, kulang ito ng isa:

```text
FOUNDATION-2 -> legacy 4, normative 4
FOUNDATION-1 -> legacy 2, normative 2
FOUNDATION   -> legacy 0, normative 1
FOUNDATION+1 -> legacy 2, normative 3
FOUNDATION+2 -> legacy 4, normative 5
```

Ang production route ay nagpapanatili muna sa Patch 01 GREEN behavior at saka dumadaan sa Discovery 02 legacy day-tag adapter para sa calculation day at target day.

Wala pang `dayTagWithFoundationScar` o alinmang Patch 02 correction sa Stage 4.

## Pagpapatakbo

Stage 1 regression:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
```

Discovery 02:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage04.Tests.ps1
```

Buong Stage 4 verification at finalization:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage04.ps1
```

Sa matagumpay na Discovery 02 verification, kailangang lumitaw ang `STAGE04_RESULT=PASS` at `STAGE04_REPOSITORY_STATE=EXPECTED_RED`.

## Wika

Ang Filipino ang nag-iisang wikang pantao ng implementasyong ito. Ang mga identifier, API name, file name, at machine-readable key ay maaaring manatili sa teknikal na anyo.
