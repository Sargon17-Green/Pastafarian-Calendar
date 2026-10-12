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
