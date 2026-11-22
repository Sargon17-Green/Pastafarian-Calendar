# QA31CD — downloaded exact-run Native evidence review (2026-11-23)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`
Scope: finite QA31CD acceptance ONLY. Stage 1 remains OPEN.

## Provenance
- Authorized branch: `qa-befunge98-stage1-order-isolation-20261008`.
- Executed commit (and branch HEAD before this report): `a2d48db290896ae6a49c280b2084148881617d40`.
- Completed-success run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45074971716 (attempt 1; head SHA matched).
- Completed-success job: `137370082535`. The source-pin, PyFunge fetch, two Native executions, independent audit, manifest and artifact-upload steps all completed/success.
- Artifact ID `14775400606`: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45074971716/artifacts/14775400606
- Downloaded artifact size: 727,967 bytes; SHA256 `a8a48737663cdcfcae6df4c93bc62dde81f02c5159803a7d3484aee7363c9db1`; ZIP CRC 11/11 valid; manifest content hashes 10/10 match.
- Immutable production blob `src/interleaved_work_counts.b98`: Git SHA1 `560d6aa5807a7f766213a33835cce85eab0fa40c`; runner checked it before execution.
- PyFunge 0.5-rc2 tar SHA256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`, checked in the completed run.

## Independent ZIP/trace recheck
Independently decompressed both original artifact traces and scanned **all** 24,977 JSONL physical STEP records per case (49,954 total), without importing the CI auditor. Rechecked STEP indices and next IP/delta continuity; p/g stack arity, storage-offset address computation and put/get value semantics; the exact consumed raw bytes and read-cursor continuity; accumulated stdout; the case trace SHA256 against the per-case receipt. Each case had 309 p/g receipts, two stdin-read events and a final HALT at tick 24977. The 20 distinct detached hostile-result entries in the artifact all record rejection; their actual execution is separately corroborated by the successful CI independent-audit log. This independent recheck did not re-execute Native or regenerate hostile mutations.

| Physical event (both new cases) | Tick | Observation |
| --- | ---: | --- |
| Original p at (860,846) to (5,1691) | 10664 | writes 1 |
| Original g at (100,1057) from (5,1691) | 10900 | returns 1 |
| Four physical gate opcodes `! * ! *` | 10901–10904 | stacks `[1,1,0]`, `[1,0]`, `[1,1]`, `[1]` |
| Original p to owner (19,1696) | 11135 | writes 1 |
| Original g from owner (19,1696) | 24722 | returns 1, nonzero |
| Original p to dynamic code (1500,1860) | 24795 | writes `56*1+62 = 118` |
| Fetch from dynamic code (1500,1860) | 24823 | opcode 118 (`v`), no intervening overwrite |
| Original `@` HALT | 24977 | termination |

| Case | Raw ASCII stdin, no newline | Trace SHA256 | Status | STEPs | Classification |
| --- | --- | --- | --- | ---: | --- |
| candidate_100 | `1 1 0 100` | `1e5282b9ecfce5e93b7ad956cc26db3237d8434f91c9cc6685fe6bcdba3486ed` | HALT | 24,977 | BOUNDED_NATURAL_WITNESS |
| candidate_999 | `1 1 0 999` | `a456b55a5172a79d78f0a0b47450e2087a56b68cf7a0dd74f35316a8ca683d03` | HALT | 24,977 | BOUNDED_NATURAL_WITNESS |

CI independent audit JSON reports: `evidence_integrity=PASS`, `cases=2`, `trace_sha256_verified_cases=2`, `physical_step_records_verified=49954`, `code_cell_pg_events_verified=2`, `dynamic_code_cell_fetches_verified=2`, `owner_cell_pg_events_verified=4`, `hostile_mutations_rejected=20`, and no route-divergence/anomaly/finite-negative cases.

## Acceptance boundary / next technical question
**QA31CD finite original-source Native witness: ACCEPTED on exact executed SHA.** This is two **additional natural-input** executions, not a re-run of QA31CB's accepted 900-case domain.

This does **not** prove a general relationship between the differing last stdin token and the owner/control value: both inputs result in owner g=1 and generated opcode 118. The bounded original-source route exists for both tested inputs; global functional reachability, value-dependent dynamic-code diversity, and complete Stage 1 gate remain **unproven**. Do not promote Stage 1, do not modify production, merge/main, or create Stage 2.

NEXT: analyze the still-open Stage 1 causal/generalization question using the exact fresh two traces and prior QA31CB accepted evidence, especially why input tokens 100 and 999 lead to the same owner/control byte. Document the narrow distinguishing-input criterion before any new experiment; do not repeat the accepted 900-case run or dispatch duplicate QA31CD CI. No user-side execution is currently required to accept this finite QA31CD result.
