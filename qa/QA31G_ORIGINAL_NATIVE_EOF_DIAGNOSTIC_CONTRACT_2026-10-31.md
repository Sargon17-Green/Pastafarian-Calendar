# QA31G — original Native EOF diagnostic contract (2026-10-31)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ; branch: qa-befunge98-stage1-order-isolation-20261008; Stage 1 OPEN.

The preceding QA31F commit 1433d57b714978f0d65ffed62a2c0c897597ac04 passed scoped source-model CI 41183915851 (6 model EOF cases, 4 opcode mutations), **not a native execution**.

Original source: src/interleaved_work_counts.b98, Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c. Runtime: PyFunge 0.5-rc2 archive SHA256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac. The three exact natural stdin byte strings are b"", b"1", b"1 " (no newline). No IP relocation, source edits, input substitution, cross-language solution, main change or merge.

Per-case hard cap: 7,000 physical native STEPs. Capture complete pre/post top-of-stack, IP, delta, op, native read and EOF events, output and all p/g/j operands into gzip JSONL, with per-file SHA256. Independent Python 3 audit checks source, trace integrity, every STEP, physical IP linkage, p/g overlay, j operands, read cursor/bytes and five forged-receipt controls. Preserve artifact and logs even for failure or model mismatch.

Bounded model predicts: b"1" reflects at EOF, reaches j(89,29) with m=1 and operand=61, then row32 j and p(248,35) writing q(1,49)=1. Empty and b"1 " predict row29 operand zero and no row32/35. These are hypotheses, not Native expectations silently forced into the driver. Native discrepancy shall be labeled MODEL_MISMATCH_OR_INCOMPLETE, not a fake PASS.

NEXT: inspect run and exact SHA, download the new artifact once, verify ZIP SHA256/CRC, full native STEP receipts and independent audit, then report measured EOF/row29/32/35 behavior. A green workflow means only this finite diagnostic, not Stage1 final acceptance, global ownership or geometric/functional QA.
