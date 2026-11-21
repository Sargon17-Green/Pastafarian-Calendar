# DISCOVERY24 — iterative DP stack regression (2026-11-21)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Branch: Clojure+Nederlands
Base HEAD: a9131c68552cdcf056a94d610c3a8d292112d71c
Scope: TEST/QA ONLY. No production, API, canonical tests, limits, main, merge, publication or policy edits.

## Reproducible defect
The independent Python suffix DP introduced in the base commit used a recursive, memoized `count`. On Python with `sys.getrecursionlimit() == 1000`, `unrank((123,)*9, 1, 2, 2000)` and `unrank((123,)*29, 1, 2, 2000)` raised **RecursionError** instead of the specified bounded refusal. This was reproduced from a byte-exact local copy of Git blob `0234339d8a9aaa87ecb8f2cf483524eb6ae7e032` (verified by `git hash-object`). Thus the previous fail-closed behavior was incomplete for long profiles, independent of any real canonical p82/p520 run.

## Narrow QA-only correction
Replace recursion with explicit depth-first postorder stack and dictionary memoization for suffix-state counts. Charge one abstract unit for each newly evaluated state and one for each legal outgoing transition, **before** evaluation, under the unchanged `LIMIT=5_000_000`. If budget is exhausted, raise `Unproven`, whose CLI maps to `BOUNDED_DP_UNPROVEN` and exit code **2**. Add regression inputs `(123,)*9` and `(123,)*29`, budget `2000`, expecting controlled refusal. This is not a claim about real canonical profiles.

## Locally executed checks on the corrected file
- `python discovery24_feasibility_oracle.py --self-test`: `STATIC_QA_PASS profiles=9 words=135 rank_position_checks=1102 max_abstract_cells=53`.
- Explicit budget 1 against profile `(4,4)`, rank 1, position 4: `BOUNDED_DP_UNPROVEN`, shell exit **2**.
- Stress `(123,)*9`, `(123,)*29`, `(123,)*47`, rank 1, position 2, budget 2000: all `Unproven`, none `RecursionError`. The 47-month case is a stress input beyond the canonical maximum total-day constraint, not a canonical witness.
- Additional independent multiset brute enumeration: all 36 profiles of two/three months with lengths in `1..3` (and total length <=9); 234 legal words, 702 selected rank/position comparisons, zero mismatches.
- `python -m py_compile discovery24_feasibility_oracle.py`: PASS.
- The source's earlier 9-profile exhaustive matrix remains unchanged and PASS.

## Boundaries
`C_DP=states+legal transitions` remains a **QA abstract counter**, not production insertion cells. BigInt cost, peak memory, runtime, independent normative canonical profile/rank and five-field differential are not yet established. In particular, p82 and p520 are **NOT PROVEN**, even if this local test succeeds. Legacy generic E2E is still 0/7, Stage2 DISCOVERY24 remains OPEN.

NEXT: independent canonical year-5000 month profile/rank extraction under the fixed 128N search; a safely bounded memo-state/transition feasibility measurement, then conversion to the actual mandatory cost units before any numeric witness. Do not replay accepted accounting job or claim Native PASS on this skip-CI QA commit.
