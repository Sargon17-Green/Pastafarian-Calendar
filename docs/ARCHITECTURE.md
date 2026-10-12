# Pensaernïaeth Cam 1

Mae'r haen gynhyrchu ar hyn o bryd yn fwriadol niwtral. Mae `BaseMonsterContext` yn perthyn i un galwad yn unig. Mae `BaseMonsterDispatcher` yn trosglwyddo cam at handler cofrestredig. Mae `BaseValidationManager` yn gwirio cyflwr y bootstrap. Mae `BaseErrorWrapper` yn trosi methiant annisgwyl yn god peiriant penderfynedig. Mae `BaseMetricsManager` yn cadw cyfrifon arsylwadol nad ydynt yn fewnbynnau semantig.

Nid oes cache semantig, retry semantig, compatibility mode, legacy adapter na patch hanesyddol yn y cam hwn. Byddai ychwanegu un ohonynt yn gynnar yn halogi'r dilyniant 55 cam.

Mae'r cyfeirnod normadol yn byw dan `src/test` ac felly nid yw'r haen gynhyrchu yn gallu ei ddefnyddio fel fallback. Mae'r math `ExactInt` yn y prif god oherwydd bydd y gweithrediad cynhyrchu yn ei angen yn y camau dilynol; nid yw'n dibynnu ar lyfrgell arbitrary-precision allanol.


## Cam 15 — PATCH 07: cyfieithydd sentinel y rhesi malu

Mae'r adapter DISCOVERY 07 yn parhau'n union fel yr oedd. Mae
`GrindPatchWrapper.patch` yn galw'r darllenydd hen yn gyntaf ac yna'n
creu golwg gyda sentinel `null` yn safle 0; mae ordinal 1..11 yn darllen
rhes 1..11 yn gywir heb drosysgrifo'r tabl ffisegol. Mae
`MonsterBootstrapManager.applyGrindPatch` yn cadw'r hen wahaniaeth,
yr allbwn cywir a pherchnogaeth pob galwad. Nid yw Cam 15 yn adeiladu
diferion gweledig. Mae'r ardystiad Kotlin/JVM brodorol yn aros am CI;
cedwir `LAST_COMPLETED_STAGE=14` hyd at hynny.


## Ardystiad brodorol Cam 15 — COMPLETE

Ar commit `40bf4f7c9e3b4395a03a055f8ae5d5a5a4850714` llwyddodd rhediad GitHub Actions
[`38244045455`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38244045455),
swydd Kotlin `114793412444`, gyda Kotlin 1.9.0 a JDK 21.
Gwiriwyd 23 marc allweddol yn uniongyrchol o'r log (a phob un o'r
11 marc grind unigol): Camau 1–14, 11 cyfieithiad cywir,
11 graith etifeddol RED, 66 prawf BigInteger cywir, 60 hen wall rhifol
a 6 hen achos undefined, gwarchodion BOOT/replay, perchnogaeth,
a holl lwybrau blaenorol. Gwelwyd `STAGE15_FULL_NATIVE_GREEN`;
gorffennodd y swydd frodorol a swydd cloi enwau gyda `SUCCESS`.
**`LAST_COMPLETED_STAGE=15`**. Cam 16 (`DISCOVERY 08`) yw'r nesaf,
heb ei ddechrau. Nid yw'r adeiladwr diferion gweledig wedi'i weithredu.


## Cam 16 — DISCOVERY 08: derbyn ordinal one-based gan unrank zero-based

Mae `oldPermutationUnrank0` yn gywir ar 0..719 ond mae'r caller
hanesyddol yn pasio `mod(drop-1,720)+1` yn uniongyrchol iddo.
Canlyniad: 719 cyfnewidiad anghywir, un `undefined` ar 720,
720/720 `EXPECTED_RED` a 0 `MATCH`. Mae
`MonsterBootstrapManager.observeLegacyPermutation` yn cofnodi'r
graith heb PATCH 08 na gwerth cywir cynhyrchu. Ni ddechreuwyd
adeiladwr diferion gweledig na pours. `LAST_COMPLETED_STAGE=15`
nes bo'r CI brodorol wedi pasio.


## Ardystiad brodorol Cam 16 — COMPLETE

Ar commit `3cf687cc17a799e01528b0e3e9ff04740190d97e` pasiodd GitHub Actions
[`38246266578`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38246266578),
swydd `114800790604`, gyda Kotlin 1.9.0/JDK 21.
Gwelwyd pob un o 33 marc gwiriad allweddol yn log y swydd:
Camau 1–15 yn PASS; helper zero-based 720/720 GREEN;
caller anghywir 720/720 EXPECTED_RED, sero MATCH,
719 canlyniad anghywir ac un undefined; 4,320 tyst BigInteger,
strict red bwriadol, BOOT/replay a pherchnogaeth.
Gwelwyd `STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE`;
gorffennodd y swydd Kotlin a'r swydd cloi enwau ill dwy â SUCCESS.

**`LAST_COMPLETED_STAGE=16`**. Mae Cam 17 (`PATCH 08`) yn
nesaf, heb ei ddechrau. Cedwir y nam cynhyrchu byw, heb adeiladwr
diferion gweledig na chywiriad cynnar.


## Cam 17 — PATCH 08: addasu rheng y permutation

Mae `PermutationPatchWrapper.patch` yn galw'r caller hanesyddol
anghywir yn wirioneddol ac yn cadw 719 canlyniad anghywir a'r
achos `undefined` ar ordinal 720. Wedyn mae'n trosi
`rank0 = oneBased - 1` a galw'r helper zero-based cywir.
Mae `MonsterBootstrapManager.applyPermutationPatch` yn
cadw'r graith a'r canlyniad cywir mewn cyd-destun unigryw.
Rhaid profi 720/720 GREEN, 720 RED etifeddol, 4,320 tyst
BigInteger a phob atchweliad Camau 1–16 cyn ardystio Cam 17.
Nid oes adeiladwr diferion gweledig na pours yng Ngham 17.
Mae `LAST_COMPLETED_STAGE=16` nes cwblhau'r CI brodorol.


## Ardystiad brodorol Cam 17 — COMPLETE

Ar commit `d6aa1486c36c3b410c7a9b459927496ec54a428d` llwyddodd rhediad GitHub Actions
[`38252648589`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38252648589),
swydd Kotlin `114822613414`, gyda Kotlin 1.9.0/JDK 21 a'r
oracl ffynhonnell gwreiddiol. Gwiriwyd **32 marc** yn uniongyrchol
yn log y swydd. Pasiodd pob atchweliad Camau 1–16;
720 permutation gywir ac unigryw, 720 graith etifeddol RED wedi'u
cadw, 719 hen allbwn anghywir ac un undefined; 4,320 tyst
BigInteger cywir gyda 4,314 hen wall rhifol a 6 undefined;
ffiniau, cyfnodedd ±720, BOOT/replay, perchnogaeth a'r llwybrau
blaenorol. Gwelwyd `STAGE17_FULL_NATIVE_GREEN`, a gorffennodd
y swydd Kotlin a swydd cloi enwau â `SUCCESS`.

**`LAST_COMPLETED_STAGE=17`**. Cam 18 (`DISCOVERY 09`) yw'r
nesaf; ni ddechreuwyd. Nid oes adeiladwr diferion gweledig na pours.


## Cam 18 — DISCOVERY 09: darlleniad arllwys sefydlog

Mae `LegacyFixedPourAdapter.oldFixedPour` yn galw'r
trefnydd cywir PATCH 08 ond yn tynnu'r tri mewnbwn arllwys o
`old[1], old[2], old[3]` yn hytrach na
`old[order[0]], old[order[1]], old[order[2]]`.
Mae `BOOT → DISCOVERY_09` yn cadw tystiolaeth 46 cymysgiad,
cipluniau a'r trefn olaf. Cedwir yr addasiad chwe bowlen
ar sail ciplun, heb ddechrau PATCH 09, PATCH 10, adeiladwr
diferion gweledig, na'r cymysgiadau terfynol.
Gwirir pob 720 trefn (714 RED, 6 MATCH damweiniol),
4,320 tyst BigInteger a holl Gamau 1–17.
**`LAST_COMPLETED_STAGE=17`** tan PASS native CI.


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


## Cam 19 — PATCH 09: arllwys o safleoedd y permutation

Mae `PourPatchWrapper` yn galw'r hen arllwys sefydlog 1,2,3
cyn cywiro'r tri ID ffynhonnell yn ôl `order[0..2]`.
Cedwir y canlyniadau etifeddol ac mae `BOOT → PATCH_09`
yn cwblhau'r 46 cymysgiad ar giplunau heb alias in-place.
Bwriedir profi 720 arllwys GREEN, 714 legacy RED,
4,320 prawf BigInteger a'r holl atchweliadau Camau 1–18.
Nid oes adeiladwr diferion gweledig yn y cam hwn.
`LAST_COMPLETED_STAGE=18` nes cwblhau CI brodorol.


## Ardystiad brodorol Cam 19 — COMPLETE

Ar commit `5e7f405f6f3f9750268c20f1ef2bdb3b43aa38ec` llwyddodd GitHub Actions
[`38261542258`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38261542258),
swydd Kotlin `114853018881`, ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **39 marc** yn uniongyrchol yn log gwirioneddol y swydd.
Pasiodd holl atchweliadau Camau 1–18; 720 o arllwysiadau
cywir, 714 nam legacy RED, 6 MATCH damweiniol a 1,800
cell legacy anghywir; 46 tro gwrthdro, union a naturiol yn
GREEN yn erbyn yr oracl; 4,320 tyst BigInteger GREEN gyda
4,284 legacy RED, 36 MATCH ac 10,800 cell anghywir.
Pasiodd BOOT, replay, metrigau, perchnogaeth a'r llwybrau blaenorol.
Gwelwyd `STAGE19_FULL_NATIVE_GREEN`, gyda swydd cloi enwau a
swydd Kotlin ill dwy yn `SUCCESS`.

**`LAST_COMPLETED_STAGE=19`**. Cam 20 (`DISCOVERY 10`)
yw'r nesaf, heb ei ddechrau. Cedwir y nodwedd mewnbynnau
diferion gweledig allanol a'r gwarchodaeth rhag alias in-place;
nid yw adeiladwr diferion gweledig yn rhan o'r cam hwn.


## Cam 20 — DISCOVERY 10: bowls byw yn lle hen snapshot

Mae `LegacyInPlaceBowlAdapter.mutateBowlsWrong` yn galw
`PourPatchWrapper.patch` yn gyntaf, gan gadw'r arllwys
etifeddol a'i gywiriad Cam 19. Yna mae'n diweddaru chwe bowl
**yn eu lle** yn nhrefn y permutation: mae safleoedd 2..6 yn
darllen bowls a newidiodd eisoes, er bod y contract normadol
yn gofyn am hen snapshot ar gyfer pob un o'r chwe darlleniad.
Caiff pob darlleniad byw a phob ysgrifen ei gadw fel tyst.

Mae'r profion Cam 20 yn mynnu 720 `EXPECTED_RED`,
720 ysgrifen gyntaf GREEN, 3600 ysgrifen anghywir,
4320 prawf BigInteger, 46 diferyn a holl atchweliadau Camau
1–19. Nid yw'r oracl yn rhan o gynhyrchu; mae'r diferion
gweledig yn parhau'n fewnbynnau allanol. Nid oes PATCH 10.

`LAST_COMPLETED_STAGE=19` nes llwyddiant CI brodorol.


## Ardystiad brodorol Cam 20 — COMPLETE

Ar commit `06eee4647f56f665db8e7b9fcb3f580a7273a07a` pasiodd GitHub Actions
[`38264758391`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38264758391),
swydd Kotlin `114863999405` ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **41 marc** uniongyrchol yn log y swydd:
holl gamau 1–19 yn PASS; 720 `EXPECTED_RED`,
0 `MATCH`, 720 ysgrifen gyntaf GREEN, 3,600 o
ysgrifeniadau byw anghywir; 4,320 tyst BigInteger
annibynnol, 21,600 ysgrifen byw anghywir; 46 diferion
identity, reverse a naturiol yn `EXPECTED_RED`,
guardiau BOOT/replay, perchnogaeth a methiant strict
bwriadol. Gwelwyd `STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE`,
a llwyddodd y swydd Kotlin a swydd cloi enwau.

**`LAST_COMPLETED_STAGE=20`**. Cam 21 (`PATCH 10`)
yw'r nesaf, heb ei ddechrau; rhaid cadw'r mutator
etifeddol anghywir yn fyw. Ni adeiladwyd diferion
gweledig cynhyrchu o fewn Cam 20.


## Cam 21 — PATCH 10: clôn legacy a chwe darlleniad snapshot

Mae `BowlSnapshotPatchWrapper.patch` yn galw'r hen
`mutateBowlsWrong` yn wirioneddol ar glôn, gan gadw
chwe ysgrifen a'r graith darlleniadau byw. Wedyn mae'n
ailddefnyddio'r pours PATCH 09 cywir o'r un graith ac yn
cyfrifo pob un o'r chwe bowl o'r **un hen snapshot**,
gan ysgrifennu i restr newydd ar wahân.

Mae `BOOT → PATCH_10` yn prosesu 46 diferion, gyda 46
galwad legacy a 276 ysgrifen gywir. Mae'r profion yn
mynnu 720/720 GREEN, 720/720 RED legacy wedi'u cadw,
4,320 BigInteger GREEN, 21,600 hen ysgrifen anghywir
a holl atchweliadau Camau 1–20. Nid oes adeiladwr
diferion gweledig cynhyrchu o hyd.

`LAST_COMPLETED_STAGE=20` nes PASS Kotlin brodorol.


## Ardystiad brodorol Cam 21 — COMPLETE

Ar commit `a8d5beef2665123e543dde9cf3340359a484dda4` llwyddodd GitHub Actions
[`38268225516`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38268225516),
swydd Kotlin `114875745625`, ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **39 marc** yn uniongyrchol yn log y swydd:
holl gamau 1–20 yn PASS; 720 permutation gywir,
4,320 ysgrifen o'r snapshot cywir, 720 o hen ganlyniadau
RED wedi'u cadw, 3,600 hen ysgrifen anghywir;
4,320 tyst BigInteger GREEN gyda 21,600 ysgrifen etifeddol
anghywir; 46 diferyn identity, reverse a naturiol yn GREEN
yn erbyn yr oracl. Pasiodd y guardiau, BOOT/replay,
perchnogaeth a holl lwybrau blaenorol.
Gwelwyd `STAGE21_FULL_NATIVE_GREEN`, a llwyddodd y swydd
Kotlin a swydd cloi enwau ill dwy.

**`LAST_COMPLETED_STAGE=21`**. Cam 22 (`DISCOVERY 11`)
yw'r nesaf, heb ei ddechrau. Mae'r hen mutator
`mutateBowlsWrong` yn parhau'n fyw, ac nid yw
adeiladwr diferion gweledig wedi'i weithredu.


## Cam 22 — DISCOVERY 11: cache hen sum yn y 12 stir

Ar ôl 46 diferion, mae `LegacyCachedStirAdapter.oldCachedPostStir12`
yn ailadrodd 12 cymysgiad ond yn ail-ddefnyddio
`savedBowlSum` o stir 1 am stir 2..12. Mae stir 1
yn gywir; mae'r order PATCH 08 a'r chwe chyfrifiad
snapshot yn gywir ar gyfer y sum a roddir. **Y cache**
yw'r unig nam newydd, ac ni chaniateir cywiro'r cache
tan Gam 23 — PATCH 11.

Mae `BOOT → DISCOVERY_11` yn cadw pob hen snapshot,
saved sum, order a bowls ar bob stir. Mae'r profion
yn mynnu 720 RED ar stir 2 a chanlyniad 12 stir,
4,320 tyst BigInteger â 51,840 cam, strict RED,
a holl atchweliadau Camau 1–21. Mae'r bowls ôl-46
yn fewnbwn allanol; dim adeiladwr diferion gweledig.

`LAST_COMPLETED_STAGE=21` hyd nes PASS Kotlin brodorol.


## Ardystiad brodorol Cam 22 — COMPLETE

Ar commit `27f5969992a96b49dcea9c0f78e508556ae99be5` llwyddodd GitHub Actions
[`38274017335`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274017335),
swydd Kotlin `114894971609`, ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **41 marc** yn uniongyrchol yn log gwirioneddol y swydd:
Camau 1–21 i gyd yn PASS; stir 1 yn GREEN i 720/720,
stir 2 yn EXPECTED_RED i 720/720 a stir 12 terfynol
yn EXPECTED_RED i 720/720, sero MATCH. Llwyddodd
4,320 tyst BigInteger annibynnol gyda 51,840 stir wedi'u
gwirio, achosion positif a negatif enfawr, guardiau,
strict RED bwriadol, BOOT/replay a pherchnogaeth.
Gwelwyd `STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE`,
a gorffennodd y swydd Kotlin a'r swydd cloi enwau yn SUCCESS.

**`LAST_COMPLETED_STAGE=22`**. Cam 23 (`PATCH 11`)
yw'r nesaf, heb ei ddechrau. Rhaid cadw'r
`LegacyCachedStirAdapter.oldCachedPostStir12` byw ac
anghywir ar gyfer y patch nesaf. Dim adeiladwr diferion
gweledig cynhyrchu yma.


## Cam 23 — PATCH 11: savedBowlSum newydd ym mhob stir

Mae `FreshStirPatchWrapper.patch` yn galw'r hen
`oldCachedPostStir12` ar glôn ac yn cadw'r graith
cache stir 1 yn llawn. Ar ôl hynny, mae'n ailgyfrifo
`save(sum(old[1..6]) + 149*s)` ar bob stir 1..12,
yn defnyddio PATCH 08 ar gyfer y permutation, ac yn
ysgrifennu chwe bowls newydd o'r un hen snapshot.

Mae'r profion yn mynnu 720 GREEN cywir a 720 RED
etifeddol, 8,640 stir unigol wedi'u gwirio gyda'r
oracl gwreiddiol, 4,320 prawf BigInteger gyda 51,840
stir, a phob atchweliad Camau 1–22. Ni ddefnyddir
oracl prawf yng nghynhyrchu. Nid oes adeiladwr
diferion gweledig cynhyrchu o hyd.

`LAST_COMPLETED_STAGE=22` nes cwblhau CI brodorol.


## Ardystiad brodorol Cam 23 — COMPLETE

Ar commit `d9623a9eeb5b39c41bbfc07b055099e29903e0d5` pasiodd GitHub Actions
[`38278498810`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38278498810),
swydd Kotlin `114909725837`, gyda Kotlin 1.9.0/JDK 21.
Gwiriwyd **40 marc** yn uniongyrchol yn log gwirioneddol y swydd:
holl Gamau 1–22 yn PASS; 720/720 canlyniad PATCH 11
GREEN, 720/720 RED etifeddol wedi'u cadw, 8,640
stir wedi'u gwirio â'r oracl ffynhonnell gwreiddiol;
4,320 achos BigInteger GREEN, 4,320 hen RED, 51,840
stir annibynnol; rhifau anferth, guards, BOOT/replay,
perchnogaeth a'r holl lwybrau blaenorol yn PASS.
Gwelwyd `STAGE23_FULL_NATIVE_GREEN`, a gorffennodd
y swydd Kotlin a'r swydd cloi enwau yn SUCCESS.

**`LAST_COMPLETED_STAGE=23`**. Cam 24
(`DISCOVERY 12`) yw'r nesaf, heb ei ddechrau.
Mae `oldCachedPostStir12` yn aros yn fyw ac yn
anghywir. Mae mewnbynnau bowls ôl-46 yn dal yn
allanol; nid oes adeiladwr diferion gweledig cynhyrchu.
