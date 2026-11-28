# QA31CF — one new original-source b=2 discriminator (pre-registered)
  
PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`  
AUTHORIZED_BRANCH: `qa-befunge98-stage1-order-isolation-20261008`  
STAGE: **Stage 1 remains OPEN; this is a finite QA-only experiment, not acceptance.**  
Production source: `src/interleaved_work_counts.b98`, immutable Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.  
Runtime: PyFunge 0.5-rc2 archive SHA256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`.  

## Prior independently accepted, **not rerun**
- QA31CB: run 44996727508, job 137129240977, artifact 14745206712, exact executed SHA faf93de8d27ec112c7c57d6fbfe193c3475a4187, full original `1 0 0 100` / `1 0 0 999` traces already retained. 
- QA31CD: run 45074971716, job 137370082535, artifact 14775400606, exact SHA a2d48db290896ae6a49c280b2084148881617d40, two `1 1 0 N` traces previously accepted.
- QA31CE: offline finite 4-trace comparison, 99,660 physically logged STEP records, no new CI/Native. At fixed N, input b=0 vs b=1 first diverges in opcode at tick 24,823; observed gate prefix `[1,1,b]`; observed owner `0/1`, dynamic fetched op `62/118`. It does **not** establish the b=2 route.

## Frozen input and decision, before any Native execution
- Execute **exactly one new natural input**, raw ASCII `1 2 0 100`, bytes `31 20 32 20 30 20 31 30 30`, **no LF**, length 9, SHA256 `1699e3d66b01f2d43c0658c479d43e15006255927be082816ed7610a38c70f83`.
- A fresh PyFunge program loads only the pinned, unchanged production source, starts at original IP, and reads the raw 9-byte stdin unmodified. No synthetic FungeSpace writes, injected IP, source patch, or fixture from a different branch.
- Termination categories are `HALT`, `STEP_LIMIT`, `MULTI_IP`, and `RUNTIME_ERROR`; cap **50,000 physical STEP** records. Non-HALT statuses are recorded with reason and are **not** a Native functional PASS. A failure in any audited evidence invariant is an **audit failure** and not acceptance.
- Output artifact must retain complete compressed physical JSONL, original stdin events and consumed byte offsets, IP/op/delta/next-IP, full TOSS pre/post, storage offsets, every physical p/g target/value, dynamic fetch events, stdout delta, exact SHA256 for input/trace/files, immutable source metadata, run/job/commit, and CRC-verifiable ZIP manifest. No summary-only substitute.

## Conditional, falsifiable source-derived oracle
First inspect the actual original parser/ingress: has it physically formed `[1,2,0,100]` at the known parsed-argument point? Did it physically store 2 with `p(5,1691)`, read 2 with `g(5,1691)`, and reach the same gate with **observed** `[a,u,b]=[1,1,2]`? These are **conditions to check, not expected evidence already obtained**.

If that chain holds, actual four instructions `! * ! *` must produce
`a * NOT(u * NOT(b)) = 1 * NOT(1 * NOT(2)) = 1`, where `NOT(0)=1` and `NOT(x!=0)=0`.
Then require actual `p(19,1696)=1` followed by actual `g(19,1696)=1`; and real `p(1500,1860)=56*1+62=118`, **subsequently executed** `fetch(1500,1860)=118 ('v')`, with no intervening code-cell write. Instruction, stacks, p/g effective address via storage offset, and bytes must all be tied to this **new** original trace.

This differentiates `b!=0` from the competing special-case rule `b==1`. The gate relation is arithmetic, **conditional on the physical parser and route**. A parser rejection, an earlier branch, a changed stack prefix, omitted owner/code fetch, or earlier HALT is separately classified. It is not a global counterexample, and no positive predicted result can be called Native PASS without physical evidence.

## Independent auditor and adverse controls
- Native instrumentation: `qa/qa31cf_nonzero_discriminator_native.py` (Python 2 original PyFunge runtime).
- Separate witness auditor: `qa/qa31cf_independent_native_audit.py` (Python 3); it does not import the Native runner. It checks source geometry, exact 9 raw bytes, file/trace hashes, all STEP records, parser stack prefix, all p/g stack/address/value transitions, physical owner and generated-code chain, last write before fetch, and stdout.
- Twenty detached hostile controls from the established same-branch QA framework (source flags, tampered input/hash, receipt, trace, p/g/owner/code/fetch summary, stdout, step and storage-offset corruption) must each be **rejected** by the independent integrity validator; this does **not** equate to a proof of completeness or independence for arbitrary adversaries.
- Source-guided result classification: `BOUNDED_NATURAL_WITNESS`, `FINITE_NEGATIVE_FOR_INPUT`, `EARLY_DIVERGENCE_OR_REJECTION`, `NONZERO_OWNER_INCOMPLETE_CODE_FETCH`, `PARTIAL_OR_DIFFERENT_ROUTE`, or explicit non-HALT status. `evidence_integrity=PASS` is necessary but does not imply the expected nonzero witness.

## Gates and restrictions
A new GitHub Actions run is relevant only if triggered on the **new QA31CF files**, completed, job/log/source SHA verified, and the actual retained artifact independently reviewed with SHA256, ZIP CRC and member manifest. A queued/in-progress run is neither PASS nor blocker. Do not rerun QA31CB's 900 cases or QA31CD's two accepted original cases. No production change, merge, main/protected-branch change, Stage 2, or global Stage 1 acceptance.

Pre-registration is a **code/contract change**; compilation/CI, Native trace generation, differential comparison to the historical b=0/b=1 witnesses, and Stage1 acceptance are separately reported.
