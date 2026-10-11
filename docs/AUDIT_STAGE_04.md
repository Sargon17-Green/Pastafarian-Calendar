# Archwiliad Cam 4 — Darganfod 02 (Kotlin + Cymraeg)

## Gofyniad a tharddiad

**Cam presennol:** 4 / `DISCOVERY 02`; **cam olaf wedi'i gwblhau cyn hyn:** 3.
**Commit sylfaen:** `020ebdb43fb40feec9ef1db3e270edd8ad725bad`.
Mae ffeiliau oracl Cam 1, `ExactInt.kt`, catalog yr enwau, a
`Stage01Tests.kt` yn parhau â'u blob SHA gwreiddiol. Mae sgript Cam 2
yn gwirio tarddiad y pum ffeil gorfodol cyn gwneud unrhyw brofion.

## Diffyg wedi'i gyflwyno a'i gadw

Cyfrifiad etifeddol ar wahân, heb ddibyniaeth ar `NormativeCore`:

```text
F = -15055671
oldDayTag(day) = 2 * abs(day - F)
```

Mae `MonsterBootstrapManager.observeLegacyDayTag` yn darparu'r llwybr
cynhyrchu: `BOOT → DISCOVERY_02 → LegacyDayTagAdapter.oldDayTag`.
Cofnodir `discovery02Input`, `discovery02Output`, statws, diagnosteg,
olrhain a metrig ar ôl llwyddiant; nid yw unrhyw wybodaeth gyfrifiannol
yn cael ei chadw mewn cyflwr semantig byd-eang.

Dim ond mewn cod prawf y ceir `NormativeCore.dayCount`:

```text
if day < F:  2 * (F - day)
if day >= F: 2 * (day - F) + 1
```

## Tystion normadol

| Mewnbwn | Hen allbwn | Allbwn normadol | Canlyniad |
|---|---:|---:|---|
| F−2 | 4 | 4 | MATCH |
| F−1 | 2 | 2 | MATCH |
| F | 0 | 1 | EXPECTED_RED |
| F+1 | 2 | 3 | EXPECTED_RED |
| F+2 | 4 | 5 | EXPECTED_RED |

Mae'r sgript yn gofyn am `STAGE04_EXPECTED_RED_3`, `STAGE04_MATCH_2`
a `STAGE04_STRICT_RED_CONFIRMED`; rhaid i'r broses gyffredinol orffen
â chod ymadael 0 wrth weld y methiant bwriadol hwnnw.

## Arferion gwarchod

- Gwrthod llwybr cyn `BOOT` a chyd-destun heb fewnbwn; dim allbwn rhannol.
- Profi bod rhestrau olrhain a diagnosteg yn perthyn i bob galwad ar wahân.
- Profi bod `PATCH_01` a `DISCOVERY_01` yn aros yn weithredol a chywir yn ôl eu contractau.
- Profi pob diwrnod yn ystod `[F−165,F+165]`: 165 MATCH a 166 EXPECTED_RED.
- Profi pedwar achos pell, gan gynnwys cyfanrifau 251 digid.
- Cadw'r hen ddiffyg mewn gweithrediad cynhyrchu; **dim PATCH 02**.
- Gwneud cyfosodiad Kotlin a phrofion ar ffeiliau gwreiddiol y gangen yn unig.

## Statws

Canlyniadau rhedeg gwirioneddol yr archwiliad hwn sy'n penderfynu
pryd y gall `LAST_COMPLETED_STAGE` newid i 4. Nid yw bodolaeth cod na
preflight ar ei ben ei hun yn ddigon. Nid oes unrhyw newid pell na push
wedi'i wneud gan y pecyn hwn.

## Canlyniad rhedeg brodorol terfynol — 11 Hydref 2026

Rhedwyd `sh run-stage04-tests.sh` yn erbyn y cod Kotlin dilys a phum ffeil
oracl Cam 1 â'u blob SHA gwreiddiol. **Cod ymadael: 0.**
Cadarnhawyd `STAGE01_PASS_66`, `STAGE02_EXPECTED_RED_3`,
`STAGE03_PATCH_GREEN_0`, `STAGE03_EXTENDED_BIGINT_GREEN_921`,
`STAGE04_EXPECTED_RED_3`, `STAGE04_MATCH_2`,
`STAGE04_RANGE_RED_166_MATCH_165` a
`STAGE04_STRICT_RED_CONFIRMED`.

**Cam 4: COMPLETE / EXPECTED_RED.** `LAST_COMPLETED_STAGE=4`.
Y cam nesaf yn unig yw Cam 5 — PATCH 02. Ni newidiwyd prif gangen GitHub.


## Estyniad v002 — metamorffiaeth ac ail-anfon

Profir 30 maint positif a'r ddwy ochr i'r Sylfaen: cyfanswm o 60
achos. Rhaid i'r hen gyfrifiad gadw `2*abs(day-F)` ac i'r oracl brofi
`old + 1` ar ôl `F`, heb newid yr ochr cyn `F`. Mae'r gwiriadau hefyd
yn profi bod dewis y diwrnod yn annibynnol ar y ddau rif dydd arall.

Profir ail-anfon yr un cyd-destun ar ôl cwblhau DISCOVERY_02: rhaid i'r
dosbarthwr wrthod â `E_DISCOVERY02_CONTEXT_NOT_READY` heb lygru
allbwn, rhestrau na metrigau. Mae gwarchodaeth y sgript
`run-stage04-tests.sh` yn mynnu'r marciau
`STAGE04_WIDE_METAMORPHIC_PASS_60` a
`STAGE04_REPLAY_REJECTION_PASS` yn ogystal â'r holl farciau blaenorol.


## Ail-redeg brodorol v002

Ar ôl ychwanegu'r achosion ychwanegol, ail-redwyd yr **union ffeiliau
terfynol** trwy `sh run-stage04-tests.sh`; cod ymadael `0`.
Cadarnhawyd holl farciau Camau 1–3, ynghyd â
`STAGE04_EXPECTED_RED_3`, `STAGE04_MATCH_2`,
`STAGE04_WIDE_METAMORPHIC_PASS_60`,
`STAGE04_REPLAY_REJECTION_PASS`,
`STAGE04_STRICT_RED_CONFIRMED` a
`STAGE04_NATIVE_EXPECTED_RED_PASS`. Dim newid i gynhyrchu nac i'r
oracl; cedwir yr anghysondeb bwriadol yn union dri thyst.


## Estyniad v003 — oracl rhifyddeg annibynnol

Yn wahanol i'r profion metamorffig blaenorol, nid yw'r disgwyliadau
rhifyddol yma'n dibynnu ar weithrediadau `ExactInt` o gwbl. Mae prawf
JVM annibynnol yn cyfrifo'r ddau werth gydag `BigInteger`:

```text
hen      = 2 * abs(day - F)
normadol = hen + (1 os yw day >= F, fel arall 0)
```

Mae'r prawf yn cymharu'r ddau werth yn erbyn `ExactInt`, yr oracl
`NormativeCore.dayCount` a'r handler `DISCOVERY_02` o'r dosbarthwr.
Ar gyfer y 409 mewnbwn, disgwylir 204 MATCH a 205 EXPECTED_RED.
Mae'r prawf hefyd yn gwirio olrhain y llwybr, y metrigau a chadw cyflwr
y cyd-destun cyntaf. Nid yw'n galw `BigInteger` mewn cynhyrchu, ac nid
yw'n cyfrif y profion estynedig fel tystion canonaidd newydd.

Nid oes unrhyw newid i'r hen algorithm nac i'r mopheth normadol.

## Ail-redeg brodorol v003

Ail-redwyd y cod terfynol ar y bum ffeil sylfaen oracl, gan gadw'r
un blob SHA ac atal amnewidion. **Cod ymadael: 0.** Cadarnhawyd
`STAGE01_PASS_66`, `STAGE02_EXPECTED_RED_3`,
`STAGE03_EXTENDED_BIGINT_GREEN_921`, `STAGE04_EXPECTED_RED_3`,
`STAGE04_MATCH_2`, `STAGE04_BIGINT_INDEPENDENT_PASS_409`,
`STAGE04_BIGINT_RED_205_MATCH_204` a
`STAGE04_STRICT_RED_CONFIRMED`.
Nid yw'r estyniad wedi cyflwyno cod o Gam 5.
