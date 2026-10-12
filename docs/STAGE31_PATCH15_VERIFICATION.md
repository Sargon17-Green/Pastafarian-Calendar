# Stage 31 — PATCH 15: signed negative gate

F=-15055671. Correct gate question is Sauce(F,F+s) for each nonzero signed step s. Each gap is 41+rank, where Bowl 1, seal 1, N=922. The original historical Stage30 oldQuestionDay(s)=F+abs(s) is unchanged and genuinely called for every legacy gap.

The new handler takes two complete source sequences: original positive-side source ingredients, and correct signed-side ingredients with an explicit targetDay. It runs the full Stage30 chain first. Positive gates reuse that already-correct Stage29 predecessor result; negative gates physically call another full Stage29 predecessor at F-n. Each actual predecessor performs 58 shared writes. The corrected gate accumulates signed correct gaps. Both historical and corrected gate days and gap ledgers remain visible. Test-only oracle is not imported by production; input preflight and transactional outer commit preserve failure rollback.

Guards: 8 true signed gates ±1..±4, 30 full predecessor calls, 1740 shared writes, five injected failure points, independent context and Stage54 barrier. Properties: 12 true signed gates ±1..±6, 63 full predecessor calls; 792 additional explicitly noncanonical mutated negative-side vectors (64 varied, 8 enormous signed, 720 distinct DROP46 orders), each with both historical and new corrected predecessor; 1647 property-suite calls, 95526 real shared writes. Independent normative GateEngine validates actual signed indices, and independent test-only bowl replay validates synthetic vectors. Prior 15 intentional RED tests remain unchanged.

Status: CI pending, LAST_COMPLETED_STAGE=30. Stage32 not started.
## GitHub Actions verified — 2026-10-12

[Stage31 implementation 07ebb091](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/07ebb0917277c6d51f6d05d8e7cf9abf71d8aa9e), [workflow run 38270609582](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38270609582): `verify` and the legacy-named `stage27-typescript-marathi` SUCCESS, native TypeScript typecheck, Stage1–31 native regression and all 15 archived intentional expected-red checks.

```text
STAGE_31_PATCH_15_GUARDS_PASS signed=8 positive=4 negative=4 correctedWrong=0 oldWrong=4 oldMatches=4 historicalQuestions=20 correctedQuestions=20 actualPredecessors=30 sharedWrites=1740 oldCalls=4 signedCalls=4 dispatchCalls=6 injectedFailures=5
STAGE_31_PATCH_15_PROPERTIES_PASS gateCases=12 positive=6 negative=6 correctedWrong=0 oldWrong=6 oldMatches=6 historicalQuestions=42 additionalNegative=21 genuineCalls=63 genuineWrites=3654 varied=64 giant=8 ranks=720 unique=720 variants=792 variantCalls=1584 variantWrites=91872 totalCalls=1647 totalWrites=95526 streamWrong=0 rankWrong=0 oldRankWrong=0 oldQuestionWrong=0
```

LAST_COMPLETED_STAGE=31. Stage32 DISCOVERY16 not started. The stage27 job label is historical metadata only; current npm test actually runs all 31 stages.
