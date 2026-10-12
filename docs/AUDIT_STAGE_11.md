# Cam 11 — Archwiliad PATCH 05: trefn agosrwydd y diferion cudd

## Ffiniau'r cam

- Gangen: `Kotlin+Cymraeg`, ar ôl Cam 10 `ec7b8c104e03e5009240dae92292d76b8465922d`.
- Mae'r hen `LegacyHiddenDropAdapter` a `legacyHiddenDirectByAssumedNearness`
  yn parhau'n union yr un fath.
- Mae'r cof corfforol yn parhau'n `hidden7, hidden6, ..., hidden1`, gyda
  sentinela yn slot 0.
- Nid oes unrhyw waith Cam 12 (`DISCOVERY 06`) yn y newid hwn.
- Mae `NormativeCore` yn parhau ar ochr y profion yn unig.

## PATCH 05: graith yn gyntaf, cyfieithydd yn ail

Mae `HiddenNearnessPatchWrapper.patch(storage,k)` yn galw'r
`legacyHiddenDirectByAssumedNearness(storage,k)` **yn gyntaf**, yn
cofnodi'r allbwn hanesyddol anghywir, ac yn defnyddio'r cyfieithiad
ffisegol `8-k` i gael y gwerth cywir trwy
`hiddenByNearness(storage,k)`.

Rhaid i `MonsterBootstrapManager.applyHiddenNearnessPatch` alw'r
llwybr `BOOT → PATCH_05`, defnyddio'r cyfrifon PATCH 02/03 a'r tabl
cerrig PATCH 04, ac ymrwymo'r data isod yn atomig:

- `patch05RequestedK` a `patch05PhysicalSlot`;
- `patch05LegacyDirectValue` a `patch05CorrectedValue`;
- `patch05BackwardStorage` a `patch05PatchedStoneRows`;
- `patch05Applied` a `patch05InvocationCount`.

Mae'r cyflwr yn perthyn i un galwad: rhaid gwrthod ail-anfon cyd-destun,
ac ni chaniateir gollyngiad i gyd-destun gwahanol.

## Profion a'r meini prawf cwblhau

Mae `run-stage11-tests.sh` yn ail-redeg Camau 1–10 gyda'r ffynonellau
a'r oracl gwreiddiol, cyn gwirio:

- pob un o saith k=1..7 yn GREEN;
- y pedwar gwahaniaeth hanesyddol k=1,2,6,7 yn dal yn weladwy;
- k=4 yn fan sefydlog, ac yn gywir hyd yn oed ar yr hen lwybr;
- union saith galwad hen ddarllenydd ar saith galwad gywiro;
- matrics annibynnol `BigInteger` gyda 35 gwerth cudd a 175 cydran carreg;
- guardiau k, hyd y storfa, perchnogaeth y data, BOOT ac ail-anfon;
- cadw holl lwybrau PATCH 01/02/03/04 a DISCOVERY 05.

Ni chaiff `LAST_COMPLETED_STAGE` ddod yn 11 cyn gweld
`STAGE11_NATIVE_GREEN` a chod ymadael 0 yn GitHub Actions gyda Kotlin
1.9.0/JDK 21.

**Cyn yr ardystiad:** LAST_COMPLETED_STAGE=10; PATCH 05 yn aros am CI.
