# Archwiliad Cam 3 — Patch 01

## Ffynhonnell a therfyn y newid

Mae'r newid yn dechrau o commit `9d096a2fe12316629e3bde858b284e9873edb871`
yn y gangen `Kotlin+Cymraeg`. Nid yw'r addasydd
`LegacyRemainderAdapter.oldRemainder` na phrofion Cam 2 wedi'u golygu.
Mae'r cyfeirnod normadol yn parhau mewn `src/test` yn unig.

## Llwybr y darn

`MonsterBootstrapManager.applySavePatch` → `BOOT` → `PATCH_01` →
`LegacyRemainderAdapter.oldRemainder` → `SavePatchWrapper.savePatch`.

Mae'r swyddogaeth lapio'n derbyn gweddill etifeddol yn ystod `[0, M)`.
Mae'n mapio `0` i `M`; mae pob gweddill arall yn aros fel y mae.
Gwirir yr ystod ar ffin yr addasydd. Mae pob galwad yn creu cyd-destun
newydd sy'n cadw'r mewnbwn, allbwn etifeddol, allbwn wedi'i gywiro,
a llwybr y digwyddiadau. Nid yw metrigrwydd yn penderfynu'r canlyniad.

## Tystion gorfodol

| Mewnbwn | Hen graith | Patch 01 | SAVE normadol |
|---|---:|---:|---:|
| `M` | `0` | `M` | `M` |
| `2M` | `0` | `M` | `M` |
| `3M` | `0` | `M` | `M` |
| `M+1` | `1` | `1` | `1` |

Y cyflwr cywir yw tri gwahaniaeth yn `DISCOVERY_01`, **sero** yn
`PATCH_01`. Mae'r prawf coch caeth blaenorol yn methu yn fwriadol,
a rhaid i'r sgript gyffredinol ei gydnabod yn fethiant disgwyliedig.

## Gorchudd y profion

- 66 prawf gwreiddiol Cam 1 a'r prawf Cam 2 llawn, drwy `run-stage02-tests.sh`.
- 195 achos cyfnodol: `k=-32..32`, gweddillion `0`, `1`, `M-1`.
- Saith achos ffin: `-3M`, `-M`, `-M+1`, `-1`, `0`, `1`, `M-1`.
- 129 achos pell neu amrywiol, gan gynnwys rhifau y tu hwnt i 256 did.
- Priodoli mewnbynnau/allbynnau i'r cyd-destun; prawf annibyniaeth rheolwyr.
- Gwrthod galwad `PATCH_01` heb gwblhau BOOT neu heb fewnbwn.
- Gwrthod mewnbynnau annilys i'r deunydd lapio (`-1`, `M`, `M+1`).
- Rhedeg Cam 2 eto i brofi nad yw'r graith hanesyddol wedi'i dileu.

## Gwirio hyd yma

**PASS mewn preflight Kotlin yn unig:** llwyddodd y profion Cam 2
ac yna'r profion Cam 3 gan ddefnyddio amnewidion ar wahân ar gyfer
`ExactInt` a `NormativeCore`. Mae'r logiau a chod yr amnewidion
yn `HANDOFF_ONLY`, nad yw'n rhan o'r delta ystorfa.

**PENDING:** ail-redeg `sh run-stage03-tests.sh` yn y goeden
Kotlin+Cymraeg go iawn, gyda'r pum blob gwreiddiol Cam 1 a'r
mopheth llawn. Rhaid i bob marc diwedd ymddangos a rhaid i'r cod
ymadael fod yn sero. Hyd hynny: `LAST_COMPLETED_STAGE=2`.

**Heb ei gynnwys:** y canfyddiad ar wahân ar `ExactInt.toLongExact()`
gydag `Long.MIN_VALUE`. Ni ddylid ei guddio o fewn Patch 01.
