# Stage 2 / DISCOVERY 05 — Exakta BI input-formo (Logo / Ido)

Stato: KONTRATO_READY; nula code-change/nativa PASS por Discovery05.
La antea Discovery01–04 esas acceptita nur per completed Native/verify
logi, ne per spekulativa bug-raporti.

## Enigo / eligo

L'enigo esas du reprezentaji di BI entjero, `calculationDay` e
`targetDay`. La normativa reprezentajo havas formo
`[sign [d0 d1 ... dk]]`, kun baz-10000 little-endian ciferi:

- zero esas precize `[0 [0]]`;
- nonzero sign esas +1 o -1; magnitude-listo ne esas vakua;
- singla cifero esas integra nombro inter 0 e 9999;
- la lasta cifero di nonzero magnitude ne esas zero;
- sign, ciferi e listo-strukturo ne esas automatike konvertata.

Valida enigo devas donar sama context e sama kvin intermedia konturi
kam `monster.stage02.workcounts` en Discovery03/04, sen test-only
oracle-voko en production. Nevalida enigo devas donar determinista
`FAILED_VALIDATION` con `phase=FAILED_VALIDATION`, sen crascho,
sen modulo/workcounts, e sen trans-invocation state. La originala
inputo ne esas mutacata. Stage1 `calendarDateSpaghetti` restas
netushita; la fina kalendarala kvinoplo ankor ne esas implementata.

## Injenierala metodo

Addicionez Stage2-only input shape guard ante la BI operaci; ne
shanjez la neutrala Stage1 validator. La production validator devas
checkar sign/ciferi per rekursiva formo-kontrolo; la test-only oracle
devas usar sendependa enumeracio/generilo de canonical BI valori.
Nula cross-implementation fixture/code esas permisita.

## Mezurebla test-kontrato

24 determinista input-kazi (12 valida, 12 nevalida), 8 asserti per
kazo = 192 checks. La valida parti inkluzas zero, +1, -1,
foundation, tablets, +/-M, +/-1000M e alta multi-cifera BI.
La nevalida parti inkluzas vakua/absenta inputo, mala sign,
nekonforma listo, vakua magnitude, negativa cifero, cifero 10000,
leading high zero, neintegra cifero e nekonvertebla vorto.
Kontrolo di output-statuso, context-field preservation,
metric/log isolation, nula production-oracle, e canonical representation
esas obligatoriya. Test-only oracle esas separata de production guard.

Acceptance gates: `STAGE_2_DISCOVERY_05_CASES_PASIS 24`,
`STAGE_2_DISCOVERY_05_CHECKS_PASIS 192` e
`NATIVE_STAGE_2_DISCOVERY_05_VERIFICATION=PASS` en completed SUCCESS
Native Stage2 job/log; native Stage1 regression completed SUCCESS kun
`STAGE_1_TESTI_PASIS`; Canonical Names verify completed SUCCESS;
regression de Discovery01–04 sen red marker. Un failed test esas
bug-investigado nur pos reproduktita execution-edo, ne anticipita
expected-red. Nula merge/main/publication.
