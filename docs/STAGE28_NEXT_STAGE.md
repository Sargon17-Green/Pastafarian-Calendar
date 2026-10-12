# Stage 28 पूर्ण — Stage 29 PATCH 14 साठी continuation

## Authoritative state
- Repository `Sargon17-Green/Pastafarian-Calendar`, branch **only** `TypeScript+मराठी`. Never touch `main` or another branch.
- Canonical 55 stages. **LAST_COMPLETED_STAGE=28**, Stage28 DISCOVERY14 is completed. Next and sole stage **29 PATCH14**, Stage30 DISCOVERY15 explicitly out of scope.
- Stage28 implementation commit `b49a4a680c34f198cccc82210c7b54fa4dd99d17`; GitHub Actions [run 38256920590](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38256920590) jobs `verify` and `stage27-typescript-marathi` both SUCCESS. Workflow second job label is legacy, but its `npm test` runs all Stage1–28 tests. `test/verifyDiscovery14ExpectedRed.mjs` checks 14th historical deliberately failing executable's nonzero exit and exact marker; previous 13 red jobs remain independently verified.
- Start from live GitHub HEAD/tree, `DEVELOPMENT_STAGE.md`, `src/discovery14LegacyShortOnlyWide.ts`, `src/patch13RejectionRank.ts`, `test/normativeOracle.ts`, `test/discovery14Red.ts`, `docs/STAGE28_DISCOVERY14_VERIFICATION.md`. Preserve all prior stages.
- Pure TypeScript; Marathi docs/comments, frozen names lock, no cross-language source/fixture/test-only oracle imported by production, immutable per-invocation semantic state, Stage54 calendar route still blocked.

## Precise historical fault and next correction
Stage28 `LegacyShortOnlyWideSelectionAdapter.oldChooseShortOnly(stream,N)` is INTENTIONALLY WRONG for `N>M`. For `N<=M`, it really calls previously verified Stage27 short rejection. For `N>M`, `floor(M/N)*N=0`, so it declares BLOCKED and returns **rank 0** (illegal) rather than an infinite rejection loop. Stage28 full production handler physically calls this old helper after the entire corrected Stage27 chain, preserving 46 drops +12 post-stirs=58 real writes and old Stage26 modulo scar.

Stage29 PATCH14 must keep the old adapter unchanged and physically invoked as forensic scar, but introduce corrected production **dispatcher**: `N<=M` follows the existing valid short route, `N>M` uses Wide Choice. Wide Choice: minimal digit count k such that M^k>=N, little-endian M-base digits of the existing stream's first k answers; rejection advances ±1 cyclically **on the whole combined wide number**, never regenerating the digits. `Patch13RejectionRankAdapter.choose` already supports both canonical modes; reuse it carefully without skipping a required physical legacy method call. Corrected rank must equal independent test-only `chooseRank` for both domains. Do NOT modify the old zero-return helper itself. Check M, M+1, M², M²+1 and huge signed inputs.

## Verified Stage28 evidence
```text
STAGE_28_DISCOVERY_14_GUARDS_PASS pairs=12 cells=72 short=51 wide=21 shortWrong=0 wideWrong=21 boundary=10 legacyCalls=2 predecessorCalls=3 shortHelperCalls=2 injectedFailures=3
STAGE_28_DISCOVERY_14_PROPERTIES_PASS shortSizes=256 shortCases=2560 shortWrong=0 shortRejected=1402 shortWrap=701 wideCases=30 wideInvalid=30 correctedWideWrong=0 largestDigits=130 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 streamWrong=0 upstreamWrong=0 fullShort=566 fullWide=238 fullBlocked=238
STAGE_28_DISCOVERY_14_EXPECTED_RED_VERIFIED nonzero=1 mismatches=1 matches=0 N=M+1 old=0
```

## Work requirements
Stage29 green guards with short/wide dispatcher, 14 archival expected-red failures retained, exhaustive direct and 804 full chain QA, actual method spies, injected error rollback, independent contexts, 58 writes, giant signed numbers, native typecheck. Obtain both GitHub CI jobs SUCCESS before changing LAST_COMPLETED_STAGE=29. The workflow's old stage27 label should be renamed to stage29 only when the editing action is supported; do not compromise workflow safety. No Stage30 work.

Live HEAD optimistic concurrency, no force pushes. User-only HANDOFF archives must not be committed. No human action required.
