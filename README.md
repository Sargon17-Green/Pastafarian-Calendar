# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Stage 9 — Patch 04

Nananatiling pisikal at direktang nasusubok ang historical `mutateStonesWrong`: binabago pa rin nito nang sunod-sunod ang iisang mutable five-stone state at kaya nitong gumawa ng maling legacy rows.

Ang bagong `stonePatch` ay isang hiwalay na correction layer:

```text
old = clone(state)
garbage = mutateStonesWrong(i, clone(state))

garbage.w = SAVE(old.w*old.w + 3*old.b + i)
garbage.b = SAVE(old.b*old.b + 5*old.s + old.w)
garbage.s = SAVE(old.s*old.s + 7*old.m + old.b)
garbage.m = SAVE(old.m*old.m + 11*old.r + old.s)
garbage.r = SAVE(old.r*old.r + 13*old.w + old.m)
```

Mahalaga ang tatlong bagay:

1. tunay na tumatakbo ang legacy mutator;
2. tumatakbo ito sa hiwalay na clone, kaya hindi nasisira ang old snapshot;
3. lahat ng limang overwrite ay bumabasa lamang sa old snapshot, hindi sa garbage.

Ang patched builder ay nagpapatakbo ng `stonePatch` sa rows 2–46: eksaktong 45 patched rows. Ang production context ay nagtatago ng huling old snapshot, legacy garbage, at committed row bilang invocation-local scar state.

Inaasahang repository state: `GREEN`.

Wala pang Stage 10 logic.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage09.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage09.ps1
```
