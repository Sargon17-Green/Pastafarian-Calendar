# DISCOVERY24 p520 — in-place insertion and five-field differential (2026-11-26)

PROJECT_ID: `PC-BRANCH-CLOJURE-DUTCH`  
Branch: `Clojure+Nederlands`  
Scope: **TEST/QA ONLY**.

## Purpose

Execute the previously committed test-only in-place insertion DP prototype on an exact branch SHA, compare its p81/p82/p520 prefix results against the independent Python insertion and gap-convolution oracles, and construct the five numeric date fields for the canonical p520 target.

No production source, public API, search budget, production shared-group ceiling, Stage policy, main branch, merge, or publication is changed.

## Canonical input contract

- Calculation day and target day: `-15055654N`.
- Normative target year: `5000`.
- Target position: exactly `520` (one-based, measured from the first day of the normative year).
- Search budget: `128N`.
- Existing production shared-group ceiling: `5000000N`.
- The 33-month, 3,569-day canonical profile and rank are regenerated from the pinned normative oracle and cross-checked against the production year/profile/rank selectors before the alternative model runs.

## Independent oracle chain

1. **Clojure in-place insertion model:** test-only implementation; no production function is changed or invoked to rank the p520 prefix.
2. **Python reference:** the committed standalone insertion implementation and a separately implemented gap-convolution counter independently recompute the canonical total and p81/p82/p520 prefix fields.
3. **Normative five-field composition:** year, cutlet identity/day, and month-name index are recomputed from `normative-oracle.clj`; the month ID and occurrence are supplied by the independent gap-convolution prefix. The Clojure in-place prefix is independently composed a second time and must yield the same five-field vector.
4. The full 3,569-symbol month weaving is not materialized. This is a bounded prefix witness, not a full-weaving computation.

## Cost-accounting units — keep separate

- `source-raming-cost`: cumulative sum of the pinned production private `raming()` result for every candidate examined, including the root candidate. This is a per-candidate diagnostic.
- `alternative-dp-cell-writes`: one unit per output-distribution array entry written by the test-only in-place DP.
- `shared-group-cost`: the active/new candidate-group charge schedule independently reproduced by the Python oracle. This is the modelled production billing schedule and is the only one directly compared with the existing 5,000,000 production ceiling.

These units are not interchangeable. A DP-write count below 5,000,000 is not a production budget PASS. A shared-group cost above the ceiling remains a refusal under the unchanged production accounting.

## Required evidence

- Exact `GITHUB_SHA` in the canonical input and generated EDN.
- Pinned production source blob `62f304dc013a9a9f70475bb0d34f186838b27318`.
- Pinned Python insertion/gap oracle blob `e3a5616acda7c1fd1853e9c6114049efa86d7bd3`.
- Pinned normative oracle blob `5b2f486a12aeb8ff3cea0d762ba26882d67fb4cc`.
- Native suite must execute the in-place test Var; a preflight checks its registration and the workflow requires the generated EDN artifact.
- CI uploads `discovery24_inplace_five_field.edn` and the exact-SHA canonical input JSON.

## Gate classification

A successful result is **PASS_MODEL_ONLY** for this independent test-only model and the five-field differential. It is not a production API PASS, production-budget PASS, full month-weaving PASS, or Stage 2 acceptance.

Stage 2 remains **OPEN** until the production accounting correspondence and all other Stage 2 gates are independently satisfied. No production change or policy decision is implied.
