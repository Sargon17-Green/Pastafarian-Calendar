# Discovery24 billing and rank association — 2026-11-25

PROJECT_ID=PC-BRANCH-CLOJURE-DUTCH
BASE_HEAD=48fdfdc75890d8f6f2b38513edb19950ce94eb8a
PRODUCTION_PATH=src/pastafari/maandrang.clj
PRODUCTION_BLOB=62f304dc013a9a9f70475bb0d34f186838b27318
ORIGINAL_QA_BLOB=410c69cbd68fccac28c16086219d648882e9cb22
FIX_QA_COMMIT=45248ace1c92a521059115996c1e82b81f215a6c
FIX_QA_BLOB=c876ddf5c32436edd7d87c62d8e16328993b74a5

Exact whole source and QA fetched from GitHub and transferred to isolated Python workspace. Transfer discrepancies detected by local Git object SHA, repaired from connector bytes, both original hashes independently verified before running. Python 3.13.5. Original pinned command exit 0: 14 rejection checks, 15 model assertions. Actual targeted mutations applied to exact full source, each anchored uniquely in prefix-volgende-keuze. Original guard results:

| Mutation | Pinned | Unpinned |
|---|---|---|
| active charge subtraction | REJECT | ACCEPT |
| double active charge | REJECT | ACCEPT |
| new group drops accumulated active charge | REJECT | ACCEPT |
| new charge subtraction | REJECT | ACCEPT |
| skipped block adds rather than subtracts rank | REJECT | ACCEPT |
| active association resets rank | REJECT | ACCEPT |
| active association resets cost | REJECT | ACCEPT |
| new association resets rank | REJECT | ACCEPT |
| new association omits new charge | REJECT | ACCEPT |

These are QA coverage gaps, not observed production failures. Added five exact clauses and nine source mutants to the existing QA guard, preserving previous checks and the blob gate. Actual Python rerun against unchanged full source exit 0, 32/32 source rejection checks (16 mutants x pinned/unpinned), 15 MODEL assertions. stdout SHA256=66a14f12a7bb84e7081e3fe6456d095bf37c32624cca207b9fee4158a5f8af6d. Exact stdout:
```json
{"canonical_prefix_sha256": "2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a", "ci": "NOT_RUN", "five_field": "NOT_RUN", "function_sha256": {"prefix-gedeelde-raming": "c0c15b1465c66e9eca9629dde27b909630d7c07fef9c254f21290f6a112fea9c", "prefix-legale-kandidaten": "dc684b2d0c8b6e3c5396a7c68740442783da95baaa90d5ca6d51a63e7f628f2d", "prefix-volgende-keuze": "33bd6a4a41f16fd159c24f680b0816d3c245a1b874b6a9ca59aa7a463ad95e68"}, "model_assertions": 15, "native": "NOT_RUN", "p82_billed_after": 5002652, "p82_billed_before": 4995675, "project_id": "PC-BRANCH-CLOJURE-DUTCH", "result": "PASS", "scope": "STATIC_PLUS_MODEL_ONLY", "source_blob": "62f304dc013a9a9f70475bb0d34f186838b27318", "source_mutations_rejected": 32, "stage2": "OPEN"}
```
Frozen canonical prefix digest emitted, not recomputed. No Clojure execution; no new CI dispatch, Native or five-field differential. Production/API/128N/5000000N unchanged; no main/merge/publication.

NEXT (QA only): audit control-flow mutations for active-empty and new-group eligibility conditions, invalid-count fallbacks and branch selection; strengthen demonstrated unpinned escapes only and rerun whole-source Python guard. Stage2 and five-field remain OPEN.
