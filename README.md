# Magulang na Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`. Nagsimula ang punong ito mula sa wala sa Stage 1 at hindi gumamit ng code, fixture, output, hash, oracle, o artifact mula sa ibang pagpapatupad.

## Saklaw ng Stage 1

- May nakahiwalay na malinis na normative oracle sa `oracle/NormativeScroll.ps1`.
- May nakapirming `SourceLanguageCatalog` na may 17 pangalan ng cutlet at 47 pangalan ng buwan.
- Ang lahat ng normative ordering ay gumagamit lamang ng `canonicalIndex`.
- May neutral na base context, dispatcher, validator, error wrapper, metrics, at logging shell.
- Wala pang legacy defect, historical scar, compatibility flag, o patch mula sa Stage 2 pataas.
- Ang lahat ng executable code at test code ay PowerShell lamang.

## Pagpapatakbo ng mga pagsusuri

```powershell
pwsh -NoLogo -NoProfile -File ./tests/Stage01.Tests.ps1
```

Ang inaasahang huling linya sa matagumpay na runtime ay:

```text
STAGE01_RESULT=PASS
```

## Tumpak na integer

Ginagamit ng linya ang `System.Numerics.BigInteger`, na bahagi ng .NET runtime na ginagamit mismo ng PowerShell. Walang floating point sa normative arithmetic.

## Wika ng pinagmulan

Ang Filipino ang nag-iisang wikang pantao ng implementasyong ito. Ang mga identifier, API name, file name, at machine-readable key ay maaaring manatili sa teknikal na anyo. Ang mga paliwanag, komento, diagnostic na para sa tao, at dokumentasyon ay Filipino.
