# Cam 12 — Archwiliad DISCOVERY 06: hanes gweledig yn unig

## Contract a chyfyngiadau

- Gangen: `Kotlin+Cymraeg`; commit sylfaen `455d38f7506a098d99b02a2aaeb3785dbc7b9017`.
- Cadw `LAST_COMPLETED_STAGE=11` nes bod prawf JVM brodorol llawn yn PASS.
- Ni chyflwynir `priorPatch`, nac unrhyw drosiad i hanes cudd; perthyn y cywiriad i Gam 13.
- Mae `NormativeCore` yn parhau ar ochr y profion yn unig.

## Y graith weledig hanesyddol

Mae `LegacyPriorAdapter.legacyPrior(visibleStore,i,back)` yn cyfrifo
`slot=i-back` ac yn darllen y storfa **weledig** yn unig. Nid oes ganddo
ffordd o gael hidden1 ar slot 0, hidden3 ar slot -2, na hidden7 ar slot -6.
Ar y tri slot hyn mae'r gwerth hanesyddol yn `null`. Nid yw'r NULL hwn
yn allbwn cywir; mae'r profion yn ei ddosbarthu fel `EXPECTED_RED`.

Y brofa wirioneddol yn y llwybr cynhyrchu yw `i=2,back=1`, felly `slot=1`.
Cedwir un gwerth wedi'i gywiro gan PATCH 05 yn y storfa weledig PROFI,
heb weithredu'r prosesu diferion gweledig. Mae'r handler yn galw'r
`legacyPrior` go iawn, yn cofnodi'r slot, gwerth, i, back, gwerth hidden1
wedi'i gywiro a'r cod `E_DISCOVERY06_MISSING_HIDDEN_HISTORY` ar gyfer
slotiau amhriodol. Mae hyn yn gyflwr sy'n eiddo i bob galwad yn unig.

## Dilysu

Mae `run-stage12-tests.sh` yn ail-redeg Camau 1–11 yn gyntaf. Yna:

- darlleniad positif slot 1 a slot 3: `MATCH`;
- tri tyst `i=1,back=1,3,7`: `EXPECTED_RED`, sero `MATCH`;
- tri thyst coll hefyd trwy'r llwybr cynhyrchu;
- 35 gwerth cudd a 175 cydran carreg wedi'u gwirio â `BigInteger` annibynnol;
- 15 achos coll dros bum pâr diwrnod (3 fesul pâr);
- prawf strict sy'n methu gyda'r ID penodol;
- perchnogaeth data, BOOT, ail-alw, terfynau, a'r pum patch blaenorol.

**Statws tan dystysgrif CI:** `EXPECTED_RED`, nid yw Cam 12 wedi'i
ardystio eto. `LAST_COMPLETED_STAGE=11`.


## Ardystiad CI brodorol — COMPLETE

**Mae'r adran hon yn disodli'r statws PENDING uchod.**

- Gangen `Kotlin+Cymraeg`, commit ffynhonnell `7fac959fc06edb8c59d0b7f0105fbf91151da87b`.
- GitHub Actions `38224902493`, swydd `114729897099` — **SUCCESS**.
- Kotlin 1.9.0, JDK 21, `run-stage12-tests.sh`, oracl a ffynonellau gwreiddiol.
- Cadarnhawyd 30 marc yn uniongyrchol yn log y swydd.
- PASS: pob atchweliad Camau 1–11, gan gynnwys `STAGE11_NATIVE_GREEN`.
- PASS: `STAGE12_VISIBLE_PROBE_MATCH_1`, `STAGE12_HIDDEN_SLOT_0_EXPECTED_RED`,
  `STAGE12_HIDDEN_SLOT_-2_EXPECTED_RED`, `STAGE12_HIDDEN_SLOT_-6_EXPECTED_RED`,
  `STAGE12_EXPECTED_RED_3`, `STAGE12_MISSING_HISTORY_MATCH_0`.
- PASS: `STAGE12_PRODUCTION_HIDDEN_RED_3`, `STAGE12_GUARDS_REPLAY_PASS`,
  `STAGE12_DIFFERENT_DAYS_OWNERSHIP_PASS`, `STAGE12_EARLIER_ROUTES_PASS`.
- PASS: `STAGE12_BIGINT_INDEPENDENT_GREEN_35`,
  `STAGE12_BIGINT_PATCH04_STONES_GREEN_175`,
  `STAGE12_BIGINT_MISSING_HIDDEN_RED_15`, `STAGE12_STRICT_RED_CONFIRMED`,
  `STAGE12_NATIVE_EXPECTED_RED_COMPLETE`.

Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38224902493

**Dyfarniad:** Cam 12 wedi'i gwblhau fel `EXPECTED_RED`.
`LAST_COMPLETED_STAGE=12`. Cedwir y graith visible-only; nid oes `priorPatch` na chod Cam 13.
