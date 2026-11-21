# Stage02 DISCOVERY01 — k5/q9 Native witnesses (candidate)
PROJECT_ID: PC-BRANCH-WAT-SPANISH
Branch: WAT+Español
Parent SHA: 5bcc8e9f1f20561dcebac9ad8b4c3e5fff4944af
Date: 2026-11-21

## Verified parent CI
Automatic push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876549857
Attempt 1 completed/success, exact HEAD 5bcc8e9f1f20561dcebac9ad8b4c3e5fff4944af.
Verify job 136762402681 completed/success; semantic job 136762403012 completed/success.
Both job logs contain the exact checkout. WAT SHA256 in semantic log:
8092e0735f2989f8804bcb16d6a9f6e04c1089c4d2ee8fea45eafa78f51f9caa.
Preserved Native regression set 107/107; 79 exact independent BigInt numeric checks.
q9 math-only oracle: 16 bounded ring walks, 44 rejection transitions,
8 structural examples, 16 medium q9 and 4 production q9; zero failures.
There were no uploaded workflow artifacts. No q9 Native was executed at the parent commit.

## New candidate contract
Only add four WAT test exports, the Node independent eight-field checker,
update regression cardinalities to 111/83, and preserve existing q8 and earlier tests:
- test_discovery01_k5_q9_forward_exact_limit
- test_discovery01_k5_q9_forward_wrap
- test_discovery01_k5_q9_backward_exact_limit
- test_discovery01_k5_q9_backward_nine_rejections

M=2^127-1, S=M^5, M mod 9=1.
FIRST=M-13 for step +1; FIRST=M-9 for step -1.
Five consecutive digits produce X by Horner in WAT. Divide X exactly by 9,
N=X/9-delta (delta=0 or 1) and invoke production choose, unchanged.
The separate JS oracle calculates X=1+sum((a_j-1)*M^j), j=0..4,
and checks the independent closed polynomial D:
D=c*(1+M+M^2+M^3+M^4) - step*(M+2M^2+3M^3+4M^4),
X=M^5-D, c=13 for forward, c=9 backward.
Expected quotient floor(S/N)=9 and LIMIT=9*N.
Expected eight exact memory fields: M,FIRST,CUR,N,SPACE,LIMIT,WIDE,RESULT.
For delta=0: accepted X, rank N, zero rejected positions.
For delta=1 forward: wrap, accepted=1, rank=1, D+1 rejected positions.
For delta=1 backward: accepted=LIMIT, rank=N, 9 rejected positions.

## Evidence level / acceptance
Pre-commit static QA: WAT parenthesis balance 0; 111 unique test exports;
four independent algebraic/positional/Horner agreements with q=9.
The blob creation is not Native. New CI must verify WABT, 111/111 Native,
83 exact numeric entries, both completed job logs and checkout SHA before acceptance.
Stage02 overall remains NOT ACCEPTED (WasmKit + original ZIP provenance).
No source production changes, no EXPECTED_RED, merge, main, or release.
