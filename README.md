# Magulang na Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`. Nagsimula ang punong ito mula sa wala sa Stage 1 at hindi gumamit ng code, fixture, output, hash, oracle, o artifact mula sa ibang pagpapatupad.

## Stage 1 — Bootstrap

Natapos at napatunayan sa aktuwal na Windows PowerShell 5.1 ang Stage 1. Nananatiling hiwalay ang malinis na normative oracle, nakapirmi ang `SourceLanguageCatalog`, at per-invocation ang semantic state.

## Stage 2 — Discovery 01

Ang Stage 2 ay sadyang naglalagay ng unang makasaysayang legacy defect sa production path:

```text
oldRemainder(x) = regularMod(x, M)
```

Hindi nito ginagawa ang normative `0 -> M` correction. Dahil dito, ang `M`, `2M`, at `3M` ay sadyang nagbubunga ng `0` sa legacy path samantalang `M` ang normative na inaasahan. Ang `M+1` ay nananatiling tugma at nagbubunga ng `1`.

Ang production route ay:

```text
Invoke-CalendarDateSpaghetti
-> base dispatcher
-> Invoke-Discovery01LegacyAdapter
-> oldRemainder
```

Ang adapter ay nagtatala lamang ng state sa sariling invocation context. Walang mutable semantic global state at hindi tumatawag sa normative oracle ang production path.

Wala pang `savePatch` sa Stage 2. Ang correction ay para lamang sa susunod na PATCH stage.

## Pagpapatakbo ng mga pagsusuri

Stage 1 regression:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
```

Discovery 01:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage02.Tests.ps1
```

Buong Stage 2 verification at finalization:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage02.ps1
```

Sa matagumpay na Discovery 01 verification, kailangang lumitaw ang `STAGE02_RESULT=PASS` at `STAGE02_REPOSITORY_STATE=EXPECTED_RED`.

## Tumpak na integer

Ginagamit ng linya ang `System.Numerics.BigInteger`, na bahagi ng .NET runtime na ginagamit mismo ng PowerShell. Walang floating point sa normative o Discovery 01 arithmetic.

## Wika ng pinagmulan

Ang Filipino ang nag-iisang wikang pantao ng implementasyong ito. Ang mga identifier, API name, file name, at machine-readable key ay maaaring manatili sa teknikal na anyo. Ang mga paliwanag, komento, diagnostic na para sa tao, at dokumentasyon ay Filipino.
