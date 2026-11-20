# SQL+தமிழ் — Slice25 structural preflight ACCEPTED (production NOT ACCEPTED)
**PROJECT_ID:** PC-BRANCH-SQL-TAMIL
**Date:** 2026-11-20
**Exact source:** `1ddaef9a315f83402ececaf4dc31f96dbdd051bd` on `SQL+தமிழ்`.
**Natural push PG17.12:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191 (attempt1 completed/success, 8/8 original jobs).

## Original evidence and independent verification
- All 8 original job logs inspected; GitHub artifact ZIPs downloaded in original binary form. **8/8** raw ZIP SHA256 checks match GitHub metadata and upload-job SHA256; **8/8** ZIP CRC checks pass, 12 members each.
- **40/40** generated/derived SHA256 entries within eight original ZIPs validated; 8/8 source manifests identical (31 source paths), 8/8 exact source SHA and PG17.12 versions. Original Python oracle self-tests in each of 8 jobs: 9411 cutlet/day and 22890 month-position tests PASS.
- Real PostgreSQL data: 8/8 structural green; **8 distinct years** 4996,4997,4998,5000,5001,5002,5003,5004; all cutlet-prefix gate positions, year length, month weaving occurrence totals and canonical indices internally consistent; 64 unique Tamil catalogue entries, identical across jobs.
- **29/29** independent Python ordinal recomputations from downloaded PG17 year JSON (five exact typed Tamil result fields) equal original Python oracle values. Additional JS recomputation from original job logs produced these **29 source-locked fixtures**, preserved in `sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl`. Each fixture records the calculation/target days, case purpose, five expected fields, original ZIP ID, and exact source SHA. This is an **ordinal/structure preflight**, not a Native comparison with production `calendar_date`.

| Year case | Year | Source-locked dates | Original ZIP | SHA256 (GitHub/upload/actual bytes) |
|---|---:|---:|---|---|
| anchor | 5000 | 6 | [ZIP 14613743791](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14613743791) | `54870a11698f23e2b6a21f7825ed1ac0fdb0bb907039ff01b6fd43fa1ef01c75` |
| next_1 | 5001 | 5 | [ZIP 14614701184](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14614701184) | `e1f52060af62d15554794e3e6695a95d8bf7db8b44b2d6ddcbb65d3a2120ef56` |
| next_2 | 5002 | 3 | [ZIP 14614830269](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14614830269) | `64e5ac64da6a15a2035ba912b011bb18a5f4ec0ad876edec9222bb5569a7228c` |
| next_3 | 5003 | 3 | [ZIP 14614018802](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14614018802) | `160d4e4470702dd1a157fa08b435458f1ce92044ce485483d75a6e38c9bd7b8b` |
| next_3_next | 5004 | 3 | [ZIP 14613823846](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14613823846) | `5cf458be07cc19b258997f38a5af30e7316b61f0bad0688043537703a91cac81` |
| prev_2 | 4998 | 3 | [ZIP 14614715487](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14614715487) | `44f7ef3d743d12b506542a55e27b93165727aac791e7ffd9974f0ea80f74f1f9` |
| prev_3 | 4997 | 3 | [ZIP 14614455831](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14614455831) | `d77902efb02af29aabd1e124e2f9b4a548a2e8d621ab56784f9f66a8f75c8785` |
| prev_3_prev | 4996 | 3 | [ZIP 14613763506](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701320191/artifacts/14613763506) | `615d08589a6b21386553e401470f3ee8707fbd38957c4fdf04aa3279ae792898` |

## Engineering NEXT
- `sql/18_stage02_target_year_navigation.sql` uses recursive `find_target_year` with sequential calls to `next_year`/`previous_year`; accepted integral domain `abs(p_target_day-p_calculation_day) <= 60000`, at most 256 steps. Earlier probes of the unchanged selector took 6m43s and 9m19s; all eight preflight logs explicitly say `slice25_selector_deferred ... reason=performance`.
- Next authorized work is **QA-only bounded selector baseline/equivalence** with the 29 exact fixtures, sharded into per-input PG17 jobs (<=12min statement timeout; <=15min job), testing exact five numeric year_rec fields and NULL/fractional/out-of-domain/boundary semantics. Measure timing and preserve logs+original ZIPs. Do not call the old selector repeatedly without new evidence.
- Only optimize production navigation after source-locked performance and field-wise equivalence tests demonstrate correctness. The Slice25 `calendar_date(numeric,numeric)` production function remains unimplemented; later gates: Native>=40, isolation>=8, differential>=24 and independent original ZIP verification. **No main, merge, publication or production change in this commit.**
