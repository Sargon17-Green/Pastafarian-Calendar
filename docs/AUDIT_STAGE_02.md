# Archwiliad Cam 2 — Darganfod 01

## Rhagdybiaeth hanesyddol

Tybiwyd bod `regularMod(x, M)` yn ddigon i gynrychioli'r holl weddillion, er bod `SAVE(x) = 1 + regularMod(x - 1, M)` yn mynnu gwerthoedd rhwng 1 ac M.

## Llwybr byw

`MonsterBootstrapManager.observeLegacyRemainder` → `BaseMonsterDispatcher` → handler `DISCOVERY_01` → `LegacyRemainderAdapter.oldRemainder` → `ExactInt.euclideanMod`.

Mae'r llwybr yn cynhyrchu allbwn etifeddol gwirioneddol. Nid oes fallback i `NormativeCore`; y profion yn unig sy'n galw'r cyfeirnod normadol. Cedwir pob mewnbwn ac allbwn semantig mewn `BaseMonsterContext` ar wahân ar gyfer pob galwad. Mae'r cyfrifon metrig yn arsylwadol yn unig.

## Tystion rhwymol

| Mewnbwn | Yr hyn sy'n dod o'r llwybr etifeddol | SAVE normadol | Cyfateb? |
|---|---|---|---|
| `M` | `0` | `M` | Na |
| `2M` | `0` | `M` | Na |
| `3M` | `0` | `M` | Na |
| `M+1` | `1` | `1` | Ie |

Disgwylir `mismatch_count=3` yn union. Mae'r modd `--strict` yn methu â `E_DISCOVERY01_NORMATIVE_DIFFERENCE:M,2M,3M`, ac mae'r sgript yn gwirio bod y methiant yn wirioneddol ddisgwyliedig; nid yw'n cymysgu methiant arall â'r gwall hanesyddol.

## Statws gwirio

Mae Cam 1 wedi'i nodi'n wyrdd yn y goeden ffynhonnell. Nid yw profion Kotlin Cam 1 a Cham 2 wedi'u rhedeg eto yn erbyn copi cyflawn o'r goeden yn y sesiwn paratoi'r delta hwn. Mae'r statws gweithredu yn parhau **heb ei wirio**, nid `PASS`; erys `LAST_COMPLETED_STAGE=1` hyd nes bod y pecyn wedi'i weithredu'n frodorol.

Nid yw Cam 3 (`PATCH 01`) wedi'i agor.

## Archwiliad cryfach y delta — 11 Hydref 2026

Dilyswyd union ffeil `src/main/kotlin/pastafari/ExactInt.kt` y gangen: mae'r
Git blob SHA yn `3c567e1bb7ad0a5d96b48edbee0d0a4163c05ce8`.  Gan ddefnyddio'r
ffeil gynhyrchu hon, yr addasydd etifeddol, y dosbarthwr a'r profion Cam 2,
llwyddodd y prawf JVM lleol.  Defnyddiwyd *dim ond* amnewidyn cryno o
`NormativeCore.save` yn yr harness dros dro; **nid yw hwn yn brawf o'r
cyfeirnod normadol llawn**.

Cafwyd y tri anghysondeb canonaidd `M, 2M, 3M` a'r cydweddiad `M+1`.
Mae'r profion bellach hefyd yn archwilio `-3M`, `-M`, `-M+1`, `-1`, `0`, `1`
a `M-1`, hunaniaeth cyfeiriadau'r cyd-destunau, rhestrau diagnostig ar wahân,
a metrigau rheolwyr annibynnol.  Yn yr harness dros dro, llwyddodd y modd
`--strict` i fethu gyda'r gwall penodol disgwyliedig.

Cynhaliwyd prawf rhifyddeg **oddi ar y goeden a heb ei becynnu i'r ystorfa**:
630 honiad PASS dros barth 64–548 did, yn cymharu `ExactInt` â BigInteger
fel archwiliad rhifyddeg annibynnol.  Nid yw hyn yn cymharu calendr arall,
nac yn newid cod nac oracl y prosiect.

**Cyfyngiad sy'n parhau:** ni chafwyd checkout cyflawn sy'n cynnwys
`NormativeCore.kt`, `NormativeCalendar.kt`, a `Stage01Tests.kt` yn yr
amgylchedd rhedeg hwn.  Felly nid oes hawl marcio'r 66 prawf Cam 1 na'r
pryfion llawn Cam 2 yn PASS.  Mae `LAST_COMPLETED_STAGE=1` yn aros, ac nid
ydym yn dechrau PATCH 01 cyn gwirio'r cam hwn.

## Archwiliad ychwanegol v003 — amodau cwblhau llymach

Mae'r harness yn gwirio bod y rhedeg Cam 1 yn dychwelyd `STAGE01_PASS_66`
yn union, nid cod ymadael sero yn unig. Ychwanegwyd 195 tyst cyfnodol
(`k=-32..32`, gweddillion `0,1,M-1`) a chyfrifiad negyddol mwy na 256 did.
Mae pob tyst yn pasio drwy'r handler cynhyrchu ac yn cael ei wirio yn erbyn
mynediad prawf-yn-unig i'r mopheth normadol. Profir hefyd na ellir galw'r
handler heb gwblhau BOOT.

**Canfyddiad ar wahân o Gam 1:** mae `ExactInt.toLongExact()` yn gwrthod
`-9223372036854775808`, er bod y gwerth yn perthyn i ystod `Long`.
Ail-gynhyrchwyd y methiant gyda'r union `ExactInt.kt` o'r gangen. Nid yw'r
pecyn hwn yn newid y dull: byddai ei newid yn atgyweiriad i'r haen rifedd
sylfaenol, nid yn `PATCH 01`, ac ni ddylid cuddio'r newid ymhlith cod
y darganfyddiad hanesyddol. Mae'r canfyddiad yn aros yn agored.

Nid yw'r goeden ffynhonnell gyflawn wedi'i rhedeg yn y sesiwn hon.
Mae'r statws felly yn parhau `LAST_COMPLETED_STAGE=1` nes bod yr archwiliad
brodorol llawn yn cael ei gwblhau.

## Gwiriad tarddiad ffynhonnell v004 — dim stubs

Cyn gweithredu profion Cam 1 mae `run-stage02-tests.sh` bellach yn gwirio bod
y gangen weithredol yn `Kotlin+Cymraeg`, a bod pum ffeil sylfaenol union
Cam 1 (ExactInt, Catalog, NormativeCore, NormativeCalendar, Stage01Tests) yn
cyd-fynd â Git blob SHA y commit sylfaen `4e54101d`. Defnyddir
`git hash-object --path` i barchu normaleiddio diwedd llinell Git ar Windows.

Bydd diffyg ffynhonnell, amnewidyn prawf, newid lleol i'r mopheth, neu gangen
anghywir yn achosi methiant cyn y compile. Nid yw'r amddiffyniad yn cymharu
hash gweithrediad arall nac yn benthyca cod o gangen arall.

Mae'r ddwy gyfres yn defnyddio JAR dros dro mewn cyfeiriadur `mktemp`,
a glanheir wrth ymadael. Gwirir pedwar marc cyflawni'r darganfyddiad yn
benodol yn ogystal â'r methiant llym disgwyliedig.

Dim ond prawf amddiffyn/ffug wedi'i labelu'n glir a redwyd yn yr
amgylchedd pecynnu; ni ellir galw hwn yn `STAGE01_PASS_66` o'r oracl
gorffenedig. Mae `LAST_COMPLETED_STAGE=1` yn aros hyd nes bod y coeden
gwreiddiol yn rhedeg y sgript heb amnewidion.

## Canlyniad terfynol — v005 / 11 Hydref 2026

**Diweddariad sy'n disodli'r statws 'heb ei wirio' hanesyddol uchod:**
mae Cam 2 bellach wedi'i wirio'n frodorol. Defnyddiwyd copi gweithredol
lleol a ailadeiladwyd gyda'r holl ffynonellau a ddefnyddir gan y profion,
gan gynnwys 6 ffeil gwaelodlin â Git blob SHA wedi'u gwirio'n union.
Nid oes honiad i glonio holl hanes y repo nac i redeg CI GitHub.

- `run-stage02-tests.sh` — exit `0`.
- Gwirio tarddiad y pum ffeil craidd — `STAGE02_BASELINE_PROVENANCE_PASS_5`.
- Pob un o 66 prawf y prawfwr gwreiddiol — `STAGE01_PASS_66`.
- 195 tyst cyfnodol — `STAGE02_PERIODICITY_PASS_195`.
- Rhif negyddol pell a gwahardd osgoi BOOT — PASS.
- Saith prawf ychwanegol a pherchnogaeth cyd-destunau — PASS.
- Anghysondebau `M,2M,3M` — `STAGE02_EXPECTED_RED_3`.
- Yr achos `M+1` — cyfatebiaeth.
- Methiant bwriadol y prawf llym — `STAGE02_STRICT_RED_CONFIRMED`.
- Ailgynhyrchu `stage01-fixtures.tsv` — Git blob SHA
  `5b172672ebb781921d32a03553539b1f2eefba1c`, yn union yr un â'r ffynhonnell.
- Gangen anghywir / mopheth wedi'i newid — gwrthodwyd yn gywir â exit `1`.

Mae `LAST_COMPLETED_STAGE=2` bellach yn gywir.
Mae'r canlyniad `EXPECTED_RED` yn fwriadol, nid yn fethiant adeiladu.
Nid yw'r canfyddiad `Long.MIN_VALUE` annibynnol wedi'i ddatrys eto.
