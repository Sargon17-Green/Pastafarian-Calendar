# Archwiliad Cam 8 — DISCOVERY 04

## Diffyg bwriadol
Mae'r addasydd `LegacyStoneBuilder` yn galw `LegacyRemainderAdapter.oldRemainder`
a `SavePatchWrapper.savePatch` o'r cod cynhyrchu. Mae'n newid pum maes yr un
gwrthrych yn ddilyniannol; nid yw'n defnyddio cipolwg o'r pum maes cyn newid.

## Meini prawf
- 47 safle yn y tabl (sentinela 0, rhesi 1–46).
- Rhes 1: `[17, 29, 43, 71, 101]`, yn gywir.
- 225 cydran mewn rhesi 2–46; 224 `EXPECTED_RED`, un `MATCH`.
- `mutateStonesWrong` yn dychwelyd yr un gwrthrych a gafodd ei newid.
- Mae cyflwr rhesi yn perthyn i bob cyd-destun; nid oes alias rhwng galwadau.
- Gwrthod ail-dispatch, galwad heb BOOT a mynegai rhes y tu allan i 2..46.
- Profion rhifiadol annibynnol BigInteger ar 230 cydran rhesi 1–46.
- Profion Camau 1–7 yn aros yn llwyddiannus.
- Methiant strict wedi'i fwriadu yn union ar 224 anghysondeb.
- Dim `stonePatch` na chod Cam 9.

## Statws
Mae prawf Kotlin ynysig yn gam cyntaf yn unig. Rhaid i GitHub Actions redeg
`sh run-stage08-tests.sh` gyda `ExactInt.kt` a `NormativeCore.kt` gwreiddiol.
`LAST_COMPLETED_STAGE=7` hyd at hynny.


## Ardystiad CI brodorol — COMPLETE

**Mae'r adran hon yn disodli'r cymhwyster PENDING uchod.**

- Gangen: `Kotlin+Cymraeg`, commit `051a928af4cc5166fc5884f80db48c530b5c5931`.
- GitHub Actions: rhediad `38183229336`, swydd `114600034894` — **SUCCESS**.
- Kotlin 1.9.0, JDK 21, y cod a'r oracl gwreiddiol, `run-stage08-tests.sh`.
- Gwiriwyd 30 marc uniongyrchol yn log y swydd.
- PASS: holl atchweliadau Camau 1–7, gan gynnwys `STAGE07_NATIVE_GREEN`.
- PASS: `STAGE08_ROW_2_EXPECTED_RED`, `STAGE08_ROW_3_EXPECTED_RED`,
  `STAGE08_ROW_46_EXPECTED_RED`, `STAGE08_EXPECTED_RED_224`,
  `STAGE08_MATCH_1` a `STAGE08_ROWS_46_PASS`.
- PASS: `STAGE08_INPLACE_SEQUENTIAL_PASS`, `STAGE08_OWNERSHIP_PASS`,
  `STAGE08_GUARDS_REPLAY_PASS`, `STAGE08_EARLIER_ROUTES_PASS`.
- PASS: `STAGE08_BIGINT_INDEPENDENT_PASS_230`,
  `STAGE08_BIGINT_NORMATIVE_RED_224`, `STAGE08_STRICT_RED_CONFIRMED`
  a `STAGE08_NATIVE_EXPECTED_RED_COMPLETE`.

Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38183229336

**Dyfarniad:** Cam 8 yn gyflawn fel `EXPECTED_RED`.
`LAST_COMPLETED_STAGE=8`. Cedwir y graith yn alwadadwy; nid oes
`stonePatch` na chod PATCH 04 wedi'i gyflwyno. Cam 9 yw'r cam nesaf.
