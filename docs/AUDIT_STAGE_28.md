# Cam 28 — DISCOVERY 14: cynllun profi'r giatiau negyddol

## Statws

**PARATOI — NID YW CAM 28 WEDI'I GWBLHAU.** Nid yw'r diffyg hanesyddol wedi'i gadarnhau eto. Peidiwch â chyfrif y nodyn hwn yn dystiolaeth EXPECTED_RED na CI.

## Hypothesis i'w brofi

Gall gweithrediad etifeddol ddefnyddio bwlch y giât bositif ar gyfer mynegai negatif wrth ymestyn y tabl giatiau yn ôl. Byddai hyn yn anghywir: mae'r oracl yn cyfrifo'r saws ar gyfer `FOUNDATION_DAY - n` ar ochr negatif, nid `FOUNDATION_DAY + n`.

## Gwirionedd normadol

- `gate[0] = FOUNDATION_DAY`.
- `gate[n] = gate[n-1] + positiveGateGap(n)` ar gyfer `n > 0`.
- `gate[-n] = gate[-n+1] - negativeGateGap(n)` ar gyfer `n > 0`.
- Mae pob bwlch yn `42..963` ac yn defnyddio `chooseRankInt(stream,922)` gyda `SEAL_GATE_GAP=1`.
- Dylai'r oracl prawf aros yn `src/test`; ni ddylid ei fewnforio i gynhyrchu.

## Amodau derbyn cyn ardystio

1. Darganfod diffyg etifeddol pendant yn y cod neu ei ddiffinio'n benodol fel addasydd etifeddol newydd, heb honni iddo fodoli o'r blaen.
2. Cymharu'r ddau gyfeiriad yn erbyn `NormativeCalendar.GateTable`, gyda samplau sy'n profi anghydraddoldeb go iawn yn hytrach na thybio bod pob sampl yn RED.
3. Profi'r mynegeion `-1`, `0`, `1`, ffiniau'r bylchau, estyniad ailadroddus, trefn galwadau, a BigInteger lle bo'n berthnasol.
4. Cadw pob prawf a llwybr Camau 1–27; gwahardd newidiadau i `main` a `CANONICAL_NAMES_LOCK.sha256`.
5. Rhedeg CI Kotlin brodorol a gwirio'r log swydd cyn newid `LAST_COMPLETED_STAGE` o 27 i 28.

## Tystiolaeth gyfredol

Mae `NormativeCalendar.kt` yn dangos cyfrifiadau positif a negatif gwahanol. Nid yw'r ffaith hon ar ei phen ei hun yn profi diffyg yn y cod cynhyrchu. Dyma gynllun ymchwilio, nid canlyniad prawf.
