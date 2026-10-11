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
