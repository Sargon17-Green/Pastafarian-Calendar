# Stage 40 — DISCOVERY20: true oldStructureSauce uses original target day

## Original contract and strictly historical behavior

The canonical implementation contract `06-implementation-prompt.md` section 13 says:

```text
function oldStructureSauce(cDay, originalTargetDay):
    return sauceWithScars(cDay, originalTargetDay)

function structureSaucePatch(cDay, originalTargetDay, year):
    ghost = oldStructureSauce(cDay, originalTargetDay)
    mustUse = year.openDay + 1
    if originalTargetDay != mustUse: return sauceWithScars(cDay, mustUse)
    return ghost
```

The first method MUST physically run in **Stage40 DISCOVERY20** while the second, correcting method MUST NOT be implemented until **Stage41 PATCH20**.

`src/discovery20LegacyStructureSauce.ts` defines `LegacyStructureSauceAdapter.oldStructureSauce(cDay,originalTargetDay,source)`: executes the full real `patch11OrderLatch(cDay,originalTargetDay,...)` processing 46 actual drop rounds, 12 actual post-stirs, 58 shared writes, the actual independent DROP46 order latch, and the original STIR_12 historical overwritten order. Returns immutable final six sauce bowls and independent query order. This is the authentic production Sauce state, not an oracle import and not a fake selected rank or mere diagnostic label. Question source fields (47 visible drops indexed 1..46, stones and six initial bowls) are provided by the caller and verified by the actual production handler; the current Stage40 API does not yet generate question-source inputs autonomously.

`Discovery20StructureSauceHandler.run` PHYSICALLY invokes the complete Stage39 handler on a real `Discovery19Request` before invoking the unmodified old helper. Thus every historical scar (including actual stale Year5000 key in Stage38) remains executable and the Stage39 three-guard corrected cache determines the genuine target-containing year. The selected year supplies `chosenYearFirstDay=selected.openGateDay+1` **for forensic comparison only**. Crucially the input to oldStructureSauce is `(cDay,originalTargetDay)`, and the first-day corrected sauce is **never** invoked or supplied as authority in Stage40. The returned `oldSauceActuallyUsed=true`, `correctedStructureSauceComputed=false`, `authoritativeStructureSauceReady=false` preserve this deliberately wrong historic state. Caller semantic context commits only after full predecessors and old sauce succeed. A failed old helper may leave a completed independent Stage39 cache query behind; it never commits caller semantic context, and same-context retry remains possible.

## Independent verification

`test/discovery20.ts` runs real distinct normative Year5000 selected in full Stage39 for c=gate(-2)+1 and c=gate(+2)+1, compares old output to an independent test-only `sauce(c,originalTarget)` and confirms it differs from the correct first-day `sauce(c,openGateDay+1)`. It checks full 58 writes, 46 drops, 12 stirs, real Year5000 gates, old Stage38 wrong cache HIT surviving, Stage39 guarded result, methods actually called, immutability, semantic ownership, refusal of bad sources, deep Stage39 and original-Sauce fault injection and retry, plus the Stage54 date barrier. It also tests the coincidental equal-target case in which the historical sauce is already correct and MUST remain unchanged.

`test/discovery20Properties.ts` independently compares 128 native Sauces, including signed 8192-bit calculation days; exactly 720 independent DROP46 order indices on a modified-but-explicitly-noncanonical input source using test-only independent bowl replay; eight immense positive/negative external drop and initial-bowl values; and full Stage39 route witnesses from the two genuine selected years. No synthetic question vector is represented as a normative generated day except where independently verified. The helper must remain physically called with original t in every case.

`test/discovery20Red.ts` is the **20th intentionally failing** standalone test on the complete real Stage39+old-sauce route; it throws the exact expected historical RED marker if real original-target sauce differs from the independent correct first-day Sauce. `test/verifyDiscovery20ExpectedRed.mjs` confirms this nonzero error. The previous 19 historical intentionally-red proof scripts are left unchanged and continue to be verified by full `npm test`.

Only after BOTH GitHub Actions jobs pass native TypeScript, entire Stage1–40 regression and frozen source catalog/hash may LAST_COMPLETED_STAGE become 40. Stage41 correction and full Stage54 route are **not** implemented.

## Native CI verification — 16 October 2026

[Implementation commit 2ebde236](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/2ebde236aebf48df8d97f8ecdae8479683523719); [Actions 38893268444](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38893268444). Both jobs SUCCESS: native TypeScript typecheck/full Stage1–40 suite including 20 expected nonzero historical witnesses, and frozen SourceLanguageCatalog/hash verification.

```text
STAGE_40_DISCOVERY_20_GUARDS_PASS realYears=2 oldSauceCalls=2 actualWrongTarget=2 originalWrongCacheHitPreserved=1 firstDayCoincidence=1 deepFaults=2 outerRollback=2 separateRealSaucePaths=2 structureSharedWrites=116 correctedStructureSauceInvoked=0
STAGE_40_DISCOVERY_20_PROPERTIES_PASS directSauces=128 directDifferent=85 equalTarget=43 giantCalculationDays=64 directWrites=7424 drop46Variations=720 uniqueOrder=720 syntheticWrong=0 syntheticWrites=41760 enormousSources=8 enormousWrites=464 realYear5000Cases=2 historicalWrong=2 realFullPredecessors=68 realFullWrites=3944 actualOldBowlChainSpy=1 nextStageCorrectedSauceCalls=0
STAGE_40_DISCOVERY_20_EXPECTED_RED_VERIFIED nonzero=1 wrongSauce=1 correctedCalls=0
```

LAST_COMPLETED_STAGE=40. True Stage39 Year5000/cDay predecessor runs physically. The original oldStructureSauce takes ORIGINAL target and really produces 58 writes. The first-day correct Sauce is test-only oracle comparison; Stage41 PATCH20 not implemented.
