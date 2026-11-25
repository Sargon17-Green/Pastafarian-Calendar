# Discovery24 prefix state and proof-map mutation QA — 2026-11-25
PROJECT_ID=PC-BRANCH-CLOJURE-DUTCH
BASE_HEAD=46f8660cd4eab6793454be7effe4adcc491b34c6
PRODUCTION_PATH=src/pastafari/maandrang.clj
PRODUCTION_BLOB=62f304dc013a9a9f70475bb0d34f186838b27318
ORIGINAL_QA_BLOB=2b3fb4becf680a075d66b80051d81c62a42e72e7
FIX_QA_COMMIT=e244dda3c3967c23edb1f013ca0d932a22707151
FIX_QA_BLOB=a5031d24241f6b2f517c312b9f36f079951b2df6

Exact full production and QA bytes fetched via GitHub connector, losslessly transferred to the local Python environment, and verified against both Git blob hashes. Python 3.13.5 original run reproduced 50/50 source rejection checks, 15 MODEL assertions and stdout SHA256 699400d85a82719cce3ff4c8a0014d0b5aaf3ba900975bb4aed17a453354d7e6.

In prefix-op-rang-begrensd, each of 21 distinct mutation anchors occurred exactly once in its extracted definition. All were REJECT pinned / ACCEPT unpinned before the QA edit, and REJECT in both modes afterward. Categories:
- Position termination (strict comparison, initial position, increment).
- Initialization and state propagation (initial residual, closed count, rank, forwarded cumulative cost, five recur state fields, appended selected month).
- Proof-map association (last month selection, month-id, day count, prefix, position, accumulated bound, proof scope, full-weaving flag).
The exact replacements are in the QA script. These are demonstrated guard coverage gaps, not production failures or executed Clojure mutants.

Only 21 clauses and 21 mutation cases were added. The whole-source Python guard exited 0 with 92/92 rejection checks (46 x 2 modes) and 15 MODEL assertions. The updated local QA blob matched the remote blob. SHA256 of stdout including newline: 2589e6e8b27ef4ee7f84b197e5f29553686f852d706fd576979e75453bb25d1d.

```json
{"canonical_prefix_sha256": "2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a", "ci": "NOT_RUN", "five_field": "NOT_RUN", "function_sha256": {"prefix-gedeelde-raming": "c0c15b1465c66e9eca9629dde27b909630d7c07fef9c254f21290f6a112fea9c", "prefix-legale-kandidaten": "dc684b2d0c8b6e3c5396a7c68740442783da95baaa90d5ca6d51a63e7f628f2d", "prefix-op-rang-begrensd": "644a814fe9cad194a5b6e8fab3cd38fc4746a6add0c8dc449bd8d5a70cb4a7d8", "prefix-volgende-keuze": "33bd6a4a41f16fd159c24f680b0816d3c245a1b874b6a9ca59aa7a463ad95e68"}, "model_assertions": 15, "native": "NOT_RUN", "p82_billed_after": 5002652, "p82_billed_before": 4995675, "project_id": "PC-BRANCH-CLOJURE-DUTCH", "result": "PASS", "scope": "STATIC_PLUS_MODEL_ONLY", "source_blob": "62f304dc013a9a9f70475bb0d34f186838b27318", "source_mutations_rejected": 92, "stage2": "OPEN"}
```

Frozen canonical prefix digest emitted, not recomputed. No new CI dispatch, Native or five-field differential. No production/API/budget changes. Stage2 OPEN.

NEXT (QA ONLY): audit prefix-op-rang-begrensd profile/position/budget/rank validation and refusal-code association, including default-budget arity forwarding. Strengthen demonstrated unpinned escapes only; rerun whole-source Python guard. Preserve source blob and 128N/5000000N; no new Native, duplicate CI, production/API/main/merge/publication changes.
