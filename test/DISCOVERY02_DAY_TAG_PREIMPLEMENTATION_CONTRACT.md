# Discovery 02: day-tag divergence — pre-implementation contract

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Authorization: user approved opening the next Discovery on Fortran+English only, 2026-11-28; no Patch, main, merge, or release.
Source baseline: b28d9c58c25471cb558748fc04a177ad7d4279e1.
Status: analytic preparation only; no legacy implementation, Native result, or stage acceptance.

## Ordinal discrepancy (must not be silently changed)

Original 06-implementation-prompt.md (2026-08-26), lines 648–666 and 952–960: canonical Stage 2 = Discovery 01, Stage 3 = Patch 01, Stage 4 = Discovery 02. The accepted branch instead combined Discovery 01 and Patch 01 as Stage 2. The current DEVELOPMENT_STAGE.md says LAST_COMPLETED_STAGE=2, CURRENT_STAGE=2, CURRENT_KIND=PATCH, CURRENT_PATCH=01. This contract is identified by defect number, not a new stage ordinal. Do not alter stage metadata, claim a stage opened, or introduce production behavior until the numbering decision is resolved. Keep all accepted exact-SHA evidence.

## Mathematical contract

Original defect 02: oldDayTag(day) = 2*abs(day-FOUNDATION), with FOUNDATION=-15055671. Inputs are signed arbitrary-precision discrete days, not physical instants; output is an arbitrary-precision integer without modulo or machine-width truncation. The normative tag is the one-based rank in the order F, F-1, F+1, F-2, F+2, ... . For k>=1, the ranks of F-k and F+k are 2k and 2k+1 respectively; rank(F)=1. An independent oracle can decode a positive rank r as offset -r/2 if even, or (r-1)/2 if odd, and verify the original offset. This proves bijectivity and classifies the legacy difference as exactly +1 for day>=F and zero otherwise. The old route collides for F-k and F+k, and outputs zero for F.

The existing clean test-only oracle day_count in test/normative_oracle_core.f90 (blob e64ca7dc71de9aab292f25846b3a97663b587f38) agrees algebraically. It is not production authority and must not be imported in production. No existing code or fixtures from another branch used.

## Independent analytic fixture (decimal exact integers)

All rows derived from rank and inverse-rank arithmetic, checked using arbitrary-precision integers outside the project. These are predictions, not observations. 17 distinct inputs, 9 predicted divergences and 8 predicted matches; all 17 inverse ranks and differences checked. Magnitudes cross 32-bit, 64-bit, 127-bit, and 10^40 boundaries; includes the Tablets day and its mirror.

| Case | Input day | Predicted legacy raw | Normative rank | Predicted classification |
|---:|---:|---:|---:|---|
| 1 | -15055671 | 0 | 1 | EXPECTED_DIVERGENCE |
| 2 | -15055672 | 2 | 2 | MATCH |
| 3 | -15055670 | 2 | 3 | EXPECTED_DIVERGENCE |
| 4 | -15055673 | 4 | 4 | MATCH |
| 5 | -15055669 | 4 | 5 | EXPECTED_DIVERGENCE |
| 6 | -15055674 | 6 | 6 | MATCH |
| 7 | -15055668 | 6 | 7 | EXPECTED_DIVERGENCE |
| 8 | -29832820 | 29554298 | 29554298 | MATCH |
| 9 | -278522 | 29554298 | 29554299 | EXPECTED_DIVERGENCE |
| 10 | -2162539319 | 4294967296 | 4294967296 | MATCH |
| 11 | 2132427977 | 4294967296 | 4294967297 | EXPECTED_DIVERGENCE |
| 12 | -9223372036869831479 | 18446744073709551616 | 18446744073709551616 | MATCH |
| 13 | 9223372036839720137 | 18446744073709551616 | 18446744073709551617 | EXPECTED_DIVERGENCE |
| 14 | -170141183460469231731687303715899161399 | 340282366920938463463374607431768211456 | 340282366920938463463374607431768211456 | MATCH |
| 15 | 170141183460469231731687303715869050057 | 340282366920938463463374607431768211456 | 340282366920938463463374607431768211457 | EXPECTED_DIVERGENCE |
| 16 | -10000000000000000000000000000000015055671 | 20000000000000000000000000000000000000000 | 20000000000000000000000000000000000000000 | MATCH |
| 17 | 9999999999999999999999999999999984944329 | 20000000000000000000000000000000000000000 | 20000000000000000000000000000000000000001 | EXPECTED_DIVERGENCE |

## Native implementation and acceptance gate (not executed)

Introduce only the stipulated raw oldDayTag in an invocation-owned production context; do not add the corrective branch, guard, or Patch02. Preserve existing accepted Patch01 route, bootstrap, oracle, and prior regression jobs. Use BigInt subtraction, absolute value and multiplication by two; never convert day to int64. Record raw output, input, single raw call, phase/trace and distinct per-invocation ownership. Use an independently coded Fortran QA comparator for fixture ranks and inverse ranks, and compare existing clean day_count as an additional check. Require 17/17 raw and normative matches to their own predicted values, exactly 9 observed EXPECTED_RED and 8 observed MATCH classifications, 8 mirrored collision checks, zero at F, 2 context isolation/reuse checks, and per-invocation call/dispatch counters. Any unexpected match, divergence, crash, overflow, or missing output fails the diagnostic gate. All prior canonical regression gates must remain green. No synthetic expected-red claim before actual execution.

Exact-SHA checkout, gfortran version, compile log, stdout/stderr, exit code, 30s native timeout, 1 GiB address-space cap, SHA256 manifest and always-uploaded artifact. CI gate success means the expected defect was actually witnessed, not that the defect is corrected. Do not rerun accepted parent tests manually. No Patch02 or stage acceptance in this preparation.
