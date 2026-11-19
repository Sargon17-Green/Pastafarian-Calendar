# Stage02 DISCOVERY01 — k=5, q=4 Native end-to-end extension (2026-11-18)

Project: PC-BRANCH-WAT-SPANISH  
Working branch: WAT+Español  
Parent SHA: c0b2f37890030e85b621507caf0c975d34abe161  
Prior math-only CI: run 44370327810, attempt 1, completed/success on the exact parent SHA.

## Verified parent gate

- Both CI jobs completed successfully and checked out exactly c0b2f37890030e85b621507caf0c975d34abe161 on WAT+Español.
- WABT 1.0.34.
- Independent k5/q4 Python oracle: 14/14 bounded ring cases, 526,908 exact rejected positions, four production-size algebraic cases, zero failures.
- Existing Native WebAssembly suite: 87/87; independent BigInt memory-field oracles: 59/59.
- Canonical names lock verify job: success.
- This is acceptance of the math-only q4 research increment only, not Stage02 global acceptance.

## New Native contract

Keep the production selector implementation unchanged. Add exactly four end-to-end WAT exports for the independently derived k=5, q=4 fixtures:

| Export suffix | step | offset | Expected accepted WIDE | Expected RESULT |
| --- | ---: | ---: | --- | --- |
| forward_exact_limit | +1 | 0 | x = LIMIT | N |
| forward_wrap | +1 | 1 | 1 after cyclic wrap | 1 |
| backward_exact_limit | −1 | 0 | x = LIMIT | N |
| backward_four_rejections | −1 | 1 | LIMIT after exactly four rejections | N |

Definitions: M=2^127−1, S=M^5, x=1+Σ(a_j−1)M^j for five consecutive answers. Forward starts at M−5 and has
x=S−(M^4+2M^3+3M^2+4M+5). Backward starts at M−1 and has
x=S−(5M^4+4M^3+3M^2+2M+1). Since M≡3 (mod 4), x is divisible by four. For offset δ∈{0,1}, N=x/4−δ and L=4N=x−4δ; the fixtures satisfy M^4<N<S and floor(S/N)=4.

The WAT fixture performs exact long division by four, then calls the unchanged selector. The independent JavaScript BigInt oracle reconstructs the five ring digits, cross-checks the closed-form polynomial, proves q=4 and L, and compares M/FIRST/CUR/N/SPACE/LIMIT/WIDE/RESULT from linear memory. It also checks rejection counts: zero for δ=0, S−x+1 for forward δ=1, and four for backward δ=1.

## Acceptance gates for this commit

- Native exports: 91/91, zero failures, including all four new q4 cases.
- Exact independent BigInt memory-field comparisons: 63/63, zero mismatches.
- Existing Python q4 oracle remains 14/14 and 526,908 rejections; no Native result is inferred from Python.
- Each child execution retains the 30-second timeout; workflow job timeout remains 10 minutes.
- Verify job and semantic job must both complete successfully and logs must show exact checkout SHA on WAT+Español.
- This fixture-only extension is not a production algorithm patch, not EXPECTED_RED, and not Stage02 global PASS. No main update, merge, or publication is authorized.

## Execution state at authoring

The code and test contract are being committed. The new CI run has not yet completed; therefore 91/91, 63/63, and overall CI success are pending and must not be claimed until completed logs are inspected.

## Completed CI acceptance evidence (2026-11-19 verification)

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44393290303
- Event: push, attempt 1, head branch `WAT+Español`, exact head SHA `c8f1d5f43a8be3e57087d29b1b815c52cdc95cab`.
- Status: completed/success; verify job ID `135116397978` completed/success with canonical names lock; semantic job ID `135116399013` completed/success.
- Semantic job log: WABT 1.0.34; Python k5 q4 14/14, 526908 bounded rejected positions; Native 91/91 and 63/63 independent BigInt memory-field comparisons, zero failures.
- This validates the q4 Native increment, **not** global Stage02 acceptance; no historical missing ZIP was reconstructed.
- The subsequent independent research question is the k5/q5 exact-limit and ring-boundary behavior; see the separately versioned q5 math-only report. No Native claim is made for q5.
