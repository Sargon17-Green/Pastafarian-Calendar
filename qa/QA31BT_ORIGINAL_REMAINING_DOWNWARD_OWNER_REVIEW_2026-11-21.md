# QA31BT — original signed remaining downward source-cell ownership

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Entry branch HEAD:** `a86180b2834853df0875f3df309f40bb72a778c2` (verified live before this QA)  
**Frozen original source Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Date:** 2026-11-21  
**Verdict:** QA31BT **LOCAL FINITE QA ACCEPTED**; **Stage1 OPEN**; **new Native=0; new CI=0**.

## Exactly bounded evidence and method

The prior exact-SHA archives QA31AI/BN/BO/BP/BQ/BR were downloaded from the existing `/Befunge_QA_Artifacts` Library location and each checked against the immutable SHA256 values in the runnable QA. All ZIP archives passed CRC verification; source cohort manifests passed per-file SHA256 and PROJECT_ID checks. Nested QA31AI archival Native shards supplied 200 historical HALT receipts / **3,628,390 original physical STEP** records. The **135 selected complete original signed compressed traces** were individually SHA256 validated, decompressed and checked for contiguous time stamps by the immutable original corpus loader. Four-way QA31BP/BQ/BR/Native trace SHA identity agreed for all 135.

The original source's 21-character vertical excerpt was **read directly from GitHub's exact immutable Git blob** on 2026-11-21 at x=1500,y=1860..1880, and cross-checked against independent literal ASCII-hex bytes. The exact originally loaded column is ` v7a*9+1a*7+a*1+a*0+g`; the eighteen newly checked cells (1500,1863)..(1500,1880) have respectively `a*9+1a*7+a*1+a*0+g`. The full ~1.8 MB source object was **not** locally rehashed; the narrow API blob reference and byte excerpt were verified, not its complete source file chain-of-custody.

## Concrete original-only findings

Both independently organized physical owner scans agreed on **135×18=2,430** cell-case checks. Oracle F constructs a chronological last-`p` write index of the original physical trace before its signed `(1500,1860)` code fetch. Oracle R searches the raw original trace backward separately for each individual target address, without reading Oracle F's index. Both apply Befunge-98's zero-underflow stack operands to `p`; the common signed trace decoder/loader is shared, so these are independent *owner algorithms*, not independent acquisition pipelines.

For **each of the eighteen original cells**, every original selected case had **zero physical `p` writes before that original fetch**, and **zero physical IP visits anywhere in its complete original trace**. Thus the frozen source byte is the effective original memory byte at that particular original fetch boundary. This extends the previous first-two-cell QA31BS check, but does not assert that a modified program would traverse the column.

The original signed anchor is unchanged: `(96,480)` executes `p` with stack suffix `[62,1500,1860]`; `(1500,1860)` executes `>` and moves to `(1501,1860)`. Nothing in this QA shows a genuine changed-run fetch of `v` or any executing instruction at `(1500,1861)..(1500,1880)`.

## Controls and their precise evidentiary meaning

- **24/24 genuine unchanged/no-numeric-effect controls** from historical signed QA31BN cases were matched to original trace SHA256 and identical input intervention `g`/output sinks; no new Native cases were manufactured.
- **54/54 detached hostile controls rejected**: 18 `p` target-address tamperings, 18 physical IP-visit tamperings, and 18 independent immutable-source-byte corruptions. Rejection means disagreement with source-pinned original baseline or source invariant, **not** rejection by a new Native execution.
- `python -m py_compile` PASS; complete six-input original archive audit PASS. See the machine-readable summary, per-case JSONL and hostile receipt JSONL in the bundled ZIP, with SHA256 manifest and local log.

## Critical limitations, remaining gates and NEXT

- The target cells' **original** pre-fetch p-writer and physical-visit findings are finite, over 135 selected original signed traces; they are **not** universal nonreachability proofs for all possible inputs or programs.
- **Actual changed-run path, fetched opcode, intermediate writers, address, stack, g read value, and Native output remain UNKNOWN.** The static characters under a counterfactual vertical move are not evidence of executing them.
- Full stage acceptance remains **OPEN**, including global FungeSpace ownership/independence and the required full functional and geometric gates. There was no production change, new CI/Native dispatch, merge, main change or Stage2 authorization.

**NEXT: QA31BU QA-only (authorized, Stage1 OPEN).** Study only *conditional static stack semantics* along original source `(1500,1861)..(1500,1881)` after a hypothetical vertical fetch, with explicit preconditions for unchanged source bytes, a specified initial stack and a bounded source step limit. Compare two independently written arithmetic/stack oracles, verify the exact original source byte at `(1500,1881)` by frozen Git blob and original physical writers, and use >=12 genuine original unchanged controls and >=12 detached hostile tests. Do **not** imply actual changed-run entry, execution or output. Do not run new Native/CI without a distinct evidence-backed hypothesis; leave protected branches and production unchanged.