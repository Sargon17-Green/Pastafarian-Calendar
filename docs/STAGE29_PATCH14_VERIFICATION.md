# Stage 29 — PATCH 14 Wide Choice (CI submission)

## Exact canonical rule and historical scar

M=2^127−1. Stage28 `LegacyShortOnlyWideSelectionAdapter.oldChooseShortOnly` is intentionally wrong for N>M (blocked / rank 0). The Stage29 handler calls the actual `discoverLegacyShortOnlyWide` production chain, so this original helper is genuinely executed once, and its zero-result is preserved as historical evidence.

`Patch14WideChoiceDispatcher` explicitly branches on family size:
- 1<=N<=M: reuse the successful `oldResult.shortSelection` returned by the real old helper, exactly the already-correct Stage27 short rejection path. No additional selector call.
- N>M: call an independent `Patch13RejectionRankAdapter.choose` on the Stage28 saved answer stream to form k M-adic little-endian answer digits (smallest k such that M^k>=N), reject on the entire composite by cyclic ±1 movement, and return 1-based canonical rank. Never recompute digits during rejection or use zero as a corrected value.

The earlier full production chain still performs 46 drops, 12 post-stirs and 58 actual shared writes. Stage26 old biased modulo is actually called, and Stage25 DROP46 correct successor is used. The independent normative reference stays test-only (`test/normativeOracle.ts`). No new Stage30 work.

## QA gates

`test/patch14.ts` checks 12 day pairs ×6 real queried bowls, M and M±1 and M² boundaries, original wrong method physically called, split short/extra wide dispatch counts, validation, three deliberately injected exceptions at different call-depths and deterministic retry, reentrant context independence, Stage54 route still blocked.

`test/patch14Properties.ts` validates 256 short cardinalities ×5 answer boundaries ×2 directions = 2560 direct checks; 10 wide classes (M+1, M²±1, M³±1 and a 16384-bit cardinality) ×3 bounded stream cases =30; 804 complete histories (12 canonical pairs, 64 varied, 8 signed giant, all 720 DROP46 ranks), 46632 historical shared writes and independent canonical oracle result. All 14 prior intentionally-red scripts must remain as expected failures; 14th red is verified from the regular npm test through its own child process.

Workflow `stage27-typescript-marathi` still bears the historical stage label because previous attempts to change workflow YAML were blocked. Nevertheless, its `npm test` runs the entire Stage1–29 suite. Do not mark LAST_COMPLETED_STAGE=29 until that job and the independent `verify` name-lock job pass.

Status: **implementation prepared for CI**, not yet verified.

## Verified production result — 12 October 2026

[GitHub Actions 38260956581](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38260956581): verify and the historically named stage27-typescript-marathi jobs both SUCCESS. The stage27 label remains old but actual npm test covers all Stage1–29 tests. Native TypeScript check passed; all 14 intentional historical red witnesses retained and verified.

```text
STAGE_29_PATCH_14_GUARDS_PASS pairs=12 cells=72 short=51 wide=21 correctedWrong=0 oldWrong=21 oldMatches=51 boundaries=11 oldMethodCalls=2 wideMethodCalls=2 shortMethodCalls=2 faultCases=3
STAGE_29_PATCH_14_PROPERTIES_PASS shortCases=2560 shortWrong=0 shortRejected=1402 shortWrap=701 wideDirect=30 wideHistoricalBlocked=30 wideDirectWrong=0 wideDigits=462 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 streamWrong=0 correctedWrong=0 short=566 wide=238 oldWrong=238 oldMatches=566 actualExtraWide=238
```

LAST_COMPLETED_STAGE=29. No Stage30 implementation.
