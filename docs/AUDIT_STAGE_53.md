# Cam 53 — PATCH 26: ardystiad brodorol

## Cyflwr: COMPLETE_VERIFIED_NATIVE_JVM

Ar ffynhonnell `47bb8e96f1c84a98b83e3ea73ae97cca3f87a9c7`, pasiodd
[GitHub Actions 40170593896](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40170593896).
Roedd pob un o'r **28 swydd yn SUCCESS**, gan gynnwys
`native-stage53-kotlin-cymraeg` (swydd `121100451583`) a `verify`.

Gwiriwyd y llinellau canlynol yn uniongyrchol yn log y swydd Kotlin:
- `STAGE52_STRICT_RED_CONFIRMED`, `STAGE52_DISCOVERY_NATIVE_PASS`
- `STAGE53_REAL_231_GATE_PAIRS_ORACLE_GREEN`
- `STAGE53_SYNTHETIC_64_BOUNDARIES_CORRECTED_64_CONTROLS_GREEN`
- `STAGE53_BIGINT_128_BOUNDARIES_CORRECTED_128_CONTROLS_GREEN`
- `STAGE53_FORWARD_64_BOUNDARIES_AND_128_DIRECTIONAL_REJECTIONS_GREEN`
- `STAGE53_GUARDS_REPLAY_METRICS_GREEN`
- `STAGE53_PATCH_NATIVE_GREEN`, `STAGE53_FULL_NATIVE_GREEN`

Mae'r prawf llawn yn galw `run-stage52-tests.sh` ac felly'n
cadw holl Gamau 1–52. Cedwir addasydd hanesyddol Cam 52 heb ei newid.
Mae `Year5000InclusiveAcceptancePatchWrapper` yn derbyn yr union ffin
`x == floor(M/n)*n` ac yn gwrthod yn unig `x > floor(M/n)*n`.

**Provenance:** arbrawf hanesyddol ar wahân, nid diffyg cynhyrchu
a gadarnhawyd. Mae'r oracl normadol yn aros yn y profion yn unig.
Nid oes cymhariaeth soak â gweithrediad annibynnol eto.
Mae `LAST_COMPLETED_STAGE=53`; Cam 54 — DISCOVERY 27 yw'r cam nesaf.
