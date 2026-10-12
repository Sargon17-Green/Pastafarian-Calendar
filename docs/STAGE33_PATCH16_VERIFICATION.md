# Stage 33 — PATCH16: reject year length above 5778

## Contract and historical behavior

The authoritative 55-stage contract specifies an original historical constant `LEGACY_YEAR_MAX=5781`, while the actual normative maximum is `5778` days. Discovery16 deliberately applies the old bound and can pass 5779, 5780, 5781 into its legacy length-only sort and real seal-10 selector. **The original `LegacyYearMaxEligibilityAdapter.oldEligibleYear`, `LegacyYearMaxCandidateFilter.filter` and all sixteen intentionally failing historical regression scripts remain untouched.**

The separate `src/patch16YearMax.ts` adds `REAL_YEAR_MAX_PATCH=5778n`. The new `Patch16YearLengthGuard.apply` physically invokes the old filter (which in turn invokes the old 5781 predicate for every input candidate). It retains the full frozen historical ledger. It then examines that original-position ledger, independently excludes all previously accepted candidate lengths greater than 5778, and ONLY THEN sorts the new eligible family by length. It does not add the Stage35 equal-length opening-gate tie correction. The old predicate, old sorted list, and old erroneous admissions remain available as diagnostic evidence.

`Patch16YearMaxHandler` preflights all candidate shapes and year-source vectors, executes the old predicate for all candidates, requires a **nonempty corrected family before any year-selector call**, executes the real signed Stage31 gate anchor (including Stage30 wrong-side scar and real Stage29 predecessors with 58 shared writes each), and calls the real `patch14WideChoice` on (calculationDay,calculationDay), Bowl 1, seal 10, with N equal to **correctedFamilySize**, not historicalFamilySize. A legacy-only 5781 singleton yields a validation error, not a zero or fake rank. Both historical and corrected full ledgers and the selected canonical-safe candidate are frozen. All outer state is committed only after the full predecessor chain completes.

The canonical maximum was checked against the independent test-only `YEAR_MAX_DAYS` from `test/normativeOracle.ts`. Production does not import that oracle. Genuine Stage31 opening gate days and selection answer streams are produced by real code. Close-gate candidate boundaries in these demonstrations remain **synthetic injected boundaries** anchored at the real opening gate; they are not represented as genuine normative gate pairs.

## CI and tests

`test/patch16.ts`: 8 boundary lengths 251/252/5777/5778/5779/5780/5781/5782, six-gate minimum, old-sort preservation and tie stability, physical legacy method spy, 4 genuine signed-gate anchors (+1,-1,+2,-2), two 5778-singleton selections on each, corrected family 2 versus historical 5, empty 5781-only corrected family never entering any selector, invalid preflight, three deep injected errors with deterministic same-context retry, reentrancy and Stage54 barrier.

`test/patch16Properties.ts`: all 255 old-vs-corrected length/gap combinations (12 known historical false accepts, **zero corrected mismatches**), 12 huge candidate integer boundary tests (up to 32768 bits), 12 genuine signed gate anchors (±1..±6) including old positive-side scar and independent canonical gate/selector ranking, and 792 **explicitly noncanonical** year-question variation fixtures (64 varied, 8 huge signed, 720 distinct DROP46 orders), independently replaying Sauce final bowls and seal10 answer stream. Full previous-stage 58-write chains and complete absence of forbidden 5779..5781 from corrected selector families must be proved. All earlier 16 expected RED checks are preserved unchanged in `npm test`.

Stage33 cannot be marked complete until BOTH GitHub Actions jobs (native TypeScript full regression and frozen name lock) succeed; `LAST_COMPLETED_STAGE=32` until then. Stage34 DISCOVERY17 must not be started.

## Verified — 12 October 2026

[Implementation commit 91c2523](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/91c252379726eefa5c31478c0bb0d8b0e465aaac), [GitHub Actions run 38280247898](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38280247898): both verify and legacy-named stage27-typescript-marathi jobs SUCCESS. Full Stage1–33 regression and TypeScript typecheck PASS; all sixteen deliberately red historical tests remain checked; frozen name catalog unchanged.

```text
STAGE_33_PATCH_16_GUARDS_PASS boundary=8 signedAnchors=4 positive=2 negative=2 oldAccepted=20 removedLong=12 correctedWrong=0 wrongSelected=0 predecessorCalls=26 sharedWrites=1508 oldPredicateSpy=3 signedSpy=1 selectorSpy=3 emptySelectorCalls=0 faults=3
STAGE_33_PATCH_16_PROPERTIES_PASS direct=255 oldDirectAccepted=128 newDirectAccepted=116 falseAccepts=12 directWrong=0 hugeCases=12 realGates=12 positive=6 negative=6 anchorWrong=0 rankWrong=0 oldKept=60 correctedKept=24 removedLong=36 originalGateCalls=42 extraSigned=21 realSelectors=12 realCalls=75 realWrites=4350 varied=64 giants=8 ranks=720 unique=720 variants=792 variantCalls=1584 variantWrites=91872 totalCalls=1659 totalWrites=96222 streamWrong=0 variantRankWrong=0 variantSelectedWrong=0 filterWrong=0
```

Stage33 is complete, LAST_COMPLETED_STAGE=33. Stage34 DISCOVERY17 not started. Close-gate candidate boundaries are deliberately injected synthetic test values, not claimed authentic normative gate pairs.
