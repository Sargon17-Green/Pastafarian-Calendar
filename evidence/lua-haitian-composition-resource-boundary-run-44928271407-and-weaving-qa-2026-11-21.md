# Lua Haitian composition boundary — verified focused Native gate and new independent weaving QA

Date: 2026-11-21
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Authorized branch: Lua+Kreyòl-ayisyen
Focused run source SHA: 280b8e09a7393f2ff8537f386c895fe4f1e3a574

## Exact completed job — not whole-run acceptance
- Canonical workflow run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928271407
- Reusable focused job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928271407/job/136919079602
- Focused job steps: all 8 completed/success, including source/Python lock, genuine Lua5.3 witness and evidence upload.
- Log: source-locked Python 286/286 PASS; QA adapter selftest 15/15 PASS; Lua Native assertions 28/28 PASS; exit=0, empty Lua stderr, COMPOSITION_SPY_CALLS=0, WEAVING_NOT_INVOKED=YES and FULL_DATE=NOT_RUN.
- Witness: day=-15017676, year=5000, candidateCount=69, rank1=56, gates=71..82, interval (-15018117,-15012823], L=5294, minMonths=44, maxMonths=47, cap=16. QA RESOURCE_REJECT is not normative invalidity.
- Resource observations from actual stdout: GAP_CALLS=85, LUA_CPU_SECONDS=54.928676, under 110s Lua CPU/135s wall/200 gap/131072KiB budgets.
- Evidence artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928271407/artifacts/14718511162
- GitHub Actions ZIP SHA256: 7eb15ced8d21326067e8d2eddcbc5a10a4ad3277aab8f94a3cc012db74d214e6, artifact contains 8 uploaded evidence files according to job log. ZIP byte-by-byte local re-verification was not performed in this receipt.
- At the status read, the full canonical run remained queued/conclusion=null; job-level success cannot be upgraded to 96-job / full-suite PASS.

## Newly executed independent small-domain check
- New test path: `test/lua_haitian_weaving_state_budget_qa.py`.
- Contract: inputs positive integer month lengths, at most 4 months and 12 days for bounded exact QA; count all multiset words with increasing first and last appearances using two independent approaches (exhaustive enumeration versus memoized state transitions).
- Local Python 3 execution (without source file available for local blob check) passed **44/44** independent exhaustive comparisons, max 58 distinct DP states; syntax compilation PASS. Local `sourceLock=NOT_CHECKED` (must become MATCH in CI).
- A forced one-state budget returns RESOURCE_BUDGET_EXCEEDED with no fake exact count. An invalid QA input has a different status. Out-of-domain valid years return NOT_EVALUATED_QA_DOMAIN, not INVALID.
- Constructive valid 44-month vector: 43 months of 123 days plus 1 month of 5 days sums to 5294, all month lengths inside [4,123]. This is proof of **feasibility**, not a real-month weaving or complete calendar conversion.
- QA script SHA256 (local): d735e4ffbdf7d197f6385441761cd98e5f692103a8b35af8177d0f03b8268113.

## New exact-SHA CI gate on this commit
The reusable Lua resource-boundary workflow now executes the new Python QA with `--check-source test/normative_oracle.lua` and demands:
1. exact source Git blob lock;
2. WEAVING_SMALL_DOMAIN_EXACT_PASS: 44/44;
3. explicit sourceLock=MATCH and realWitnessStatus=NOT_EVALUATED_QA_DOMAIN;
4. empty stderr, zero exit, and persisted stdout/stderr in the existing artifact (including on failure).
Only the next exact-SHA completed job and artifact can confirm the new Native/CI gate. No duplicate manual dispatch.

## Scope / next step
This is **QA-only**, with no modification to `test/normative_oracle.lua`, `src/bigint.lua`, `src/source_language_catalog.lua`, or production date functions. Normative maximum 47 months remains unchanged. New test is a proof of tiny-domain exactness and correct budget classifications; it is not a performance claim for L=5294, a proof of large-domain weaving efficiency, or fullDate PASS. NEXT: inspect new exact-SHA canonical CI and focused job/log/artifact; if that new gate passes, plan a resource-bounded production composition strategy without conflating resource rejection with invalid dates. No Stage56/main/merge/release.
