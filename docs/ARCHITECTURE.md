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
