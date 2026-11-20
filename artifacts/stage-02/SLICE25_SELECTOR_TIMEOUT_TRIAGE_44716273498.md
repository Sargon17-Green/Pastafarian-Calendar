# SQL+தமிழ் — Slice25 selector baseline original evidence + primitive diagnosis

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL  
**Date:** 2026-11-20  
**Source-locked run:** [44716273498](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44716273498), `SQL+தமிழ்`, exact SHA `7b4b5edbf6b6f0a4c99ab6fcbeaf41d4460e99f3`.  
**Scope:** Review eight original completed PG17.12 jobs and prepare a bounded, independent **QA-only** primitive diagnostic. No production, normative, `main`, merge or publication change.

## Verified original evidence

The eight GitHub job logs were read, all eight original ZIPs were downloaded and independently hashed, and ZIP integrity was checked (`ZipFile.testzip() == None`). For every case, the **GitHub artifact metadata `digest` = original upload job log ZIP SHA256 = calculated downloaded ZIP SHA256**. All eight CRC checks passed, all eight show the exact source SHA and PG17.12. Each job generated exactly one source-locked input from eight records/29 goldens. Six invalid-input flags are present in each original log.

| Case | Job ID | Artifact ID | ZIP SHA256 (GitHub = upload log = downloaded bytes) | Selector milliseconds | Result |
|---|---:|---:|---|---:|---|
| prev_3_prev | 136220371517 | 14622103412 | `e7852cbcd8c40ad294baa442b44f956e5d5674b3e66f23cf6ff113354e2ff013` | >=720000 | statement timeout; no five-field comparison |
| prev_3 | 136220371027 | 14621863356 | `ac41dbf2fdd30247213a52559cd2ae5af0e0295752e7010ca639b2b8de802212` | 662832.339 | five fields PASS |
| prev_2 | 136220371338 | 14622986260 | `913014e610cfc04812de624f2fcab28656304f6ae4f2c6792823b6ad06ab821d` | >=720000 | statement timeout; no five-field comparison |
| anchor | 136220371543 | 14622068580 | `e2c514af089367a150cb58ee95f8d19e6e24c6f3e09d15887410d0bf77801aa8` | 299484.216 | five fields PASS |
| next_1 | 136220371619 | 14623231163 | `aa4f265ba432216408f6cd6f3c300daf616c916fb3fe7f43c8ab6d326e5235b4` | 449550.495 | five fields PASS |
| next_2 | 136220371552 | 14622801946 | `5c6a6a15e75e2f321c38e37d544cace46d6bda763cacb46a652fe35b642d2995` | 557887.373 | five fields PASS |
| next_3 | 136220371486 | 14621724423 | `9bd9e5e2c14707fe471ad24bc37838d4a7053a1befd6c2bb0fc35801938af152` | >=720000 | statement timeout; no five-field comparison |
| next_3_next | 136220371581 | 14623500692 | `4bf271e98330fa4b4692e1af2e148fef74bdc5802ff4831e8e8b0aab6bc86d6b` | 516917.216 | five fields PASS |

**Aggregate:** 8/8 completed; 5 success, 3 failure; 8/8 original ZIP SHA256 triplets and CRC; 8/8 initial fixture locks and 48/48 invalid flags; 25/25 exact field flags in five successes; **0/3 numeric results from timed-out jobs**. These observations are **not** eight selector PASS and **not** Slice25 acceptance. Original timed-out ZIPs lack `completion.txt` as expected. Stage1 run 44716273468 and Names Lock run 44716273548 each have a completed/success job on the same source SHA; they are distinct workflows, not selector PASS.

## Scope of measured failure and analysis

All three failed jobs report `ERROR: canceling statement due to statement timeout` at `sql/test/154_stage25_selector_benchmark.sql:102`, after the six invalid-input checks and before the timed selector returned. The baseline `statement_timeout` is 12 minutes, and no per-field mismatch was observed in five completed cases. The production `find_target_year(numeric,numeric)` in `sql/18_stage02_target_year_navigation.sql` starts from `year5000` and moves through `next_year` / `previous_year` for each year until the desired range is reached; these costly primitives are plausible contributors, **not yet demonstrated as the actual bottleneck**. The baseline alone cannot apportion cost to seed/adjacent steps.

## Atomic QA-only targeted diagnostic

New generator `sql/test/155_stage25_selector_hop_input.py` requires precisely eight source-locked `year_rec` records, the original 29-golden SHA lock, seven valid adjacent pairs and one common calculation day; it generates **one** typed SQL fixture for each of these seven independent probes: `seed` (year5000), `next_1`, `next_2`, `next_3`, `next_3_next`, `prev_3`, `prev_3_prev`. The two backward probes use accepted previous-year transitions 4998→4997 and 4997→4996; no invented 4999 record or unproven inverse navigation is used. The four forward probes use 5000→5004 in increasing order.

New `sql/test/156_stage25_selector_hop_benchmark.sql` measures **one** actual production primitive call (`year5000`, `next_year` or `previous_year`) per case, then verifies the five exact numeric result fields against locked original records. Each case is bounded by a 12-minute SQL statement and a 15-minute job, and fails if any field differs; no cache, reference schema or normative function supplies expected values. New workflow `.github/workflows/sql-tamil-stage02-selector-hop-diagnostic.yml` includes seven independent PG17 jobs and original artifact preservation on failure.

Local QA: Python source compiles; all **7/7 source-locked pair-generation cases** passed on the eight verified year values using a local synthetic transport of those source records (not the live PG engine). PostgreSQL runtime for this new diagnostic is **not yet assessed**. It must run by its natural push; do not dispatch a duplicate run on the same SHA.

## Gate and next action

The completed baseline establishes a real performance fault against the 12-minute budget; it **does not** justify changing the previously accepted production SQL by conjecture. Inspect the new seven-job PG17 logs and original ZIP SHA256/CRC; identify the dominant production primitive or first incorrect boundary, then prepare an equivalence-preserving, source-locked optimization and validate full selector and Slice25 calendar-date acceptance separately. Slice25 `calendar_date` remains NOT IMPLEMENTED, and there is no main/merge/release authorization.
