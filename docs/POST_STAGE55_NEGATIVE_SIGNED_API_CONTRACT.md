# Post-Stage55: negative signed-input public API differential contract

**Project:** PC-BRANCH-TYPESCRIPT-MARATHI / TypeScript+मराठी  
**Grounded parent:** \`54bfda99000f2c00a6e136a0c09ad2a3448809d0\`  
**Accepted prerequisite:** Gate D exact-SHA CI run \`41537683096\`, all four jobs successful, including both bounded-differential and independent-rank markers.  
**Scope:** test-only verification of the already-integrated public API. This is a follow-up contract, **not Stage56**, not a production change, and not permission to merge or release.

## 1. Why this is the next useful check

Gate D now independently certifies six positive-era public \`(c,t)\` cases, all five output components, three complete large-year legal-weaving families, the exact Year5000 day-239 nonmembership, reliability/replay, and a propagated deep fault with a clean retry.

A source audit shows a remaining *coverage gap*, not a demonstrated defect: Gate D's calculation-day anchors are a positive signed gate and a positive non-anchor. It does not exercise the negative-anchor branch in \`createProductionPatch20Request\`, the negative signed-gate prefix as an end-to-end public date, or a target immediately across the foundation gate. These paths already exist in production and should be verified before considering broader work.

The contract must not manufacture an expected-red case. If a real mismatch appears, preserve its exact input, output, and completed log before classifying or fixing it.

## 2. Exact bounded input set

Use the existing test-only \`NormativeOracle\` and its \`FOUNDATION_DAY = -15055671n\`. Construct the cases algorithmically, rather than hardcoding derived gate days:

\`\`\`ts
const oracle = new NormativeOracle();
const negativeAnchorC = oracle.gateDay(-1n) + 1n;
const negativeNonAnchorC = negativeAnchorC + 1n;
const negativeAnchorYear = oracle.year5000(negativeAnchorC);
const anchorMiddleCandidate = negativeAnchorYear.openGateDay +
  (negativeAnchorYear.closeGateDay - negativeAnchorYear.openGateDay) / 2n;
const negativeAnchorMidDay = anchorMiddleCandidate === negativeAnchorC
  ? anchorMiddleCandidate + 1n : anchorMiddleCandidate;
const negativeNonAnchorYear = oracle.year5000(negativeNonAnchorC);
const negativePrevious = oracle.previousYear(negativeNonAnchorC, negativeNonAnchorYear);
const negativeNext = oracle.nextYear(negativeNonAnchorC, negativeNonAnchorYear);
const foundationCrossingC = FOUNDATION_DAY + 1n;
const foundationCrossingT = FOUNDATION_DAY - 1n;

const cases = [
  { label: "negative-anchor-middle-day", c: negativeAnchorC, t: negativeAnchorMidDay },
  { label: "negative-anchor-year-first", c: negativeAnchorC,
    t: negativeAnchorYear.openGateDay + 1n },
  { label: "negative-anchor-year-last-gate", c: negativeAnchorC,
    t: negativeAnchorYear.closeGateDay },
  { label: "negative-non-anchor-same-day", c: negativeNonAnchorC,
    t: negativeNonAnchorC },
  { label: "negative-previous-year-last-day", c: negativeNonAnchorC,
    t: negativePrevious.closeGateDay },
  { label: "negative-next-year-first-day", c: negativeNonAnchorC,
    t: negativeNext.openGateDay + 1n },
  { label: "foundation-crossing-backward", c: foundationCrossingC,
    t: foundationCrossingT }
] as const;
\`\`\`

Preflight invariants:

- Exactly seven distinct ordered pairs and 35 public tuple-component comparisons.
- Every \`c\` and \`t\` is negative.
- \`oracle.exactGateIndex(negativeAnchorC - 1n) === -1n\`; therefore the production request must report \`signedAnchorIndex === -1n\` and execute real historical anchor diagnostics.
- \`oracle.exactGateIndex(negativeNonAnchorC - 1n) === null\`; therefore production must report \`signedAnchorIndex === null\`, \`SKIPPED_NO_REAL_STAGE16_ANCHOR\`, and empty legacy anchor arrays. No synthetic anchor is permitted.
- For the foundation-crossing pair, \`c - 1n === FOUNDATION_DAY\` (gate index zero), but zero is not a Stage16 anchor. The request must retain \`signedAnchorIndex === null\`; its verified signed window must cover both \`t\` and \`c\`.
- The three target-year boundary cases must be independently confirmed as the first day, last day, and adjacent previous/next year days by the oracle.

## 3. Independent expected-value construction

For each pair, calculate the expected date without calling the production date API for expected values:

1. Resolve the target year with \`NormativeOracle.findTargetYear(c,t)\`.
2. From \`sauce(c, year.openGateDay + 1n)\`, independently select cutlet count, cutlet partition, distinct cutlet names, month count, month lengths, and distinct month names using the existing normative Sauce/Bowl selectors.
3. Run the actual full production Stage19–55 Native chain for one representative target in each distinct \`(c, openGateDay, closeGateDay)\` family and inspect its complete corrected legal weaving.
4. Certify that complete observed word with the existing test-only \`IndependentLegalWeavingRank\`: its full-word rank must equal \`chooseRank(askBowl(referenceSauce, 4, 32n), independent.count())\`. Do not use production rank/unrank, production suffix counters, or a sampled-prefix approximation as the expected rank. Reuse the already-proven insertion-DP oracle; do not copy another branch's implementation.
5. Only after the exact full-word rank matches, derive the target month ID and 1-based prefix occurrence from the certified word. Assemble the independent five-component tuple from the oracle's year, cutlet and month-name selections.
6. Compare all five fields with \`calendarDateSpaghetti(c,t)\` for each of the seven pairs. Require exactly five own keys, \`Object.isFrozen(result) === true\`, exact bigint numeric fields, and a fresh output object on independent calls.

The test must cache a rank certificate only for repeated targets sharing the same calculation day and exact target-year gate pair. It must not treat two different calculation days as the same family merely because their year number matches. The existing large-family \`NormativeOracle.weavingFamily\` Map-capacity limitation remains; use the independent insertion-DP ranker for full-size words.

## 4. Branch-specific production assertions

In addition to the seven public calls, make bounded request-factory probes for the negative anchor, negative non-anchor, and foundation-crossing pair. Assert the exact \`productionConstruction\` metadata described above, including the real negative anchor candidate family and the absence of fabricated candidates for null-anchor cases. These probes are part of the Native-call accounting.

No source file under \`src/\` may import from \`test/\`. Do not alter the public two-bigint API, calendar rules, canonical catalogs, or Native handlers.

## 5. Resource and CI contract

- Per certified family: at most 47 months, 5,778 year days, and 123 occurrences per month.
- At least 39 evenly distributed interleaving/prefix checks per distinct certified family; all target ordinals must also be checked exactly.
- Instrument actual \`Patch14WideChoiceDispatcher.dispatch\` calls across the complete test, including the three request-factory probes. Every counted predecessor must report one real legacy call and 58 shared writes.
- Hard aggregate ceiling: **1,200 actual Native calls**, with \`sharedWrites === 58n * BigInt(nativeCalls)\`; fail explicitly if exceeded. Do not silently truncate, cache across top-level public calls, or convert an unbounded signed day to Number.
- Dedicated GitHub Actions job timeout: **35 minutes**. The existing verify, Stage27 full Native/typecheck/regression/expected-red, Gate D differential, and Gate D reliability jobs remain required and unchanged.
- Add a separate package script and dedicated job for this negative signed API test. Do not make the existing Stage27 job execute the same expensive Native test a second time.

Required dedicated log marker (actual counters, not constants):

\`\`\`text
POST_STAGE55_NEGATIVE_SIGNED_API_PASS pairs=7 components=35 independentFamilies=5 rankMismatches=0 negativeAnchor=-1 negativeNonAnchor=null foundationCrossing=1 nativeCalls=<measured> sharedWrites=<measured> interleavingChecks=<measured>
\`\`\`

The marker is valid only when all seven outputs match, the branch-specific assertions pass, the five family certificates match their independent ranks, the call/write reconciliation holds, and all limits are respected. The complete workflow must finish successfully on the exact new SHA. A queued or in-progress run is neither PASS nor a blocker.

## 6. Delivery boundary

This contract authorizes only the test/package/workflow work needed to verify the existing negative signed-input path. Keep changes test/docs/workflow-only unless a completed log proves a production defect and the correction is within the existing authority. Do not open Stage56, change \`main\`, merge, publish, or release as part of this contract.

Implementation clarification (2026-11-03): the previous-year last-day test uses `negativePrevious.closeGateDay` exactly; the previous `-1n` expression denoted the penultimate day and was corrected before implementation.

Fixture correction (2026-11-03): the failed exact-SHA negative-signed job 125972296826 in run 41651997321 stopped at the seven-distinct-pairs preflight. The anchor same-day and anchor year-first selections may coincide; the deterministic interior-day witness is distinct from the anchor c and from both boundary days. This is a test-input collision, not evidence of a production defect.
