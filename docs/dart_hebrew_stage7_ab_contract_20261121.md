# Dart+עברית — Stage7 controlled A-versus-B QA contract (2026-11-21)

Project: PC-BRANCH-DART-HEBREW. Scope: **QA-only comparison of accepted Stage7 candidates**; no Stage8, no production replacement, main, merge or release.

## Immutable inputs and source provenance

- A: commit \`1d98a83db7446ceb4548c39e0eaf9b4441b72b9a\`, original planner blob \`3553a7f2e3899c958d56620c5449daa35b0731e2\`.
- B: commit \`01cf39143731782bb96cc4d9c9a7075195693344\`, original planner blob \`d736ca8afe3409a10474b8514284aceb154a46a9\`.
- B's direct parent must be A. The A-to-B changed-path set must be precisely the planner, the Stage7 profiler and the Candidate B feasibility document. The runner creates two detached worktrees from those exact commits, never cherry-picks a production file or reconstructs a modified contender.
- The **identical QA probe** is placed, untracked, in both worktrees. Both execute sequentially on the same GitHub-hosted Ubuntu job using Dart SDK **3.13.2**. Time-dependent host load remains an important limitation.
- Fixed canonical input: foundation \`-15055671\`, year 5000, 4,244 days, 45 months; canonical plan uses the original §V bowl-4/seal-32 selection. Time only \`MonsterMonthWeavePlanner.plan\`, not Dart startup, digest, file I/O or prior year/length calculation.

## Mandatory correctness locks and timing

Before measuring, each original source independently computes **COUNT**, **FIRST**, **LAST**, **CANONICAL**. SHA-256 is over exact decimal count or comma-separated one-based month IDs as UTF-8 **without trailing newline**, and must equal the four accepted baseline digests recorded in \`tool/dart_hebrew_stage7_ab_runner.py\`. These locks were accepted in Stage7 runs [A 44877189934](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44877189934) and [B 44890464671](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890464671).

Run an **unmeasured warm-up** per contender, verify its canonical digest, then collect **five sequential paired** canonical timings in microseconds. Alternate order AB, BA, AB, BA, AB. Each timing is validated against the same canonical SHA-256. Preserve raw timings, paired B-minus-A deltas, paired percentage speedups, per-contender medians, median paired delta, paired speedup median, and number of pairs where B is faster.

Outputs: \`out/dart-hebrew-stage7-ab/results.json\` (full provenance and data), \`pairs.csv\`, and GitHub Actions job logs/artifact. Failure of a lock, source identity, output equality, environment setup or a sample fails this QA run. Missing artifacts or incomplete/queued jobs are **not** PASS.

## Decision rule and caveat

The QA-only marker \`B_OBSERVED_BENEFIT_REVIEW\` requires B faster in **5/5** pairs, median *paired* speedup at least **2%**, and the minimum paired speedup at least **1%**. Otherwise: \`INCONCLUSIVE_DEFAULT_A\` (retain simpler accepted A for any future selection; B remains an experiment). These thresholds are engineering screening criteria, **not** a statistical significance test or proof across machines/workloads. Even a positive marker is a request to review evidence, **not** automatic performance acceptance or authorization to change production. No later documentation commit inherits Native acceptance: A correctness at its original SHA; B correctness at its original SHA.
