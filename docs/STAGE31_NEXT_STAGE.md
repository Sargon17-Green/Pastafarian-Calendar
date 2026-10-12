# Stage 31 पूर्ण — Stage 32 DISCOVERY 16 continuation

## Verified source of truth

Repository Sargon17-Green/Pastafarian-Calendar, branch ONLY `TypeScript+मराठी`. TOTAL_STAGES=55; **LAST_COMPLETED_STAGE=31**, current PATCH15 green, NEXT_STAGE=32 DISCOVERY16 expected-red. Do NOT start Stage33 PATCH16 in same response. Start from fresh GitHub live HEAD and read `DEVELOPMENT_STAGE.md`, `docs/STAGE31_PATCH15_VERIFICATION.md`, `src/patch15SignedGate.ts`, `src/discovery15LegacyPositiveGate.ts`, `src/patch14WideChoice.ts`, `test/normativeOracle.ts`, and authoritative 55-stage contract. Do not invent Stage32's specific historical defect from its ordinal; identify it in the contract first.

Stage31 implementation [commit 07ebb091](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/07ebb0917277c6d51f6d05d8e7cf9abf71d8aa9e), [CI run 38270609582](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38270609582): both jobs SUCCESS, native TypeScript typecheck, Stage1–31 regressions and all 15 historical expected-red scripts (including Stage30's verified intentional negative gate error). Frozen name catalog and lock PASS. CI job continues to bear old stage27 name but executes newest `npm test`.

## Canonical signed-gate repair

Foundation F=-15055671. Positive nth gate gap uses Sauce(F,F+n); negative nth gate gap MUST use Sauce(F,F-n), Bowl1 seal1 chooseRank N=922, resulting gap 41+rank in 42..963. Stage30 `LegacyPositiveOnlyGateQuestionAdapter.oldQuestionDay` still returns wrong F+abs(n), and Stage31 genuinely invokes it for every historical question. Production `patch15SignedGate` receives historical-positive ingredients AND independently supplied signed ingredients with verified targetDay. For positive steps reuse genuinely correct Stage30/29 predecessor output. For negative steps PHYSICALLY invoke a separate Stage29 `patch14WideChoice` using signed negative-day ingredients; no sign-only conversion or test-only oracle substitution. Both gap ledgers and both gate days retained. Underlying previous-stage 46 drops+12 stirs=58 real writes per predecessor, original Stage26 old modulo and Stage28 wrong short-only scars preserved.

Verified results:
```text
STAGE_31_PATCH_15_GUARDS_PASS signed=8 positive=4 negative=4 correctedWrong=0 oldWrong=4 oldMatches=4 historicalQuestions=20 correctedQuestions=20 actualPredecessors=30 sharedWrites=1740 oldCalls=4 signedCalls=4 dispatchCalls=6 injectedFailures=5
STAGE_31_PATCH_15_PROPERTIES_PASS gateCases=12 positive=6 negative=6 correctedWrong=0 oldWrong=6 oldMatches=6 historicalQuestions=42 additionalNegative=21 genuineCalls=63 genuineWrites=3654 varied=64 giant=8 ranks=720 unique=720 variants=792 variantCalls=1584 variantWrites=91872 totalCalls=1647 totalWrites=95526 streamWrong=0 rankWrong=0 oldRankWrong=0 oldQuestionWrong=0
```

## Stage32 development constraints

Exactly one discovery stage. Read true historical defect definition in project's 55-stage contract first; implement an executable but intentionally erroneous original method, using full real Stage31 preceding route where appropriate, independent reference proof, sixteenth standalone expected-red witness with exact marker, ownership/reentrant/rollback/huge integer coverage. Keep previous 15 historical expected-red scripts deliberately failing. Do not prematurely integrate `calendarDateSpaghetti` before Stage54; no Stage33 correction.

Pure TypeScript production, Marathi human docs/comments, names catalog and lock unchanged, no source/test oracle imported from other language branch. Use optimistic expected_sha fast-forward only, never force and never touch main/other branches. No HANDOFF_* files committed. No human action required.
