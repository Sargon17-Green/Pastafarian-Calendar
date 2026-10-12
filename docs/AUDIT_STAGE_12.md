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
