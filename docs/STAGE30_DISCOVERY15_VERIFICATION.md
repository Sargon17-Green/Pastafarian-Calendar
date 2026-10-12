# Stage 30 DISCOVERY15 — जुना ऋण-द्वार प्रश्न चुकीच्या बाजूला

## Canonical oracle and historical scar

From independent `test/normativeOracle.ts` `NormativeOracle`:
- `gateDay(0)=FOUNDATION=-15055671`.
- For positive index +n, the n-th gap is `41+chooseRank(askBowl(sauce(F,F+n),1,1),922)`, and gates advance right by this gap.
- For negative index -n, the n-th gap is `41+chooseRank(askBowl(sauce(F,F-n),1,1),922)`, and gates move left.
- Each individual gap lies in 42..963; cumulative gate days sum n genuine gaps, not 365-day approximations.

Stage30 `LegacyPositiveOnlyGateQuestionAdapter.oldQuestionDay(signedStep)` **intentionally uses `F+abs(signedStep)` for both signs**, unchanged; standalone production handler `Discovery15PositiveSideGateHandler` executes the original bad day question and real `patch14WideChoice` 58-write predecessor for *each* gap. The legacy gate location is `F+sum(gaps)` for positive indices and `F-sum(wrongPositiveGaps)` for negative indices. The returned `normativeTargetDay` is only a diagnostic expected-question coordinate; Stage30 deliberately does not perform a corrected negative-side call, which belongs to Stage31.

The external caller supplies each question's 46 visible drops, 46 stone rows and six starting bowls (same input convention as Stages25–29). Each supplied question must be generated for the **historical positively asked** day. The production stage never imports the independent test-only normative oracle.

## Verification

- `test/discovery15.ts`: signed ±1..±4 gates, independently computed signed gate days, 20 genuine positive-side questions and 1,160 historical shared writes; required independent mismatches for -1 and -2, positive correctness, real prior chain, actual old method and actual Patch14 dispatch spies, invalid/non-ready contexts, incomplete second query preflight, three fault-injected rollback cases, same-context retry, reentrancy, Stage54 barrier.
- `test/discovery15Properties.ts`: ±1..±6 genuine gate days, 42 genuine predecessor calls, plus 64 synthetic variations, 8 giant signed cases, and all 720 distinct DROP46 permutations on a one-gap historical negative-side question. Synthetic injected drops are explicitly noncanonical and compared against an independently transformed final-bowls oracle, not mislabeled as real calendar dates. Expected 834 genuine predecessor executions total, 48,372 real shared memory writes, independent full-rank and stream comparison.
- `test/discovery15Red.ts`: two truly negative gate witnesses (-1,-2) against canonical GateEngine; must exit nonzero with `DISCOVERY_15_EXPECTED_RED mismatches=2 matches=0 gates=-1,-2 asked=FOUNDATION+abs`. `test/verifyDiscovery15ExpectedRed.mjs` enforces this marker and exit as a fifteenth expected RED in ordinary `npm test`; previous fourteen remain untouched.
- Existing workflow's historically named stage27-typescript-marathi job still runs the current full `npm test`; independent `verify` job checks frozen name lock. Stage30 can close only after both succeed; Stage31 deliberately deferred.

**Submission status: no CI success claim yet, LAST_COMPLETED_STAGE=29.**

## GitHub Actions actual success — 2026-10-12

Final verified implementation [commit 0070e91a](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/0070e91a6f5e685f7692b79bd3e0f4452af2e258). [CI run 38265673925](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38265673925) completed: both `verify` and the legacy-named `stage27-typescript-marathi` SUCCESS. The latter ran the complete Stage1–30 native TypeScript suite, with all prior 14 expected-red checks plus 15th red verifier.

```text
STAGE_30_DISCOVERY_15_GUARDS_PASS signed=8 positive=4 negative=4 oldWrong=4 oldMatches=4 actualQuestions=20 sharedWrites=1160 oldMethodCalls=2 dispatchCalls=2 injectedFailures=3
STAGE_30_DISCOVERY_15_PROPERTIES_PASS realCases=12 positive=6 negative=6 oldWrong=6 oldMatches=6 genuineCalls=42 genuineWrites=2436 varied=64 giant=8 ranks=720 unique=720 variants=792 variantWrites=45936 totalCalls=834 totalWrites=48372 streamWrong=0 gapWrong=0
STAGE_30_DISCOVERY_15_EXPECTED_RED_VERIFIED nonzero=1 mismatches=2 matches=0 gates=-1,-2
```

**LAST_COMPLETED_STAGE=30**, Stage31 PATCH15 not started. The CI job label is administrative historical naming, not an omission of Stage30 tests.
