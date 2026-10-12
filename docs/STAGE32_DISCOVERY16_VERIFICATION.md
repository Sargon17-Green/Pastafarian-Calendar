# Stage 32 — DISCOVERY 16: historical year maximum 5781 (expected RED)

## Contract and separation

The authoritative 55-stage contract, `06-implementation-prompt.md`, requires a genuine historical `LEGACY_YEAR_MAX=5781` in Patch16, while normative Appendix A says 5778. Stage32 DISCOVERY16 **must execute the old predicate and must not implement Stage33 PATCH16's mandatory late `candidateLength>5778` exclusion before sorting/selection**. Later Stage34 corrects the historical tie-breaking in Year5000; Stage32 uses the old stable length-only sort.

`src/discovery16LegacyYearMax.ts` adds the actual wrong `LegacyYearMaxEligibilityAdapter.oldEligibleYear` with gate gap minimum 6, year length minimum 252 and maximum **5781**. The actual filter calls that method on every well-formed raw candidate, sorts accepted candidates by length alone, and does not reject 5779..5781. Its result includes a frozen ledger and `acceptedLongLengths`; caller-owned boundary objects are snapshotted.

## Genuine chain and injected gate boundaries

`Discovery16YearMaxHandler` is not a standalone constant demo. For every invocation it physically runs `patch15SignedGate` as an actual signed-gate anchor with its full historical/negative corrected question chains, including 58 real shared-memory writes per predecessor. Then it invokes the actual Stage29 `patch14WideChoice(calculationDay, calculationDay, ..., bowl=1, seal=10, N=kept.length)` on the true year-question answer stream. The original erroneous 5781 eligibility result **actually reaches the sorter and the real seal10 selector**, and a singleton 5781 candidate demonstrably becomes the selected candidate. This stage does not import the test-only normative oracle.

Important provenance: candidate close-gate days/indices in these stress witnesses are **synthetic, caller-injected candidate boundaries** anchored at a genuinely computed signed opening gate. The production result marks `candidateSource="INJECTED_CANDIDATE_BOUNDARIES"`. They are not claimed to be actual normative gate pairs. The real signed anchor and all sauce-dependent selections, in contrast, are genuinely computed through the full existing production paths.

## Test requirements

`test/discovery16.ts`: exact 251/252, 5777/5778/5779/5780/5781/5782 boundary behavior, min gap 5/6, short/long combinations, old predicate invocation spy, old stable length-only sort, independent canonical oracle gate anchor ±1 and year sauce(c,c) seal10. Explicit single-candidate 5781 winner in the actual selector. Real Stage31 and old signed-side helper spies, two injected faults (at gate and year selection) with transaction-safe same-context retries; validation, frozen ownership and Stage54 barrier.

`test/discovery16Properties.ts`: 255 direct legacy-range cells, 12 deliberate 5779..5781 false accepts vs 5778 oracle ceiling, signed real anchors ±1..±6 with actual correct gate locations, full real production year selector, 792 injected noncanonical year-question variations (64 varied, 8 huge signed integers, 720 distinct DROP46 permutations), independent bowl replay/answer ranks and old eligibility ledger.

`test/discovery16Red.ts`: sixteenth deliberately failing full production witness with three forbidden candidate lengths 5779, 5780 and 5781, including an actual Stage31 gate predecessor and an actual seal10 selection. The expected nonzero exception is verified via `test/verifyDiscovery16ExpectedRed.mjs` in normal `npm test`; previous fifteen historical expected-red scripts remain unchanged.

CI closure requires both the independent names-lock job and the full native TypeScript test job SUCCESS. Preserve Stage33 PATCH16 entirely unimplemented, including no 5778 late filter. Last completed stage remains 31 until verified.

## Verified GitHub Actions — 2026-10-12

[Implementation commit cfc2dd9](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/cfc2dd9cb279ac096c1d3a875f45d325be10862a), [Actions run 38274577638](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274577638), both `verify` and historical-named `stage27-typescript-marathi` jobs SUCCESS. Native TypeScript typecheck, all Stage1–32 regression cases, first fifteen archived intentionally-red proofs, sixteenth new historical RED verified with deliberate nonzero exit. Frozen name catalog hash unchanged.

```text
STAGE_32_DISCOVERY_16_GUARDS_PASS anchorSides=2 actualCases=4 legacyLongAccepted=6 selectorWrong=0 predicateCalls=12 selectorCalls=4 fullWrites=580 oldCalls=1 signedCalls=1 dispatchCalls=3 faultCases=2
STAGE_32_DISCOVERY_16_PROPERTIES_PASS direct=255 wrongAccepted=12 directMismatch=12 realGates=12 positive=6 negative=6 anchorWrong=0 rankWrong=0 legacyCalls=42 extraSigned=21 realSelectors=12 realCalls=75 realWrites=4350 varied=64 giant=8 ranks=720 unique=720 variants=792 variantCalls=1584 variantWrites=91872 totalCalls=1659 totalWrites=96222 streamWrong=0 rankMismatch=0 selectedWrong=0
STAGE_32_DISCOVERY_16_EXPECTED_RED_VERIFIED nonzero=1 mismatches=3 matches=0 oldMax=5781
```

**Stage32 complete, LAST_COMPLETED_STAGE=32.** The 5781 old predicate is unchanged; Stage33 5778 repair not implemented. All 5779..5781 demonstration boundaries are explicitly synthetic, and the signed opening gates / selection streams are physically computed.
