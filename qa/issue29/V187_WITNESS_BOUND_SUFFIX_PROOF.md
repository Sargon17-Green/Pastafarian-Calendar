# Issue #29 — v187, corrected source-only witness-domain proof

**Status:** source-mathematical proof, not native date-converter QA; no F(c,t), no original-calendar observer, no Soak or production edits. Corrected Ada base 1160096aa847c54cbef27c232771ce1549d7ba8f; historical Ada a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72; historical Python 0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4. Exact original Git blobs: Ada normative_oracle.adb 923733d4f8face03586aee304640bf7540c28b4c, Ada month_weaving.adb 9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef, Python normative_reference.py d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53.

## First: withdraw the unsound part of v186

v186's 252-day full-weave unreachability proof inferred exact first three ticket *values* (1,82,82) from first three interior month *labels* (1,2,2). This was unjustified. Original Ada's From_Choices maps MANY ticket values onto one label whenever a month has multiple remaining copies. Direct counterexample: for lengths (84,84,84), initial answer 82 and step +1 yields **tickets (82,83,84)**, but the same labels (1,2,2). The old 252-day full-weave claim is NOT ESTABLISHED by that argument, and is retracted. The v186 independent exhaustive 40/90 toy count is a separate result and is not retracted.

## New observation-bound theorem

The historical outputs for both original engines include day-in-cutlet 503. By source contract every year has at least six cutlets and each cutlet spans at least one gate gap of at least 42 days. Therefore the cutlet containing this day contributes at least 503 days and the other five at least 42 each. The original year therefore necessarily has **L >= 503+5*42=713 days** and target zero-based year offset >=502. With month length <=123, month count >=ceil(713/123)=6. This does not yield the actual original year length, offset, gate geometry, or month count.

A **synthetic** 720-day year satisfies these numeric constraints: six illustrative gate gaps (503,42,42,42,42,49), six cutlets, six months of length 120. These are allowed by min/max rules, but there is NO assertion that the original deterministic Sauce generated this gate sequence or that it is the actual year-5000 source trace.

## Corrected, exhaustive unreachable *word* theorem on 720 days

Set M=2^127-1, month lengths (120,120,120,120,120,120), total=720, K=720-2*6=708 interior positions. Construct a fixed-rail word with:
- opening labels (1,2,3,4,5,6)
- interior prefix: 1 repeated 117, 2 repeated 117, 3 repeated 117, 4 repeated 117, 5 repeated 118, 6 repeated 118 (704 labels)
- interior tail: (1,3,4,2)
- closing labels (1,2,3,4,5,6)

The full 720 labels have exactly 120 occurrences of every month, and ordered first and last occurrences, hence belong to the **Python globally legal weave family** and even to the Ada fixed-rail subfamily. This is membership in the combinatorial family, **not a claim** that original Python's finite Sauce/stream path generated this exact rank.

At the last four interior positions, the remaining multiplicities are **(1,1,1,1,0,0)**. Decoding the forced tail (1,3,4,2) uniquely requires **tickets (1,2,2,1)**. These ticket values ARE unique because the relevant months each have exactly one remaining occurrence. In particular at index i=K-4 the ticket is 1 (odd), and at i=K-2 it is 2 (even).

In the safe initial-stream region 2K+1 <= x <= M-2K, original Ada's shifted cyclic answer with step d in {-1,+1} neither wraps nor hits rejected values. It therefore satisfies:

    ticket_i - 1 = (x-1+d*K) mod (K-i).

For i=K-4 and i=K-2 the slot counts 4 and 2 are even, hence these two tickets MUST have the same parity. The forced 1 and 2 violate this.

The two excluded boundary intervals contain exactly 2K+2K=2,832 possible first answers, or **5,664 (first, direction) pairs**. Complete evaluation leaves only two cases with required tail ticket values: (first=705, step=-1), which yields initial ticket 705; and (first=M-704, step=+1), initial ticket 635. But this constructed word's FIRST interior label is 1, for which the initial ticket must be in [1,118]. Both exceptions are impossible. Thus **NO lawful original Ada cyclic stream first answer and step can produce this complete 720-day word**.

The source-only script also confirms the fast endpoint calculation against a literal finite cyclic walk in **3,084** independent small-modulus cases. All numerical conditions are asserted, not merely printed.

## Limits / needed evidence

This replaces the invalid v186 witness example with a correctly proven unreachable synthetic full word at an admissible witness-scale year length. It still does **NOT** prove that this precise structural defect caused original Ada [5000,10,503,30,52] vs Python [5000,10,503,20,56] at inputs (-15055671,-15055671). Those fourth fields are *canonical month-name indices*, not month counts. Original intermediate gate/year/offset, Sauce, month-length/rank, month weaving and name-map receipts remain unavailable; first actual internal divergence remains UNKNOWN. Stop new original-converter native/Soak dispatch. No production source changes or merges.

Reproduce source-only: python3 -B qa/issue29/v187_witness_bound_suffix.py. GitHub Actions source-only run pins original source blobs and disables all legacy native-dispatch jobs; it runs only this independent Python proof and uploads hashes. Never executes original Calendar_Date.
