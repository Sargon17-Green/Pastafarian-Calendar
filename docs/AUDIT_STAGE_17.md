# Cam 17 — PATCH 08: cyfieithu ordinal un-seiliedig i unrank sero-seiliedig

## Cwmpas
Gangen `Kotlin+Cymraeg`; sylfaen ardystiedig Cam 16 `a032223a514422bf0dfc48ffcb7faa92a4db34a9`.
Mae `LAST_COMPLETED_STAGE=16` hyd nes PASS CI brodorol llawn.
Ni ddechreuwyd Cam 18, adeiladwr diferion gweledig na pours.

## Cywiriad gan gadw'r graith
Mae `LegacyPermutationOrderAdapter.legacyPermutationOrderFromDropWrong`
yn aros yn union fel yr oedd yng Ngham 16: ar gyfer ordinal 1..719
mae'n dychwelyd y permutation nesaf, ac ar 720 mae'n cofnodi
`E_DISCOVERY08_RANK0_RANGE` ac `undefined=true`.

Mae `PermutationPatchWrapper.patch(drop)` yn galw'r caller anghywir
hwnnw yn **gyntaf**, yn cadw'r cofnod etifeddol (gan gynnwys y
methiant 720), ac wedyn yn galw `oldPermutationUnrank0(oneBased - 1)`.
Mae'r ail alwad yn rhoi'r union drefn lexicographic 1..720.
Ar ordinal 1 mae'n rhoi `[1,2,3,4,5,6]`; ar 720 mae'n
rhoi `[6,5,4,3,2,1]`. Nid oes cyfrifiad diferion yma.

Mae `BOOT → PATCH_08` yn storio'r drop, y rhengoedd, yr
allbwn etifeddol neu `null`, `errorId`, y permutation gywir,
nifer galwadau, a marc y patch mewn cyd-destun unigryw. Ymrwymir
dim ond ar ôl llwyddiant pob gwiriad.

## Prawf brodorol
Mae `sh run-stage17-tests.sh` yn rhedeg pob cam 1–16 gan gynnwys
y strict RED hanesyddol, yna'n profi:
- pob un o 720 ordinal, 720 GREEN cywir a 720 RED etifeddol wedi'u cadw;
- 720 permutation unigryw, cofnod `undefined` etifeddol ar 720;
- ffiniau, rhifau negatif, a pheriodedd ±720;
- llwybr cynhyrchu, metrigau, atal replay, BOOT, a pherchnogaeth;
- atchweliadau DISCOVERY 08, DISCOVERY 07, PATCH 07 a PATCH 06;
- 4,320 prawf rhifyddol annibynnol `BigInteger` ar chwe chylch.

Rhaid gweld `STAGE17_FULL_NATIVE_GREEN` gyda swydd GitHub Actions
lwyddiannus ar Kotlin 1.9.0 a JDK 21 cyn gosod
`LAST_COMPLETED_STAGE=17`. Y cam nesaf yw 18 — DISCOVERY 09.


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
