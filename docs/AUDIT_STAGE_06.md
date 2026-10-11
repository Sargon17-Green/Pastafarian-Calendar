# Cam 6 — DISCOVERY 03: gwahaniaeth tagiau yn lle pellter cronolegol

## Craith fwriadol

Mae `LegacyDistanceAdapter.oldDistance(c,t)` yn cyfrifo
`abs(dayTagWithFoundationScar(c)-dayTagWithFoundationScar(t))`.
Mae'r ddau dag yn mynd drwy'r cod cynhyrchu go iawn o PATCH 02:
`LegacyDayTagAdapter.oldDayTag` ac yna `DayTagPatchWrapper`.
Nid oes galwad at yr oracl normadol o'r cod cynhyrchu, ac ni roddwyd
unrhyw gywiriad pellter na PATCH 03 yn y cam hwn.

## Yr wyth tyst

| Achos | c | t | Hen bellter | Normadol | Dosbarthiad |
|---|---|---|---:|---:|---|
| BEFORE_LEFT | F−2 | F−1 | 2 | 2 | MATCH |
| AFTER_RIGHT | F+1 | F+2 | 2 | 2 | MATCH |
| BEFORE_LEFT_SECOND | F−3 | F−2 | 2 | 2 | MATCH |
| SAME_BEFORE | F−1 | F−1 | 0 | 1 | EXPECTED_RED |
| SAME_FOUNDATION | F | F | 0 | 1 | EXPECTED_RED |
| CROSS_FOUNDATION | F−1 | F | 1 | 2 | EXPECTED_RED |
| CROSS_TWO | F−1 | F+1 | 1 | 3 | EXPECTED_RED |
| CROSS_FOUR | F−2 | F+2 | 1 | 5 | EXPECTED_RED |

Mae'r oracl ar wahân yn cyfrifo `abs(target-calculation)+1`.
Mae'r llwybr `BOOT → DISCOVERY_03` yn storio'r dyddiau a'r gwerth
hen ar gyd-destun y galwad yn unig; nid yw'n newid canlyniadau
Camau 1–5. Mae'r prawf strict yn methu'n fwriadol a rhaid i'r sgript
wirio achos y methiant hwnnw.

## Gwiriadau a statws

Mae `Stage06Tests` yn cynnwys 441 pâr ychwanegol o ddyddiau,
cymesuredd, perchnogaeth cyflwr, gwrthod ail-alw a cheidwaid mewnbwn.
Mae `Stage06BigIntegerTests` yn defnyddio oracl Java annibynnol **yn y
profion yn unig** i wirio 549 pâr arall, gan gynnwys rhifau 2,048 did.

Mae `run-stage06-tests.sh` yn ail-redeg Camau 1–5 a'r oracl gwreiddiol
cyn Cam 6. Dylai CI gynhyrchu `STAGE06_NATIVE_EXPECTED_RED_COMPLETE`.
Cyn cael PASS brodorol y gangen, nid yw'r cam hwn wedi'i ardystio:
`LAST_COMPLETED_STAGE=5` yw'r statws hyd nes y dilysiad llawn.
