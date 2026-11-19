# Stage02 DISCOVERY01 — k=5, q=5 independently bounded research (2026-11-19)

Project: PC-BRANCH-WAT-SPANISH. Working branch: WAT+Español.
Parent/previously verified CI source SHA: `c8f1d5f43a8be3e57087d29b1b815c52cdc95cab`.

## Purpose and scope

Research the next quotient boundary q=5 with k=5 and exact cyclic selection, without changing production WAT, borrowing another converter's fixture, or claiming completion of Stage02. Arithmetic-only study precedes any Native extension.

## Independent mathematical contract

Let `B ≡ 2 (mod 5)`, `S=B^5`. For five consecutive ring responses, construct `x=1+Σ(j=0..4) (a_j−1)B^j`.

- Forward: `step=+1, first=B−5`, digits `B−5,...,B−1`, deficit `D_f=B^4+2B^3+3B²+4B+5`, so `x=S−D_f`.
- Backward: `step=−1, first=B−4`, digits `B−4,...,B−8`, deficit `D_b=8B^4+7B^3+6B²+5B+4`, so `x=S−D_b`.
- In both orientations, `x≡0 (mod 5)`. With `δ∈{0,1}`, choose `N=x/5−δ`, `L=5N=x−5δ`. For all selected bounded bases and production `B=2^127−1`, verify `B^4<N<S` and `floor(S/N)=5`.
- `δ=0`: x=L, accept immediately, RESULT=N.
- `δ=1, step=+1`: x>L, reject `D_f+1` positions until wrapping at `1`, RESULT=1.
- `δ=1, step=−1`: reject five positions until `L`, RESULT=N.

## Test inputs and gate

Bounded `+1` moduli B=12,17,22; bounded `−1` moduli B=52,57,62; each with δ=0,1 (12 stepwise cases total). Real production modulus `2^127−1`, both steps and δ=0,1 (four algebraic cases); **never** walk the astronomical production ring. Explicit maximum of 300,000 steps per bounded case. Compare independently assembled digits with closed-form deficits and then run actual stepwise cyclic rejection. Expected bounded total: 376,079 rejection steps, zero mismatches. Run with `node tests/stage02_k5_q5_boundary_oracle.cjs`.

Expected output: JSON with `bounded_cases=12`, `bounded_rejections=376079`, `failed=0`, four production cases and `native=NOT_EXECUTED_BY_THIS_ORACLE`. Any mismatch or timeout is a QA failure; not an automatically proven production bug. CI invokes this oracle as an additional check and retains the unchanged 91 Native and 63 BigInt checks from prior q4 gate.

## Acceptance boundary

Passing this arithmetic-only contract establishes feasible q5 fixtures, **not** Native q5 acceptance, EXPECTED_RED, the missing historical Stage02 ZIP, or overall Stage02 PASS. If successful, the next increment is independent q5 fixture design and actual branch-only Native differential, including complete per-field memory oracle, with exact SHA and logs before any acceptance claim.
