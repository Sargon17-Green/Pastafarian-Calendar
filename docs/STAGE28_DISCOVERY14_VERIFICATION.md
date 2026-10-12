# Stage 28 — DISCOVERY 14: historical short-only selection

Stage28 defect is the assumption `N<=M`, with `M=2^127-1`. The old selector is correct for the short branch, using the real Stage27 rejection helper. For `N>M`, its short-only threshold `floor(M/N)*N` is zero: it explicitly marks the result BLOCKED and returns **rank 0**. This reproduces the historical failure without running an impossible rejection loop. No Wide Choice repair is applied in Stage28.

## Implementation boundary

`src/discovery14LegacyShortOnlyWide.ts` adds the actual historical `LegacyShortOnlyWideSelectionAdapter.oldChooseShortOnly` and `Discovery14ShortOnlyWideHandler`. The handler executes the full corrected `patch13RejectionRank` path on a child context (including the previous 58 memory writes, DROP46 latch, and the real Stage26 wrong modulo method), then **physically calls** the standalone historical short-only helper. Stage27's correct wide rank is displayed for forensic comparison only: it does not affect the old rank or blocked flag.

The independent oracle is `test/normativeOracle.ts:chooseRank`. Production never imports that test-only reference. No foreign implementation/source artifacts are used.

## Coverage and closure requirements

`test/discovery14.ts` checks 12 independent canonical date pairs × six IDs, short/wide divergence, N=M/M+1/M² boundaries, guards for invalid sparse inputs and types, real method instrumentation, rollback/retry fault injection, context ownership and Stage54 calendar-route barrier.

`test/discovery14Properties.ts` runs all 256 short sizes × five edge first-answers × two directions, 30 wide direct cases including 16384-bit N, and 804 full predecessor histories: 12 real +64 varied +8 huge signed +720 DROP46 permutations, with 46632 real shared-memory writes and independent answer-stream/rank comparisons.

`test/discovery14Red.ts` is the fourteenth deliberately failing witness, on a **full real Stage27 route** at N=M+1, with old=0 and independent canonical rank ≥1. `test/verifyDiscovery14ExpectedRed.mjs` executes this script in a child Node process and requires a nonzero exit plus the exact expected marker during the ordinary `npm test` suite.

Both existing GitHub jobs must pass including the expanded npm test before changing LAST_COMPLETED_STAGE. The workflow's historical Stage27 job label remains unchanged because editing that workflow was blocked; this label alone must not be mistaken for a lack of Stage28 test execution. Stage29 must not be started.

## Actual CI results — 2026-10-12

[Implementation b49a4a6](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/b49a4a680c34f198cccc82210c7b54fa4dd99d17), [GitHub Actions run 38256920590](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38256920590): `verify` and `stage27-typescript-marathi` both SUCCESS. The latter job retains its old label, but executes Stage1–28 through the updated `npm test`, along with the independent 14th expected-red verifier. The previous thirteen expected-red jobs also succeeded.

```text
STAGE_28_DISCOVERY_14_GUARDS_PASS pairs=12 cells=72 short=51 wide=21 shortWrong=0 wideWrong=21 boundary=10 legacyCalls=2 predecessorCalls=3 shortHelperCalls=2 injectedFailures=3
STAGE_28_DISCOVERY_14_PROPERTIES_PASS shortSizes=256 shortCases=2560 shortWrong=0 shortRejected=1402 shortWrap=701 wideCases=30 wideInvalid=30 correctedWideWrong=0 largestDigits=130 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 streamWrong=0 upstreamWrong=0 fullShort=566 fullWide=238 fullBlocked=238
STAGE_28_DISCOVERY_14_EXPECTED_RED_VERIFIED nonzero=1 mismatches=1 matches=0 N=M+1 old=0
```

**Stage 28 complete and verified, LAST_COMPLETED_STAGE=28.** No Stage29 implementation. CI job label rename remains administrative housekeeping, not a computational error.
