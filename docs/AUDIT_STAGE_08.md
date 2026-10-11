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
