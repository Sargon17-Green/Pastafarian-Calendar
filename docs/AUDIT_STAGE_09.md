# Cam 9 — archwiliad PATCH 04: ciplun pum carreg

## Y diffyg sydd wedi'i gadw

Ni chaiff `LegacyStoneBuilder.mutateStonesWrong` ei newid. Mae'n diweddaru'r pum carreg yn eu trefn ar un gwrthrych, gan ail-ddefnyddio gwerthoedd sydd eisoes wedi'u newid. Mae `DISCOVERY_04` yn cadw 224 anghysondeb o 225 cydran yn rhesi 2–46.

## Y llwybr cywiro

Mae `StonePatchWrapper.stonePatch(previous, rowIndex)` yn cadw ciplun o'r hen res, yn galw'r mutator **hanesyddol go iawn** ar glôn, ac yn cadw'r `legacyGarbage`. Dim ond wedyn y mae'n creu `corrected` gyda'r pum fformiwla yn darllen y ciplun yn unig. Ni ddefnyddir yr oracl prawf mewn cynhyrchu.

Mae `buildPatchedRows()` yn creu rhes sentinela 0, rhes gychwyn 1 (`17,29,43,71,101`), ac yn adeiladu rhesi 2–46 mewn 45 galwad hanesyddol. Mae'r tabl a'r garbage yn gofnodion annibynnol, heb aliasu. Mae `BOOT → PATCH_04` yn cadw'r ddau dabl, y 45 galwad a'r 46 rhes mewn cyd-destun y galwad ac yn ymrwymo'n atomig ar ôl llwyddiant.

## Amodau prawf

- `Stage09Tests`: pob un o'r 230 cydran wedi'u trwsio yn hafal i `NormativeCore.STONES`; 224 anghysondeb yn y llwybr etifeddol yn parhau.
- Prawf fod `stonePatch` yn galw'r mutator ar glôn yn unig, heb newid y mewnbwn, a bod y garbage yn cael ei gadw.
- Prawf gwrthod mynegai rhes anghywir, lleoliad cyd-destunau annibynnol, gwrthod ail-anfon a gwrthod os nad oes BOOT.
- `Stage09BigIntegerTests`: 230 gwirio cyfrifiadol annibynnol o'r rhesi cywir, a gwirio'r garbage yn erbyn y fformiwlâu dilyniannol.
- Pob prawf Camau 1–8 yn y gadwyn `run-stage09-tests.sh`, gan gynnwys methiant strict disgwyliedig Cam 8.

**Statws cyn CI:** PENDING. Ni ddylid newid `LAST_COMPLETED_STAGE=8` heb `STAGE09_NATIVE_GREEN` gan Kotlin/JVM gwreiddiol.

**Cam nesaf ar ôl ardystiad:** Cam 10 — DISCOVERY 05. Ni ddechreuwyd ef.


## Ardystiad CI brodorol — COMPLETE

**Mae'r adran hon yn disodli'r statws PENDING uchod.**

- Gangen `Kotlin+Cymraeg`, commit ffynhonnell `8145a9b7c07affe982c09ce0668dc1cf0610b068`.
- GitHub Actions `38186462459`, swydd `114609724515`: **SUCCESS**.
- Kotlin 1.9.0, JDK 21, y cod a'r oracl normadol gwreiddiol, `sh run-stage09-tests.sh`.
- Gwiriwyd 19 marc yn uniongyrchol yn log y swydd.
- PASS: holl atchweliadau Camau 1–8, gan gynnwys `STAGE08_NATIVE_EXPECTED_RED_COMPLETE`.
- PASS: `STAGE09_PATCH_GREEN_0`, `STAGE09_PRESERVED_DISCOVERY04_RED_224`,
  `STAGE09_GARBAGE_CAPTURE_PASS`, `STAGE09_WHOLE_TABLE_GREEN_230`,
  `STAGE09_SNAPSHOT_AND_CALLS_PASS`, `STAGE09_OWNERSHIP_GUARDS_REPLAY_PASS`,
  `STAGE09_EARLIER_ROUTES_PASS`, `STAGE09_COMPLETE_GREEN`,
  `STAGE09_BIGINT_INDEPENDENT_GREEN_230`,
  `STAGE09_BIGINT_GARBAGE_CAPTURE_PASS` a `STAGE09_NATIVE_GREEN`.
- Ni newidiwyd `LegacyStoneBuilder.mutateStonesWrong` na'r oracl gwreiddiol.

Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38186462459

**Dyfarniad:** Cam 9 wedi'i gwblhau a'i ardystio. `LAST_COMPLETED_STAGE=9`.
Cam 10 (`DISCOVERY 05`) yw'r cam nesaf; ni ddechreuwyd eto.
