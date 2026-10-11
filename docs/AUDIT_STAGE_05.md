# Archwiliad Cam 5 — PATCH 02 (Kotlin + Cymraeg)

## Sylfaen a'r contract

Commit wrth gychwyn: `7bf84f7c1a40dc99c0c0093d563c035893b56333`.
`LAST_COMPLETED_STAGE=4`. Un cam yn unig: PATCH 02, dim DISCOVERY 03.

## Yr hen ddiffyg a'r lapio

Mae'r hen swyddogaeth yn aros fel y'i diffiniwyd yng Ngham 4:

```text
F = -15055671
oldDayTag(day) = 2 * abs(day - F)
```

Mae'r handler newydd yn galw `oldDayTag(day)` yn gyntaf, unwaith, yna:

```text
if day >= F OR day == F:  legacyDayTag + 1
else:                    legacyDayTag
```

Mae `day == F` yn amod **diangen ond bwriadol**, yn ôl hanes y patch.
Mae'r oracl normadol wedi'i gyfyngu i'r profion, heb ddibyniaeth
arno o'r cod cynhyrchu.

| Diwrnod | Hen lwybr | Llwybr PATCH 02 | Oracl |
|---|---:|---:|---:|
| F−2 | 4 | 4 | 4 |
| F−1 | 2 | 2 | 2 |
| F | 0 | 1 | 1 |
| F+1 | 2 | 3 | 3 |
| F+2 | 4 | 5 | 5 |

## Llwybr cynhyrchu a pherchnogaeth

Mae `applyDayTagPatch` yn rhedeg `BOOT → PATCH_02`. Mae'r handler yn
cadw `patch02Input`, `patch02LegacyOutput`, `patch02Output`, olrhain,
diagnosteg a metrigau ar ôl cyfrifiad llwyddiannus. Bydd ail-anfon
cyd-destun, diffyg mewnbwn neu statws cyn BOOT yn methu heb newid
gwerthoedd na metrigau. Mae galwadau unigol yn annibynnol.

Mae `DISCOVERY_02` yn aros ar gael, gyda'r tri gwahaniaeth canonaidd.
Mae llwybrau `DISCOVERY_01` a `PATCH_01` yn aros yn weithredol hefyd.

## Tystiolaeth rhedeg

- Ailadeiladwyd `ExactInt.kt` yn lleol â blob Git union:
  `3c567e1bb7ad0a5d96b48edbee0d0a4163c05ce8`.
- Llwyddodd cyfansoddiad Kotlin/JVM wedi'i ynysu gyda'r gwir `ExactInt`.
- Llwyddodd y pum tyst, 331 diwrnod, 60 achos mawr a phrofion perchnogaeth.
- Llwyddodd 418 prawf ychwanegol gyda `BigInteger` fel oracl prawf annibynnol.
- Roedd y gwrthrych `NormativeCore` yn y rhediad hwn yn **amnewidyn
  prawf cyfrifiadol ar wahân**, nid yr oracl Cam 1 llawn.

**Cymhwyster terfynol heb ei gwblhau:** ni chafodd y sgript
`run-stage05-tests.sh` ei rhedeg yn llawn ar holl ffynonellau
Camau 1–5 yn y pecyn gwaith hwn. Felly cadwir `LAST_COMPLETED_STAGE=4`.
Nid oes hawliad am PASS llawn na newid GitHub.


## Ardystiad CI brodorol — cwblhawyd Cam 5

**Mae'r adran hon yn disodli'r cymhwyster PENDING uchod.**
Ailadeiladwyd y gangen gyfan gan swydd
`native-stage05-kotlin-cymraeg` yn GitHub Actions:

- Gangen: `Kotlin+Cymraeg`, commit
  `b832b6430fb6b2beea09234a97f06e3a07f09a18`.
- Kotlin 1.9.0, JDK 21, ffynonellau ac oracl normadol Cam 1 gwreiddiol.
- `sh run-stage05-tests.sh`: cod ymadael 0.
- Cam 1: `STAGE01_PASS_66`.
- Cam 2: `STAGE02_EXPECTED_RED_3`, `STAGE02_STRICT_RED_CONFIRMED`.
- Cam 3: `STAGE03_PATCH_GREEN_0`, `STAGE03_EXTENDED_BIGINT_GREEN_921`.
- Cam 4: `STAGE04_EXPECTED_RED_3`,
  `STAGE04_BIGINT_INDEPENDENT_PASS_409`, `STAGE04_STRICT_RED_CONFIRMED`.
- Cam 5: `STAGE05_PATCH_GREEN_0`, `STAGE05_DISCOVERY02_SCAR_RED_3`,
  `STAGE05_RANGE_GREEN_331`, `STAGE05_WIDE_GREEN_60`,
  `STAGE05_BIGINT_INDEPENDENT_PASS_418` a `STAGE05_NATIVE_GREEN`.
- Dilyswyd y marciau hyn yn uniongyrchol o log swydd CI, nid yn unig
  o ganlyniad cyffredinol y rhediad.

Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38173345431

**Canlyniad:** `LAST_COMPLETED_STAGE=5`; `CURRENT_STAGE=5`;
`EXPECTED_REPOSITORY_STATE=GREEN`. Cedwir y llwybr
`DISCOVERY_02` gyda thri anghysondeb disgwyliedig, ac mae
`PATCH_02` yn rhoi sero anghysondeb. Dim cod Cam 6 yn y commit hwn.
