# Stage 30 पूर्ण — Stage 31 PATCH 15 continuation

## Current state

Repository `Sargon17-Green/Pastafarian-Calendar`; **only branch `TypeScript+मराठी`**. Of 55 stages, LAST_COMPLETED_STAGE=30, current DISCOVERY15 expected red, next sole stage **31 PATCH15**. Do NOT work on Stage32 DISCOVERY16 in same turn. Always read live branch HEAD, `DEVELOPMENT_STAGE.md`, `docs/STAGE30_DISCOVERY15_VERIFICATION.md`, `src/discovery15LegacyPositiveGate.ts`, `src/patch14WideChoice.ts`, `test/normativeOracle.ts`, and this continuation first.

Stage30 implementation commit `0070e91a6f5e685f7692b79bd3e0f4452af2e258` and [GitHub Actions 38265673925](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38265673925): both jobs SUCCESS; TypeScript tsc, full Stage1–30 tests, historical 15 expected-red proofs and frozen names lock. Existing CI second job still has old stage27 job label, but executes current full `npm test`.

## True gate semantics vs wrong historical method

`FOUNDATION_DAY=-15055671n`; for positive index n>0 the canonical gap is `41+chooseRank(askBowl(sauce(F,F+n),1,1),922)`, and gates extend right. For negative index -n the canonical gap is `41+chooseRank(askBowl(sauce(F,F-n),1,1),922)`, gates extend left. Gaps 42..963, cumulative n gaps for each gate index.

Stage30 production `LegacyPositiveOnlyGateQuestionAdapter.oldQuestionDay(step)` **intentionally returns F+abs(step)** for both signs. `Discovery15PositiveSideGateHandler` calls this old helper for every step and physically runs real Stage29 `patch14WideChoice` (58 shared writes, Stage26 old modulo, Stage25 DROP46 successor, Stage28 old short-only scar) with the **wrong positively queried source ingredients**; for negative -1,-2 this demonstrably differs from independent canonical GateEngine. It returns historicalGateDay based on incorrect positive-side gaps. Keep old helper unchanged and ACTUALLY invoked by Stage31 for forensics. Do not alter or remove earlier expected-red script `test/discovery15Red.ts`.

Stage31 must add separate corrected production gate-side question routing. For each step +n query F+n; each step -n query F-n. Actual corrected negative question needs its own 46 visible drops, stones, initial bowls derived from the proper negative target. Use true production Stage29 path, not the test-only normative oracle, to select each gap; build cumulative gate days with signed side. Preserve the **historical actual old method call** and old wrong-side evidence independently. The Stage30 API takes a series of positive-side question source ingredients; Stage31 may explicitly accept both historic positive-side and corrected signed-side ingredients (or another well-validated source factory), but production may not import test-only `test/normativeOracle.ts`. Preserve fault rollback and input ownership.

## Verified witness logs

```text
STAGE_30_DISCOVERY_15_GUARDS_PASS signed=8 positive=4 negative=4 oldWrong=4 oldMatches=4 actualQuestions=20 sharedWrites=1160 oldMethodCalls=2 dispatchCalls=2 injectedFailures=3
STAGE_30_DISCOVERY_15_PROPERTIES_PASS realCases=12 positive=6 negative=6 oldWrong=6 oldMatches=6 genuineCalls=42 genuineWrites=2436 varied=64 giant=8 ranks=720 unique=720 variants=792 variantWrites=45936 totalCalls=834 totalWrites=48372 streamWrong=0 gapWrong=0
STAGE_30_DISCOVERY_15_EXPECTED_RED_VERIFIED nonzero=1 mismatches=2 matches=0 gates=-1,-2
```

Stage31 QA must prove zero corrected differences against independent GateEngine for signed ±1,±2 and larger gate indices; preservation of historical mismatches on -1,-2; real 58-write predecessor for each corrected gap, exact cumulative side, real negative sauce calls, 15 old reds still intentionally fail; 720 DROP46 permutations, huge signed values, mutation isolation, invalid inputs, failure rollback. Final `calendarDateSpaghetti` remains disabled until Stage54. Only after both CI jobs PASS may LAST_COMPLETED_STAGE become 31.

Pure TypeScript production and Marathi human docs/comments, SourceLanguageCatalog and frozen `CANONICAL_NAMES_LOCK.sha256` untouched. Use optimistic expected_sha fast-forward only, never force, never modify main or other branches; do not commit user-only HANDOFF_* archives.
