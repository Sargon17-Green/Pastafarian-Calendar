# Stage 2 / DISCOVERY 03 — exakta dayCount e work-counts (NEXT)

## Limo
Nova production pipeline solo en Logo; nula importo de test-only
normativa reference. SourceLanguageCatalog restas frozita.
calendarDateSpaghetti dil Stage1 ne shanjesas. Nula rezulto de
ca intermediate grado devas esar prezentita kom la kalendara kvinoplo.

## Kontrato
Inputo: du signizita exakta BI entjeri (calculationDay,targetDay).
F = nr.foundation. DayCount(d):
  se d = F, 1;
  se d > F, 2 * (d - F) + 1;
  se d < F, 2 * (F - d).
Distance = abs(targetDay - calculationDay) + 1;
Connection = DayCount(calculationDay) + DayCount(targetDay);
Direction = 1 se targetDay < calculationDay, 2 se egala,
3 se targetDay > calculationDay.
Outputo: nova per-invocation context kun 2 modulo-valori de
DISCOVERY02 plus 5 intermediate work-counts (4 BI e direction).
Production implementation devas esar sendependa de
nr.day.count e nr.work.counts en test-only normative_reference.logo.

## Verifikado
Test-only oracle: nr.work.counts de Appendix A.
Minime 24 determinista pari ink. F, F+1, F-1, negativi,
egala inputo, negativa/pozitiva transpaso, granda BI inputo.
Aparte kontrollar signizita distanco, 1-based distance,
direction 1/2/3, monotone/parity de dayCount, isolation di
3 invocationi, absence de cross-call state, Stage1 regression,
DISCOVERY01 e DISCOVERY02 regressions. Native completed/log
bezonas novan PASS marker e verify sur sama SHA.

Nula via de previous historical lost archive esas necesa.
