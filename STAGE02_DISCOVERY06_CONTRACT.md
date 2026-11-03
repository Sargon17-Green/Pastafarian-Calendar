# Stage 2 / DISCOVERY 06 — 46-ronda stone-serio (Logo / Ido)

Stato: KONTRATO_READY; nula implementation o Native PASS por Discovery06.
Prekondico: DISCOVERY05 ACCEPTED en completed Native 41712427420,
Stage1 41712427288 e verify 41712427305. LAST_COMPLETED_STAGE=1.

## Enigo / eligo

Nova Stage2-only proceduro `monster.stage02.stones :ctx` prenas
la valida, fresh context de `monster.stage02.workcounts`.
Se `status` ne esas `INTERMEDIATE_COUNTS_ONLY`, la proceduro
redonas `:ctx` netushita, inkluzive `FAILED_VALIDATION`.
Valida context obtenas `stoneSeries`: precize 46 elementi;
singla elemento esas precize 5 kanonala BI-entjeri (baz-10000,
little-endian), por i=1..46. Nula inter-invocation state esas permisita.

La unesma stone esas [17,29,43,71,101] (kvin BI valori).
Por i=2..46, de antea (w,b,s,m,r), nova:
w' = save(w*w + 3*b + i);
b' = save(b*b + 5*s + w);
s' = save(s*s + 7*m + b);
m' = save(m*m + 11*r + s);
r' = save(r*r + 13*w + m).
La `save` semanticajo esas 1-bazita modulo M, uzante nur
`monster.stage02.normalize` e la production `bi.*` operaci.
Omna ronda operacas sur la kompleta ANTEA quinteto, ne partiala
in-place updates. Nula `nr.stones` o altra test-only proceduro
esas vokata en production.

Valida eligo retenas calculationDay, targetDay, normaligo e la
kvin intermedia konturi; `phase=STONES_READY`,
`mode=STAGE_2_DISCOVERY_06`, `status=STONE_SERIES_ONLY`.
`metrics=[stage02.dispatch stage02.counts stage02.stones]` e
`logs=[stage02.enter stage02.normalized stage02.counts.ready stage02.stones.ready]`.
`calendarDateSpaghetti` e Stage1 validator ne esas modifikata;
nula fina kalendarala quinteto esas generata.

## QA-independeso e kontrakto

Test-only `nr.stones` (Appendix A) restas la sendependa
referenco; production devas usar altra modulala implemento kaj
nultempe vokar test-only kodon. 46 roundi x 5 valoro-kompari =
230 exakta asserti; plus 10 explicitita checks por:
(1) calculationDay preservita, (2) targetDay preservita,
(3) 5 intermedia conturi preservita, (4) phase,
(5) mode, (6) status, (7) metrics, (8) logs,
(9) repeated-call determinismo, (10) invalid-input context
redonita netushita. Totalo: 240 asserti, kun unika markers:
`STAGE_2_DISCOVERY_06_ROUNDS_PASIS 46`,
`STAGE_2_DISCOVERY_06_CHECKS_PASIS 240`,
`STAGE_2_DISCOVERY_06_PASIS`,
`NATIVE_STAGE_2_DISCOVERY_06_VERIFICATION=PASS`.

Boundary: fiksita 46 roundi, nula senlimita search, unika context
en la test; Native task timeout <= 300 seconds. Se la tempo esus
insuficanta, diagnozez la completed-log, ne sen-evidenca PASS.
Pre-execution static QA devas kontar 46x5+10, validar source-isolation
e retenar regressioni de Discovery01–05.

Acceptance nur pos completed SUCCESS Native Stage2 log kun exacta
markers e absento di failure-marker; completed SUCCESS Stage1 kun
`STAGE_1_TESTI_PASIS`; completed SUCCESS Canonical Names verify.
Nula merge/main o publika publication. Nula kopiado de altra branch.
