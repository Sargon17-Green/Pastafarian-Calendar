# Stage02 DISCOVERY01 — k=5, q=3 independent boundary expansion (2026-11-18)

Project: PC-BRANCH-WAT-SPANISH; branch: WAT+Español.
Verified parent: 42099f772a1cab4b539149caaa9b586a7323875e.
Previous run 43961294326 attempt 1 completed/success, both verify/semantic jobs,
WABT 1.0.34, Native 83/83, 55 exact BigInt oracle comparisons.

This is fixture expansion only; the selection algorithm and Stage01 catalog stay unchanged.

For M=2^127−1, SPACE=M^5:
- step +1, FIRST=M−4: x=SPACE−(M^3+2M^2+3M+4).
- step −1, FIRST=M−3: x=SPACE−(7M^4+6M^3+5M^2+4M+3).
- M mod 3=1, hence both x are multiples of 3.
- N=x/3−offset for offset in {0,1}, so k=5 and floor(SPACE/N)=3.
- offset 0: x is LIMIT and RESULT=N.
- offset 1, backwards: three rejected values, WIDE=LIMIT, RESULT=N.
- offset 1, forwards: wrap to WIDE=1, RESULT=1.

Independent Python oracle: 4 base moduli 31,34,37,40, each with 4
step/delta cases; 16 bounded ring-walk cases and 194378 rejection steps;
4 production-size algebraic expectations. Smaller bases were excluded because
the backward model may have quotient 4 rather than quotient 3.
WAT fixtures: four additional exports; Node compares M,FIRST,CUR,N,SPACE,
LIMIT,WIDE,RESULT against independent BigInt arithmetic, with each Native
test in its own 30-second process.

Local math-only preflight was checked before commit; CI must still confirm
Python, WABT, Native 87/87, 59 BigInt oracle cases, verify and exact SHA.
No Stage02 global PASS, no historic EXPECTED_RED, no main/merge/release.
