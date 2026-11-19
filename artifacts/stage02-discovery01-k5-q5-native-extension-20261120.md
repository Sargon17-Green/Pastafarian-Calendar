# Stage02 DISCOVERY01 — k5 q5 Native candidate, 2026-11-20

PROJECT_ID: PC-BRANCH-WAT-SPANISH. Branch: WAT+Español. Parent: 0de14a656c788db888065cb85fb2ed363e85d178.

## Prerequisite
Run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613964991 attempt 1 completed/success, exact parent checkout in semantic job 135877561176 and verify job 135877561706. WABT 1.0.34, q5 JS 12/12 cases and 376079 rejected positions, 4 large algebraic cases, q4 Python 14/14 and 526908 rejections, 91/91 Native, 63/63 BigInt, canonical names lock.

## q5 independent contract
M=2^127−1≡2(mod 5), S=M^5, x=1+Σ(j=0..4)(a_j−1)M^j, N=x/5−δ, δ=0 or 1. Forward +1: FIRST=M−5, x=S−(M^4+2M^3+3M²+4M+5). Backward −1: FIRST=M−4, x=S−(8M^4+7M^3+6M²+5M+4). Exact divisibility by 5, M^4<N<S and floor(S/N)=5 checked independently by JS BigInt before commit.

Four new Native exports: forward_exact_limit (WIDE=LIMIT, RESULT=N), forward_wrap (WIDE=RESULT=1, S−x+1 mathematical rejections), backward_exact_limit (WIDE=LIMIT, RESULT=N), backward_five_rejections (WIDE=LIMIT, RESULT=N, exactly 5 rejections). WAT fixture computes five digits in base M and exact long division by 5 using 30-bit limbs. Production choose/choose_wide unchanged. Independent JS memory-field oracle checks M, FIRST, CUR, N, SPACE, LIMIT, WIDE and RESULT, reconstructing x and its separately derived closed form.

## Acceptance boundary
Static preflight: 95 unique WAT exports, balanced WAT parentheses after removing comments, four production BigInt algebraic cases, zero mismatches. This is not a WABT or Native execution. Expected CI gate: 95/95 native and 67/67 independent BigInt memory comparisons, existing arithmetic oracles and canonical names lock. 30-second child-process timeout, 10-minute job timeout. Native on new SHA NOT VERIFIED until both jobs completed/success with exact checkout. Stage02 globally NOT ACCEPTED; no main/merge or publication.
