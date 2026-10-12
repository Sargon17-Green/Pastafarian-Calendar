# Stage 27 PATCH 13 — GitHub Actions verified PASS

## Normative semantics and production independence

`M=2^127-1`, candidate stream `answerAt(k)=1+regularMod(first-1+direction*k,M)`, first in 1..M and direction in {+1,-1}. The test-only `test/normativeOracle.ts` is **not** imported in production.

- Short `1<=N<=M`: threshold `L=floor(M/N)*N`; return `1+((x-1) mod N)` for first stream answer `x<=L`.
- Wide `N>M`: smallest `k` with `M^k>=N`; combine `x_j=answerAt(j)` in **little-endian** M-adic order `1+Σ(x_j-1)*M^j`; threshold `L=floor(M^k/N)*N`; following rejected candidate composite increments/decrements ±1 cyclically modulo `M^k`. First accepted candidate maps to 1-based rank.
- Efficient skip theorem: If initial candidate `y>L`, and cyclic step=-1, exactly `y-L` candidates are rejected before accepting `L`. If step=+1, exactly `space-y+1` are rejected before accepting 1. These are **exact** results of repeated single-step rejection, not an approximation.
- Stage26 original `LegacyBiasedModuloRankAdapter.oldChooseModulo` stays intentionally wrong and physically invoked by production `discoverLegacyBiasedModulo` nested chain. Corrected `Patch13RejectionRankAdapter.choose` does not call any test oracle or original modulo for its result.

## Production and regressions

- `src/patch13RejectionRank.ts`: both short/wide, frozen answer-digit diagnostics, exact rejected-count metrics, Stage26 full child route (Stage25 46 drops +12 post-stirs =58 actual shared-memory writes), fault-safe outer context/inputs, actual old helper call and historical mismatch side by side.
- `test/patch13.ts`: 12 canonical pairs ×6 queries; rank2 etc handled by predecessor, 3 historical M-top rejected vectors, huge exact short + wide rejection gaps in both directions, M^k ranks, malformed/inconsistent data, true method spies, injected failures before/after old selector and correction, reentrant ownership, Stage54 final-route guard.
- `test/patch13Properties.ts`: 256 short sizes × five boundary first answers × two directions =2560 direct comparisons to test-only normative oracle; finite miniature M bases (2..12) exhaustive independent brute-force answer enumeration to prove skip; M^k, 16K-bit family size, 804 authentic full histories (12+64+8+720) with 46632 true shared-memory writes and separate correct oracle.
- `.github/workflows/canonical-names-lock.yml`: Stage1–27 native regression + all **13** archived expected-red proofs, canonical names lock, stage-specific grep; 10-minute timeout.

## GitHub Actions verified results

Implementation [commit 2b348599](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/2b3485995f97e6f0efa2013f0e2db44d893be194); [GitHub Actions run 38253073014](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38253073014): `verify` and `stage27-typescript-marathi` both **SUCCESS**. Native TypeScript typecheck PASS, full Stage1–27 regression suite PASS, all 13 archived historical expected-red scripts nonzero with exact expected markers, frozen catalog/name lock PASS.

```text
STAGE_27_PATCH_13_GUARDS_PASS dayPairs=12 cells=72 mismatches=0 oldWrong=16 oldMatches=56 wide=16 boundaries=13 legacyCalls=2 correctedCalls=2 predecessorCalls=2 injectedFailures=3
STAGE_27_PATCH_13_PROPERTIES_PASS shortSizes=256 shortCells=2560 shortMismatches=0 shortOldWrong=1365 shortOldMatches=1195 shortRejected=1402 shortWraps=701 surrogateCases=13926 surrogateRejected=2466 surrogateWide=12628 surrogateWrap=1290 powerCases=10 powerDigits=154 giantWideGaps=2 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 streamMismatches=0 fullMismatches=0 fullOldWrong=177 fullOldMatches=627
```

**LAST_COMPLETED_STAGE=27**, Stage28 DISCOVERY14 is not started. These results are from the completed job logs, not projected counts.
