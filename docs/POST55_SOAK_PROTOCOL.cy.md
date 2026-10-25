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
