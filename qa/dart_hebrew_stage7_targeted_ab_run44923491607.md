# Dart+עברית — Stage 7 targeted A/B QA run 44923491607

Project: `PC-BRANCH-DART-HEBREW`
Date: 2026-11-21
Classification: **QA-only measured result; NOT performance acceptance, NOT production selection, NOT a full Stage acceptance.**
GitHub source HEAD/run SHA: `71faa25858f691ca1a44eedd32acc008cc9e376b` (unchanged during test)
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607
Targeted job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607/job/136904389242 — completed/success
Run conclusion: completed/success; 27 successful jobs and 1 intentionally skipped legacy A/B job.

## Exact evidence

Artifact URL: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607/artifacts/14715470687
Artifact ID: `14715470687`; 6 files; ZIP SHA-256 `57a15b7369c7e2711fcd4854fae10d8e32edce9e17804b3508d1270179dc348e` (GitHub digest and independent downloaded-byte check agree).
`results.json` SHA-256: `9213f0e6acc3be9c30c5c98819ab184f933e39aab982429f8b0494d9a7688c0e`.
`pairs.csv` SHA-256: `276e305b8d1aa0775aeb1d48b62e60c866bab5e7da92c1e1c489b59adc3139e9`.
Original source-lock Git blobs: A `3553a7f2e3899c958d56620c5449daa35b0731e2` at commit `1d98a83db7446ceb4548c39e0eaf9b4441b72b9a`; B `d736ca8afe3409a10474b8514284aceb154a46a9` at commit `01cf39143731782bb96cc4d9c9a7075195693344`. Independent oracle blob `575569a9d96b217675f5b858443f509e3149e56b`, runner blob `81bac58a5bdf5d570acbc6512887084491434f83`. GitHub source reads verified all four blob IDs.

## Independent audit (not a fresh Native run)

A separate offline checker read the downloaded ZIP, verified member names, checked the structured JSON against the raw trace files and CSV, recomputed every paired delta/percentage, median, minimum, faster-pair count and gate, and independently enumerated admissible words using a *sequential opening/closing-order DFS*, distinct from the pre-existing whole-word filter oracle.

| Domain / rank | Independent valid words | A and B output | A day-3 factor | B day-3 shortcut | B faster | Paired median speedup | Minimum speedup | Gate |
| --- | ---: | --- | ---: | --- | ---: | ---: | ---: | --- |
| [4,4,3] / 57 | 461 | identical to independent rank-57 word | 15 | ordinal=2, lower bound=3 | 5/5 | +8.927906% | +3.020059% | PASS |
| [4,4,4] / 127 | 1301 | identical to independent rank-127 word | 35 | ordinal=2, lower bound=3 | 2/5 | -9.308410% | -11.553694% | FAIL |

Every case used five AB/BA/AB/BA/AB pairs, and the runner reported 500 warmups + 5000 timed unrank calls per sample. Dart SDK: 3.13.2 Linux. All raw trace files have matching ordered CHOSEN records and expected day-3 A factor / B shortcut; both candidates return the independently enumerated rank word.

Acceptance gate per case was B faster **5/5**, paired median speedup at least **2%**, and minimum paired speedup at least **1%**. The gate must hold in **both** domains. This was **NOT** met. `INCONCLUSIVE_DEFAULT_A`; do not promote B. The synthetic JIT microbenchmark is not statistical proof of a general slowdown or speedup and does not establish production performance.

## Scope and operational follow-up

- A remains the **accepted selection policy**; no new production/main/merge/release changes authorized.
- Important source distinction: current QA branch HEAD actually contains the B planner blob `d736ca8...`. That branch fact is **not** evidence that B was selected/released as default. Do not silently replace HEAD with historical A SHA or revert a production file under this QA-only task.
- Existing source-level Stage 7 correctness acceptance on historical A/B source SHAs remains valid in its own scope; this run only accepted execution/completeness of the targeted QA job and independent artifact audit.
- NEXT: close this measured Stage7 B-performance promotion attempt as **gate failed**, retain A selection, and investigate a materially new algorithmic hypothesis only if it predicts a workload-wide gain. Do not dispatch a duplicate of this benchmark on the same SHA. Resolve the QA-branch B-vs-selected-A distinction before any release/production action. No Stage8.

No user-local execution results were involved; no `/Pending_User_Execution` cleanup is triggered.
