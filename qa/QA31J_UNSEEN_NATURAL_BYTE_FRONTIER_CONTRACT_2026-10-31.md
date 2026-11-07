# QA31J — two unseen natural-byte Native frontiers (2026-10-31)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008. Stage 1 remains OPEN.

## Verified predecessor

QA31I exact-SHA workflow 41203213096 on 5f25d0fb70e27a1dbed854b1aa3f1224f4ab3b82 completed/success, job 124542999420. Artifact 13044105277 independently downloaded: SHA256 06ac2cf25259a77cf1c6e958815c3c3d87d9f70c7c8eefdfbcac3456a6e85c6e, ZIP CRC 4/4 files. Native original signed pair 5084 STEPs, first input-read difference tick 292, 1131 matching physical-state STEPs, first physical divergence tick 1132; 10/10 hostile pair mutations rejected. This is finite QA, not Stage1 PASS or global source ownership.

## QA31J engineering choice and scope

Choose NEW unseen equal-length natural byte inputs: b'1\n' (hex 310a, newline terminator) and b'1\t' (hex 3109, tab without newline). Do not re-run the established b'1' or b'1 ' cases. The two-byte constraint separates byte length from line-buffer/EOF branching, but no outputs or control routes are assumed before Native evidence. The program source and IP stay unchanged.

The original QA31G PyFunge-98 observer is reused from this SAME Befunge branch solely as an execution probe; the newly written QA31J Python 3 source/STEP auditor is independent of this Native driver. An existing Stage1 PyFunge-98 0.5 rc2 tarball is SHA256-pinned e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac and runs under Python 2.7. Original Git source blob 560d6aa5807a7f766213a33835cce85eab0fa40c must match.

## Measurable contract

Inputs: exactly two new raw two-byte stdin buffers. Output: bounded native receipt, compressed full-physical-STEP JSONL for both, and independent audit JSON/log. Each case uses at most 7,000 STEPs, with an outer 360-second process timeout. Preserve HALT, STEP_LIMIT or RUNTIME_ERROR as observed; do not invent successful outcomes. Never change original source, inject values, move IP or re-run QA31G pair.

Verifier: exact Git source blob, natural stdin hex/SHA256, compressed STEP SHA256, every physical STEP and IP continuity, source/overlay cell opcode, physical p/g and relevant j behavior, exact input read byte slices, observed HALT/limit/error accounting, and eight independent receipt/trace corruptions rejected. Scope excludes storage-offset and string-mode paths not modeled by the current verifier. If such a path occurs, keep RED with actual evidence rather than assigning PASS.

Acceptance: only after exact-head CI completed/success, log inspection, separate downloaded artifact SHA256/ZIP CRC check and full receipt audit. The new natural-input result must not be used as general ownership, total functional QA, geometric QA or Stage 1 acceptance. No Stage 2, main, merge or protected-branch writes.

NEXT: inspect exact-head QA31J run, independently verify its ZIP/artifact and both complete new Native traces. If diagnostic fails, repair on the actual failing event. If it passes, compare witnessed gate and memory writers with QA31G finite evidence and select the next original-source ownership frontier.
