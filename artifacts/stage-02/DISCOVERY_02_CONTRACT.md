# Stage 2 / DISCOVERY 02 — per-invocation modulo-contexto

## Deveno
Ca esas nova sendependa implemento, aprobita da la uzanto.
Ol ne rekonstruas la perdita Stage2 delta-arkivo.
Stage1 calendarDateSpaghetti restas senmodifika. Ca stato ne
produktas la fina kvin-komponenta kalendarala rezulto.

## Kontrato
monster.stage02.context acceptas du signizita exakta BI entjeri,
calculationDay e targetDay. Ol konstruktas nova per-invocation
contexto. Du rezulto-keyi, normaligita modulo inter 1 e M:
normalizedCalculationDay = 1 + ((calculationDay - 1) mod M);
normalizedTargetDay = 1 + ((targetDay - 1) mod M).
Production uzas monster.stage02.normalize, ne la test-only nr.save.
Stato BOUNDARY_NORMALIZED; fazo MODULO_NORMALIZED; subPhase 2;
mode STAGE_2_DISCOVERY_02. Un metric e du logi por singla voko.
Mankanta inputo donas FAILED_VALIDATION sen normaligita rezulto.

## Native akcepto
28 fiksa input-pari (inkluzive 0, +/-M, M-1, M+1, 2M,
3M e 1000000*M) kun 14 asserti por paro: 392.
8 izolado/determinismo asserti, 4 invalida-inputo asserti,
2 kontrolaji di preciza nombro: 406 entute.
La oracle nr.save esas en test-zono sole.
Akcepto postulas completed native run kun marki:
STAGE_2_DISCOVERY_02_PAIRS_PASIS 28
STAGE_2_DISCOVERY_02_CHECKS_PASIS 406
STAGE_2_DISCOVERY_02_PASIS
NATIVE_STAGE_2_DISCOVERY_02_VERIFICATION=PASS
Plus originala Stage1 e Stage2/DISCOVERY01 regresio e verify,
omna completed SUCCESS sur la sama commit.
Stage 2 entere ne esas kompletigita. LAST_COMPLETED_STAGE=1.
