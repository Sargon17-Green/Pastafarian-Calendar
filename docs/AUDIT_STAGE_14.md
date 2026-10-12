# Cam 14 — Archwiliad DISCOVERY 07: mynegai zero-based tabl malu

## Cyfyngiadau a sail

- Gangen: `Kotlin+Cymraeg`; sylfaen wedi'i hardystio:
  `0e258c3b119ce580b01a395f0865240d2eca1409` (Cam 13).
- Mae `LAST_COMPLETED_STAGE=13` hyd nes bod GitHub Actions yn
  gwirio Camau 1–14 gyda ffynonellau ac oracl gwreiddiol.
- Rhaid i'r graith Stage 14 fod yn fyw ac yn alwadadwy. **Nid yw'r
  cyfieithydd sentinel PATCH 07 (Cam 15) wedi'i weithredu.**
- Dim adeiladwr diferion gweledig: mae hynny'n gam ar wahân yn y cynllun.

## Y tabl ffisegol a'r graith

Mae `LegacyGrindTableAdapter` yn cynnwys 11 rhes `VisibleGrindRow`
yn union, mewn trefn zero-based: mae mynegai corfforol 0 yn hafal i
res normadol 1, mae mynegai 1 yn res 2, ac mae mynegai 10 yn res 11.
Mae'r rhesi (a,b,c,d,stoneKind) yn union yr 11 cyfuniad a welir yn
`NormativeCore.visibleGrinds` ar ochr y prawf; nid oes sentinel.

Ond mae `legacyGrindRow(grind)` yn derbyn ordinal **1-based**
ac yn galw `physicalRows.getOrNull(grind)` yn uniongyrchol.
Hynny yw:

- grind 1 → rhes normadol 2 (`directIndex=1`), **EXPECTED_RED**;
- grind 2..10 → rhes normadol 3..11, **EXPECTED_RED**;
- grind 11 → `null`, `undefined=true`, **EXPECTED_RED**;
- 11 `EXPECTED_RED` ac 0 `MATCH`.

Mae `BOOT → DISCOVERY_07` yn galw'r hen helper yn wirioneddol,
yn cofnodi ordinal, mynegai uniongyrchol, rhes neu `null`,
baner undefined, tabl corfforol a chyfrif galwad, a hynny'n
gyd-destun perchnogaeth y galwad. Y probe diofyn yw grind 1.
Nid yw'r llwybr cynhyrchu yn galw `NormativeCore`.

## Prawf brodorol

Mae `sh run-stage14-tests.sh` yn galw `run-stage13-tests.sh`
yn gyntaf (pob cam 1–13), yna'n profi:

- union 11 rhes, pob gwerth yn cyfateb i'r oracl rhifol, sentinel yn absennol;
- pob ordinal 1..11 yn RED, grind 1 → rhes 2, grind 10 → rhes 11,
  grind 11 → undefined;
- probe cynhyrchu grind 1 a galwad ychwanegol grind 11;
- gwarchodion ffiniau, atal replay heb BOOT, metrigau, perchnogaeth
  a chadw'r holl lwybrau cywiro/gwahaniaethau hanesyddol;
- prawf `java.math.BigInteger` annibynnol â 6 gwerth cychwynnol,
  60 gwahaniaeth rhifol + 6 achos undefined = 66 tyst RED;
- prawf strict bwriadol sy'n methu yn union gyda
  `E_DISCOVERY07_STRICT_GRIND1_RED`.

Rhaid gweld `STAGE14_NATIVE_EXPECTED_RED_COMPLETE` gyda chod
ymadael 0 ar Kotlin 1.9.0/JDK 21 cyn llofnodi Cam 14.


## Ardystiad CI brodorol — COMPLETE

**Mae'r adran hon yn disodli'r statws PENDING uchod.**

- Gangen `Kotlin+Cymraeg`, commit ffynhonnell `634b30b4ccdf2830b0cb16a98d19e689462ea8e4`.
- GitHub Actions `38233182742`, swydd `114757365134`: **SUCCESS**.
- Kotlin 1.9.0, JDK 21, `run-stage14-tests.sh`, ffynonellau ac oracl gwreiddiol.
- Dilyswyd 43 marc log, heb unrhyw un ar goll.
- PASS: pob atchweliad Camau 1–13, gan gynnwys `STAGE13_NATIVE_GREEN`.
- PASS: `STAGE14_PHYSICAL_ROWS_GREEN_11`, `STAGE14_SENTINEL_ABSENT_PASS`,
  `STAGE14_GRIND1_EXPECTED_RED` ... `STAGE14_GRIND11_EXPECTED_RED`,
  `STAGE14_EXPECTED_RED_11`, `STAGE14_MATCH_0`,
  `STAGE14_GRIND1_IS_ROW2_PASS`, `STAGE14_GRIND10_IS_ROW11_PASS`,
  `STAGE14_GRIND11_UNDEFINED_PASS`.
- PASS: `STAGE14_PRODUCTION_REAL_ADAPTER_PASS`,
  `STAGE14_PRODUCTION_PROBE_G1_PASS`, `STAGE14_PRODUCTION_UNDEFINED_G11_PASS`,
  `STAGE14_GUARDS_REPLAY_PASS`, `STAGE14_CONTEXT_OWNERSHIP_PASS`.
- PASS: `STAGE14_BIGINT_INDEPENDENT_RED_66`,
  `STAGE14_BIGINT_SHIFTED_NUMERIC_60`, `STAGE14_BIGINT_UNDEFINED_6`,
  `STAGE14_STRICT_RED_CONFIRMED`, `STAGE14_NATIVE_EXPECTED_RED_COMPLETE`.
- Mae `LegacyGrindTableAdapter.legacyGrindRow` yn parhau'n anghywir a heb
  unrhyw gyfieithydd sentinel; nid oes cod PATCH 07 na builder diferion gweledig.

Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38233182742

**Dyfarniad:** Cam 14 wedi'i gwblhau fel `EXPECTED_RED`. `LAST_COMPLETED_STAGE=14`.
Cam 15 (`PATCH 07`) yw'r nesaf; nid yw wedi dechrau.
