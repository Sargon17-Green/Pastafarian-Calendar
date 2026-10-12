# Cam 13 — Archwiliad PATCH 06: adfer hanes cudd i prior

## Y ffiniau

- Gangen `Kotlin+Cymraeg`, sylfaen: `56bd7f882b9bb91aca8872860f51de1fa897965d`.
- Mae `LegacyPriorAdapter.legacyPrior` o Gam 12 yn aros **heb newid**,
  fel bod y tri `EXPECTED_RED` hanesyddol yn dal yn brofadwy.
- Mae `HiddenNearnessPatchWrapper.hiddenByNearness` o Gam 11 yn
  parhau i ddarllen `backwardHiddenStore[8-k]`; nid yw trefn ffisegol
  `hidden7..hidden1` yn newid.
- Ni chrëir diferion gweledig go iawn yng Ngham 13; dim gwaith Cam 14.

## Y cywiriad

Mae `PriorPatchWrapper.priorPatch(visibleStore,backwardHiddenStore,i,back)`
yn dechrau gyda `slot=i-back`.

1. Pan fo `slot>=1`, galwir **`LegacyPriorAdapter.legacyPrior` go iawn**.
   Rhaid i'r slot fod yn bodoli ac yn gynnwys gwerth. Nid oes angen storfa
   gudd ar y gangen hon; ni chaniateir llwybr cudd fel ei disodli.
2. Pan fo `slot<=0`, gosodir `hiddenK=1-slot` a galwir
   **`HiddenNearnessPatchWrapper.hiddenByNearness`**. Nid yw'r gangen
   hon yn galw `legacyPrior`, oherwydd nid yw'r helper raw yn gwybod
   am slotiau negyddol. Nid yw'r storfa backward yn cael ei haildrefnu.

Dychwelir `PriorPatchOutcome` gyda'r slot, `hiddenK` dewisol, ffynhonnell
y gangen, a'r gwerth union. Mae `BOOT → PATCH_06` yn adeiladu'r un
cyfrifon PATCH 02/03, cerrig PATCH 04 a storfa PATCH 05 â'r hen lwybr,
yna'n ymrwymo'r canlyniad a'r metadata yn **atomig** i gyd-destun y
galwad yn unig. Ni chofnodir metrigau PATCH 06 cyn llwyddiant.

## Tystion

- Gangen bositif: `i=2,back=1 → slot=1` yn cyfateb i'r oracl ac
  yn profi galwad wirioneddol i'r helper etifeddol.
- Mewnbynnau synthetig `i=4,back=1/3` yn darllen slot 3/1 hyd yn oed
  gyda storfa gudd wag.
- Ar `i=1`, mae `back=1..7` yn cyfateb yn union i
  `hidden1..hidden7` a gywirwyd.
- Mae'r tri achos Cam 12 `slot=0,-2,-6` yn parhau'n `EXPECTED_RED`
  ar y llwybr DISCOVERY 06 **heb newid**, ond yn GREEN ar PATCH 06.
- 35 gwerth cudd a 5 darlleniad positif dros 5 pâr diwrnod gan
  oracl `java.math.BigInteger` annibynnol, ynghyd â 175 cydran carreg.
- Gwiriadau drysau BOOT, ail-anfon, cyd-destunau annibynnol, dilysu
  sentinel, hyd storfa, ffiniau, a holl rag-brofion Camau 1–12.

**Prawf derbyn:** `sh run-stage13-tests.sh` ar Kotlin 1.9.0/JDK 21
gyda'r oracl gwreiddiol, cod ymadael 0 a `STAGE13_NATIVE_GREEN`.
Tan y dystysgrif hon, `LAST_COMPLETED_STAGE=12`.
