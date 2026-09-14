# Kalendaryong Pastafarian — PowerShell + Filipino

Ito ang malayang linya ng pagpapatupad para sa `PowerShell` at `Filipino`.

## Mga natapos na naunang stage

Napatunayan na ang Bootstrap, ang remainder discovery/patch pair, ang Foundation day-tag discovery/patch pair, at ang distance discovery/patch pair.

## Stage 8 — Discovery 04

Sa Stage 8, idinadagdag sa tunay na production route ang ikaapat na historical defect: `mutateStonesWrong`.

May limang bato sa state:

```text
w, b, s, m, r
```

Ang maling historical code ay nagbabago sa iisang mutable state nang sunod-sunod:

```text
S.w = SAVE(S.w*S.w + 3*S.b + i)
S.b = SAVE(S.b*S.b + 5*S.s + S.w)
S.s = SAVE(S.s*S.s + 7*S.m + S.b)
S.m = SAVE(S.m*S.m + 11*S.r + S.s)
S.r = SAVE(S.r*S.r + 13*S.w + S.m)
```

Dahil dito, ang `b` ay nakakabasa na ng bagong `w`, ang `s` ng bagong `b`, ang `m` ng bagong `s`, at ang `r` ng bagong `w` at bagong `m`.

Ang normative stone row ay dapat gumamit ng iisang lumang snapshot para sa lahat ng limang formula.

### Inaasahang pulang surface

Ang tunay na legacy builder ay gumagawa ng rows 1–46. Ang rows 2, 3, at 46 ay inihahambing sa test-only normative stone table.

Inaasahan sa Stage 8:

- row 2 — `EXPECTED_RED`;
- row 3 — `EXPECTED_RED`;
- row 46 — `EXPECTED_RED`;
- eksaktong tatlong divergences at walang matching control sa tatlong probe na ito.

Sa row 2, ang unang bato `w` ay nagkataong tama dahil ito ang unang ina-update; ang `b`, `s`, `m`, at `r` ay mali na.

### Production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> Discovery 04 legacy stone adapter
-> mutateStonesWrong
```

Ang maling stone table at row count ay pag-aari lamang ng kasalukuyang invocation.

Wala pang Patch 04. Walang `stonePatch`, walang snapshot-based five-field overwrite, at walang Stage 9 correction.

## Pagpapatakbo

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage01.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tests\Stage08.Tests.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Run-Stage08.ps1
```

Ang Stage 8 verification ay dapat magtapos sa `STAGE08_RESULT=PASS`, habang ang repository state ay `EXPECTED_RED`.
