# SQL+தமிழ் — Slice23 PostgreSQL 17 acceptance: choose_month_names

**PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`  
**Date:** 2026-11-06. **Decision:** **Slice23 ACCEPTED**, native PostgreSQL 17.11 and source-locked artifact review.  
**Original tested branch:** `SQL+தமிழ்`, **tested commit:** `d61dfbeef318ea7d73f86bb9703c00eb771bb77e`.  
**Run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42177386297 (attempt 1; completed/success).  
**Source implementation:** https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/c69b030f3ddfd1ad4e81688969107830488a6740  
**Test/CI commit:** https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/d61dfbeef318ea7d73f86bb9703c00eb771bb77e

## Acceptance gates and observed evidence

- All **10/10 original jobs** were `completed/success` on exactly the tested commit: `native`, `isolation`, `a1`, `a2`, `b1`, `b2`, `c1`, `c2`, `d1`, `d2`. Verified original job logs, not just workflow overall status.
- `native`: **96/96** distinct named checks reported true; explicit `slice23_native_all_green=1`. Among them **64 complete expected integer arrays**, each checked against the independent Python golden generator, and **32 semantic/boundary checks**. The 64 golden arrays cover `k = 3,4,5,7,12,17,31,47`, eight ranks per k. Independently recomputed and matched **64/64 SHA-256 hashes** of the comma-joined array values in the original artifact ZIP.
- Standalone Python oracle from the original native job: `slice23-oracle=PASS exhaustive_small=2360 goldens=64 distinct_k=8 max_k=47 reference=independent-Python`. The oracle brute-enumerates small-domain permutations and has no SQL-production import.
- `isolation`: **11/11** named assertions true, including production-only signature, immutable/strict properties, no normative test schema, no name cache and repeatability; `slice23_isolation_all_green=1`.
- Eight independent PostgreSQL differential jobs (`a1/a2/b1/b2/c1/c2/d1/d2`): all **8/8** yielded `exact_array_match=t`, `length_ok=t`, `uniqueness_ok=t`, `range_ok=t` and a successful corresponding `diff_*_exact_array` scalar gate; four distinct reachable k values **3, 5, 17, 47**, two sauce variants per k. These compare complete `integer[]` values, not only digests.
- Every original ZIP contains `versions.txt` declaring exactly the tested SHA and **PostgreSQL 17.11**. The original run used pinned source `git rev-parse HEAD = GITHUB_SHA` and `psql -v ON_ERROR_STOP=1`.
- **10/10 original ZIPs downloaded and independently SHA-256 verified** against both GitHub artifact metadata `digest` and upload-job log digest. **10/10 ZIP CRC** checks passed. All 10 manifests `source-sha256.txt` are byte-identical and source-locked. **10/10 generated file SHA-256** checks passed: eight `differential-case.sql` files plus `goldens.sql` and `golden-hashes.txt` in the native archive. These are **10 files across 9 generated-file archives**, not a claim of 10 separate jobs generating scripts.
- No `ERROR:`/`FATAL:` in the original `result.txt` files; all explicit all-green markers and numeric counts were checked from ZIP contents.

## Original artifact digest register

The SHA-256 strings below were individually matched against GitHub artifact metadata, corresponding job upload logs and locally downloaded original ZIP bytes; all CRC checks passed.

| Case | Job ID | Artifact ID | Original ZIP SHA-256 |
|---|---:|---:|---|
| native | 127758862336 | 13483884100 | `682e5d417ac61871023d38d745230318eff18786e46b622babefb6d2b7794a05` |
| isolation | 127758862374 | 13483819759 | `f977fe7131013e3487c774016034ec367969b56b858f8925a5937a871a913570` |
| a1 | 127758861881 | 13483877354 | `a9c13e3c0e7d7017eb22eab27fb6db153abea4088baa84589fe0d99306330e38` |
| a2 | 127758862259 | 13484691196 | `7b3bb2dacab88b25874e222f0765f05abae5a6e4c342c9d27a685715b20a1246` |
| b1 | 127758862287 | 13484651136 | `36b1c987757179750b78bd903864b29004d8e919deb23b3ee6ce4648fd0db7cc` |
| b2 | 127758862402 | 13485045230 | `0606ea802bb97460cacdf1635025ed1bfb7e8e986dff62238da8709b6375ad14` |
| c1 | 127758862276 | 13484056590 | `357902bb4e790837275d3ef79330a3afc2455082d4f6f7b5c50ecb3e6a8b0926` |
| c2 | 127758862256 | 13484460484 | `8f9308833d26e45de4210e67983946dcd7e726366d6afc7ae20dfd7ef26fc2b6` |
| d1 | 127758862406 | 13484023134 | `d29f88f33892f0841f7456d104ec59fc4ad271808a7f9e9cd8dd1902b25aa407` |
| d2 | 127758862299 | 13484221397 | `1e6071592bf275dbfc960cac04d7ccf5f0ce25ad86b4d934a3202534bc67e733` |

## Source SHA-256 in every original artifact

- `sql/25_stage02_month_names.sql`: `eb3cc710f2ba1b845fbdc76e7e90ba0bdaa824000a5d71b6479c9f3b0d03e829`
- `sql/test/136_stage02_month_names_oracle.py`: `bc7b70e6e6cc079252d07fe02ed222e8669d24abde391a449ef7d5f3e64be34e`
- `sql/test/10_normative_reference.sql`: `6d0dcc7a5ee6e696461fc2623736c702419591bed9c7e6c21ced21ade6d75220`

The 10 ZIP manifests agree on these values. Git blob identity for the normative reference is `ce17bf6fd166451b6904411c5e29d1b26d92e278`, confirmed at tested HEAD; Git blob SHA-1 and file SHA-256 are distinct identifiers.

## Decision boundaries

This acceptance covers Slice23 behavior on the tested source commit and explicit contract gates. It **does not** claim Stage2 overall completion, validation of future integration, migration to `main`, or external publication. Do not rerun this accepted Slice23 SHA just to reconfirm PASS.

**NEXT:** engineer Slice24 `build_year_structure` integration under a separate source-locked contract and independent oracle, preserving reference isolation and original-artifact checks. See `artifacts/stage-02/SLICE_24_YEAR_STRUCTURE_CONTRACT.md`.
