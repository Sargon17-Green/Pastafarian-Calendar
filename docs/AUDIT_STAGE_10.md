# Cam 10 — Archwiliad DISCOVERY 05

## Contract a ffiniau

- Gangen yn unig: `Kotlin+Cymraeg`; dim newidiadau i `main`.
- Ffynhonnell cychwyn: commit `3b985cfd96573b4bc86a83455266e4f1ccdead12`, Cam 9 wedi'i ardystio.
- Cam 10 yn `EXPECTED_RED`; **ni weithredir PATCH 05**.
- Cedwir y pedwar patch blaenorol a'r oracl normadol yn ddigyfnewid.

## Nam hanesyddol wedi'i wireddu

Mae `LegacyHiddenDropAdapter.buildBackwardStorage` yn cyfrifo saith diferyn o'r
cyfrifon PATCH 02/03 a'r cerrig PATCH 04 cywir. Mae'r cyfernodau yn cael eu
cadw'n gorfforol yn ôl, ond defnyddir y set gywir i gyfrifo diferyn `k`.
Yn groes i drefn agosrwydd, storir hidden7 yn slot 1 a hidden1 yn slot 7.
Mae `legacyHiddenDirectByAssumedNearness(storage, k)` yn darllen `storage[k]`
**heb** gyfieithu'r cyfeiriad: dyma'r graith wirioneddol.

Yn nhystion Sylfaen ceir pedwar gwahaniaeth (`k=1,2,6,7`) ac un
cyfatebiaeth (`k=4`). Mae'r llwybr cynhyrchu yn gwneud darlleniad `k=1`
yn wirioneddol, yn cofnodi'r storfa a'i chanlyniad, ac yn diweddaru'r metrigau
ar ôl cyfrifiad llwyddiannus yn unig.

## Prawf a diogelu

Mae `run-stage10-tests.sh` yn ailredeg Camau 1–9 yn gyntaf. Wedi hynny:

- gwirio'r saith slot yn erbyn `NormativeCore.buildHiddenDrops` o'r ochr prawf;
- gwirio 46 rhes PATCH 04 a 45 galwad i'r hen mutator;
- gwirio pedwar `EXPECTED_RED` ac un `MATCH`;
- profi 35 gwerth cudd a 175 cydran carreg gyda BigInteger annibynnol;
- profi'r sentinel, ffiniau `k`, perchnogaeth, gwrthod ail-alw a BOOT;
- profi PATCH 01/02/03/04 a'r hen `DISCOVERY 04`;
- sicrhau bod prawf strict anghywir yn methu am y rheswm bwriadedig.

**Statws cyn yr ardystiad CI:** cod newydd wedi'i baratoi; nid yw'r
rhediad brodorol llawn wedi'i gadarnhau eto. `LAST_COMPLETED_STAGE=9`.


## Ardystiad CI brodorol — COMPLETE

**Mae'r adran hon yn disodli'r statws PENDING uchod.**

- Gangen: `Kotlin+Cymraeg`, commit ffynhonnell `b2c0a978ca452545c98ff9a7349c6cddd5db345b`.
- Rhediad GitHub Actions: `38214703144`; swydd `114696619440` — **SUCCESS**.
- Kotlin 1.9.0, JDK 21, `run-stage10-tests.sh`, a'r oracl gwreiddiol.
- Dilyswyd 24 marc yn uniongyrchol o'r log.
- PASS: holl atchweliadau Camau 1–9, gan gynnwys `STAGE09_NATIVE_GREEN`.
- PASS: `STAGE10_BACKWARD_STORAGE_PASS_7`, `STAGE10_PATCH04_ROWS_GREEN_230`,
  `STAGE10_PRODUCTION_WRONG_K1_PASS`, `STAGE10_EXPECTED_RED_4`, `STAGE10_MATCH_1`,
  `STAGE10_CONTEXT_GUARDS_REPLAY_PASS`, `STAGE10_BIGINT_INDEPENDENT_PASS_35`,
  `STAGE10_BIGINT_PATCH04_STONES_GREEN_175`, `STAGE10_STRICT_RED_CONFIRMED`,
  a `STAGE10_NATIVE_EXPECTED_RED_COMPLETE`.

Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38214703144

**Dyfarniad:** Cam 10 yn gyflawn fel `EXPECTED_RED`. `LAST_COMPLETED_STAGE=10`.
Cedwir y darllenydd anghywir; nid oes PATCH 05 na chod Cam 11.
