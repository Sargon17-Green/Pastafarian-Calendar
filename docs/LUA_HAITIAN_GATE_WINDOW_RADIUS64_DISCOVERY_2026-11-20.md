# Lua / Kreyòl ayisyen — bounded radius64 gate discovery v5 (2026-11-20)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent: 5e1f3c84e3ca30139876e4f902499abaade8c5bd
Scope: QA-only static year gate admission. No product, composition, full-date test, Stage56, main, merge, release.

## Evidence for this choice
Run 44715871183 completed/success with 91 jobs on exact parent SHA. Dedicated Native job 136219009521 completed/success. Artifact 14621064362 ZIP SHA256 b33a3383a7e252d7ad6d8775dbbe6f7490b8c0e06097aa612bf6141a3dfd67cf; CRC 6/6; source SHA matched; exit 0; stderr empty. Independent reconstruction of 81 gates, 80 adjacent gaps, 75 six-gap windows and 10 markers passed. Observed minimum 2087 days at indices 18..24, 0/75 short windows (252..1968), and 0/8 probes. This is a finite negative, not a full date PASS.

## Exact bounded input/output contract
Unchanged normative gate-index oracle; expand only the scan indices from -40..40 to -64..64 inclusive. Output exactly 129 gate rows, 128 adjacent gaps, 123 six-gap windows and all existing summary and admission markers. Gaps must lie in 42..963. Each window must equal both gate[i+6]-gate[i] and the sum of six adjacent differences. A possible 16-month year has length at most 16*123=1968 days and necessarily includes a six-gap subwindow no longer than that. This is necessary, not sufficient, for a qualifying selected year. Eligible windows are ordered by (length, absolute index, signed index). At most eight distinct 1/3 and 2/3 interior samples may be probed.

Hard ceilings: 200 gate-gap evaluations, 110s Lua CPU, 120s wall and 2s kill grace, 128 MiB virtual, 131072 KiB Lua heap, 8 target days, 16 months, 20000 static composition states. Reject any budget breach explicitly, never call composition.

New independent Python interval checker does not import Lua and reconstructs all reported intervals. Its 7/7 selftests use 1 valid synthetic receipt and 6 deliberately mutated receipts. Native CI must invoke this checker on actual stdout and save both its selftest and actual-result logs in the evidence ZIP. This checker establishes interval integrity only, not full-date correctness.

Frozen normative Git blob SHA:
test/normative_oracle.lua = 8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d
src/bigint.lua = fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d
src/source_language_catalog.lua = 5b59ee6bb0ea2c2a551185929b5531ea28a50e49

Acceptance on NEW commit requires completed success Native job, exact SHA, single artifact ZIP, source locks, CRC/digest manifest, exit 0, empty stderr, 129 gate and 123 window rows, independent interval checker 7/7 selftests and actual PASS, resource limits and COMPOSITION_NOT_INVOKED=YES. A queued job does not count as PASS. If admitted, next step is a separate bounded composition differential; otherwise document the finite negative and plan another evidence-based bounded extension.
