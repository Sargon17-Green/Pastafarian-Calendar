# Stage 1 — R75 original Native two-seed CI acceptance (2026-10-28)

**Project ID:** `PC-BRANCH-PERL-GUOYU` — `Perl+國語`.  
**Evidence-bearing branch HEAD at CI:** `02bd39edab693f10a62433aa49d1834edb2cbaa3` (do not confuse with the documentation commit).  
**Live evidence:** [run 40674037609](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609), completed `success` 2026-10-28 11:07:57 UTC, attempt 1.  
**Workflow source:** [stage01-r75-native-two-seeds.yml](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/02bd39edab693f10a62433aa49d1834edb2cbaa3/.github/workflows/stage01-r75-native-two-seeds.yml).  
**Scope:** Existing Stage 1, original `tools/profile_r75_fivemonth_prefix_tree.pl` with original dependencies on GitHub-hosted Linux/Perl (not the independent substitute). No Stage 2 approval.

## Verified CI outcome

- 9/9 additional original Native R75 matrix jobs completed `success`: first × second = 1..3 × 1..3. Each job ran `PERL_HASH_SEED=11` and `97`, i.e. 18 successful original native invocations.
- All 18 emitted one `R75_COMPLETE passed=1 blocked=0 failed=0` line and one `R75_WATCH passed=1 blocked=0 failed=0` line with the matching pair. Each job reported `R75_TWO_SEEDS result=PASS`. Original Native stderr was required empty, exit 0 was checked and successful; comparison `cmp evidence/seed_11.complete evidence/seed_97.complete` passed. The two result digests and all checked result fields were identical within each pair.
- 27 vectors per pair, total 243 per single nine-job pass; 86,543 legal words per complete nine-job pass. Same words are re-evaluated under two seeds; this is **not** a claim of 173,086 distinct words.
- Maximum logged `max_RSS_KiB` across the 18 invocations: **19,308 KiB**, within the 393,216 KiB ceiling. Original runner configured `--seconds 185 --rss-kib 393216`, with external timeout 195 s; all finished within limits.
- Nine distinct workflow artifacts `r75-native-*-two-seeds` were reported and listed as present and not expired at audit time. Their ZIP bytes were **not** separately downloaded and independently re-hashed in this audit; the links and run logs are the provider evidence.
- `verify`: `success`. `perl-stage01`: `success`; full test suite: **97 files, 89,620 tests, Result: PASS**. The existing `Wide character in print at ... Test2/Formatter/TAP.pm` diagnostics were observed in the latter log: **not** proof of clean TAP/UTF-8 diagnostics. They did not fail the suite. Some cache-path/Node deprecation warnings were also present.
- Historical `R75 五個月全深度前綴` jobs in the same run were intentionally `skipped`; do not misreport them as the nine successful two-seed jobs.

## Per-shard Native evidence (both seeds matched)

| Pair | Words per seed | Depth nodes 0–4 | Endpoints | Partitions | Outside | Digest of original R75 result (`sha256` field, identical for both seeds) | Max RSS KiB | Native job | Saved artifact |
|---|---:|---|---:|---:|---:|---|---:|---|---|
| 1-1 | 215 | 27,27,27,27,39 | 588 | 108 | 24 | `06e2c1f648cb139a0d5b59151efc366fbf2f6b96ef815ea875f030af197a45e1` | 18660 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770768) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12810111417) |
| 1-2 | 892 | 27,27,27,45,66 | 768 | 126 | 114 | `2d7fe0bbddfe3cd8966ad4f8ea12d54444f1074c2125d1020d00197e22a611f1` | 18860 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770765) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12810176157) |
| 1-3 | 2596 | 27,27,27,45,84 | 840 | 126 | 150 | `93039a0b1d5b00cf0438e2170240bee4631a0e4615494ff939540b1bec092761` | 18964 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770870) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12809474620) |
| 2-1 | 215 | 27,27,27,27,27 | 540 | 108 | 0 | `f531a02d6ee02f472db23502bec3e21b83b3fe7e0f09055ba6ddc18d77f468cf` | 18792 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770875) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12810153734) |
| 2-2 | 3488 | 27,27,54,72,129 | 1236 | 180 | 348 | `2a8bfff1d65378526c348c492ecb361abd07b6cf0c9a7c5b8f3dfc818e3998ff` | 18924 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770792) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12810693200) |
| 2-3 | 15016 | 27,27,54,99,192 | 1596 | 207 | 528 | `140eb44287900c69b71f19a9b1bfef789f3ff9c2e1c57641e2177399cab1a7e8` | 19124 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770829) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12810633245) |
| 3-1 | 215 | 27,27,27,27,27 | 540 | 108 | 0 | `c834da8df6b478810fe393ea4ea2eafd75dab3fb001977ef241629526fe796cf` | 18736 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770824) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12810733541) |
| 3-2 | 9698 | 27,27,54,99,156 | 1452 | 207 | 456 | `ee23c98e54a853343740ccbcdcd2b2f0bfc33724440182ab3dd86fc946f639da` | 19004 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770903) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12811406724) |
| 3-3 | 54208 | 27,27,54,126,273 | 2028 | 234 | 744 | `f577b9edfe3ddbf0f1bdff1ec06e57eb204c85a2f95d245cd64b43558c5f9a32` | 19308 | [job](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/job/122767770871) | [artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609/artifacts/12811452242) |

Values are transcribed from the nine completed original-Native workflow-job logs; each row's peak RSS is the larger of its two seed observations. The SHA field hashes the original test's canonical result, **not** the artifact ZIP.

## Acceptance and remaining boundaries

**Accepted, bounded claim:** the exact pre-documentation SHA's original R75 nine-shard two-seed CI matrix completed successfully, with identical outputs under hash seeds 11/97, bounded runtime/RSS, and intact original stdout/stderr/exit comparison checks. This closes the specific CI-based 9×2 original-Native rerun requested as the immediate NEXT, even though a separate local workstation checkout remains unavailable.

**Not established:** full 45-month/4,244-day year correctness, all 47-month stress cases, removal of preexisting TAP UTF-8 warnings, an independent byte-level audit of the nine artifact ZIPs, or a Stage 1 completion decision. Preserve prior independent Perl QA evidence at [2026-10-27 independent report](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/02bd39edab693f10a62433aa49d1834edb2cbaa3/docs/STAGE_01_R75_INDEPENDENT_LOCAL_QA_2026-10-27.md) and the earlier failure run 40235684653 rather than overwriting history.

**Next within Stage 1:** narrowly investigate the preexisting `Wide character in print` TAP-output diagnostics, identify whether they reflect display/output encoding only or an actual assertion/data fault; avoid modifying production code absent demonstrated regression. No repeat of already-passed run, no Stage 2, merge, or main changes.
