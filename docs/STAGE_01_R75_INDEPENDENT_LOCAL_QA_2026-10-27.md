# Stage1 — R75 independent local Perl QA (2026-10-27)

**Project:** PC-BRANCH-PERL-GUOYU  
**Branch:** `Perl+國語`  
**Original R75 HEAD:** `ca65b5cf127503cabbf352394b41a8e3d56c6c04` (confirmed before saving).  
**Local test source:** [tools/qa_r75_independent_fivemonth_prefix.pl](../tools/qa_r75_independent_fivemonth_prefix.pl).  
**Important scope:** Independent Perl exhaustive lexicographic enumeration; **NOT** a rerun of the original `tools/profile_r75_fivemonth_prefix_tree.pl` and its rank/unrank dependencies. Do not use this to claim an additional native-R75 run.

## Actual local evidence

- Environment: Linux `/proc`, Perl 5.40.1, `LC_ALL=C.UTF-8`.
- Executions: 9 shards (`--first a --second b`, a,b=1..3), twice per shard with `PERL_HASH_SEED=11` and `97` (also `PERL_PERTURB_KEYS=2`).
- All 18 processes exited 0, produced success records and empty stderr; both seeds yielded exactly identical record per shard.
- Limits enforced by a local parent observer: walltime 185 s, observed RSS 393216 KiB; kill on limit breach. Observer polled /proc and measured maximum **observed** RSS, not guaranteed instantaneous peak.
- 243 length vectors checked; aggregate 86543 legal words **per complete nine-shard pass**, enumerated in lexicographic order.
- Each prefix at depths 0..4: contiguous interval and endpoints, partitions, and nearest outside-neighbor mismatch checked. Nine SHA-256 digest fixtures, node-count fixtures, outside-neighbor fixtures, and counts matched.
- Unicode UTF-8 encode/decode smoke of `第七十五輪：五個月份檢查 國語 ✅` passed in all runs.
- Maximum **observed** RSS: 16408 KiB. Maximum elapsed walltime: 0.585 s. No new regression observed.

| shard | words | nodes (depth 0–4) | endpoints | partitions | outside | observed RSS KiB (seeds 11/97) | elapsed seconds (11/97) |
| --- | ---: | --- | ---: | ---: | ---: | --- | --- |
| 1,1 | 215 | 27,27,27,27,39 | 588 | 108 | 24 | 7620 / 6516 | .052 / .031 |
| 1,2 | 892 | 27,27,27,45,66 | 768 | 126 | 114 | 7708 / 7740 | .041 / .041 |
| 1,3 | 2596 | 27,27,27,45,84 | 840 | 126 | 150 | 7884 / 8088 | .053 / .074 |
| 2,1 | 215 | 27,27,27,27,27 | 540 | 108 | 0 | 7680 / 6636 | .041 / .031 |
| 2,2 | 3488 | 27,27,54,72,129 | 1236 | 180 | 348 | 7936 / 7980 | .093 / .072 |
| 2,3 | 15016 | 27,27,54,99,192 | 1596 | 207 | 528 | 10020 / 10024 | .164 / .155 |
| 3,1 | 215 | 27,27,27,27,27 | 540 | 108 | 0 | 7712 / 6880 | .041 / .031 |
| 3,2 | 9698 | 27,27,54,99,156 | 1452 | 207 | 456 | 9212 / 8580 | .113 / .114 |
| 3,3 | 54208 | 27,27,54,126,273 | 2028 | 234 | 744 | 16408 / 16408 | .483 / .585 |

## Reproduce (independent test only)

Run the linked Perl script from the repo root for each pair with two hash seeds, capturing stdout/stderr and exit code. Enforce `--seconds 185 --rss-kib 393216` equivalents in an external /proc-aware watcher; the standalone independent script itself does not enforce them. Compare normalized stdout byte-for-byte between seeds and confirm all tests exited 0. The script is not a substitute for the project's original R75 CI/native tests.

## Preserved external prior evidence

Original native R75 CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40279609622 at `ca65b5cf`: previously recorded 9/9 R75 native jobs SUCCESS, `verify` and `perl-stage01` SUCCESS. This local independent test does not re-verify those historical CI outcomes.

## Remaining blocker and single NEXT

**Gap:** The specific requested two-seed **local rerun of the repository's original nine Perl Native R75 shards**, including original rank/unrank modules, has **not** been completed. Network DNS from the isolated local container cannot reach github.com; both authorized Desktop Commander machines were offline at the time. Original native module files were inspected through GitHub; no claim that their full dependency tree was executed.

**NEXT:** On a machine with the branch checkout, run the original `tools/profile_r75_fivemonth_prefix_tree.pl` for the nine pairs twice (`PERL_HASH_SEED=11,97; LC_ALL=C.UTF-8; --seconds 185 --rss-kib 393216`), preserve complete original `R75_COMPLETE` and `R75_WATCH` logs, compare SHA/counts/endpoints/partitions/outside/exit and RSS per shard, then fix only an evidenced Stage1 regression. No Stage2, merge or main changes.
