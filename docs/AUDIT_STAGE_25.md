# Cam 25 — PATCH 12: cymydog bowl yn ôl trefn diferyn 46

## Llinach
Gangen `Kotlin+Cymraeg`, sylfaen ardystiedig Cam 24:
`b6a566a6dfdd59e020f830ebbd5e8cee5fc4a9dc`. Mae `LAST_COMPLETED_STAGE=24` tan
llwyddo Kotlin brodorol. Cam 26 heb ei ddechrau.

## Graith a chywiriad
Mae `LegacyNumericNeighborAdapter.oldNumericNeighborQuestion`
yn aros heb newid. Mae'n cyfrifo'r permutation
gwirioneddol PATCH 08 o ddiferyn 46 ond yn darllen
bowl `queriedBowlId+1` (neu 1 os queried=6)
yn lle'r bowl nesaf yn nhrefn y permutation.

Mae `PositionalNeighborPatchWrapper.patch` yn
galw'r hen ddull ar glôn o'r bowls terfynol **gyntaf**,
gan gadw'r canlyniad anghywir, yr ID rhifol a'r
cymydog normadol yn `legacyRead`. Yna, o'r
**un permutation diferyn 46**, mae'n cyfrifo
`order[(indexOf(queriedBowlId)+1)%6]` ac yn
ailgyfrifo'r first answer, direction number a
direction step â'r un fformiwlâu SAVE 179/181/193/197.
Nid yw'n ailalw'r permutation; mae'n ei ailddefnyddio
o'r graith. Nid oes oracl prawf yn y llwybr cynhyrchu.

Mae `BOOT → PATCH_12` yn cadw'r darlleniad
etifeddol, y cymydog cywir, y first answer a'r
direction, y metrigau a'r graith mewn cyd-destun
annibynnol. Nid yw replay yn ailgyfrifo'r ateb.

## Dilysu bwriadedig
`sh run-stage25-tests.sh` yn ailredeg pob cam
1–24 yn erbyn yr oracl ffynhonnell, ac wedyn:
- 720 × 6 bowl × 2 sêl: 8,640 GREEN cywir,
  6,912 hen RED wedi'u cadw a 1,728 MATCH damweiniol;
- 6 cylch o 720 × 6 bowl mewn BigInteger:
  25,920 GREEN cywir, 20,736 hen RED, 5,184 MATCH;
- gwrthdroad, wrap 6→1, guardiau, BOOT/replay,
  perchnogaeth a chadw DISCOVERY 12;
- cwblhau mewnbynnau naturiol o PATCH 10,
  PATCH 11 ac oracl `NormativeCore.askBowl`.

Rhaid cadw `LAST_COMPLETED_STAGE=24` hyd nes
`STAGE25_FULL_NATIVE_GREEN` a `SUCCESS`
GitHub Actions ar Kotlin 1.9.0/JDK 21.
