# DISCOVERY24 whole-source guard execution — 2026-11-25

PROJECT_ID=PC-BRANCH-CLOJURE-DUTCH
SOURCE_COMMIT=02555ac7e0e27a97c591e31fbc0e29964d5fb6b5
SOURCE_PATH=src/pastafari/maandrang.clj
SOURCE_GIT_BLOB=62f304dc013a9a9f70475bb0d34f186838b27318
QA_PATH=qa/clojure-dutch/discovery24_source_formula_drift_qa.py
QA_GIT_BLOB=3ba36cffe24c0e6d8a0c28d0581ab7ada24d2158

Both complete files fetched from the exact commit via authorized GitHub connector, losslessly transferred to isolated local workspace; Python independently calculated Git object hashes (26298 and 9597 bytes respectively) before executing. No checkout modification. Direct network clone unavailable. Python 3.13.5; 20-second timeout; actual command: python discovery24_source_formula_drift_qa.py --source maandrang.clj.

Exit 0. Exact stdout:
```json
{"canonical_prefix_sha256": "2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a", "ci": "NOT_RUN", "five_field": "NOT_RUN", "function_sha256": {"prefix-gedeelde-raming": "c0c15b1465c66e9eca9629dde27b909630d7c07fef9c254f21290f6a112fea9c", "prefix-legale-kandidaten": "dc684b2d0c8b6e3c5396a7c68740442783da95baaa90d5ca6d51a63e7f628f2d", "prefix-volgende-keuze": "33bd6a4a41f16fd159c24f680b0816d3c245a1b874b6a9ca59aa7a463ad95e68"}, "model_assertions": 15, "native": "NOT_RUN", "p82_billed_after": 5002652, "p82_billed_before": 4995675, "project_id": "PC-BRANCH-CLOJURE-DUTCH", "result": "PASS", "scope": "STATIC_PLUS_MODEL_ONLY", "source_blob": "62f304dc013a9a9f70475bb0d34f186838b27318", "source_mutations_rejected": 10, "stage2": "OPEN"}
```
stdout SHA256=5e8039436b681d38472a4f2aded1b6e795428fc45b69177f33df3ddfae8fbb79
Source SHA256=e244b19a9536a2ccea9765ee929a6b2d019288b8c2d24941c31c650d6339a003
QA SHA256=ace68d952c618c38b6a76d04ebb6dae63c40261737894a0d8a98c22e104d396d

Additional actual CLI negative probes: appended newline to a temporary copy -> exit 1, AssertionError: FAIL-CLOSED: production Git blob changed; missing.clj -> exit 1, FileNotFoundError. No production mutation committed.

Scope: STATIC_PLUS_MODEL_ONLY PASS, 10/10 rejection checks (5 distinct mutants x 2 guard modes), 15 MODEL assertions. Frozen prefix digest is emitted as a constant, not recomputed by this script; p82 witness arithmetic is tested. No new CI, Native or five-field differential; Stage2 OPEN. No production/API/128N/5000000N/main/merge/publication changes.

NEXT (QA only): independently audit clause multiplicity and active/new budget-guard mutation coverage. In particular, the script uses set(clauses), so the two repeated rank-branch clauses are not enforced by multiplicity when the blob guard is bypassed. Test targeted deletion of one occurrence against the exact full source, then strengthen the QA-only guard if needed, preserving the blob gate and existing checks. No new Native or duplicate CI.
