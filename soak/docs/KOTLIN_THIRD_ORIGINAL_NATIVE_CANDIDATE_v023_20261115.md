# Native Kotlin+Cumraeg production as a third comparator candidate — v023 / 15 November 2026

## Confirmed independent *execution path*, not certified independent algorithm

The separate original branch `Kotlin+Cymraeg` at commit `0c703446d8a3b7435698bd16402ac5fa30e461c9` has Kotlin production code under `src/main/kotlin/pastafari` and a seven-column adapter `soak/Post55ProductionDateBridge.kt`. It is NOT the derived JS optimization from v022. In particular, the production month weaving uses an exact bounded suffix-count table and branch-ratio unranking, rather than the old JavaScript exhaustive state memo. It has its own implementation; **the independence of the underlying mathematical derivation and provenance remains to be audited**.

## Fresh pinned native run

[CI run 43647140743](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43647140743) compiled the original Kotlin+Cumraeg source using Kotlin 1.9.0 with Java 21, in an isolated GitHub runner, from exact SHA `0c703446d8a3b7435698bd16402ac5fa30e461c9`. It separately fetched frozen Python+Türkçe test reference commit `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`, checked the latter's SHA-256, and computed the same three dates in the separate original engines.

For fixed calculation day `-15055671`:

| target day | year | cutlet index | day in cutlet | month index | day in month |
| ---: | ---: | ---: | ---: | ---: | ---: |
| `-15055672` | 5000 | 10 | 502 | 32 | 21 |
| `-15055671` | 5000 | 10 | 503 | 20 | 56 |
| `-15055670` | 5000 | 14 | 1 | 29 | 38 |

All **21/21 native output columns**, including 15 numeric date fields, matched. Both original child processes exited `0`. Native witness: `THREE_PINNED_KOTLIN_PRODUCTION_DATES_MATCH_NOT_CERTIFIED`. The script does not proclaim an independent canonical PASS.

### Native runtime observations (isolated Linux CI)

| path | three-day runtime | peak resident memory |
| --- | ---: | ---: |
| Python reference (one process, three calls) | 42.25s | 122,748 KiB (about 119.9MiB) |
| Kotlin production (one JVM, three lines) | 7.36s | 469,148 KiB (about 458.2MiB) |

The compiler output jar SHA-256 is `70f2567a67712511f7e86c8ed3147c26c373f33150f7d707f390c207c9c522d6`; it was built on CI and is not automatically a reproducible-build contract for Windows. The result ZIP (GitHub Action artifact ID `14134453329`) has SHA-256 `de68c8f24b56984548d7770fc054e11d3a0245b99788c7920770a0b522e69dbd`. Source-bound results and frozen comparator metadata are also preserved in `soak/control/kotlin_original_production_three_day_candidate_v023.json`, and QA in `soak/tests/test_kotlin_original_candidate_v023.py`.

### Practical whole-year cost warning

The two engines' observed three-day timings would, if they remained linear for 4,244 days with the same year/c and without additional reuse, extrapolate to roughly **16.6 hours** for Python plus **2.9 hours** for Kotlin for one full-year pair. This is **only a scale estimate** from three runs, not a validated benchmark or deadline. A 10,000-year comparison based on repeated unoptimized individual-day conversions would be prohibitively expensive. Any use of internal annual-structure reuse must be separately tested against the unmodified original `F(c,t)`, and its output must be labeled derivative until equivalence is established. No such reuse has been implemented or certified here.

## Gates not yet passed

1. Document Kotlin's full original source closure and independent-source development provenance; there is no algorithmic independence certification.
2. Test signed coordinates, year boundaries and representative months at more than three adjacent dates. The three-day pilot does not certify a complete year.
3. Audit reproducible Kotlin compilation and Windows memory admission. The earlier Windows test had only about 1.06GiB RAM available, and no further local converters were executed.
4. Design native per-year streaming with exact raw evidence and crash-safe resume; compare years sequentially and stop at the first mismatch. No full-year run was started.

`main` remains protected and unchanged. `verified_full_year_comparisons=0`; `soak_started=false`.
