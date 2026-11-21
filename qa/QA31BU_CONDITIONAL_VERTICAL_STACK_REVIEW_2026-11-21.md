# QA31BU — conditional vertical stack semantics with original signed dot-cell provenance

**PROJECT_ID** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized branch** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified entry HEAD** `a68cb80e34af6f1482d8fa275d8f901483bace63`  
**Immutable original Git blob** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Date** 2026-11-21  
**Verdict** QA31BU **LOCAL FINITE PASS, QA-only**. Stage1 **OPEN**. New Native=0; new CI=0.

## Scope and original evidence

GitHub's immutable Git blob API was read for x=1500, zero-based y=1861..1881; all 21 observed byte positions were `v7a*9+1a*7+a*1+a*0+g.`; y1881 was ASCII 46 (`.`), y1882 was `8` (outside this QA bound). Source window original row lengths were each 1501. This was an exact immutable Git-blob lookup for the byte-window; the entire ~1.8MB original source blob was **not locally rehashed**. Original-source coordinate pinning is narrow; no modified source was fetched or used.

Four previously accepted immutable archives, **QA31AI/BN/BO/BT**, were materialized from `/Befunge_QA_Artifacts` and independently SHA256/ZIP-CRC/manifest-verified; individual 200 original Native HALT receipts and all 3,628,390 signed physical STEP records were authenticated by the original QA31BP corpus loader. Within the selected 135 source-pinned original complete traces, the new y1881 cell has:

- Original physical `p` writes before original (1500,1860) fetch: **0 across all 135**.
- Original IP visits at (1500,1881) in the complete original trace: **0 across all 135**.
- Independent chronological and reverse `p` owner scans: **135/135 agreement**.
- Consequently, the original memory value at that original fetch was the immutable `.` byte. This is **not** proof of its value in a changed run.

The same original 135 corpus traces contained **24 genuine unchanged/no-numeric-effect controls** tied to the original signed trace digests. Those controls were checked against immutable QA31BN no-op receipts, not synthesized Native cases.

## Conditional execution contract

**Preconditions (counterfactual only):** start a Befunge-98 instruction pointer at (1500,1861), fetch original immutable `v`, use original unchanged 21 source bytes through y1881, an explicit initial stack `S`, explicit storage offset `SO=(SO_x,SO_y)`, an explicit integer cell `M[(79+SO_x,1710+SO_y)] = m`, and stop after **exactly 21 executed source instructions** at the `.` (the next IP would be (1500,1882)). This is a conditional partial prefix, not program termination.

The source computes **relative** `g` vector `(79,1710)`, not an unconditional absolute address. Under Funge-98 storage-offset rules, actual `g` address is `(79+SO_x,1710+SO_y)`. The value `m` is output as a decimal integer by `.` and popped, leaving the end stack equal to the explicit initial stack `S`. The output receipt's example trailing ASCII space follows the **test oracle's specified I/O convention**; this QA is not Native byte-for-byte output validation.

- Oracle A: independently executes each source opcode (`v`, integer pushes, `a`, `*`, `+`, `g`, `.`) with explicit stack and IP, bounded to 21 steps.
- Oracle B: independently derives the two decimal-place expressions `7*10+9` and `1*1000+7*100+1*10+0`, applies `SO`, and verifies preserved initial stack, output value, and next IP without running a stack interpreter.
- Test grid: 12 initial stacks × 12 memory values × 4 storage offsets = **576/576 exact cross-oracle agreements**. Values include negatives, zero, 32/127, and signed-64-bit extremes. Offsets include `(0,0)`, `(25,-10)`, `(-79,0)`, and `(-100,1)`.
- **33/33 detached hostile controls rejected**, including 21 independent source-byte corruptions at each position (including the final dot), and 12 tampered signed receipt-memory rows. These rejections are checks against static/source and original-report baselines only; none is an altered Native witness.

## Limits, reproducibility and NEXT

Actual modified-run entry, traversal, dynamic `p` writers, storage offset, operand stack, source cell values, real `g` read, Native output, and global Stage1 functional/geometric gates remain **UNKNOWN/OPEN**. The source static path does not imply altered-run reachability. No production code, main, protected branch, new Native/CI run, or Stage2 authorization was involved.

Evidence: `qa31bu_conditional_vertical_stack.py`, original QA31BP immutable corpus loader, `evidence/qa31bu_summary.json`, 135 signed original ownership rows, 576 conditional oracle rows, 33 detached hostile rows, `QA31BU_LOCAL_RUN.log`, manifest SHA256 and ZIP CRC. Inputs are externally frozen, not duplicated into this evidence bundle; `RUN_QA31BU.txt` specifies the exact four input archives.

**NEXT (QA31BV, QA-only; not a new stage):** determine original signed storage-offset provenance at each relevant original `g`/`p` site and at the original (1500,1860) fetch using existing signed event metadata; produce a finite signed-vs-symbolic offset audit, include unknown states explicitly, with source/trace/receipt integrity controls. Do not equate the conditional source vector to a modified-run absolute address. Do not dispatch Native/CI without a distinct evidence-backed hypothesis; Stage1 remains open.