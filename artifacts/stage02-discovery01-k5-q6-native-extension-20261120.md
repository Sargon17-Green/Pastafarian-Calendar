# Stage02 DISCOVERY01 — k5/q6 Native WAT candidate (2026-11-20)

PROJECT_ID: PC-BRANCH-WAT-SPANISH. Branch: `WAT+Español`. Parent `839e4c6083c405649c368e928182143b11e51555`.

## Verified prerequisite
CI run [44707822474](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44707822474) attempt 1 completed/success at exactly `839e4c6083c405649c368e928182143b11e51555`. Both verify job 136191698096 and semantic job 136191698432 completed/success and checkout logs match parent. WABT 1.0.34; 95/95 native WebAssembly exports passed, 0 failed. Pre-existing runner covers 67 independent BigInt memory-field checks. Existing q6 math-only CI oracle: 12 small explicit walks, 1,237,658 rejected transitions, 16 medium q6 algebraic cases, 4 production q6 algebraic cases.

## New q6 Native fixture
The four new WAT exports cover forward exact-limit, forward wrap, backward exact-limit and backward six-rejections for k=5 and q=6, with δ=0/1.

Let M=2^127−1, S=M^5. For +1, FIRST=M−7 and X=S−(3M^4+4M^3+5M²+6M+7). For −1, FIRST=M−3 and X=S−(7M^4+6M^3+5M²+4M+3). M≡1 (mod 6) and both X values are divisible by six. Set N=X/6−δ; ensure M^4<N<M^5, q=floor(S/N)=6 and LIMIT=6N.

Expected WIDE/RESULT: δ=0 accepts X and returns N; δ=1 step=+1 wraps to 1 and returns 1 after S−X+1 abstract rejection steps; δ=1 step=−1 accepts LIMIT and returns N after exactly six rejection steps. Expected CUR=M−2 forward, M−8 backward.

Fixture builds X with exact base-2^30 limb operations, long division by six with mandatory remainder zero, then calls unchanged production `$choose`. Independent BigInt checker reconstructs digits and the closed-form X and verifies the eight memory fields: M, FIRST, CUR, N, SPACE, LIMIT, WIDE and RESULT. WAT fixture construction and checker are separate implementations.

## Acceptance boundary
Only precommit arithmetic/static evidence: 4/4 exact BigInt algebraic cases, 99 unique WAT test exports and balanced WAT parentheses. These checks are not a compiler run, WebAssembly execution or full Stage02 PASS. CI now targets 99/99 Native and 71/71 independent numeric probes, retaining all old oracles, 30-second subprocess timeouts and 10-minute job cap. Accept these gates only after a completed CI run and exact SHA checkout logs.

No changes to `$choose` or `$choose_wide`, no main/merge, no historical ZIP equivalence, no EXPECTED_RED, no Stage02 global acceptance.
