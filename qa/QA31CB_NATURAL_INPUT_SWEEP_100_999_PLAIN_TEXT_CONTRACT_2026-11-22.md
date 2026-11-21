# QA31CB — 900 ordinary three-digit stdin inputs, plain-text QA source

**Project:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Production source Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Runtime:** PyFunge 0.5-rc2, SHA-256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`

## Recovery decision

The old binary `qa/QA31CB_CODE.tar.gz` is retained as historical failure evidence only. Its bytes pass the pinned SHA-256 but its gzip stream is corrupt; it is no longer an input to the workflow. This replacement keeps the runner, independent auditor and source-cell metadata as ordinary reviewable text files. No source or production file is modified.

## Measurable execution contract

- **Input corpus:** exactly 900 byte strings `b"1 0 0 " + ASCII(n)`, for integers 100 through 999 inclusive, three decimal digits, no newline.
- **Isolation:** one fresh PyFunge Native `Program` instance per input; one input per process state; original entry IP; no concurrent IP accepted as HALT.
- **Source:** exact original Git blob above, verified before each run; no source, IP, stack, FungeSpace or storage-offset intervention.
- **Runtime cap:** 50,000 attempted Native STEP instructions per input. HALT, STEP_LIMIT, MULTI_IP and RUNTIME_ERROR are distinct statuses.
- **Trace:** one gzip JSONL physical STEP trace per case, with consecutive tick number, IP, delta, fetched opcode, string mode, pre/post TOSS, storage offset, actual stdin read events, stdout byte deltas, every executed p/g physical address and before/after cell value, and every fetch at `[1500,1860]`.
- **Source-cell metadata:** zero-based coordinates `[19,1696]` (empty source row; initial FungeSpace blank value 32) and `[1500,1860]` (source blank, byte 32; adjacent `[1501,1860]` is `>`, byte 62). The independent auditor re-derives these facts from the pinned source.
- **Independent oracle:** a separate Python 3 auditor imports none of the Native runner or its helpers. It rehashes the source and each compressed trace; reconstructs input bytes consumed and stdout bytes emitted; checks complete STEP continuity; recomputes each p/g target from pre-TOSS and storage offset; verifies p writes and g reads against physical cell receipts; cross-checks all owner-cell/code-cell events and every instruction fetch at the dynamic code cell; evaluates `code_value = 56*g_value + 62` only when the observed chain exists.
- **Evidence:** 900 unique receipts and per-trace SHA-256 values; full traces remain available to the independent auditor in the job's temporary workspace. Artifact retains cases 100, 199, 500, 999 and every non-HALT or evidence anomaly trace, plus case/audit JSONL, aggregate report, hostile results and file manifest.
- **Adversarial checks:** 20 detached receipt/trace mutations must all be rejected by the independent validator.

## Interpretation

- Natural reachability for an input is established only if an unmodified Native run physically reads owner cell `[19,1696]` as 1, writes 118 to `[1500,1860]`, and later physically fetches opcode 118 there.
- A matching 0 → 62 → fetch-62 chain is a finite negative result for that input only.
- Missing owner/write/fetch observations are classified as route divergence, not as a failed execution.
- Non-HALT statuses are retained and reported separately; they are never counted as HALT.
- Even a positive case is finite Native evidence, not full Stage1 acceptance. The aggregate explicitly retains `stage1_accepted=false`.

## Scope boundary

This is QA-only. No merge, main update, protected-branch change, Stage1/Stage2 policy change, release or publication is authorized.
