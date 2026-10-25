# Protocol soak ar ôl Cam 55 — Kotlin+Cymraeg

**Statws: heb ei ardystio.** Rhaid i Cam 55 basio Kotlin/JVM CI cyn
cynnal prawf soak llawn yn erbyn gweithrediad annibynnol.

## Pethau mae'n rhaid i'r soak eu cymharu

Mae pob gweithrediad yn cael yr un pâr union `c,t` ar echelin
linol JDN y contract. Ar gyfer pob achos, cymharer **pum maes canonaidd**:
`year_number`, `cutlet_canonical_index`, `day_in_cutlet`,
`month_canonical_index`, `day_in_month`. Ni chymharer
enwau iaith Cymraeg/Türkçe oherwydd eu bod yn wahanol yn fwriadol.

Cynhelir pob prawf yn erbyn fersiynau penodol o'r ddwy goeden Git.
Dewisir `Python+Türkçe` fel y gweithrediad annibynnol cyntaf.
Nid yw modd defnyddio data statig a gopïwyd neu benderfyniadau'r
oracl Kotlin yn lle'r gweithrediad Python go iawn.

## Fformat protocôl

Mae'r ddau broses yn derbyn ar stdin linellau
`c<TAB>t`; mae pob ateb stdout yn cynnwys 7 cyfanrif degol
`c<TAB>t<TAB>year<TAB>cutletIndex<TAB>dayInCutlet<TAB>monthIndex<TAB>dayInMonth`.
Mae unrhyw neges ychwanegol, gwall, timeout, diffyg ateb neu
alwad sy'n dychwelyd rhifau y tu allan i'r ystod yn methu'r prawf.
Caiff tystiolaeth ei chadw yn JSON gydag SHA256 y corpus ac
enw/rif y ddau fersiwn. Ceir yr un samplau wrth ailredeg yr un seed.

## Rhyngwynebau

- `soak/python_turkce_bridge.py`: galw'r API cyhoeddus
  `calendar_date_spaghetti(c,t)` yn uniongyrchol; mapio'r
  enwau Türkçe yn ôl y catalog 17/47 ar gyfer mynegeion.
  Mae `PASTAFARIAN_PYTHON_SRC` yn pwyntio at `src` mewn
  checkout annibynnol o'r gangen `Python+Türkçe`.
- `src/test/kotlin/pastafari/Post55OracleSoakBridge.kt`: offer
  **diagnostig yn unig** sy'n defnyddio'r oracl prawf Kotlin.
  Nid yw'r llwybr hwn yn llwybr cynhyrchu ac ni ellir ei
  ddefnyddio i ardystio'r soak terfynol.
- Rhaid i ryngwyneb **Kotlin cynhyrchu** sy'n gweithredu
  pum maes gwirioneddol gael ei ychwanegu a'i wirio;
  mae'n ABSENNOL ar hyn o bryd. Rhaid iddo beidio
  ag mewnforio `NormativeCore` na `NormativeCalendar`.

## Rhwystrau ardystio

1. CI Cam 55: `STAGE55_FULL_NATIVE_GREEN`.
2. Kotlin production full-calendar converter ar gyfer unrhyw `c,t`,
   gyda phum maes canonaidd (nid dim ond cywiriad rank blwyddyn 5000).
3. Corpus sylweddol: ffin sylfaen, clwydi dwy ochr, tymhorau
   / misoedd, parau `c != t`, blwyddyn bell, gwrthdroi
   cyfeiriad, rhifau mawr ac ailadrodd ag un seed.
4. Dwy weithrediad annibynnol, dim ail-ddefnyddio oracl Kotlin
   fel dewiswr cynhyrchu. Dim mismatch na timeout.
5. Log ac artifacts wedi'u gwirio; atal y gangen rhag cael
   ei marcio'n gyflawn os oes unrhyw anghysondeb.

**Ni ddylid camddehongli CI llwyddiannus Cam 55 na phrawf
Kotlin-oracl yn lle soak y ddau beiriant cynhyrchu.**

## Diagnosteg eilaidd heb ardystio

Mae gwaith GitHub Actions ar wahân yn croeswirio allbwn pum maes
oracl prawf Kotlin yn erbyn API cynhyrchu annibynnol Python+Türkçe ar
SHA penodol. Mae'n cyhoeddi adroddiad JSON, yn methu ar unrhyw wahaniaeth
neu timeout, ac **nid yw'n ardystio** Kotlin cynhyrchu. Mae hyd yn oed
`--kotlin-mode production --certify` yn cael ei wrthod tan archwiliad
ffynhonnell ac adeiladwaith Kotlin cynhyrchu gwirioneddol: nid yw baner
CLI yn brawf o annibyniaeth gweithrediad. Cedwir `main` heb newid.

## Soak cydran cynhyrchu ar wahân (rheng/gap yn unig)

Mae `soak/Post55ProductionRankBridge.kt` yn rhedeg cod **cynhyrchu**
`GateGapRankPatchWrapper` a `Year5000InclusiveAcceptancePatchWrapper`.
Mae `soak/python_turkce_rank_bridge.py` yn rhedeg y cod cynhyrchu
`LegacyBiasedSelectionAdapter` a `SelectionRejectionPatchWrapper`
o'r gangen Python+Türkçe wedi'i phinio. Nid yw'r naill
bont yn mewnforio'r oracl Kotlin.

Ar gyfer mewnbynnau `G|Y<TAB>gateIndex|n<TAB>first<TAB>step`,
cymharir yn union `rank1`, `gap` a nifer yr atebion a wrthodwyd.
Mae'r corpus yn cynnwys cyfeiriadau -1/+1, union ffin derbyn,
ffiniad+1, `M`, teuluoedd 1..64 a 1001..1128, a samplau
canolog â had pendant. Mae'r prawf yn stopio ar y gwahaniaeth cyntaf,
yn cofnodi SHA256 a hunaniaethau'r ddau commit, ac yn defnyddio terfyn
amser/memori. Disgwylir marciau
`STAGE55_COMPONENT_DIFFERENTIAL_GREEN_...` a
`STAGE55_COMPONENT_NOT_FULL_DATE_SOAK`.

**NID YW** llwyddiant y cydran hon yn profi bod y fersiwn Kotlin
yn gallu cynhyrchu'r calendr cyfan. Mae'r soak pum maes yn dal ar agor;
mae'r ddiagnosteg ar yr oracl llawn wedi methu ar
`NormativeCore.WeavingFamily.count` oherwydd dyfnder recursion.
Nid yw'r methiant yma yn profi anghydweddiad cynhyrchu.
Mae'r gwaith diagnostig hwn bellach yn `workflow_dispatch`
yn unig i osgoi ailadrodd yr un prawf resource-unbounded ar bob push.

## Integreiddio rhannol injan Kotlin cynhyrchu (gate a blwyddyn 5000)

Yn `ProductionGateYear5000Engine.kt` ychwanegwyd tabl gate cadarn
gyda threfn gadarnhaol/negyddol, cap 8192 gate rhagosodedig, rheol
bwlch 42..963, cache per-ymholiad, a llwybr dewis ymgeiswyr 5000:
(hyd 252..5778; chwech gate o leiaf; (open,close]; trefnu ar hyd ac
agoriad), ac yna `PATCH_26` a `PATCH_27` gyda'r hen graith yn fyw.

Y bwlch pwysig: mae'r cyfrifiannell hon yn mynnu
`ProductionGateAnswerProvider` ar gyfer stream sauce seal 1
a `ProductionAnswerStream` ar gyfer seal 10. Nid oes
adeiladwr sauce/bowls cynhyrchu cyffredinol eto; felly nid yw'r
jigsaw blwyddyn 5000 yn ddigon ar gyfer galwad `c,t` i'r
calendr llawn.

Mae prawf Kotlin CI ar wahân yn rhoi'r stream a ddaw
o'r oracl **test-only** ac yn cymharu'r gate a'r canlyniad
blwyddyn 5000. Dim ond gwirio **cydrannau Kotlin** mae'r prawf
hwn; nid oes hawl i'w alw'n soak dau beiriant.
