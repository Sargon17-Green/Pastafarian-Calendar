# WAT+Español Stage02: independent five-field compositional QA (2026-11-23)

PROJECT_ID: `PC-BRANCH-WAT-SPANISH`  
Authorized branch: `WAT+Español`  
Parent branch HEAD before this QA: `84671b1256da87924058f1683e3aab86e0c31954`  
Original normative calendar WAT Git blob: `70267bb5730678f81d6138a2224d6b8d9a193eb8` (unchanged)  
Original isolated WAT selector Git blob: `e23f013ab96b498b0ac365dbb1b25273c845e790` (unchanged)

## Provenance and scope

Original completed [GitHub Actions run 45087126165](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087126165), attempt 1, exact trace source SHA `d05ce85128ab0eabcf4f1b1712f3c97da35886a7`; trace job `137408195912` `completed/success`. Source/semantic and verify jobs also succeeded. WasmKit job `137408197371` was **skipped**, not PASS. Artifact `14779309057` (`wat-calendar-runtime-trace`), byte length `66834`, SHA-256 `2a3d163485b610a49290a087624b27514ef83c3543005e361ee39b2fc3b170ba`, retains `identity.txt`, `source.json`, `native-results.json`, `sha256.txt`, `instrumented.wasm`. No fresh native execution is claimed.

## Reproduction

Use Python 3 and the **unchanged** existing `tests/stage02_calendar_trace_compositional_oracle.py` next to this new QA-only script:

```sh
python3 tests/stage02_calendar_weave_independent_oracle.py --selftest
python3 tests/stage02_calendar_weave_independent_oracle.py path/to/wat-calendar-runtime-trace.zip
```

The script pins artifact SHA-256, Git run/attempt/SHA and normative WAT blob, verifies recorded identity and per-member digests, and recomputes selector ranks and year/cutlet/day-in-cutlet via the pre-existing independent compositional oracle. The **new independent month oracle** independently recomputes month count, bounded month lengths and their names from the trace, then decodes seal-32's arbitrary-width rank without reading WAT memory or using observed month/day as an input. A suffix-completion DP gives exact family cardinalities. At each still-open month position, candidate blocks are counted combinatorially. Once all month identifiers have first appeared, the final suffix is decoded by descending-month combinatorial subsets, with each month’s last position constrained by canonical closing order. This factorization is essential: merely lexicographically unranking all remaining month words gives an incorrect rank convention. Finally month name is obtained from the independently unranked seal-33 name permutation, and day ordinal by counting occurrences of its independently derived month ID.

## Observed local verification

- Small exhaustive unit oracle: `[2,2]`, `[2,2,2]`, `[2,3,2]`, `[3,2,2]`, `[2,2,3]` enumerated as all valid whole words and compared for every rank. Out-of-bounds ranks rejected. `WEAVE_SMALL_EXHAUSTIVE_PASS`.
- Exact artifact validation and local five-field differential: three cases PASS, each with independent three-field calendar reconstruction and two-field weave result.

| Case | Independent month ID | Independent month name | Independent day-in-month | Verified positions |
| --- | ---: | ---: | ---: | ---: |
| foundation | 11 | 3 | 54 | 2662 |
| future_navigation_probe | 5 | 26 | 78 | 3740 |
| past_navigation_probe | 15 | 23 | 96 | 3527 |

All five output fields agree in all three cases; checked original Native trace events `46 / 54 / 70`, required seals `1,10,11,12,20,21,22,30,31,32,33`. No code path, expected tuple, or fixture from another branch was copied. The month oracle itself is independent of WAT’s implementation, but its rank convention is deliberately based on the documented canonical sequence ordering; this is a differential test over three recorded cases, not exhaustive domain acceptance.

## Gate classification

- Normative WAT code: **unchanged**.
- New code/report: QA-only, local selftest **PASS**.
- New local differential (all five fields, three historical Native traces): **PASS**.
- Historical CI/Native: completed and inspected on `d05ce851...` only; WasmKit **SKIPPED**.
- New CI/Native: **NOT RUN**. Local QA does not imply CI or Native PASS on the new commit.
- Historical original Stage02 ZIP + manifest: **UNVERIFIED**.
- Overall Stage02: **NOT ACCEPTED**.

NEXT: augment independently selected boundary cases beyond the 3 trace records and run source-fresh focused QA if justified, without repeating previously accepted Native runs at the same source SHA; separately recover and verify original Stage02 ZIP and manifest provenance. Do not merge/main/publish.
