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
