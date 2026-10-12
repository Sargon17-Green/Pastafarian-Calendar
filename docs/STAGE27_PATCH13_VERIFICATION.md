# Stage 27 PATCH 13 — CI verification submission

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

**Status:** implementation submitted, no claim of CI success yet. Keep LAST_COMPLETED_STAGE=26 until BOTH CI jobs pass. Stage28 DISCOVERY14 not started.
