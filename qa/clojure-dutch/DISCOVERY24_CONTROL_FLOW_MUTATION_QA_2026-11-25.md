# Discovery24 control-flow mutation QA — 2026-11-25
PROJECT_ID=PC-BRANCH-CLOJURE-DUTCH
BASE_HEAD=f84c1b3ab67cd8516979db85a2e2e61a947b3669
PRODUCTION_PATH=src/pastafari/maandrang.clj
PRODUCTION_BLOB=62f304dc013a9a9f70475bb0d34f186838b27318
ORIGINAL_QA_BLOB=c876ddf5c32436edd7d87c62d8e16328993b74a5
FIX_QA_COMMIT=e72714e7f7e0aff08ccfcfd6f165d924cc10f3a1
FIX_QA_BLOB=2b3fb4becf680a075d66b80051d81c62a42e72e7

Fetched exact full production and QA bytes via connector and verified local Git blob hashes. Python 3.13.5 original run returned 32 rejection checks and 15 model assertions. Each unique anchor was changed in the full source. All nine mutants were REJECT pinned / ACCEPT unpinned before repair:

- Active charge on empty rather than nonempty group.
- Active block computation on empty rather than nonempty group.
- Inverted new-group eligibility comparison.
- Bypassed new-group eligibility.
- Inverted block selection.
- New-rank invalid-count fallback incorrectly classified as budget refusal.
- No-new-group invalid-count fallback incorrectly classified as budget refusal.
- New opened count not incremented.
- Active-empty fallback resets cumulative cost to zero.

Added nine exact source clauses and nine source mutants only. The empty vector versus nil fallback was excluded because seq treats both as empty here. These are demonstrated static guard escapes, not observed production defects. Python whole-source guard completed exit 0, 50/50 source rejection checks (25 mutants x 2 modes) and 15 MODEL assertions. SHA256 of stdout including newline: 699400d85a82719cce3ff4c8a0014d0b5aaf3ba900975bb4aed17a453354d7e6.

```json
{"canonical_prefix_sha256": "2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a", "ci": "NOT_RUN", "five_field": "NOT_RUN", "function_sha256": {"prefix-gedeelde-raming": "c0c15b1465c66e9eca9629dde27b909630d7c07fef9c254f21290f6a112fea9c", "prefix-legale-kandidaten": "dc684b2d0c8b6e3c5396a7c68740442783da95baaa90d5ca6d51a63e7f628f2d", "prefix-volgende-keuze": "33bd6a4a41f16fd159c24f680b0816d3c245a1b874b6a9ca59aa7a463ad95e68"}, "model_assertions": 15, "native": "NOT_RUN", "p82_billed_after": 5002652, "p82_billed_before": 4995675, "project_id": "PC-BRANCH-CLOJURE-DUTCH", "result": "PASS", "scope": "STATIC_PLUS_MODEL_ONLY", "source_blob": "62f304dc013a9a9f70475bb0d34f186838b27318", "source_mutations_rejected": 50, "stage2": "OPEN"}
```

Frozen canonical prefix digest emitted, not recomputed. No Native, new CI dispatch or five-field differential; no production/API or budget changes. Stage2 OPEN.

NEXT (QA only): audit prefix-op-rang-begrensd position termination, state propagation and proof-map association mutations; strengthen only demonstrated unpinned escapes, retain exact production blob and 128N/5000000N. No new Native or duplicate CI; Stage2 and five-field OPEN.
