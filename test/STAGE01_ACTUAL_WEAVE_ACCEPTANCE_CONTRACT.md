# Stage 1 actual weaving acceptance contract — canonical reconciliation

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Reviewed evidence commit: `ce900e8d7a0b8805a8a59a2183e0aa8eae374c0f` (Fortran+English).
Review date: 2026-11-27.
Disposition: canonical full-year projection/count/rank gate PASS; Stage 1 NOT ACCEPTED. QA-only; no production algorithm, Stage 2, main, merge or publication.

## Authority and independent review

The governing Hebrew Scroll, Megilat_HaItim_Yehuda_FINAL_2026-09-18.md, was recovered from the Library and hashed again as 82,877 raw bytes: SHA-256 `7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b`. Exact match. Lines 1509–1660 require exact month lengths, both strict endpoint orders, lexicographic whole-weave selection; lines 1806–1885 require building the year once with its first day as the construction target, and counting occurrences inclusively for the five-field projection. This is separate out-of-band source-byte verification; the CI JSON source_bytes_verified=false remains truthful. See STAGE01_CANONICAL_SCROLL_AUDIT.md for source/component crosswalk and the shared old Python post-stir defect. The legacy 45/4244 structure is superseded, not an expected canonical value.

Both exact-SHA automatic push runs 45913529700 and 45913529675, attempt 1, completed success. Job logs and artifact metadata were rechecked; the following three ZIPs were downloaded, SHA-256 matched to GitHub metadata and CRC checked:
- Full year, job 140227224366, artifact 15161372382, b6a257ce71e84ce5a7c729841e617cfeb0e567ba17557ec2437737446b03fb32. Native/diff exit 0/0. Report/raw SHA matched; all actual/expected rows and all rank arrays equal, 4399 month IDs, 21995 date fields, exact 7021-digit count, 17596 IDs over ranks 1,2,N-1,N. Earlier independent reverse-endpoint and occurrence-poset replay retained. Five frequency/order checks. Original build_year_structure once, project_calendar_date for every day, count_weavings and unrank_weaving original routines; not 4399 calls to normative_calendar_date.
- Direct date, job 140227398997, artifact 15161384119, daaad432c128a2129d021805d5169092623b24cad2c8fb97d1ef63fc829e6157. Rechecked all 36 JSON records/180 fields, 33 unique input pairs; actual=expected. The probe calls original normative_calendar_date and resets cache.
- Cache, job 140232358874, artifact 15161689587, aa167d7040fe7218b8791a96044250bf53d9d53fe7326e076b6c5f649d4da6cc. Rechecked all 48 records against same-run direct-date artifact expected pairs (24 warm, 24 reset-each, 240 fields). Probe calls original normative_calendar_date in one process per mode.
- Component job 140227223611, artifact 15161078807; Seal32 job 140227224334, artifact 15161585771 (prior byte/CRC and independent replay evidence, current metadata and logs rechecked). Gate-cache job 140227224295 zero failures; full-mode job 140227224356 and native-compile job 140227224299 success. Seven legacy failures retained as diagnostics, not canonical passes.

## Actual remaining direct-entry coverage gap

The old contract specifically required eight novel direct dates drawn from first/last occurrences of four dispersed month IDs of the actual year. The canonical replacement direct suite reused eight old target offsets: -2022, 2161, -2011, 2175, -1995, 2189, -1777, 2179. Cross-check against exact canonical full-year artifact: four positive offsets are outside year 5000 (canonical offsets -4021..377); four negative offsets are interior occurrences of month IDs 5,4,28,31, respectively. None of the 36 direct-date records at calculation offset zero hits any actual month first/last occurrence. Full-year projection covers those endpoints but does not establish direct entrypoint coverage. This is a coverage gap, not an observed conversion defect.

Retain the original eight-direct-date intent, without adding a requirement for thousands of direct calls. Select dispersed actual month IDs 1,15,30,44 (positional IDs, not canonical name indices). Eight distinct new inputs, calculation offset 0, expected five fields independently available from canonical artifact 15161372382:
| Month ID | Target offset | Expected year, cutlet name index, cutlet day, month name index, month day |
|---|---:|---|
| 1 | -4021 | 5000,10,1,26,1 |
| 1 | -50 | 5000,4,712,26,114 |
| 15 | -4005 | 5000,10,17,7,1 |
| 15 | 335 | 5000,3,335,7,118 |
| 30 | -3974 | 5000,10,48,1,1 |
| 30 | 359 | 5000,3,359,1,88 |
| 44 | -3852 | 5000,10,170,29,1 |
| 44 | 377 | 5000,3,377,29,108 |

NEXT: implement an isolated canonical actual-month endpoint suite using the existing independent Scroll full-date oracle (regenerate expected results, do not use Fortran output as oracle); validate eight unique cases and the endpoint selection against canonical month IDs/frequencies, original direct-entry calls, 8/8 cases and 40/40 fields, bounded execution and exact-SHA log/artifact evidence. No rerun of accepted same-SHA gates merely for review. Then complete remaining Stage 1 acceptance review against the existing bootstrap contract. This is not a production converter: README states the clean oracle is test-only and the production skeleton has no calendar algorithm. No new Stage 2 authorization.

## Historical contract (superseded reference values; preserved verbatim)

# Stage1 normative interleaving: explicit coverage boundary

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Baseline: Fortran+English @ 3ed11b0a4dc0ea83b0c5d4bcbd01e99a9da68923.

Previous run 44892813372 completed 11/11 successful jobs. Those checks include
seven original direct-date results, 14 original calculation contexts / 70 fields,
four original boundary-neighbor dates / 20 fields, and 58 full-mode assertions.
The 45-month 4244-day candidate projection is not an original end-to-end
materialization of a confirmed actual normative 45-month year. Differential
agreement with Python also does not independently prove the specification.

## New gate (QA only)

- Input: original Fortran normative_calendar_date, calculation day -15055671,
  exact Python reference blob d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53.
- Select four dispersed distinct month IDs from year 5000 as actually
  constructed by that reference; take first and last available occurrences,
  skipping known fixed-date QA targets. Record the actual month count and year
  length; do not assume the actual year has 45 months.
- Require sound month counts/length frequencies, eight novel distinct dates,
  exactly five output fields/date, matching input framing, no failures/timeouts,
  8/8 case equality and 40/40 field equality.
- Fortran: per-case 65s wall-clock timeout and 1GiB memory; CI job 18min.
  Retain log, self-test output, and JSON record with exact dates and fields.
- Successful execution proves only those eight selected original-date
  comparisons. It is not full Stage1 acceptance.

## Remaining acceptance gap

Run 44937396296 on SHA
`d5893a6e6820555fee77fa5f006c1647a2c4febb` completed 14/14 jobs. Its
QA-only full-year artifact compared the actual 45-month / 4,244-day year
against the SHA-pinned Python reference: 4,244/4,244 month IDs and
21,220/21,220 date fields, with no discrepancies. This establishes the
actual year structure and full-year build-plus-projection comparison; it
does not establish 4,244 calls to the public entry point.

The rank-boundary extension below is a new QA gate and is not evidence until
a completed run on its own SHA has matching job logs and artifact. The
full-year probe calls the original `build_year_structure` once and
`project_calendar_date` for all 4,244 days; the eight selected
`normative_calendar_date` calls remain a separate public-entry check.
This contract does not silently add a requirement to call that public
entry point 4,244 times. The remaining normative gap is that agreement with
a pinned Python implementation, even across every date and rank boundary,
does not by itself independently prove the canonical specification; that
requires independently grounded normative evidence. No Stage2, main change,
merge or publication.


## QA-only extension: actual 45-month weaving rank boundaries

Input remains the original Fortran year 5000 built from foundation day
-15055671 and the independently pinned Python reference blob
`d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53`.

The added gate must:

- Reconstruct the actual 45-month year with the original Fortran
  `build_year_structure`; do not synthesize month lengths.
- Compute the exact weaving count with original Fortran `count_weavings`
  and compare its full decimal representation with the independent Python
  `MonthWeavingFamily.count()`.
- Execute original Fortran `unrank_weaving` at ranks 1, 2, N-1 and N,
  passing the exact total as the count hint; independently compute all four
  expected sequences with the pinned Python `MonthWeavingFamily.unrank1()`.
- Compare all 4,244 month IDs for each rank, not only hashes or prefixes.
- Check month frequencies and strict first-occurrence and last-occurrence
  ordering for the actual selected weave and all four boundary sequences.
- Retain the full-year projection, exact 21,220 date-field comparison,
  explicit QA-only status, self-test and artifact.

The four-rank boundary gate and five ordering checks are QA evidence only.
They do not call the public `normative_calendar_date` entry point 4,244
times: the full-year probe still builds the original year once and calls
`project_calendar_date` for each day. The eight selected public-entry
differential cases remain a separate, narrower end-to-end check. No Stage1
acceptance, Stage2 transition, main change, merge or publication follows
from these QA results alone.


## 2026-11-27 — exact endpoint gate accepted; bootstrap review

Reviewed source HEAD `7761e8bfb216f95dbe4ddeab6ad4000b539da57f`; automatic push runs 45964710665 and 45964710623 completed SUCCESS attempt 1. Job 140390525047 completed success, 5/5 selector self-tests, 8/8 direct calls, 40/40 exact fields, 205.91 s, 390580 KiB peak. Endpoint artifact 15182721998 (SHA-256 b210eeab24361f5a837514572c08802f24df5e819d4a19fd0d198181d61e577c) downloaded, CRC clean. All eight raw stdout hashes, empty stderr hashes, frame offsets, exit codes and five fields verified against the independent expected rows of same-SHA full-year artifact 15181384449 (SHA-256 1aa644291a96fb866c3f478c4bffcb6109b1816f45a26ff80a9e94612667794b; CRC clean). The full-year artifact's 4399 rows, 21995 fields, 17596 rank IDs, exact 7021-digit count and weave hash matched. The original eight-month-endpoint gate is satisfied; no same-SHA rerun is required.

Rechecked completed jobs: native compile, verify, 58/58 full mode, 215/215 gate-cache, 37/37 component, 30/30 stir bowls, direct 36/36 and cache 48/48. Eight legacy failures are retained as diagnostics against the known defective reference. Current direct-date ZIP 15183167990 and cache ZIP 15184341376 were downloaded and CRC/hash checked; component 15182037658, Seal32 15182288269 and gate-cache 15181594336 likewise. The governing Scroll byte verification remains prior out-of-band evidence; current CI reports do not claim it.

The bootstrap's year-walking boundary coverage still has a specific gap: the old direct-date labels refer to the superseded 45/4244 structure's year transitions. Exact canonical year 5000 at calculation offset zero occupies -4021..377, inclusive. Neither immediate exterior day -4022 nor 378 occurs in the 36 direct-date or eight endpoint inputs. The endpoint calls already cover both interior days. The two missing neighboring days must return year 4999 and 5001 respectively; all other expected fields will be independently generated from the existing Scroll oracle before calling the original Fortran entrypoint. Do not infer a conversion error from this coverage gap. New isolated QA compares two novel calls, 10 fields, verifies adjacent year gate identity, checks exact checkout SHA and preserves raw streams, hashes, JSON, exit and resources. 120 s/call, 180 s/150000-state per oracle build, 600 s/1 GiB overall. No production algorithm change, no Stage2, main, merge or publication. Stage1 remains NOT ACCEPTED pending this targeted gate and final review.

## 2026-11-27 — final bootstrap acceptance review

**Disposition: Stage 1 BOOTSTRAP ACCEPTED at tested SHA `90aa649ab95c9f0a8c7221ccc4cc54d5d3b23fb2`.** This is cumulative review of the existing Stage 1 contract, not a claim made by any individual QA job. The prior QA-only flags and historical dispositions are retained. No Stage 2 authorization, production converter, main, merge or release.

Exact branch HEAD was unprotected and matched the tested SHA. Both automatic push runs 46003949648 (canonical Scroll) and 46003949672 (Canonical Names Lock) completed SUCCESS. All canonical jobs completed successfully. The eight legacy failed diagnostics remain failures against the defective historical reference, as documented in STAGE01_CANONICAL_SCROLL_AUDIT.md; they are not reclassified as passing. No duplicate dispatch.

- Bootstrap: name lock/verify job 140522298066, native compile 140522298203, original full-mode job 140522298165: 58/58, exit 0; BigInt 313/313, six extremes, two expected overflow rejections, 13/13 invalid inputs. The original suite covers 17/47 frozen catalog names, neutral dispatch, deterministic trace and observational metrics. The bootstrap module was reviewed: it imports no oracle and contains no production calendar algorithm.
- Canonical stir 30/30 and component differential 37/37 (job 140522297550; artifact 15201010137). Gate-cache structure job 140522298327, no failures (artifact 15200725593).
- Full canonical year job 140522298281, artifact 15199278549: 4,399/4,399 month IDs and 21,995/21,995 date fields, exact 7,021-digit count, 17,596/17,596 IDs across four boundary ranks. Raw log SHA matched; native/diff exits 0/0, empty native stderr. Rechecked all actual/expected rows and ranks, five frequency and endpoint-order invariants. Independent Seal32 job 140522298364, artifact 15200426120: 4,399 IDs and 5/5 fields; its complete weave and count independently cross-checked against the full-year artifact.
- Direct date job 140523018446, artifact 15201593180: 36/36 calls, 180/180 fields, 33 unique input pairs. Cache job 140534624971, artifact 15203376013: 48/48 calls, 240/240 fields, both modes; all records compared against same-SHA direct expected pairs.
- Month endpoint job 140522297409, artifact 15201035289: 8/8 calls, 40/40 fields; raw stdout/stderr hashes, exit codes, target framing and endpoint selection independently checked against same-SHA full-year rows.
- Exterior year-neighbor job 140522297201, artifact 15200020611: selection 1/1, calls 2/2, 10/10 fields. SHA-256 of downloaded ZIP 7330e913c2c64319e1ef1ff0fd1656affdabd28c9360dc254a06e6dcd7ad7772. Checkout exact; CRC clean; raw stream hashes, offsets, empty stderr, exits and all five fields verified. Calculation offset 0: target -4022 -> (4999,13,538,17,123); target 378 -> (5001,9,1,33,1). Oracle year gate spans (-9644,-4022], (-4022,377], (377,6000] are adjacent; lengths 5622,4399,5623. Both adjacent month-length sums match their day spans. Resource 158.59 s, 669056 KiB, exit 0. This closes the final identified direct-entry coverage gap.

All eight canonical ZIPs in the bullets above were downloaded, SHA-256 matched to GitHub metadata and CRC checked. The source-byte verification of the governing Hebrew Scroll remains the prior out-of-band review (not repeated here); current CI reports truthfully retain source_bytes_verified=false. The independently authored Python comparators are QA verification only and do not become executable Fortran project implementation or normative authority.

Acceptance is of the defined Stage 1 bootstrap and test-only oracle gates, not exhaustive mathematical proof for every possible date, full production integration, astronomical conversion, arbitrary future stages, or all 55 stages. The documentation update records the review of the tested SHA without changing any executable source or asserting a Native run on the documentation-only successor. Stage 2 remains unopened.
