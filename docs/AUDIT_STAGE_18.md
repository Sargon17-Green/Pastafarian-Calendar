# Cam 18 — DISCOVERY 09: arllwys i IDau sefydlog yn lle trefn y bowlenni

## Cadw ffiniau
Sylfaen wedi'i hardystio: `9baeef5d888bebda7a989a10c215e3c596eef0e2`. Cwblhawyd Camau 1–17.
Rhaid i `LAST_COMPLETED_STAGE=17` aros nes PASS brodorol Cam 18.
Nid yw Cam 18 yn gweithredu `bowlAlias`, PATCH 09/PATCH 10,
creu'r 46 diferion gweledig, na'r deuddeg tro olaf.

## Y nam byw
Ar bob diferyn `i`, penderfynir trefn gywir chwe bowlen drwy
`PermutationPatchWrapper.patch(drop)`. Dylai'r arllwys cyntaf
ddarllen `old[order[0]]`, yr ail `old[order[1]]`, a'r trydydd
`old[order[2]]`. Mae `LegacyFixedPourAdapter.oldFixedPour`
yn galw'r un wrapper, ond yn DARLLEN `old[1], old[2], old[3]`.
Dyma'r nam i'w ddatgelu yn unig; nid yw'r tair darlleniad yn
cael eu cywiro. Mae'r cymysgiad chwe bowlen arall yn defnyddio
ciplun `old` a threfn gywir er mwyn ynysu'r nam i'r arllwys.

Mae `runWrongPours` yn derbyn 47 diferyn gweledig a saith
slot bowls (0 sentinela, 1..6); mae'n defnyddio tabl cerrig
PATCH 04 yn y ffynhonnell gynhyrchu ac yn cadw cofnodion
**46** cam, pob hen giplun, y tair arllwys anghywir, y chwe
gwerth newydd a threfn diferyn 46. Ni chaiff y ffynhonnell
gynhyrchu alw `NormativeCore`: mae'r oracl yn brofion yn unig.

## Tystiolaeth
- Pob un o 720 trefn gyda bowls gwahanol: 714 EXPECTED_RED,
  6 MATCH damweiniol (dim ond pan fydd y tair ffynhonnell gyntaf
  yn 1,2,3), 1,800 darlleniad anghywir o blith 2,160.
- Gwrthdroad olaf `[6,5,4,3,2,1]`: ID 1,2,3 anghywir yn
  lle 6,5,4; 46 cylch gyda chymysgiad snapshot cywir.
- Trefn hunaniaeth drwy 46 cylch: MATCH dilys, nid methiant prawf.
- 46 diferyn o `NormativeCore` prawf, `initialBowls`
  canonig a'r oracl chwe bowl: gwahaniaeth disgwyliedig.
- 4,320 tyst `BigInteger` annibynnol: 4,284 RED, 36 MATCH,
  10,800 cell arllwys RED.
- BOOT/replay, perchnogaeth, cyflwr atomig, gardiau, a'r
  holl gamau blaenorol 1–17.
- Methiant strict **bwriadol** `E_DISCOVERY09_STRICT_REVERSED_SOURCES_RED`.

Mae `run-stage18-tests.sh` yn galw `run-stage17-tests.sh` yn
gyntaf, ac wedyn yn gwirio'r profion, BigInteger a strict.
Dim ond os bydd `STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE`
gyda Kotlin 1.9.0/JDK 21 a GitHub Actions SUCCESS y caiff
`LAST_COMPLETED_STAGE` newid i 18. Y cam nesaf: 19 PATCH 09
— `bowlAlias[position] = order[position]`, heb gyffwrdd â'r graith.


## Ardystiad brodorol Cam 18 — COMPLETE

Ar commit `3831f1aa90d8fbb422cd64b4c8041240ad3254c0`, llwyddodd GitHub Actions
[`38256135742`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38256135742),
swydd `native-stage18-kotlin-cymraeg` `114834585726`, ar
Kotlin 1.9.0/JDK 21 gyda'r oracl git gwreiddiol.
Gwelwyd **38 marc** gwirio yng nghynnwys gwirioneddol y log:
PASS holl Gamau 1–17; 714/720 RED, 6 MATCH damweiniol a
1,800 arllwys anghywir; 46 cylch gwrthdroad RED, hunaniaeth
MATCH, a mewnbwn naturiol yr oracl RED; 4,320 tyst BigInteger
gyda 4,284 RED, 36 MATCH, 10,800 cell anghywir; strict
RED bwriadol, BOOT, replay, ownership, ac atchweliadau.
Gwelwyd `STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE`; llwyddodd
y swydd Kotlin a'r clo enwau (SUCCESS). Yr unig rybudd gweithredu
oedd rhybudd Node.js 20 GitHub Actions digyswllt â'r mathemateg.

**`LAST_COMPLETED_STAGE=18`** a `EXPECTED_REPOSITORY_STATE=EXPECTED_RED`,
fel y dylai fod i gam DISCOVERY. Cam 19 (`PATCH 09`) yw'r nesaf,
heb ei ddechrau. Nid yw'r graith etifeddol wedi'i dileu.
