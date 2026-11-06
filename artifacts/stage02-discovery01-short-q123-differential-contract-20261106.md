# Stage02 DISCOVERY01 — q1/q2/q3 short-route differential regression, 2026-11-06

- Project: `PC-BRANCH-WAT-SPANISH`; branch `WAT+Español`.
- Verified pre-change HEAD: `7679b10a749af6b7a5985e5e984d86612f27d12c`.
- Pre-change WAT blob: `49613dbb283968a2d06e09006c6d12103f261efd`.
- This is new, independently derived regression evidence on the q2 short-liveness PATCH, not a reconstruction of the missing historical Stage02 package.

## Independent contract
For each odd `m=11,13,...,99`, every `n in [1,m]` for which `q=floor(m/n)` is 1, 2 or 3, every `first in [1,m]`, and both directions `{-1,+1}`, an independent reference oracle iterates every rejected position on the mathematical ring `[1,m]` until reaching the first `x<=q*n`. Compare the accepted `x`, exact `rank=((x-1) mod n)+1`, and rank bounds to the constant-time candidate. Fail on any mismatch or more than `m` rejections.

Expected bounded totals, measured in a separate pre-commit local model: q1: 1,260 values of n, 168,960 pairs, 541,380 simulated rejections; q2: 405 n, 54,630 pairs, 78,330 rejections; q3: 214 n, 28,640 pairs, 23,470 rejections. Grand total: **252,230 pairs and 643,180 simulated rejections** across 45 moduli. The in-repository Python oracle asserts all nine counters before reporting success.

## Production-size WAT fixtures
Add six exports to the existing 51:

1. q1, `N=(M+1)/2`, `FIRST=M`, backward: `CUR=RESULT=N`.
2. q1, same N, `FIRST=N`, forward: `CUR=RESULT=N`.
3. q2, `N=(M+2)/3`, `FIRST=2N+1`, forward: `CUR=RESULT=1`.
4. q2, same N, `FIRST=N+1`, backward: `CUR=FIRST`, `RESULT=1`.
5. q3, `N=(M+1)/4`, `FIRST=M`, backward: `CUR=3N`, `RESULT=N`.
6. q3, same N, `FIRST=M`, forward: `CUR=RESULT=1`.

The Node runner checks `M,N,FIRST,CUR,LIMIT,RESULT` as precise base-2^30 memory integers compared with independent BigInt formulas. New expected totals: **57 Native tests and 29 numeric checks**. Existing 51/23 are preserved.

## Acceptance gates and explicit exclusions
Required on this **new HEAD**: WABT `wat2wasm` parses successfully; 57/57 separately isolated Node WebAssembly exports pass, all 29 exact numeric checks pass, Python independent oracle completes 252,230/252,230 with zero mismatches, and canonical names lock passes. The GitHub workflow's verify and semantic jobs must both reach `completed/success`, with exact checkout SHA corroborated in logs. Each Native export has a 30-second timeout.

A Python model result is not a Native PASS; symbolic production-size iteration counts are not a reproduced Native timeout or `EXPECTED_RED`. If CI fails, isolate failure and repair on the branch. The entire Stage02 stays **OPEN/READY, not ACCEPTED** pending a final review of DISCOVERY01 acceptance gates. No main change, merge or publication.
