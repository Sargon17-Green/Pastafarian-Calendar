# Stage02 DISCOVERY01 — k=5, q=2 boundary probes, 2026-11-16

Project PC-BRANCH-WAT-SPANISH; branch WAT+Español; parent eaed118c486d68f84ad44fdd741299127b7a1b5b.
New independent gap analysis: 5-digit wide selector and quotient 2.
For M=2^127−1 and SPACE=M^5, forward from FIRST=M−5 gives
x=SPACE−(M^4+2M^3+3M^2+4M+5).
Backward from FIRST=M−1 gives
x=SPACE−(5M^4+4M^3+3M^2+2M+1).
Both x even. For N=x/2−offset (offset 0 or 1), k=5, q=2, LIMIT=x−2offset.
Exact offset 0 accepts x with RESULT=N; offset 1 rejects twice backward
to LIMIT and RESULT=N, or wraps forward to 1 and RESULT=1.

Standalone Python oracle performs 12/12 stepwise cases for bases 17/19/21,
453914 rejection steps, 4 exact production BigInt expectations, no failures.
Four Native WAT fixtures and corresponding BigInt memory-field comparisons
are added without touching the selector. Gate: 83/83 exports, 55 numerical
oracles, Python script, exact SHA and completed/success verify+semantic jobs.
The new CI result remains UNVERIFIED at commit time; not Stage02 accepted.
No main, merge, release or historical EXPECTED_RED claim.
