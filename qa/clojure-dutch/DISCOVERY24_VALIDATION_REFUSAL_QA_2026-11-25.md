# DISCOVERY24 bounded-prefix validation and refusal-code QA — 2026-11-25

PROJECT_ID=PC-BRANCH-CLOJURE-DUTCH
BASE_HEAD=d5a9be2ff730b0cdea2e307b2c68788a7a18beb6
PRODUCTION_PATH=src/pastafari/maandrang.clj
PRODUCTION_GIT_BLOB=62f304dc013a9a9f70475bb0d34f186838b27318
QA_PATH=qa/clojure-dutch/discovery24_source_formula_drift_qa.py
QA_GIT_BLOB=522fb4be3bf286aae54b5d9cfa8cc07209ebd2cd

## Audit scope

QA-only audit of prefix-op-rang-begrensd: default-budget arity forwarding, profile/position/budget/rank validation, and each validation failure's refusal-code association. The production source was fetched at the exact branch HEAD and independently verified against its Git blob. No Clojure source, public API, budget constant, main, or merge target was changed.

## Existing-guard escape evidence

Twenty uniquely anchored semantic mutations were applied to isolated copies of the exact source. All twenty passed the pre-existing unpinned source guard (require_blob=False), proving validation coverage gaps in the QA guard, not defects observed by executing the production Clojure function.

- Default 3-arity forwarding: wrong default budget.
- Profile (7): vector-only requirement; minimum and maximum profile count; integer element requirement; minimum and maximum month length; profile refusal-code association.
- Position (4): integer requirement; lower bound; strict upper bound; position refusal-code association.
- Budget (4): integer requirement; lower bound; upper bound; budget refusal-code association.
- Rank (4): integer requirement; lower bound; upper bound; rank refusal-code association.

## QA-only strengthening

The source guard now pins the complete default-budget forwarding expression and all four complete validation/refusal blocks. It requires each of those clauses to occur exactly once in the extracted definition. Twenty corresponding mutation cases were added; each mutant is checked both with the Git-blob pin enabled and with the pin disabled. The independent Python contract model adds 35 boundary/refusal assertions covering valid and invalid profiles, positions, budgets, ranks, and the default-budget path.

## Actual local execution

Python 3.13.5; 20-second bounded command:

python discovery24_source_formula_drift_qa.py --source maandrang.clj

Exit code: 0.

Exact stdout:

```json
{"canonical_prefix_sha256":"2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a","ci":"NOT_RUN","five_field":"NOT_RUN","function_sha256":{"prefix-gedeelde-raming":"c0c15b1465c66e9eca9629dde27b909630d7c07fef9c254f21290f6a112fea9c","prefix-legale-kandidaten":"dc684b2d0c8b6e3c5396a7c68740442783da95baaa90d5ca6d51a63e7f628f2d","prefix-op-rang-begrensd":"644a814fe9cad194a5b6e8fab3cd38fc4746a6add0c8dc449bd8d5a70cb4a7d8","prefix-volgende-keuze":"33bd6a4a41f16fd159c24f680b0816d3c245a1b874b6a9ca59aa7a463ad95e68"},"model_assertions":50,"native":"NOT_RUN","p82_billed_after":5002652,"p82_billed_before":4995675,"project_id":"PC-BRANCH-CLOJURE-DUTCH","result":"PASS","scope":"STATIC_PLUS_MODEL_ONLY","source_blob":"62f304dc013a9a9f70475bb0d34f186838b27318","source_mutations_rejected":132,"stage2":"OPEN"}
```

- 66 distinct source mutants rejected in both modes: 132/132 rejection checks.
- 50 independent MODEL assertions (15 pre-existing + 35 validation assertions).
- stdout SHA256, including the final newline: 1305328dfe2d816f35f543fed0b5cc371477ac9320b71089ed9ab0077078fef8.
- Production source Git blob remains exactly 62f304dc013a9a9f70475bb0d34f186838b27318; all four function SHA256 values remain unchanged.

## Limits

STATIC_PLUS_MODEL_ONLY PASS. This is not a production Clojure execution, CI result, Native result, five-field differential, or Stage2 acceptance. No CI was dispatched, and the earlier cancelled run was not repeated. Stage2 and five-field remain OPEN.
