# QA31BZ — exact-match p interception preflight (QA-only)

**PROJECT_ID:** PC-BRANCH-BEFUNGE98-KYRGYZ  
**Branch:** qa-befunge98-stage1-order-isolation-20261008  
**Entry HEAD:** d22c1f95fa8e695cd5cf27ce04be5c71f0f8790d  
**QA code commit:** 0eb8bc9ce4b143b5eaf8c66945b50422e060c1db  
**Original source Git blob:** 560d6aa5807a7f766213a33835cce85eab0fa40c (1,836,425 bytes, prior QA31BY evidence)  
**Date:** 2026-11-21

## Delivered and verified

Created qa/qa31bz_exact_p_gate.py, Python 3.11+ standard library, with exact_preflight(snapshot) and --selftest. A byte-identical local copy was constructed and its canonical Git blob SHA-1 compared against live GitHub file content: **2b286c6e5faaf19b2e45f6b16edcce0d3b19136f**, **7,680 bytes**. Local python3 -m py_compile PASS. Executing python3 qa31bz_exact_p_gate.py --selftest returned **16/16 synthetic positive cases, 20/20 detached hostile mutations rejected**. This is **STATIC CONTRACT QA ONLY**, not original physical evidence. No Native or CI dispatched.

The gate checks exact project, source pin, case, tick, IP, opcode, string mode, IP count, stack-of-stacks depth, queue/invert mode, SO integer shape and value, effective target and the integer p operands. A hypothetical pre-p execution snapshot must contain:

- project_id=PC-BRANCH-BEFUNGE98-KYRGYZ, source_git_blob_sha1=560d6..., case=pair_30_30.
- tick=17817, ip=[96,480], op=112 (p), one IP, no string mode, one TOSS stack, no queue/invert modes.
- storage_offset=[so_x,so_y], pre_toss bottom-to-top with suffix [62,x_rel,y_rel], and (x_rel+so_x,y_rel+so_y)==(1500,1860). Reported effective_target=[1500,1860] must agree with computed address.
- Result: proposed pre-TOSS changes just the stored-value operand 62→118. Predicted post-TOSS after the three p pops remains original_pre_toss[:-3]. This preflight function does not itself execute Native or mutate the FungeSpace.

Existing QA31BY showed the original signed writer tick17817 p(96,480), target (1500,1860), value62 and original subsequent fetch tick17845 opcode '>' (62). Historical signed BW/BX records do **not** yet prove the full original p pre-stack and storage offset required by this new Native guard.

## Precise remaining Native contract (NOT EXECUTED)

1. Read the actual immutable original pair_30_30 manifest, stdin and physical STEP file. Verify original archive SHA-256, ZIP CRC, member digests, source SHA, compressed trace hash, step continuity and original-case identity. Do not treat independent static synthetic states as Native receipts.
2. Instrument the original Python 2 PyFunge/QA20 runner without modifying the .b98 file or starting IP. At the p tick capture original full pre/post TOSS, IP, delta, source opcode, SO, stack mode, stack-of-stacks depth, physical FungeSpace before and after, target address, input reads and output. Compare **the entire original physical STEP trace** with the original signed control, not just IP/tick.
3. Only after original-state parity, run exactly one modified Native case on the same signed source and stdin. Require identical full prefix state and a single-fire latch at the exact p event. Replace only the third-from-top TOSS value 62→118 before the Native interpreter executes p. Keep coordinates, offset, and pop consumption fixed; confirm that physical FungeSpace (1500,1860) becomes 118. Abort on zero or multiple latch firings and on any pre-state mismatch.
4. Persist both complete original and changed STEP streams (or bounded error/timeout), compressed digests, stdin/read/stdout records, full p/g and FungeSpace receipt lineage, source/runner SHA and explicit output status. A fully separate auditor must verify trace continuity, original-control equivalence, changed-run earliest divergence, effective-address and owner calculations, and reject at least 12 independent detached forgeries. It must not copy the producer algorithm or fixtures. Conditional vertical path to dot at (1500,1881) is **not guaranteed** and cannot be credited before physically observed.
5. Dispatch distinct CI only once when a pinned runner and separate auditor with original-case data exist. No redundant accepted original CI, no claim of natural stdin perturbation, no production/main/merge/release/Stage2 changes.

## Gate status

| Gate | Result |
| --- | --- |
| Exact live GitHub blob vs locally executed code | PASS |
| Local Python compilation | PASS |
| 16 synthetic positives / 20 detached hostile rejections | PASS / PASS |
| Original signed p pre-stack/SO and full control replay | UNKNOWN — not executed here |
| Real modified Native and independent differential audit | UNKNOWN — not executed |
| New CI | NOT RUN (commit deliberately skipped CI) |
| Stage1 global source ownership, functional and geometric gates | OPEN — NOT ACCEPTED |

**NEXT QA31CA (QA continuation label, not Stage2):** implement original-case source-bound Native pre-p snapshot/receipt capture and a separate independent trace auditor. First verify the exact raw stdin and archived pair_30_30 identity, then decide whether one changed-run p splice is warranted. Do not infer signed source proof from static selftest.
