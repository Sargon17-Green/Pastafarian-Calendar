# Dart+עברית — Stage 7 Candidate B feasibility and exact contract

**Scope:** exploratory branch-only change; no Stage 8, merge, main or release. Source parent: `1d98a83db7446ceb4548c39e0eaf9b4441b72b9a`. Candidate A is already accepted at that SHA by [run 44877189934](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44877189934) (26/26 completed/success); no re-run of that SHA.

## Evidence before change

Stage 7 Native at the parent reported COUNT=223ms, FIRST=235ms, LAST=5849ms and CANONICAL=8809ms. Five alternated **legacy vs Candidate A** pairs were legacy=[9059,9074,8955,9096,9016]ms and A=[8762,8807,8816,8884,8867]ms (medians 9059ms and 8816ms). These are five observations on one runner, not a generalized speed guarantee. Four baseline output SHA-256 digests were matched; independent oracle coverage was 6 small domains and 55 ranks.

## Candidate B exact lower-bound shortcut

In `_unrankWithKnownTotal`, the first active candidate has an active-only completion count `C0 = childBases[0]`. Its exact full branch size is `C0 * F` where `F = _unopenedFactor(...)`. When active selection is admissible, `F` counts non-empty valid unopened-suffix completions and is at least 1. Thus `ordinal <= C0` implies `ordinal <= C0*F`: the lexicographically first active candidate must be chosen. No factor evaluation is needed in that case, and `nextBase=C0`. When the inequality fails, the old exact factor and all candidate comparisons remain unchanged. The shortcut subsumes the already accepted rank-1 shortcut.

### Bounded independent evidence

A separate Python multiset-leaf enumeration (not Dart Native, not the production counter) checked all 55 legal full words in the six Stage 7 oracle domains: [2,2,1], [2,2,2], [3,2,2], [2,3,2], [1,2,2], [3,3,2], with counts 2+5+9+11+2+26. It found two additional non-rank-1 shortcut opportunities in [3,3,2], at one-based ranks 13/day-index 2 and 25/day-index 3. Both independently selected the first active candidate. This shows reachability, not a speed benefit for the canonical year.

## Native acceptance gates for this candidate SHA (not yet evaluated when authored)

1. Automatically triggered push run is completed with all 26/26 jobs successful. No manual duplicate dispatch.
2. Dart formatter changes 0 files, analyzer clean, Stage 7 independent six domains / 55 ranks and immutable outputs preserved.
3. The exact original COUNT/FIRST/LAST/CANONICAL SHA-256 digests match; the three full-year words, AC.1, and public `unrankFull` rank semantics remain unchanged.
4. Stage 6 retained_sum_ac1=true, Stage1, P16, D17 and verify jobs pass; no new artifacts required.
5. Stage 7 five paired timings are **legacy vs Candidate B**, *not* Candidate A vs B. A-versus-B performance is therefore not established by these pairs. If there is no persuasive benefit, discard B rather than claiming an improvement.

Candidate A's existing acceptance is preserved at its exact parent SHA whether B passes or fails.
