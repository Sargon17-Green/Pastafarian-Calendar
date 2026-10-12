# Cam 16 — DISCOVERY 08: nam ordinal one-based yn unrank zero-based

## Sylfaen a chyfyngiadau
- Gangen: `Kotlin+Cymraeg`.
- Sylfaen Cam 15 wedi'i hardystio: `2312159a4e89139790c121e1fd2389e784f35c4b`.
- `LAST_COMPLETED_STAGE=15` hyd nes PASS brodorol Cam 16.
- **Dim PATCH 08.** Dim adeiladwr diferion gweledig, dim pour na bowl alias.
- Mae'r oracl `NormativeCore` yn y profion yn unig.

## Ymddygiad hanesyddol
Mae `oldPermutationUnrank0(rank0)` yn gweithredu'r unrank
lexicographic **cywir** ar 0..719. Mae 0 yn rhoi
`[1,2,3,4,5,6]`, a 719 yn rhoi `[6,5,4,3,2,1]`;
gwrthodir 720 gyda `E_DISCOVERY08_RANK0_RANGE`.

Mae'r caller `legacyPermutationOrderFromDropWrong` yn cyfrifo
`oneBased = mod(drop-1,720)+1` ond yn pasio `oneBased`
**fel rank0**, heb dynnu un. Mae ordinal 1 yn rhoi
`[1,2,3,4,6,5]`; mae 720 yn galw'r hen helper,
yn dal ei wall ystod ac yn cofnodi `undefined`.
Ceir **720/720 EXPECTED_RED; 0 MATCH**, gan gynnwys
719 trefn anghywir ac un undefined.

Mae `BOOT → DISCOVERY_08` yn cadw pob mewnbwn, y ddau
fynegai, allbwn anghywir neu null, errorId, metrigau a'r
trace mewn cyd-destun unigryw. Nid yw'n cyhoeddi gwerth cywir.

## Dilysu
`sh run-stage16-tests.sh` yn rhedeg pob cam 1–15
gyda'r oracl ffynhonnell gwreiddiol ac yna:
- prawf bijection 720/720 o'r helper zero-based;
- 720 ordinal anghywir, achos 720 undefined, 0 MATCH;
- prawf cynhyrchu, BOOT/replay, perchnogaeth ac atchweliadau;
- 4,320 tyst BigInteger o chwe chylch;
- methiant strict bwriadol `E_DISCOVERY08_STRICT_RANK1_RED`.

Dim ond ar ôl `STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE`
y caniateir llofnodi Cam 16. Bydd Cam 17 yn PATCH 08,
ond ni chaniateir dechrau hynny nawr.


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
