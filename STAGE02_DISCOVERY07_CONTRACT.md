# Stage 2 / DISCOVERY 07 — 7 hidden-seed BI valori (Logo / Ido)

Stato: ACCEPTED_NATIVE (2026-11-04). Run 41872294990/job 126722352207 completed SUCCESS with 5 contexts / 53 checks on SHA 3e56c8ab5d800a9e9b8d8652d664eb295b9f0a97; Stage1 41872294983 and Canonical Names 41872294959 also completed SUCCESS. LAST_COMPLETED_STAGE=1.
Prekondico: DISCOVERY06 ACCEPTED sur commit `342e740e830108da40f3da92d147328e1c77e874`.
Native Stage2 41870469940/job 126715826531 completed SUCCESS,
46 stone-rondi/240 asserti, plus 128 fast-divmod asserti;
Stage1 41870469866/job 126715826423 e verify 41870469889 SUCCESS.
LAST_COMPLETED_STAGE=1.

## Enigo, eligo, side-effect guardilo

Nova Stage2-only `monster.stage02.hidden :ctx` prenas fresh context
post `monster.stage02.stones`, kun `status=STONE_SERIES_ONLY`,
`phase=STONES_READY`, `stoneSeries` de precize 46 kanonala
5-BI quinteti, e la kvin exacta intermedia conturi:
`actionCount`, `targetCount`, `distanceCount`,
`connectionCount`, `directionCount`.
Se status ne esas `STONE_SERIES_ONLY`, la proceduro redonas
`:ctx` netushita (inkluzive FAILED_VALIDATION e
INTERMEDIATE_COUNTS_ONLY). Nula inter-invocation state.

Valida context obtenas `hiddenSeeds`: precize 7 kanonala BI
entjeri en [1,M], kun `phase=HIDDEN_READY`,
`mode=STAGE_2_DISCOVERY_07`, `status=HIDDEN_SEEDS_ONLY`.
La originala dates, normaligo, 5 workcounts e tota `stoneSeries`
restas identa. `metrics` appendas `stage02.hidden`, e
`logs` appendas `stage02.hidden.ready`, un foyo sole.
Nula fina kalendarala outputo, Stage1 API o validator ne chanjesas.

## Exakta normativa algoritmo (Appendix A)

`save(z) = 1 + ((z - 1) mod M)`, kun exacta positive modulus
e kanonala base-10000 little-endian BI. Por k=1..7 uzez la
k-esma stone-quinteto `S[k]` e coefficients
`C[k]=[a,b,c,d]` de la fiksita tabelo:

| k | a | b | c | d |
|---|---|---|---|---|
| 1 | 3 | 4 | 6 | 8 |
| 2 | 5 | 7 | 10 | 12 |
| 3 | 7 | 10 | 14 | 16 |
| 4 | 9 | 13 | 18 | 20 |
| 5 | 11 | 16 | 22 | 24 |
| 6 | 13 | 19 | 26 | 28 |
| 7 | 15 | 22 | 30 | 32 |

Fixita kind-sequenco por singla k esas [1,2,3,4,5,1,2].
Notante A=actionCount, T=targetCount, D=distanceCount,
C=connectionCount, R=directionCount, komence:

`x[0] = save(A + a*T + b*D + c*C + d*R + sum(S[k][1..5]))`

Por g=1..7, uzante `kind[g]` del sequenco:

`x[g] = save(x[g-1]^2 + 3*x[g-1] + S[k][kind[g]] + g)`

`hiddenSeeds[k] = x[7]`. Omna rondo esas exacta aritmetiko;
modulo aplikacesas pos singla grind, ne sole en fino.
Production NE darf vokar `nr.hidden.build`, `nr.hidden.one`,
`nr.hidden.grind`, o test-only `nr.*` algorithmic oracle.
Reuzar shared exact BI primitives e production normalization
esas permisita, kun aparta production hidden algorithm.

## QA: sendependa Oracle, nombri, limiti

Test-only oracle: `nr.hidden.build` in
`test/normative_reference.logo`, kun sendependa
`nr.work.counts` e `nr.stones` por expected values.
Nula kopiado di test-only algorithmic implementation in production.

Tri valida, determinista contexti, qua obtenesas tra
`monster.stage02.workcounts` -> `monster.stage02.stones`:
(A) calculationDay=bi.zero, targetDay=bi.small 1;
(B) calculationDay=nr.foundation, targetDay=nr.tablets;
(C) calculationDay=bi.neg nr.M, targetDay=nr.M.

Por singla valida context: 7 BI value-comparisons kun normativa
oracle (21 totalo), plus 9 asserts pro context (27 totalo):
(1) calculationDay, (2) targetDay, (3) two normalizations + five
intermediate counts together, (4) full stoneSeries intact,
(5) phase, (6) mode, (7) status, (8) metrics, (9) logs.
Un repeated-call determinism assertion por valida context (3).
Du malvalida contexts, FAILED_VALIDATION e
INTERMEDIATE_COUNTS_ONLY, redonacesas identa (2 asserts).
**53 total** = 21 + 27 + 3 + 2.
Test markers:
`STAGE_2_DISCOVERY_07_CASES_PASIS 5`,
`STAGE_2_DISCOVERY_07_CHECKS_PASIS 53`,
`STAGE_2_DISCOVERY_07_PASIS`;
CI marker: `NATIVE_STAGE_2_DISCOVERY_07_VERIFICATION=PASS`.

La D7 test step devas havar striktan `timeout` <= 650s, e tota job
<= 30 minutes inkluzive pinita UCBLogo build e D8. Nula endless search.
La 2026-11-04 run 41879013512 job 126746318536 sur SHA 34a966d9
finis per exit 124 pos 420s sen finala D7 markeri; antea la sama D7
source/test sur 3e56c8ab finis 53/53 en circa 251s. Ca esas
runtime-variance hard-timeout, NE pruvas algoritmo-manko; CASE_BEGIN/END
markeri informas pri preciza progresi. Ca reviso NE deklaras PASS.
Akcepto NUR per completed SUCCESS Native Stage2 log kun exacta
markers, absento de failure/exception markers, e la D1–D6
regressioni; completed SUCCESS Stage1 originala native tests e
Canonical Names Lock sur la sama implementation SHA.
Nula main/merge; LAST_COMPLETED_STAGE=1 til Stage2 plena acceptance.
