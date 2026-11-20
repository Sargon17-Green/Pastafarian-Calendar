# SQL+தமிழ் — verified Slice25 primitive latency and next bounded component profile

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL. **Date:** 2026-11-20.
**Source lock:** `SQL+தமிழ்` HEAD `39b5c8e2dc66c7289ba0eddf33c063665c338ffe` before this QA-only commit.
**Original natural push:** [44734929602](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734929602), completed/success attempt 1; seven original PostgreSQL 17.12 jobs.

## Original job and artifact verification

All 7 original job logs and ZIP downloads inspected. Each ZIP: SHA256 of downloaded bytes exactly matches the original upload-job digest and GitHub artifact metadata; `ZipFile.testzip() is None`, 7/7. Each manifest declares exact source SHA and same 31 source paths; generated `input.sql` hash equals the embedded generated-sha256.txt (7/7); every `completion.txt` is present. Exactly 7/7 independent year primitives returned all five correct numeric fields (35/35) against frozen accepted year records. This is **primitive diagnosis**, not a full selector PASS or Slice25 calendar_date PASS.

| Pair | Job ID | Artifact ID | ZIP SHA256 | Actual primitive milliseconds |
|---|---:|---:|---|---:|
| seed | 136283805961 | 14630279309 | `11a553ba593d880f28d87a86f126c869acfe57b9a79cd581f6edd7d2b4532ce3` | 379353.083 |
| next_1 | 136283805992 | 14629449677 | `95b9750bf4a437f114e097461fa3a92313b9db4820f10393afff072c5eb507de` | 114358.846 |
| next_2 | 136283805863 | 14630278402 | `3ead9e73a074cfb82a70311bd11f43e4f23647c7b21e8be526875d7318a87c31` | 124853.981 |
| next_3 | 136283805743 | 14629234852 | `8d47e5a59d74ecb797109105c37407d4c72e1e59b110f653d8aadb13da79c558` | 84580.849 |
| next_3_next | 136283805355 | 14630516462 | `d4ef01bb5576d2dbd5c523c7d739d1b75aff1d05dc1a3654eb86b55dc6eca9ef` | 77560.154 |
| prev_3 | 136283805934 | 14630806042 | `0b73b374a28d69a1b25dd3e12b01de4f7ce169c9425cca284dd63b438f5ada60` | 75837.625 |
| prev_3_prev | 136283805920 | 14630666154 | `dfc22401a58fc1f8b16f031574d625e4a98f3cd6717d5de407773f1d343f4ea7` | 67194.789 |

Other same-SHA runs: Stage1 [44734929532](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734929532) completed/success; Names Lock [44734929462](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734929462) completed/success. Full selector baseline [44716273498](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44716273498) previously timed out 3/8 at 12 minutes, and succeeded in 5/8; no re-run.

## Grounded engineering implication

The real year5000 seed takes ~379 seconds in its own isolated job, and each adjacent-year primitive 67–125 seconds. For a chain of four forward hops, the independent observed seed and four hop durations total approximately 781 seconds; these independent timings are diagnostic, not an exact end-to-end measurement, but support cumulative runtime as a plausible cause of the 12-minute selector timeout. There are no incorrect fields in the seven completed probes.

The next *single-job* QA-only profile calls the same production `year5000_gate_window`, `year5000_gate_pairs`, and `sauce/ask_bowl/choose_rank` components, timing each separately, then compares the same five output fields to the locked accepted seed record. Its statement budget is 12min, job budget 15min; all PostgreSQL sources are loaded in indexed order 00–26 and checked against source SHA manifests. Original evidence is saved on failure. This does not claim that the dominant internal function is known yet. Production SQL is unchanged.

**Next gate:** inspect natural component profile on its exact SHA, original log and ZIP digest/CRC, use measured phase contribution to select a semantics-preserving optimization, then recheck the original full 8-case selector baseline and proceed to Slice25 `calendar_date` with independently derived >=24 records and Native/isolation/differential acceptance gates. No main, merge or publication.
