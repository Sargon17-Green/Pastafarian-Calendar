# Stage56 B5 — production-source and Year5000 provenance discovery (QA-only)

Date: 2026-11-21 (Asia/Jerusalem)
PROJECT_ID: PC-BRANCH-PHP-MALAY
Authorized working branch: PHP+Bahasa-Melayu
Audited PHP branch HEAD: 597b4bfe58cdedd33b31d0fabdc52ae556e259bf
Result: SOURCE_HIERARCHY_IDENTIFIED; PHP_PRODUCTION_PROVIDER=NOT_AUTHENTICATED; CONTEXTUAL_ANCHOR=NOT_PINNED; GENUINE_EXPORTS=0; STAGE56=IN_PROGRESS.

## Verified independent source hierarchy

Precisely scoped external repository: Sargon17-Green/pastafari-calendar at commit cc2cf0b422757a5e7c33218ce30cffa8f99c6786. Source text was obtained at this commit using the GitHub repository connector. SHA-256 below is over its UTF-8 Git file content (the hashing implementation was checked against the standard SHA-256 digest of 'abc'); Git blob SHA-1 was independently returned by GitHub.

| Role | Source path at exact commit | Git blob SHA-1 | Git-byte SHA-256 |
| --- | --- | --- | --- |
| Normative scroll | sources/מגילת העיתים.md | 291353f4e5a83bb3d958b7f98e32040ee00b9f8a | d36b0c944b4685d1aa1d89bb20a8dd530ee3167c897dcdf85161a7ec0dde9c96 |
| Independent spec-derived reference, NOT production dependency | verification/reference-oracle/reference.mjs | 8c8f092cb43fbaa76a9e7b33aaee1f19266ba516 | 21c103d3540eb5481445a190cef98f2628de7eb90b7240879fede0d519cf4a95 |
| Browser authoritative public doorway | browser/pastafari-calendar-core.js | 3b349037967550b0253db6235db5044ac9703466 | 823937139efb9ca37d8b8422187c09855ade5ad95d52efff733036f7b7e62c15 |
| Node public doorway (package.json main) | src/public-api.js | 1aa02a5aff724b305f16f94512ef8fd07dccfd6b | b72876a4acceb44408caaf15ec940112fa1cdf80a81324f7980a1b25f759e507 |
| Adjacent optimized JS engine, NOT the oracle | browser/pastafari-calendar-fast.js | 014eca6908ed726c6c760204580bf18119015bbc | 9855be62ebe9e9e24d301f849dc010e8195fa8cf7857b45c492b60a2bb0c60ef |
| Explicit hierarchy declaration | docs/authority/ORACLE-AUTHORITY.md | 1428211ea41ce7f578a8c7dc4391e536d5d6e158 | 029db4ce5b9a8a99565d277472eddb764ab80f80b2c5085e24cad826d699abb9 |

Source hierarchy declared in docs/authority/ORACLE-AUTHORITY.md: Scroll > independent reference > production implementations/generated artifacts. Agreement between fast and authoritative implementations alone does not establish normative correctness. We did NOT treat the fast JS engine as an independent oracle. Documentation of authoritative entrypoints does not, by itself, prove which bytes are currently deployed to all clients.

## Three material findings from source inspection

1. **Year5000 is a function of calculationJdn.** Normative Scroll, tablet 18: the candidate year must contain the calculation day; selection is by the sauce computed with calculation day equal to target day. The independent reference explicitly exposes referenceYear5000(calculationJdn), and the adjacent fast JS engine's CalculationState.getYear5000() calls enumerateYear5000Candidates(this.calculationJdn) and then chooseUniform(this.getSauce(this.calculationJdn),...). Therefore a context-free claim of a single canonical numeric open_gate_day is insufficient. A contextual Year5000 record must bind exact calculationJdn, source commit, algorithm, and independent oracle witness.
2. **There is a real year-construction implementation in JavaScript, but no reviewed PHP provider in the authorized PHP branch.** JS fast engine exposes CalculationState.getStructure(year) calling buildYearStructure(this,year); the authoritative package uses src/public-api.js and a sealed core with detours. PHP DateTuplePatch23.calendarDate(...) receives an injected callable yearStructureProvider, and the PHP tree's src/ has no standalone source-authenticated YearStructureProvider. YearStructureSlices56 is combinatorial and expressly does not generate year records. This discovery does not authenticate a direct production PHP provider.
3. **The existing B5 provenance schema is narrower than the identified JS runtime.** stage56_actual_year_profile.php requires source.provider_path under src with .php extension; stage56_b5_source_binding_audit.py audits a committed PHP source file and a committed static canonical/anchor JSON. Its input contains no calculationJdn and does not encode external source repository identity. JS buildYearStructure produces zero-based monthWeave, while PHP B5 requires month_weaving IDs 1..month_count. Any verified export adapter must explicitly map JS monthWeave[k] + 1, preserve month lengths, and set open_gate_day=startJdn-1 and close_gate_day=endJdn. This is a proposed transformation contract, NOT an executed or accepted export.

## Next bounded implementation/verification contract (no new Stage)

- Fix one exact, reproducible calculationJdn as an explicit input and pin it together with external source repository, exact commit and Git-byte hashes. Do not silently choose a moving 'today' value.
- Use the public authoritative JS doorway for a source-derived candidate export, or review a minimal read-only adapter against the authoritative call graph if public API cannot expose raw year structures. Do not re-label fast, synthetic, legacy-generator or independent-oracle fixtures as production output.
- Independently compare source-derived Year5000 and year 4999/5000/5001 date/seam semantics with the Scroll-derived reference (including the contextual calculationJdn); document any unresolved mismatch. For each year require correct contiguous interval, [4,123] month lengths, 3..47 months, zero-to-one based month-index mapping with counts and lexical first/last order, and exact day coverage.
- Amend the QA-only B5 adapter to accept an independently authenticated external JS source and contextual anchor *only after* that production binding is demonstrated. Do not manufacture canonical/anchor.json merely to satisfy the old PHP-path test. Bind the external export bytes by independently pinned SHA-256 and exact source checkout; reject ambiguous provenance.
- Only after passing the above provenance and semantic gates invoke three separate bounded PHP8.3/64 count/rank/unrank profiles (external 900s timeouts, 512M memory, separate exit codes/stderr/stdout/log/artifact), compare results, and consider Stage56 acceptance. No PATCH22/PATCH23 integration, merge/main, or publication.

## Evidence and gate separation

- Existing accepted B5 native synthetic preflight on the PHP branch: Actions run 44811159245 completed/success, head SHA 597b4bfe58cdedd33b31d0fabdc52ae556e259bf. This audit did not redispatch it. Artifact evidence remains in the checkpoint.
- This round: GitHub pinned branch/commit/directories, targeted source file and normative contract inspection, SHA-256 byte hashing of six external canonical-repository files, and this QA-only source qualification report. No genuine production-year JSON exports were generated; no PHP profile, Native runtime on the candidate source, or differential result occurred.
- The two current obstacles are *source-interface incompatibility* and *missing calculation-day-bound canonical anchor proof*. Both permit further authorized QA, so D=פתוחה and G=READY remain appropriate.

## Source URLs

- https://github.com/Sargon17-Green/pastafari-calendar/blob/cc2cf0b422757a5e7c33218ce30cffa8f99c6786/sources/מגילת העיתים.md
- https://github.com/Sargon17-Green/pastafari-calendar/blob/cc2cf0b422757a5e7c33218ce30cffa8f99c6786/verification/reference-oracle/reference.mjs
- https://github.com/Sargon17-Green/pastafari-calendar/blob/cc2cf0b422757a5e7c33218ce30cffa8f99c6786/docs/authority/ORACLE-AUTHORITY.md
- https://github.com/Sargon17-Green/pastafari-calendar/blob/cc2cf0b422757a5e7c33218ce30cffa8f99c6786/docs/AUTHORITATIVE-ENGINE-ARCHITECTURE.md
- https://github.com/Sargon17-Green/pastafari-calendar/blob/cc2cf0b422757a5e7c33218ce30cffa8f99c6786/src/public-api.js
- https://github.com/Sargon17-Green/pastafari-calendar/blob/cc2cf0b422757a5e7c33218ce30cffa8f99c6786/browser/pastafari-calendar-core.js
- https://github.com/Sargon17-Green/pastafari-calendar/blob/cc2cf0b422757a5e7c33218ce30cffa8f99c6786/browser/pastafari-calendar-fast.js
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/597b4bfe58cdedd33b31d0fabdc52ae556e259bf/src/Patches/DateTuplePatch23.php
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/597b4bfe58cdedd33b31d0fabdc52ae556e259bf/tests/stage56_actual_year_profile.php
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811159245
