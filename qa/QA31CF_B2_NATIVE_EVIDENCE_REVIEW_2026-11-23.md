# QA31CF — independently verified finite b=2 original Native witness (2026-11-23)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`  
Authorized QA branch: `qa-befunge98-stage1-order-isolation-20261008`  
Executed CI SHA: `efce52f94a02a94685e657bbd99de902c3bdf547`  
**Stage 1 remains OPEN.** QA-only acceptance of this one finite original-source input is not global Stage 1 acceptance.

## Precondition and repair
- Previous run [45254582600](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45254582600) / job `137972917902`: **completed/failure**, at Python 2 `py_compile` on stale path `/tmp/qa31cf_natural_input_sweep.py`; no original-source Native execution.
- Atomic workflow-only fix: [`efce52f94a02a94685e657bbd99de902c3bdf547`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/efce52f94a02a94685e657bbd99de902c3bdf547) changed the compile target to the copied `/tmp/qa31cf_nonzero_discriminator_native.py`; checkout branch HEAD was verified before and after the edit. No production or Native-runner changes.
- Corrected [run 45271815328](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45271815328), job `138033281715`: **completed/success** at exact `efce52f94a02a94685e657bbd99de902c3bdf547`. No manual duplicate dispatch.

## Source and retained evidence
- Git tree at executed SHA resolves `src/interleaved_work_counts.b98` to the original unchanged blob `560d6aa5807a7f766213a33835cce85eab0fa40c` (1,836,425 bytes). The workflow separately performed the Git blob pin check before execution.
- Runtime: PyFunge 0.5-rc2, original tarball SHA256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`, checked in job logs.
- [Artifact 14865377417](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45271815328/artifacts/14865377417) independently downloaded. Outer ZIP SHA256 `bc05038212ebd4bf48a62103fc192e0adfd068f0baf9dd9c134fd90200666252` exactly matches GitHub artifact digest and runner upload log. ZIP CRC: PASS. All **9/9** manifest member SHA256 digests independently matched; trace gzip SHA256 `fe6c6aee53066d7e7a261988753ccad942debf0726fa548dc46f2a2df0f62b61`.
- Input is the pre-registered unmodified 9 bytes `31 20 32 20 30 20 31 30 30` = ASCII `1 2 0 100` **without LF**; SHA256 `1699e3d66b01f2d43c0658c479d43e15006255927be082816ed7610a38c70f83`.
- The original PyFunge run **HALT**ed after **24,977 physical STEP** records (cap 50,000); independent offline audit checked all 24,977 sequential `t` values, stdout reconstruction, address/storage offsets and event consistency across **309 p/g records**. First `~` read: tick 292, byte cursor 0→9. Second `~` read: tick 9,598, cursor 9→9, EOF. No synthetic IP placement, source mutation, or injected FungeSpace state.

## Independent physical causal checks (ticks are 1-based)
1. At **10664**, original `p(5,1691)=2`; at **10900**, `g(5,1691)=2` with physical stack prefix `[1,1,2]`.
2. Consecutive original instructions at **10901–10904**, `! * ! *`, change this stack prefix: `[1,1,2]` → `[1,1,0]` → `[1,0]` → `[1,1]` → `[1]`. This explicitly tests `b=2` rather than only `b=1`.
3. At **11135**, original `p(19,1696)=1`; at **24722**, original `g(19,1696)=1`, with no intermediate write to the owner cell.
4. At **24795**, original `p(1500,1860)=118`, consistent with `56×1+62`; at **24823**, actual instruction fetch at `(1500,1860)` reads opcode **118 (`v`)**, with no intervening write to that code cell.
5. The CI auditor reports `evidence_integrity=PASS`, `classification=BOUNDED_NATURAL_WITNESS`, and **20/20** detached hostile mutations rejected. The downloaded `qa31cf_hostile_results.jsonl` contains 20 unique mutations with explicit `rejected=true`. The offline check verified the receipts and integrity chain; it did not re-run all 20 generated forgery experiments independently.

## Scope and next gate
This is a **new finite original-source Native witness** for the nonzero `b=2` discriminator. Together with the previously accepted separate QA31CB b=0 and QA31CD b=1 evidence (not re-run here), it supports the conditional nonzero-owner relationship on these inputs. It is **not** a proof for arbitrary inputs or global FungeSpace/IP reachability, nor independent engine reimplementation. No production/main/merge or Stage 2 modification. `stage1_accepted=false` and `global_reachability_proven=false` remain mandatory.

NEXT: a focused independent differential review of the previously accepted signed b=0/1 trace receipts against this new b=2 signature, without repeating Native execution; then determine what additional global Stage1 proof obligations remain. Preserve the signed artifact and this report.
