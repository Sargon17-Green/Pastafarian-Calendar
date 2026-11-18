# Stage02 DISCOVERY01 — k=5, q=4 bounded boundary research (2026-11-18)

Project: PC-BRANCH-WAT-SPANISH; branch: WAT+Español.
Source parent HEAD: 62b811bacec1566edb68e0e13dc096f7936f2bce.
Parent CI run 44364499104 attempt 1 completed/success on exact SHA: both jobs passed; Native 87/87; independent BigInt numerics 59; Python k5 q3 16/16; canonical names lock passed.

## Independent k5 q4 oracle

Let M=2^127−1, S=M^5, take five consecutive ring answers in [1,M] with step +1 or −1. Define x=1+Σ(a_j−1)M^j (j=0..4). New fixtures are generated independently of the WAT engine:

- Forward: first=M−5, step=+1. Then x=S−(M^4+2M^3+3M^2+4M+5).
- Backward: first=M−1, step=−1. Then x=S−(5M^4+4M^3+3M^2+2M+1).
- M ≡ 3 (mod 4), so 4 divides x in both cases. For each offset in {0,1} set N=x/4−offset, L=4N=x−4offset, yielding M^4<N<M^5 and floor(S/N)=4.
- offset 0: x=L, accepted rank N without rejection.
- offset 1, backward: exactly four rejections, accepts L, rank N.
- offset 1, forward: cyclic wrap after S−x+1 rejections, accepts 1, rank 1.

## Bounded independent preflight (local math only)

- Bases 11,15,19,23 test forward; 31,35,39 test backward. All are congruent to 3 modulo 4 and maintain k=5,q=4 for both offsets.
- 7×2=14/14 exact ring-walk cases, total 526,908 rejected positions, zero mismatch; longest walk 305,860 steps (limit 350,000 per case).
- Four full production-size cases checked via exact integer algebra, no astronomical loops; python3 -m py_compile passed.
- Locally tested Python SHA-256: 1fb84ea7bc569d8624becbe732527923f58b1ad94482a67d82aec99edff281db.
- This phase changes only the independent oracle, its CI gate, and this research report. It does not add WAT exports or Native probes. Existing WAT selector and Stage01 catalog stay unchanged.

## Acceptance gate and next step

CI semantic job must execute the new Python script with 14/14 and 526,908 exact rejected positions, plus existing Native 87/87 and BigInt 59. Accept only the math-only research expansion after completed run + verify/semantic logs with exact SHA; never infer Stage02 global PASS. Then add four end-to-end WAT k5 q4 exports and four independent BigInt memory-field comparisons (target Native 91, numerics 63), run bounded CI and compare exact fields. Do not modify main, merge, publish, infer historical EXPECTED_RED, or assert Native coverage before actual logs.

