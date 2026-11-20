# Fortran+English Stage 1 — context cache revisit QA (2026-11-20)

Project: PC-BRANCH-FORTRAN-ENGLISH. Branch: `Fortran+English`. Verified source HEAD before change: `1c0851a606977a9b253292640ed28990578b98cc`.

Evidence inspected: GitHub Actions run [44811459328](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811459328), attempt 1, status completed / success, 10/10 jobs; original context job 136548783765. Six retained artifacts have matching HEAD SHA. Inspected artifact 14667168697 directly: ZIP CRC passes; artifact SHA-256 `c6578bf9bac4be4d2bc8ff483afd5bfe2733670dec9ae8c9addbe834b5ff1dcd`; internal JSON SHA-256 `8294de2f0e0414a15aeb47cdccba60020213e2986767f01a3a83dcb5e6ea2855`.

Verified from job log and independently replayed the JSON's structure: 14/14 Fortran-vs-pinned-Python calculation-context cases, 70/70 exact fields; boundary sensitivity 2/2; same-process no-reset order `11,13,12,14,11,13` with 6/6 calls, 30/30 exact fields; each sequence row matches the corresponding independent Python result. This evidence is a PASS for these bounded gates, **not** full Stage 1 acceptance.

Identified coverage gap: the old same-process order revisited cases 11 and 13 (4999 boundary target), but never revisited 12 and 14 (5001 boundary target) after warming the original Fortran cache. This is a **coverage gap**, not a demonstrated failure.

QA-only change contract: keep all 14 baseline contexts unchanged. Use the original `normative_calendar_date` in one process and compare each call against independently computed SHA-pinned Python expected fields, adding revisit `12,14` at the end. New exact order `11,13,12,14,11,13,12,14`; no inter-call reset; 8/8 calls and 40/40 five-field comparisons. Add two harness self-test assertions (34 to 36). Preserve current 480-second same-process subprocess limit and the 20-minute job limit. The Fortran command-line probe accepts up to eight cases. **Do not** change normative algorithm, reference commit, Stage 2, main, merge, or publication. Native verdict remains pending until CI on the new SHA completes.

Evidence classes: original run = completed Native+differential PASS for source `1c0851a606977a9b253292640ed28990578b98cc`; JSON structural replay = local QA PASS for this source; new code = static contract only until CI execution. No duplicate workflow dispatch.
