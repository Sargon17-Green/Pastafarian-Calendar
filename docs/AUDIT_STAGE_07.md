# Cam 7 — PATCH 03: pellter cronolegol cynhwysol

## Y diffyg sydd i'w gadw

Mae'r graith o Gam 6 yn aros yn gwbl alwadadwy:
`LegacyDistanceAdapter.oldDistance(calculation,target)` yn cyfrifo
`abs(PATCH02_DAY_TAG(calculation) - PATCH02_DAY_TAG(target))`.
Nid yw'r llwybr hwn yn cael ei ddisodli'n dawel nac yn cael ei gywiro.
Mae'r wyth tyst hanesyddol yn cadw 5 `EXPECTED_RED` a 3 `MATCH`.

## Y patch newydd

Llwybr cynhyrchu `BOOT → PATCH_03`:

1. Gwiriad READY, meddiant y cyd-destun, a'r ddau ddiwrnod penodol.
2. Galw **oldDistance** go iawn i gael y sail hanesyddol.
3. Cyfrifo'r sail gronolegol `abs(target-calculation)` yn annibynnol ar dagiau'r dydd.
4. **Dim ond os yw'r ddwy sail yn wahanol**, dewis y sail gronolegol yn lle'r hen sail.
5. Ychwanegu'r `+1` cynhwysol olaf ym mhob achos, hyd yn oed os na chafwyd disodli.
6. Ar ôl cyfrifiad llwyddiannus yn unig, ymrwymo'r hen sail, y sail gronolegol,
   y sail a ddewiswyd, y faner disodli a'r allbwn i'r cyd-destun per-galwad.

Mae `DistancePatchWrapper` yn y cod Kotlin cynhyrchu, **heb alw'r oracl
NormativeCore**. Nid yw `java.math.BigInteger` yn cael ei ddefnyddio yn y
llwybr cynhyrchu; dim ond yn y profion annibynnol.

## Tystion penodol

| Achos | oldDistance | abs(t−c) | PATCH 03 | Sail wedi'i disodli? |
|---|---:|---:|---:|---|
| BEFORE_LEFT | 2 | 1 | 2 | Ie |
| AFTER_RIGHT | 2 | 1 | 2 | Ie |
| BEFORE_LEFT_SECOND | 2 | 1 | 2 | Ie |
| SAME_BEFORE | 0 | 0 | 1 | Na |
| SAME_FOUNDATION | 0 | 0 | 1 | Na |
| CROSS_FOUNDATION | 1 | 1 | 2 | Na |
| CROSS_TWO | 1 | 2 | 3 | Ie |
| CROSS_FOUR | 1 | 4 | 5 | Ie |

**Noder:** Nid yr un peth yw `legacy != normativeDistance` a
`legacyBase != chronologicalBase`. Yn y tri achos cyntaf,
mae'r hen allbwn ar hap yn cyfateb i'r pellter normadol terfynol,
ond mae'r hen **sail** yn anghywir ac mae angen ei disodli. Mae'r
profion yn gwahaniaethu'r ddau beth yn fwriadol.

## Cwmpas y profion

- Wyth tyst: sero anghysondeb PATCH 03, pum anghysondeb Cam 6 yn aros.
- 441 pâr lleol mewn matrics dwy ochr i'r Sylfaen, gan wirio'r faner
  disodli, y sail a ddewiswyd a'r canlyniad ar bob galwad.
- 549 pâr `BigInteger` annibynnol (hyd at 2,048 did), gan wirio'r hen
  sail, y sail newydd, y faner a'r pellter terfynol.
- Gwrthod cyd-destun heb BOOT, diffyg dydd, anghysondeb rhwng dydd y
  cyd-destun a'r cais, ac ail-alw. Dim ymrwymiad rhannol o gyfrifiad.
- Gwarchod stori Camau 1–6 gan gynnwys camau `EXPECTED_RED` a'r
  `STRICT_RED` o Gam 6.

## Statws cyn ardystiad

Ni ellir newid `LAST_COMPLETED_STAGE=6` nes bod
`sh run-stage07-tests.sh` yn rhedeg yn llawn yn erbyn holl ffynonellau
**gwreiddiol** y gangen a'i oracl normadol, gyda
`STAGE07_NATIVE_GREEN` a chod ymadael 0.

Ar ôl PASS brodorol, dogfennir commit y prawf, ID y job ac URL yr
archwiliad. Nid yw Cam 8 wedi'i ddechrau yma.
