# Stage 36 — DISCOVERY18: genuine old 365-day jump, diagnostic only

## Historical contract

The authoritative 55-stage contract states that the historical estimate `oldJumpGuess(anchor,targetDay)` calculates `anchor.number + floorDiv(targetDay-anchor.firstDay,365)`. The actual calendar has year lengths from 252 to 5778 days, with variable selection and continuity through real gate boundaries. Therefore dividing by a Gregorian-like 365 is **not** an authoritative year transition. Preserve the mistake as real executed historical code. The Stage37 PATCH18 repair will later walk `nextYear` / `previousYear` one complete year at a time. This **has not been implemented in Stage36**.

`src/discovery18LegacyJump.ts` adds a real `Legacy365JumpGuessAdapter.oldJumpGuess`, using exact bigint mathematical floor division on negative as well as positive deltas. `Legacy365JumpDiagnostic.measure` physically invokes this wrong method and emits a frozen result: quoted year number and signed-day quotient, and `knownAnchorMismatch` only when the target actually lies in the recorded anchor interval. It explicitly marks `role=TELEMETRY_ONLY`, `authoritativeTraversalPerformed=false` and `authoritativeTargetYearResolved=false`. There are no production `nextYear` or `previousYear` computations in this stage.

`Discovery18JumpHandler` physically invokes full `patch17Year5000Tie`, preserving all earlier Stage1–35 old scars, signed real opening-gate questions, original Stage32 5781 acceptance, Stage33 corrected 5778, Stage34 wrong length-only sorting and Stage35 equal-length-run correction, and all true Stage29 Bowl1/seal10 selection questions. The guessed anchor has `number=5000n`, `firstDay=selected.openGateDay+1` and `lastDay=selected.closeGateDay`. Crucially, the estimate **never becomes the year number used by the original Stage35 producer, cannot choose a gate, and does not control a transition**. Original selected candidate and all frozen predecessor ledgers are preserved, and only the outer diagnostic context commits after all fallible calls succeed.

**Provenance:** Stage35's multi-opening test family includes deliberately injected synthetic alternative year-candidate boundaries. Its signed opening gate and all underlying Sauce selection streams are generated through the full real algorithm, but the synthetic year close-gate boundaries are not genuine normative year pairs. The prod output accordingly marks `anchorProvenance=INJECTED_MULTI_OPENING_GATE_BOUNDARIES` and does NOT claim its seed is an authentic independently selected normative Year5000.

## Independent tests and expected historical RED

`test/discovery18.ts`: exact signed floor-div behavior near -731,-730,-366,-365,-1,0,364,365,730,999; unbounded giant integers; invalid inputs; eight full real Stage35 paths over signed opening gate indices ±1/±2 and two target-day questions each; actual old helper and original predicate spies, 5 real negative signed predecessor selector calls; four injected deep failures (old candidate, negative gate, Stage35 final selector, old 365 helper itself), transactional rollback and same-context retries; independent ownership and Stage54 barrier.

`test/discovery18Properties.ts`: 801 independently computed direct signed /365 cells; large 16,384/32,768-bit signed divisions; one geometrically genuine valid gate-pair seed (assigned the **hypothetical** number 5000 only for comparison, *not* independently verified as the selected Year5000(c)) and actual *test-only* normative `nextYear` seal11 and `previousYear` seal12 calls, verifying the historical /365 guess is wrong in both directions. A full 24 genuine Stage35 anchored production histories for ±1..±6 and forward/backward test days; 792 injected noncanonical source vectors (64 varied, eight giant, 720 distinct DROP46 orders), independently rebuilt 58-write predecessor and true Sauce/seal10 question ranks. The old ghost must have **zero** influence on the predecessor selected candidate in all tests.

`test/discovery18Red.ts`: eighteenth deliberately failing *full production* example whose synthetic but physically selected 1000-day anchor's last day is necessarily inside Year5000, whereas old /365 emits Year5002. Normal `npm test` verifies the exact nonzero exception via `test/verifyDiscovery18ExpectedRed.mjs`. All previous seventeen historical expected RED scripts remain independently verified and untouched.

Close only after native TypeScript typecheck, every Stage1–36 test and all 18 intentional expected RED proofs, as well as independent frozen SourceLanguageCatalog/hash job, pass GitHub Actions. Until then `LAST_COMPLETED_STAGE=35`; Stage37 PATCH18 not started.

## Native CI verified — 13 October 2026

[Implementation 214f2bb](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/214f2bb629326bf5de607f909da506abdcb7dec9), [GitHub Actions run 38376499660](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38376499660): BOTH independent frozen-name `verify` and historical-label `stage27-typescript-marathi` native TypeScript jobs SUCCESS; all Stage1–36 regressions and **18 archived intentionally red** witnesses verified.

```text
STAGE_36_DISCOVERY_18_GUARDS_PASS boundaries=14 signedAnchors=8 positive=2 negative=2 falseWithin=4 estimateWrong=0 rankWrong=0 legacyCalls=1 priorSelectorCalls=5 originalPredicateCalls=3 truePredecessors=42 sharedWrites=2436 telemetryOnly=8 faultCases=4
STAGE_36_DISCOVERY_18_PROPERTIES_PASS floorGrid=801 floorWrong=0 wrongWithinCells=328 negativeFloors=395 giantDeltas=8 genuineSeedPair=1 normativeNext=1 normativePrevious=1 forwardOldWrong=1 backwardOldWrong=1 realAnchors=24 positive=6 negative=6 realGhostWrong=0 realRankWrong=0 realKnownMismatches=12 realPredecessors=198 realWrites=11484 varied=64 giants=8 ranks=720 unique=720 variants=792 variantPredecessors=3168 variantWrites=183744 totalPredecessors=3366 totalWrites=195228 streamWrong=0 rankWrong=0 ghostWrong=0 selectionChanged=0
STAGE_36_DISCOVERY_18_EXPECTED_RED_VERIFIED nonzero=1 mismatches=1 matches=0 oldGuess=5002
```

LAST_COMPLETED_STAGE=36. 365-day jump remains diagnostic only and never selects a year; Stage37 one-year authoritative traversal not implemented. Real signed opening gates and Sauce question streams are physical production; other year-candidate boundaries are labeled injected, and test-only true next/previous comparisons used a geometrically valid but hypothetical Year5000 seed.
