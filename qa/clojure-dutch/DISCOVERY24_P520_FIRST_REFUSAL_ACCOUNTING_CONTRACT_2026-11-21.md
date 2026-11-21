# DISCOVERY24 p520 — first-refusal accounting, TEST ONLY (2026-11-21)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Branch: Clojure+Nederlands
Reference result: run 44910763612 on faa37816ae4e1384e019d406c62415af7ab028b6, job 136865879505 completed SUCCESS but bounded-prefix-budget-unproven. Full Native intentionally SKIPPED. No five-field proof.

## Contract

Input: exactly year 5000, calculation day = target day = -15055654N, canonical prefix target p520, search limit 128N and cell budget 5000000N. Use a separately selected normative month profile and rank. The unchanged production month-prefix function is probed by bisection at strictly smaller positions; NEVER re-dispatch the p520 witness. Only when the first failure is before 520 does the diagnostic pass.

Output: exact first refusal position p; production-accepted prefix p-1 with its cost; cost-accounting branch (shared-active-candidates vs new-month-candidate), safe cost immediately preceding that branch, proposed upper cost, exact assertion 0 <= safe <= 5000000 < proposed. Output is persisted with project ID and GITHUB_SHA to qa/discovery24_p520_first_refusal_accounting.edn even on failure.

Independent oracle: for each state, enumerate the combinatorial Cartesian product of unopened month IDs and remaining suffix slots. Count one shared base cell plus one coefficient opportunity per product element; account for the shared active block once and a separate new-month candidate only when that candidate is chosen. Do not invoke production private cost/count methods. Compare this accounting model against the production cost of its *previously accepted* prefix. Exhaustively compare every rank and every interior position for the [4,4], [4,5] and [5,4] families using separately enumerated complete words.

Gates: source/branch/commit/blob readback; opt-in isolated job and verify completed SUCCESS on exact SHA; inspect raw job logs and uploaded EDN. A controlled accounting refusal is **not** p520 numeric five-field proof, full Native suite PASS, DISCOVERY24 acceptance, or Stage2 acceptance. Original generic seven-case E2E remains 0/7 at 100000N. No production/API/budget/policy edits, main, merge, publication, or user-machine dependency.

This document is a test contract, not a claim of a completed CI or Native result.
