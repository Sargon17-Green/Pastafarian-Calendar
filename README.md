# Magulang na Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`. Nagsimula ang punong ito mula sa wala sa Stage 1 at hindi gumamit ng code, fixture, output, hash, oracle, o artifact mula sa ibang pagpapatupad.

## Stage 1 — Bootstrap

Natapos at napatunayan sa aktuwal na Windows PowerShell 5.1 ang Stage 1. Nananatiling hiwalay ang malinis na normative oracle, nakapirmi ang `SourceLanguageCatalog`, at per-invocation ang semantic state.

## Stage 2 — Discovery 01

Napatunayan ang historical defect:

```text
oldRemainder(x) = regularMod(x, M)
```

Para sa mga multiple ng `M`, nagbubunga ang legacy path ng `0` sa halip na normative `M`. Nakumpirma sa runtime ang eksaktong Discovery 01 `EXPECTED_RED` surface.

## Stage 3 — Patch 01

Ang Patch 01 ay hindi nagbubura o nagpapalit sa `oldRemainder`. Sa halip, idinadagdag nito ang makitid na correction:

```text
savePatch(legacyRemainder) =
    M, kung legacyRemainder = 0
    legacyRemainder, kung hindi
```

Ang production route ay ngayon:

```text
Invoke-CalendarDateSpaghetti
-> base dispatcher
-> Invoke-Patch01SaveAdapter
-> oldRemainder
-> savePatch
```

Sa ganitong paraan, nananatiling nakikita at nasusubok ang historical scar, ngunit ang public production result ng kasalukuyang stage ay muling tumutugma sa normative `SAVE` behavior.

Walang Stage 4 discovery logic sa Stage 3.

## Pagpapatakbo ng mga pagsusuri

Stage 1 regression:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
```

Patch 01:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage03.Tests.ps1
```

Buong Stage 3 verification at finalization:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage03.ps1
```

Sa matagumpay na Patch 01 verification, kailangang lumitaw ang `STAGE03_RESULT=PASS` at `STAGE03_REPOSITORY_STATE=GREEN`.

## Tumpak na integer

Ginagamit ng linya ang `System.Numerics.BigInteger`, na bahagi ng .NET runtime na ginagamit mismo ng PowerShell. Walang floating point sa normative, Discovery 01, o Patch 01 arithmetic.

## Wika ng pinagmulan

Ang Filipino ang nag-iisang wikang pantao ng implementasyong ito. Ang mga identifier, API name, file name, at machine-readable key ay maaaring manatili sa teknikal na anyo. Ang mga paliwanag, komento, diagnostic na para sa tao, at dokumentasyon ay Filipino.
