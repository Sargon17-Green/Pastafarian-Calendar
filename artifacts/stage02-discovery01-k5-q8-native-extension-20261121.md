# Stage02 DISCOVERY01 — k5/q8 Native candidate (2026-11-21)
PROJECT_ID: PC-BRANCH-WAT-SPANISH. Branch WAT+Español.
Verified parent SHA: 9cbd90cf4fb14982c6c3826f4bd7fed87e52fbb3; base tree: 6447aad0c7e381838e197d2ccceaf4253d94ddf3.
Accepted prior q8 math gate: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811611151, attempt 1 completed/success, semantic job 136549328479 and verify job 136549329074 both completed/success; both logs show exact checkout SHA. WABT 1.0.34, 16 bounded ring walks (64 rejection transitions), 8 structural small cases, 16 medium q8 cases, 4 production q8 math cases, failed=0.
Historical parent Node WebAssembly: 103/103 Native with 75 BigInt numeric fields/groups; no workflow artifact uploaded.

## Numeric contract and boundaries
M=2^127-1; S=M^5. Five consecutive digits from FIRST=M-9 forward, FIRST=M-5 backward; X=1+sum((digit_j-1)*M^j). Independent deficit: Df=5M^4+6M^3+7M^2+8M+9, Db=9M^4+8M^3+7M^2+6M+5, X=S-D; M mod 8=7, X divisible by 8.
N=X/8-delta, delta in {0,1}. Enforce M^4<N<S, floor(S/N)=8, LIMIT=8N=X-8delta. Exact case delta=0 gives accepted X and rank N. Forward delta=1 wraps accepted to 1, rank 1 (D+1 rejected positions). Backward delta=1 accepts LIMIT, rank N, eight rejected positions.
Four new WAT exports invoke unchanged production $choose; helper computes N by exact limb division by 8 with nonzero remainder trap. The Node checker independently computes X by positional summation and verifies a separate deficit polynomial, then eight memory fields M,FIRST,CUR,N,SPACE,LIMIT,WIDE,RESULT.

## New static/model checks before Native
107 unique WAT test exports = previous 103 + four q8; balanced WAT parentheses ignoring comments and strings; all four BigInt q8 production models mathematically verified. No change to production selector path. Workflow target 107 Native and 79 independent numeric comparisons, not yet a claimed result.

## Acceptance
New exact-SHA CI and its verify/semantic job logs must prove 107/107 Native and 79 independent numeric checks, full SHA checkout, WABT version and 0 fail. Stage02 globally NOT ACCEPTED; WasmKit and historical ZIP equivalence remain unverified. No merge/main, release or EXPECTED_RED.
