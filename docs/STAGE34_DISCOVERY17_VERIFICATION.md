# Stage 34 — DISCOVERY 17: historical stable year-length-only tie

## Exact fault from the 55-stage contract

For Year 5000, the canonical candidate order is ascending by year length, with a second criterion of **earlier opening gate day when lengths tie**. The historical implementation uses a stable sort on year length **only**. Stage34 must physically execute that comparator and exhibit a real wrong result, WITHOUT applying Stage35's late same-length-run tie repair.

`src/discovery17LegacyYearTie.ts` adds `LegacyYear5000LengthOnlySorter.oldLengthCompare` (returns zero on equal lengths) and a genuine stable historical sort invoking that method. The result preserves input chronology within a same-length run; no production code sorts ties by opening day. An adjacent tied reverse opening-date pair is measured diagnostically (`lengthTieInversions`), but NEVER corrected or used to override selection.

`Discovery17Year5000TieHandler` explicitly runs full real `patch16YearMax` as its genuine Stage33 predecessor: that in turn runs the real Stage31 signed opening gate, original Stage30 wrong-side helper, old Stage32 5781 predicate, corrected Stage33 5778 guard and an actual seal10 selection. It next physically calls `Patch16YearLengthGuard.apply` on a different family of **injected multi-opening-gate candidates**, preserving the original old 5781 predicate and the 5778 restriction; it calls the original length-only sorter again, then physically calls `patch14WideChoice` on Sauce(c,c), Bowl1 seal10 with N equal to that eligible family's size. No independent oracle is imported by production. All previous 58-write predecessors and original semantic state ownership rules are preserved.

**Data provenance matters:** the genuine opening gate is computed from the signed gate algorithm. Other open/close gate coordinates for the equal-length diagnostic family are synthetic caller-injected data and explicitly marked `INJECTED_MULTI_OPENING_GATE_BOUNDARIES`, not presented as authentically generated calendar gates. Test-only canonical ordering is computed independently from `test/normativeOracle.ts`'s Year5000 comparator (length, then opening gate day).

## Regression gates

`test/discovery17.ts`: four genuine signed anchors (+1,-1,+2,-2), each with two synthetic 1000-day year candidates in reverse opening-day order, real full Stage33 producer, two real seal10 calls and an additional true sorting invocation. The result chooses the wrong tied candidate even while the rank matches the independent oracle. Physical comparator, old 5781 predicate and real production selector spies; validations; deep injected faults before and after the real signed-gate and old-sort chains; independent-context retry/ownership; Stage54 barrier.

`test/discovery17Properties.ts`: 256 direct three-candidate equal-length families with stable length-only comparator and independent canonical tie order; 12 genuine signed anchors (±1..±6) with full Stage33 chain and real seal10 selection; 792 additional explicit noncanonical source variants (64 varied, eight enormous signed integers, 720 distinct DROP46 orders), with independent Bowl1 seal10 replay and 58-write chain audit. Expected 87 genuine predecessor calls across 12 real-gate tests plus 2,376 full predecessor calls in injected variations, totalling 2,463 real 58-write sequences and 142,854 historical writes.

`test/discovery17Red.ts`: seventeenth standalone deliberately failing full-route witness comparing two equal-length 1000-day entries sorted in reversed opening-day order. The normal `npm test` invokes its independent nonzero-result verifier `test/verifyDiscovery17ExpectedRed.mjs`; prior sixteen intentionally failing historical scripts remain unchanged.

Stage34 closes only after both GitHub Actions jobs (native TypeScript full regression and frozen-name-lock check) pass. **Stage35 PATCH17 tie correction must NOT be applied in Stage34**. No main/other branch edits, no HANDOFF archives committed.

## Verified native CI — October 12 2026

[Implementation commit bccf5474](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/bccf5474192fd5e65944bc3dd9438d0fe6345b6d) and [GitHub Actions run 38283939340](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38283939340): independent `verify` and historic-name `stage27-typescript-marathi` jobs both SUCCESS. Native TypeScript typecheck and full Stage1–34 suite passed. All original 16 intentionally-red scripts remain verified; the seventeenth standalone expected RED was separately verified as a nonzero execution with exact marker. The frozen name hash remains unchanged.

```text
STAGE_34_DISCOVERY_17_GUARDS_PASS anchors=4 positive=2 negative=2 wrongSelections=4 rankWrong=0 tieInversions=4 realPredecessors=17 sharedWrites=986 originalPredicateCalls=12 comparatorSpy=1 stableSortSpy=1 selectorSpy=3 predicateSpy=3 faults=4
STAGE_34_DISCOVERY_17_PROPERTIES_PASS directFamilies=256 directOldWrong=256 directComparatorCalls=512 realGates=12 positive=6 negative=6 realRankWrong=0 realTieWrong=12 originalGateCalls=63 realYearSelectors=24 realPredecessors=87 realWrites=5046 varied=64 giants=8 ranks=720 unique=720 variants=792 variantPredecessors=2376 variantWrites=137808 totalPredecessors=2463 totalWrites=142854 streamWrong=0 selectorWrong=0 wrongTieWitnesses=792
STAGE_34_DISCOVERY_17_EXPECTED_RED_VERIFIED nonzero=1 mismatches=2 matches=0 length=1000
```

**Stage34 complete; LAST_COMPLETED_STAGE=34.** Original year-length-only comparator and stable ordering remain uncorrected and genuinely executed; Stage35 PATCH17 not started. Alternative opening/closing gate boundaries used in diagnostic ties are explicitly injected synthetic candidates, not genuine normative gate pairs.
