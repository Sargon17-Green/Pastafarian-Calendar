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
## 2026-11-21: Candidate B exact-SHA Native evidence and decision record

**Source lock:** branch \`Dart+עברית\`, exact code SHA \`01cf39143731782bb96cc4d9c9a7075195693344\`. The [automatically triggered push run 44890464671](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671) completed with **26/26 successful jobs**; no duplicate dispatch. Its first-page artifact listing was empty. This is an acceptance of the explicitly scoped **Stage 7 correctness/Native gate for Candidate B at that source SHA**, not acceptance of a performance advantage over Candidate A and not authorization for Stage 8, main, merge or release.

### Per-job log evidence (Dart 3.13.2 / Linux)

- [Stage1 job 136804938644](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671/job/136804938644): \`dart format\` 47 files / 0 changed; analyzer \`No issues found!\`; completed/success.
- [Stage7 job 136804938899](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671/job/136804938899): format 1/0; analyzer clean; \`STAGE7_HOTPATH_PASS\`, checks=13259, year_days=4244, month_count=45, full_year_words=3, small_domains=6, small_ranks=55, canonical_case=1, phases=4, optimization=candidate_b_first_active_bound. Phases COUNT=251ms, FIRST=262ms, LAST=6663ms, CANONICAL=9809ms, TOTAL=16987ms.
- Four **unchanged baseline digest locks**, printed by the Stage7 Native job:
  - COUNT: \`c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8\`
  - FIRST: \`dc2dabc1c69f5007425c032e576577195ea6cf7b1d1054a9faca74e025aaf13c\`
  - LAST: \`71b78eb2ce0c68252f404e6c6d34b52a2f8f2b834eb6a2eff687bbc6c0bccdd8\`
  - CANONICAL: \`7093c6c666dc19642d650fe7fd8a9bbe43cd12238ac4f563ebe668d370eacdda\`
- [Stage6 job 136804938828](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671/job/136804938828): \`STAGE6_PROFILE_PASS\` checks=18, retained_sum_ac1=true, canonical_anchors=1.
- [P16 job 136804938906](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671/job/136804938906): \`PRODUCTION16_DATE_PASS\`, checks=391, synthetic_cases=36, canonical_anchors=3.
- [D17 job 136804938825](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671/job/136804938825): \`DISCOVERY17_COVERAGE_PASS\`, checks=31072, valid_words=11002, rank_probes=268, canonical_anchors_retained=3.
- [verify job 136804938868](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671/job/136804938868): completed/success.

### Reproducible paired timing evidence: legacy vs B, **not A vs B**

All timing figures are the exact \`STAGE7_PAIR_*\` values from job 136804938899; each pair alternates execution order. Difference is B minus legacy; negative is faster.

| Pair | Legacy (ms) | Candidate B (ms) | B − legacy (ms) |
| --- | ---: | ---: | ---: |
| 1 | 10222 | 10343 | 121 |
| 2 | 10330 | 10311 | -19 |
| 3 | 10371 | 10327 | -44 |
| 4 | 10625 | 10450 | -175 |
| 5 | 10640 | 10270 | -370 |

**Within-run descriptive summary:** median legacy 10371ms; median B 10327ms; median difference of medians -44ms (-0.424%); B faster in 4/5 pairs. These are single-run, small-sample observations with variable runner load; there is no established statistical significance or generalized speed claim. The previous Candidate A's 8816ms median was measured in a **different** run, and comparing that number to B's 10327ms here would be confounded. Candidate B's additional shortcut reachability was demonstrated independently on two non-rank-1 small-leaf cases, **not** as a proven canonical-year speedup.

**Gate decision:** Candidate B Stage7 **Native/correctness ACCEPTED** at exact code SHA \`01cf3914…\`; Candidate A correctness remains accepted at \`1d98a83d…\`. **A-vs-B performance is UNDECIDED.** Do not silently promote the B optimization as faster and do not call a docs-only successor commit a new Native acceptance.

**NEXT — QA-only, no new stage:** build a same-run, same-OS/Dart-version, fixed-input A-vs-B benchmark contract and runner: exact locked source blobs for A and B, canonical test input/output digest equality, warm-up separated from five or more alternated timed pairs, raw data plus robust median paired differences, source commit/run/job/artifact provenance, and explicit inconclusive-result path. Do not repeat the accepted 26-job run solely to collect the same evidence. Only retain B as a speed optimization if controlled evidence justifies it; otherwise preserve A while keeping the regression evidence. No protected-branch change or release.

