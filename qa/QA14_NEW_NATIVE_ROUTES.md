# QA14 — new 2D Native physical-memory and geometry routes

**Status: pending native evidence.** This is a new finite corpus, not a replay of QA13's 17 original Native traces. The production source byte-identical blob remains `560d6aa5807a7f766213a33835cce85eab0fa40c`.

Per test, 5 real independently started PyFunge processes: actual instrumented production, fresh plain production, Native work-count oracle and two independent Native SAVE oracles. Frozen 16 unordered signed day pairs, both ordered directions, 32 new exact Native input cases. Four shards of eight; 160 Native interpreter invocations expected if all runs succeed. In each trace, independent consumers reconstruct physical p/g events, verify time-ordered mutable instruction bytes, real read-after-write and execution of previously-written executable cells. A fifth job validates complete shard coverage and the finite measured totals. Ten synthetic forged manifests rejected locally; CI still required.

See `qa/stage1_qa14_native_new_routes.py`, `qa/stage1_qa14_native_new_routes_audit.py`, `.github/workflows/befunge-stage1-qa14-new-native-routes.yml`.

Scope limit: source/prompt/interpreter Native only, no cross-implementation oracle, no full calendarDate orchestration, no Stage 1 completion, no Stage 2 and no canonical merge. Historical QA13 PASS and QA09 intentional RED remain independently tracked.

## Verified new Native QA14 execution — 20 October 2026

**QA14 scoped Native PASS.** [CI run 39374913267](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39374913267) on exact source/QA commit `1184e7a3728808d46d359e88973820af4fa5f00d`, 5/5 success: four new Native shards plus the independent cross-shard receipt audit. All 32 frozen new directed day pairs completed five genuine separate interpreter processes each: **160 real Native PyFunge invocations** (32 traced production, 32 additional plain production, 96 native reference), 32 new original raw `STEP`/`p`/`g` logs. For every valid input, the seven-field final output matched all independently executed Befunge reference parts and a fresh uninstrumented production replay.

Original Native artifacts: shard 0 `12242831803`, shard 1 `12243500881`, shard 2 `12243575160`, shard 3 `12243082239`. Independent aggregate artifact `12242474938`. Each raw trace is preserved gzipped with SHA-256 of its original uncompressed bytes in the shard manifest, along with stdout, code provenance and a physical trace audit proof.

Actual observed totals **11,490 physical `p` writes**, **22,210 physical `g` reads**, **596 executions of cells written earlier**, and **32 distinct arithmetic write-history digests**. Per-trace audits independently cross-checked temporal Native `p/g` before/after events, physical memory values, read-after-write, executed runtime-mutated opcodes, input-dependent gate `(1500,1860)`, and the existing directed Native IP graph/source/memory auditor. Local and CI synthetic manifest tests rejected 10/10 forged scenarios. The aggregate verifier rejected missing/misordered shards and made no claim of global Stage 1 acceptance.

**Limitations:** finite evidence only, 32 selected real paths (in addition to QA13's earlier 17). No generalized correctness proof over unbounded integers, no unrestricted reentrancy/same-object reuse proof, no full geometric anti-dead-code/ownership certification, no release readiness. Production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c` unchanged. QA11B/QA12/QA13 accepted scopes remain independent. `LAST_COMPLETED_STAGE=0`; canonical branches and `main` untouched, no Stage 2, no PR merge.
