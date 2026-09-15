# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 16 — Discovery 08

Ang historical permutation helper ay zero-based:

```text
oldPermutationUnrank0(rank0)
    valid lamang sa 0..719
```

Ang helper mismo ay tama sa domain na iyon. Ang defect ay nasa caller: kinukuha nito ang semantic one-based ordinal na `1..720` mula sa drop at ipinapasa iyon nang diretso bilang `rank0`.

Kaya ang ordinals `1..719` ay isang permutation na huli, at ang ordinal `720` ay undefined. Lahat ng 720 ordinals ay `EXPECTED_RED`.

Sa production route ay may neutral `dropValue=1` probe. Wala pang Patch 08 `oneBased-1` bridge at wala pang bowl-alias logic.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage16.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage16.ps1
```
