# Stage02 DISCOVERY01 — k5/q7 independent arithmetic extension (2026-11-20)

PROJECT_ID: PC-BRANCH-WAT-SPANISH. Working branch: WAT+Español.
Parent HEAD: 083c3a2181d05a610f18f0339f6d7ee1102992bb.

## Gate checked before this extension
CI run 44715966354 attempt 1 completed/success at the exact parent SHA. Both verify and wat-stage02-semantic jobs completed/success; both checkout logs show the exact SHA. Semantic WABT/Node WebAssembly: 99/99 Native exports, zero failures, and 71 independent BigInt memory-field checks; canonical names lock passed. No Stage02 global acceptance or historical ZIP equivalence is claimed.

## Next bounded hypothesis and mathematical witness
Extend the same k=5 boundary study one quotient beyond q6 to q7. Let M=2^127-1, S=M^5. For forward circular responses use FIRST=M-5 and STEP=+1; for backward use FIRST=M-1 and STEP=-1. Both produce five digits in [1,M]. Because M mod 7 = 1, the base-expanded X is divisible by seven:
- forward X = S - (M^4+2M^3+3M^2+4M+5);
- backward X = S - (5M^4+4M^3+3M^2+2M+1).

Set N=X/7-delta, delta=0 or 1. Check M^4 < N < M^5, floor(S/N)=7, LIMIT=7N. For delta=0, X is accepted with rank N. For delta=1 forward, rejection wraps and returns rank 1; its abstract rejection count is S-X+1. For delta=1 backward, seven steps reach LIMIT and return rank N.

## Independent test plan and local preflight
New Node BigInt oracle does *not* read or execute WAT. It constructs X through radix Horner evaluation and independently checks the deficit polynomial. It then checks exact N/LIMIT/quotient and ring accept/reject semantics. For two tiny moduli congruent to 1 mod 7 (15 and 22), explicit bounded ring walks give 8/8 cases and 315214 total rejected positions. Their backward quotients are 10 and 9, respectively: negative controls against assuming every small ring has q7. For moduli 43/50/57/64, all 16/16 cases are true k5/q7. For production M, four exact algebraic cases are checked (forward/backward and delta=0/1). Local Node preflight passed 8+16+4 = 28 cases, zero failures.

## Acceptance boundary and NEXT
This commit adds only an independent arithmetic oracle, workflow hook and report; WAT code and Native runner are unchanged. The local 28 cases are NOT Native tests. Auto push CI on the new SHA must reach completed/success, run the new oracle, and prove exact checkout SHA. Only then consider adding four separate q7 Native fixtures (with 8-field BigInt memory oracle), followed by completed CI 103/103 Native and 75/75 BigInt if those four are committed; these future targets are not results. No duplicate dispatch, main/merge, publication, claimed global Stage02 PASS or reconstructed historical ZIP.
