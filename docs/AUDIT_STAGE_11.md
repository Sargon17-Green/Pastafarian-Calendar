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


## Ardystiad CI brodorol — COMPLETE

**Mae'r adran hon yn disodli'r statws PENDING uchod.**

- Gangen `Kotlin+Cymraeg`, commit ffynhonnell `326c843d2fb8a7f5c070362113a3284c4cbe6aac`.
- GitHub Actions `38222120118`, swydd `114720632237`: **SUCCESS**.
- Kotlin 1.9.0, JDK 21, `sh run-stage11-tests.sh`, ffynonellau gwreiddiol ac oracl gwreiddiol.
- Dilyswyd 30 marc log yn uniongyrchol, heb unrhyw un ar goll.
- PASS: holl atchweliadau Camau 1–10 gan gynnwys `STAGE10_NATIVE_EXPECTED_RED_COMPLETE`.
- PASS: pob un o `STAGE11_K1_GREEN` ... `STAGE11_K7_GREEN`,
  `STAGE11_PATCH_GREEN_7`, `STAGE11_PRESERVED_DISCOVERY05_RED_4`,
  `STAGE11_FIXED_MIDPOINT_K4_GREEN`, `STAGE11_WRONG_ACCESS_CALLED_7`,
  `STAGE11_TRANSLATOR_7_PASS`, `STAGE11_CONTEXT_OWNERSHIP_PASS`,
  `STAGE11_BOOT_REPLAY_GUARDS_PASS`, `STAGE11_EARLIER_ROUTES_PASS`,
  `STAGE11_BIGINT_INDEPENDENT_GREEN_35`,
  `STAGE11_BIGINT_PATCH04_STONES_GREEN_175`, `STAGE11_NATIVE_GREEN`.
- Ni newidiwyd yr hen `LegacyHiddenDropAdapter.kt`, `ExactInt.kt` na'r oracl.

Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38222120118

**Dyfarniad:** Cam 11 wedi'i gwblhau, `LAST_COMPLETED_STAGE=11`.
Cam 12 (`DISCOVERY 06`) yw'r cam nesaf; nid yw wedi dechrau.
