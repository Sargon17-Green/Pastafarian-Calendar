# QA31S — original PyFunge Native finite frontier matrix (planned gate)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ; branch qa-befunge98-stage1-order-isolation-20261008.
This is a **QA31S implementation**, not evidence of completed Native execution or Stage 1 PASS.

## Verified precursor

Parent branch HEAD: b111f5f7980c427eccea16bc7f24318e976460f2.
QA31R signed finite original evidence: three row-29/32/35→38 ingress transitions on raw b'1'; 12 of 15 QA20-unseen controls witnessed, with (286,5), (235,23), (235,32) remaining unwitnessed in that finite case. QA31R does not prove global unreachability or ownership.
All 23 parent-HEAD workflows have completed: 22 success, QA09 80-opcode workflow run 41525895742 failure due to bounded timeout (exit 124); Stage 1 Native Regression 41525895752 completed/success. QA09's failure is separate and is **not** presented as Stage 1 PASS.

## Contract

- Original untouched source: src/interleaved_work_counts.b98; pin Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c; original IP and original source Funge-Space, no input/source/IP injection.
- Exactly twelve raw stdin candidate octet strings in the runner, in declared order: b'1\n', b'1 0\n', b'1 0 0\n', b'1 0 0 0\n', b'1 0 0 0 0\n', b'1\t0\t0\n', b'1\t0\t0\t0\n', b'100\n', b'1000\n', b'111\n', b'1111\n', b'1 0 0 0' (without LF).
- Per case at most 25,000 physical Native STEPs, total at most 300,000; process timeout 840 seconds, job timeout 20 minutes. Record HALT, STEP_LIMIT or RUNTIME_ERROR as observed; no invented HALT or expected-red classification.
- Every case: original exact stdin bytes and SHA256; all observed readline/read offsets and true EOF (empty slice) with source IP/tick; input read count; full signed IP/stack/p/g/j/x event gzip, SHA256 and step count; output and status. Audit the entire physical trace using independent initial source-byte+previous-p memory replay and IP continuity.
- Report actual row29 (3,49)=m, row32/38 (1,49)=q and their last writers where physically read; row29/32/38 j operands, ingress x edges, actual physical visits at (286,5),(235,23),(235,32). Candidate values are **not** expected observations.
- Independent auditor checks original Git blob and 2015 splitline source rows, receipt/bytes/hash integrity, per-step time, IP and delta continuity, native opcode versus initial source plus previous p writes, p stack semantics, g value semantics, stdin bytes/EOF and physical control events. It must reject 18/18 intentionally forged receipts/trace events.
- Output: qa31s_receipt.json, twelve compressed Native traces, qa31s_independent.json, native.log, audit.log. CI artifact is finite evidence only. Report explicitly whether any candidate witnessed m=1 and q>=3 and which of the three frontier cells were actually visited. A finite miss never certifies unreachability.
- Accept QA31S only on exact-SHA completed/success with full receipts and independent artifact review. The runner/auditor code being committed, or the CI being queued/in_progress, is not acceptance.
- Keep Stage1 OPEN. No Stage2, main, merge, functional or geometric PASS from this experiment.

## NEXT

Review completed exact-HEAD QA31S logs/artifact/CRC/SHA. If Native or independent auditor fails, investigate actual exception or falsified assumption, repair only QA31S in this branch, and rerun on the repair SHA. If accepted, use observed finite frontier/gate data to specify the next bounded stage; independently handle QA09 timeout as a separate outstanding QA09 issue.
