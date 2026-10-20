# QA14 — new 2D Native physical-memory and geometry routes

**Status: pending native evidence.** This is a new finite corpus, not a replay of QA13's 17 original Native traces. The production source byte-identical blob remains `560d6aa5807a7f766213a33835cce85eab0fa40c`.

Per test, 5 real independently started PyFunge processes: actual instrumented production, fresh plain production, Native work-count oracle and two independent Native SAVE oracles. Frozen 16 unordered signed day pairs, both ordered directions, 32 new exact Native input cases. Four shards of eight; 160 Native interpreter invocations expected if all runs succeed. In each trace, independent consumers reconstruct physical p/g events, verify time-ordered mutable instruction bytes, real read-after-write and execution of previously-written executable cells. A fifth job validates complete shard coverage and the finite measured totals. Ten synthetic forged manifests rejected locally; CI still required.

See `qa/stage1_qa14_native_new_routes.py`, `qa/stage1_qa14_native_new_routes_audit.py`, `.github/workflows/befunge-stage1-qa14-new-native-routes.yml`.

Scope limit: source/prompt/interpreter Native only, no cross-implementation oracle, no full calendarDate orchestration, no Stage 1 completion, no Stage 2 and no canonical merge. Historical QA13 PASS and QA09 intentional RED remain independently tracked.
