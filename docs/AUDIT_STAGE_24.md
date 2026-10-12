# Cam 24 — DISCOVERY 12: y bowl nesaf yn ôl ID rhifol yn lle safle

## Cwmpas
Gangen `Kotlin+Cymraeg`. Sylfaen Cam 23 wedi'i hardystio:
`051fad0ad37123a009a59268c9b78a3d02baf9d9`. Cedwir `LAST_COMPLETED_STAGE=23` tan lwyddo'r
prawf Kotlin brodorol. Cam 25 PATCH 12 heb ddechrau.

## Y contract normadol a'r nam
Ar ôl 46 diferyn gweledig a 12 stir, mae'r chwe bowl
terfynol yn gywir o PATCH 11. Mae'r cymydog a ofynnir
iddo yn dibynnu ar drefn **diferyn 46**, nid ar drefn y
stir olaf nac ar rif y bowl.

Mae `LegacyNumericNeighborAdapter.oldNumericNeighborQuestion`
yn derbyn y chwe bowl terfynol cywir, gwerth diferyn 46,
ID y bowl a sêl. Mae'n galw'r un `PermutationPatchWrapper.patch`
sy'n rhoi'r union permutation cywir ar gyfer diferyn 46,
ac yn cofnodi'r ID cymydog normadol yn y drefn honno.

Mae'r NAM hanesyddol yn y darlleniad o'r bowl cymydog:
`queriedBowlId + 1` neu `1` ar ôl `6`, hyd yn oed
pan fo'r cymydog yn wahanol yn y permutation.
Mae cyfrifiadau `firstAnswer`, `directionNumber`, a
`directionStep` yn aros gyda'r un fformiwlâu SAVE
normadol. Nid oes newid i'r bowls, y permutation na'r
camau 1–23, ac nid oes PATCH 12 eto.

Mae `BOOT → DISCOVERY_12` yn ysgrifennu'r graith,
y ddau ID cymydog, yr ateb a'r cam cyfeiriad i un
context annibynnol ar ôl llwyddo'n gyfan gwbl.

## Tystiolaeth brodorol
`sh run-stage24-tests.sh` yn ail-redeg Camau 1–23
gan gynnwys yr holl strict RED hanesyddol ac wedyn:
- 720 permutation × 6 bowl × 2 sêl (21 a 31):
  8,640 ymholiad, 6,912 EXPECTED_RED, 1,728
  cydweddiad damweiniol; 12 achos (permutation/sêl)
  lle mae pob un o'r 6 cymydog yn cyd-fynd;
- gwrthdroad ordinal 720, cylchdroi 6→1,
  prawf strict RED gwirioneddol, guards,
  BOOT/replay a pherchnogaeth;
- 25,920 ymholiad BigInteger annibynnol mewn
  6 chylch × 720 × 6: 20,736 RED, 5,184 MATCH;
- mewnbynnau gwirioneddol o'r llwybrau PATCH 10,
  PATCH 11 a'r oracl prawf heb ddefnyddio'r oracl
  yn y cod cynhyrchu.

Ni chaniateir gosod `LAST_COMPLETED_STAGE=24`
nes bod `STAGE24_FULL_NATIVE_EXPECTED_RED_COMPLETE`
wedi'i gadarnhau gyda PASS CI Kotlin 1.9.0/JDK 21.
Cam 25 fydd PATCH 12.


## Ardystiad brodorol Cam 24 — COMPLETE

Ar commit `77f21e3830118848dd66afc22515bc39641b7534` llwyddodd GitHub Actions
[`38282797263`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38282797263),
swydd Kotlin `114923880682` gyda Kotlin 1.9.0/JDK 21.
Gwiriwyd **44 marc** yn uniongyrchol yn log y swydd:
Camau 1–23 oll yn PASS; 8,640 ymholiad (720 permutation
× 6 bowl × 2 sêl) gyda 6,912 EXPECTED_RED a 1,728
MATCH damweiniol; 12 cylch rhifol llawn;
25,920 ymholiad BigInteger gyda 20,736 EXPECTED_RED
a 5,184 MATCH. Pasiodd y strict RED, gwrthdroad,
mewnbynnau naturiol, BOOT/replay, perchnogaeth a'r
holl atchweliadau. Gwelwyd
`STAGE24_FULL_NATIVE_EXPECTED_RED_COMPLETE`,
gyda'r swydd Kotlin a swydd cloi enwau yn SUCCESS.

**`LAST_COMPLETED_STAGE=24`**. Cam 25
(`PATCH 12`) yw'r nesaf, heb ei ddechrau.
Cedwir `oldNumericNeighborQuestion` yn fyw ac
yn anghywir. Nid oes adeiladwr diferion gweledig
cynhyrchu yn y cam hwn.
