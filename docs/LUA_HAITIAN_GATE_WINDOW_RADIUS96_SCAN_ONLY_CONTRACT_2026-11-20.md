# Lua+Kreyòl-ayisyen — bounded radius96 scan-only QA (2026-11-20)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent: 3f30e30c189e04d8918e5ebe95cc9f1ab04aa366
Scope: QA-only extension, no Stage56, no main/merge/release, no full-date or month composition.

## Grounded source
Canonical CI 44800290037 completed/success (92/92) on exact parent SHA.
Dedicated Lua job 136510368350 completed/success; artifact 14662180678 SHA256 e96a51238c81a201a88798c9541909082632fda2422931623b0bf18ea0a6203e.
Its 129 unique gate points (-64..64) were parsed from the Native job log; the 81-point v4 core overlapped exactly, as did its 123 recomputed six-gap windows. Minimum 1694 days, short windows begin at 36,37,38. Python verifier previously passed 7/7 synthetic tests and actual receipt. No qualifying year/candidate or month composition was observed.
Pinned 129-point seed: test/lua_haitian_gate_window_radius64_v5_1_seed.tsv
Git blob SHA: 95e77bc49a4c9e944bbac72b744ae0b3628043e5

## Input, output, oracle, bounds
Input: immutable source receipt seed points G[-64..64], with 129 exact index/day rows and source provenance. Verify foundation at G[0] and every seed difference in 42..963.
Normative Lua oracle: same locked O.negativeGateGap / O.positiveGateGap on only 32 new indices below -64 and 32 above 64. Reset oracle cache, compute exactly 64 fresh gate gaps. Do not call O.year5000, month streams, composition, full-date conversion, or weaving.
Output: G[-96..96] exactly 193 rows, 192 in-range positive adjacent differences, 187 six-gap windows with j=i+6, len=G[j]-G[i]=sum six gaps, minimum and short count within [252,1968]. The short-window criterion is a necessary geometric condition for any year with <=16*123 days; it is not proof of admission.
Runtime: <=110s Lua CPU, <=120s wall with 2s kill grace, <=128 MiB virtual memory and Lua heap, max 200 gap calls. Breach is ABORT and not a PASS.

Independent Python verifier reads native stdout and seed without importing Lua. Reconstruct all indices, gaps and windows; checks source Git blob SHA and fixed prior run/job/artifact identities, counters, summary, and explicit no-composition markers. Selftest: one valid synthetic receipt plus eight distinct adversarial corruptions (9/9 required).
Native acceptance requires exact Git commit SHA, the three historical source blobs unchanged, locked seed, Lua5.3 completed success, exit=0, empty stderr, complete output, verifier synthetic 9/9 and actual PASS, and manifest/sha256/exit/stdout/stderr as uploaded artifact. The whole CI workflow success is separately tracked. queued/in_progress is not PASS.

## NEXT logic
If windows are short, document their indices only; designing year5000 admission is a separate gate. If no window is short, record bounded negative for -96..96 only. Never infer full-date product correctness, global impossibility, Stage56 approval or release.
