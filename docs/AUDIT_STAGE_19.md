# Cam 19 — PATCH 09: ffynonellau arllwys yn safleoedd y permutation

## Llinach
Gangen `Kotlin+Cymraeg`. Sylfaen Cam 18 a ardystiwyd:
`4199d964694911fc92f927d6c3c9eb43be639da6`. Cedwir `LAST_COMPLETED_STAGE=18` hyd nes
profi llawn ar JVM brodorol. Nid yw Cam 20 wedi dechrau.

## Y nam a'r cywiriad
Ni newidir `LegacyFixedPourAdapter.oldFixedPour`, sydd yn
defnyddio bowl IDs sefydlog 1,2,3 ar gyfer y tri arllwys.
Mae `PourPatchWrapper.patch` yn galw **yr union ddull anghywir**
yn gyntaf ac yn cadw'r ffynonellau, y gwerthoedd, y permutation
a nifer y galwadau.

Yna, gan ddefnyddio'r **un permutation PATCH 08**, mae'n dewis
yr IDs gwirioneddol yn y tair safle gyntaf:
`order[0]`, `order[1]`, `order[2]`. Yr un cyfrifiad SAVE
sy'n cynhyrchu'r tri arllwys cywir. Cedwir rhai 4,5,6 yn sero.

`runPatchedPours` yn adeiladu 46 cam gyda ciplun o'r chwe
bowlen cyn pob cam ac yn perfformio'r cymysgu'n union yn ôl
y contract presennol. Nid yw'n cyflwyno nam alias in-place
Cam 20 nac yn adeiladu'r 46 diferion gweledig eu hunain.
Mae'r ddau fewnbwn (bowls cychwynnol a diferion gweledig)
yn dod o'r galwr.

Mae `BOOT → PATCH_09` yn cadw'r rhesi, y canlyniad,
yr order ar gam 46, 46 galwad legacy a 46 galwad gywir,
a'r holl fetrigau mewn cyd-destun unigryw, heb ail-chwarae.

## Dilysu bwriadedig
`sh run-stage19-tests.sh` yn profi pob cam 1–18
yn erbyn yr oracl gwreiddiol ac yna:
- 720 permutation: 720 arllwys cywir, 714 legacy RED,
  6 legacy MATCH damweiniol, 1,800 cell anghywir;
- cyfres gwrthdro 46 diferion: corrected GREEN,
  legacy RED, gyda chiplunau a phob galwad;
- cyfres union 46 diferion: corrected a legacy GREEN;
- 46 diferion a bowls cychwynnol oracl: corrected GREEN,
  legacy RED, heb ddibyniaeth cynhyrchu ar oracl;
- 4,320 prawf BigInteger annibynnol, 4,284 legacy RED,
  36 legacy MATCH, 10,800 cell anghywir;
- guards, perchnogaeth, BOOT, replay a holl scarau blaenorol.

Dim ond ar ôl `STAGE19_FULL_NATIVE_GREEN` a PASS GitHub Actions
gellir symud `LAST_COMPLETED_STAGE` i 19.


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
