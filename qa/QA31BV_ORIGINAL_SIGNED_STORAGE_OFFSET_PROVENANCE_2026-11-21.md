# QA31BV — original signed storage-offset provenance

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified branch HEAD at task entry:** `6de731142364f6a4aed29fe197a6f571563877c2`  
**Original source blob recorded in signed Native receipts:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Disposition:** **QA31BV LOCAL FINITE PASS, QA-only. Stage1 OPEN.** No new native or CI runs.

## Input contract and source locks

All five archives are re-read from the existing `/Befunge_QA_Artifacts` Library folder. The primary QA31AI ZIP contains immutable nested QA31AH and QA31Y evidence archives. The audit checks the fixed SHA-256 values for all seven archives, checks ZIP CRC, checks embedded project manifests, and checks all eight original QA31V shard ZIPs against their signed manifest values. Every original per-case compressed trace is independently checked against `trace_sha256`, its native receipt, HALT status, exact STEP count, contiguous `t=1..N`, and physical `next`→following `ip` continuity. A terminal HALT with `next=null` is legitimate. No original archive is modified or duplicated into this package.

## Storage-offset contract

With the standard Funge-98 initial SO=(0,0), an executed `{` saves the previous SO and sets SO to the position immediately after that instruction, while an executed `}` restores the saved SO. Ordinary `g` and `p` use coordinates relative to SO; `u` does not independently change SO. The assessment is limited to **physically recorded executed instructions**, not all bytes in source space or hypothetical future execution.

- Independent oracle F reads chronological physical STEP records and maintains an SO stack.
- Independent oracle R scans an isolated ledger of `{`/`}` events **backward** from each site to reconstruct the unmatched active block without consulting F's saved state.
- Four detached synthetic brace-nesting fixtures independently test the agreement under nonzero and restored SO. They are mathematical controls, **not** signed original Native runs.
- If a required SO-changing event were unobservable or the recorded trace were incomplete, the offset claim would be **UNKNOWN**, not inferred from a source excerpt.

## Measured original signed results

| Signed original check | Measured result |
| --- | ---: |
| HALT receipts | 200 / 200 |
| Physical STEP records | 3,628,390 |
| Original executed `{` and `}` events | 0 |
| Original observed `p` sites | 14,820 |
| Original observed `g` sites | 27,395 |
| Original observed fetches of (1500,1860) | 140 |
| Original observed fetches of (1500,1881) | 0 |
| Chronological-vs-reverse SO agreements across all recorded p/g and selected fetch sites | 42,355 / 42,355 |
| SO at all **observed** audited sites | (0,0) |
| Distinct unmodified original signed cases additionally rechecked | 12 |
| Genuine original no-numeric-effect BN rows (6 signed original case identities) | 24 / 24 |
| Detached hostile receipt/trace/source corruption attempts rejected | 16 / 16 |

**Conclusion:** In the recorded *original* Native paths, no SO-changing instruction executed. Consequently, for the physically observed `g` and `p` sites, Funge-98-relative addresses equal absolute addresses under the standard zero-origin execution model. This cannot be extended to an **unvisited** site: the SO of an unvisited hypothetical fetch is **UNKNOWN**. The original 140 fetches of (1500,1860) are evidence only for that original site, not for altered-run entry, y1881, or a changed instruction stream. The bounded Git source row was previously inspected in QA31BU; the entire ~1.8MB original source Git blob was **not newly fetched and rehashed** by QA31BV.

The intact original receipt, trace and nested SHA checks are distinct from the detached hostile controls. The latter intentionally change copies of signatures, receipts, output fields and compressed payloads. They are not forged original native-run outputs. The 12 distinct untouched signed cases and the 24 genuine BN control rows constitute positive unchanged-original controls.

## Unresolved global gates / next work

**No Stage1 acceptance**: a changed-run IP route, altered FungeSpace, actual modified `p` writers, SO transitions, source-byte provenance, effective `g` address, result stack and real Native output are **UNKNOWN**. Nothing here demonstrates FULL_FUNCTIONAL_QA_PASS or GEOMETRIC_SPAGHETTI_QA_PASS. No main, merge, protected branch, production code, Native rerun or Stage2 change was made.

**NEXT QA31BW, QA-only:** using the now verified original SO=(0,0) at actually visited `p/g` sites, independently compute each signed original effective p/g coordinate from recorded pre-stack operands (with Funge-98 underflow semantics), reconstruct last physically observed p-writer at the selected original g/fetch sites, compare forward writer history against a separate reverse-site oracle, preserve immutable source and receipt SHA links, and mark not-observed provenance UNKNOWN. Include at least 12 untouched signed original controls and at least 12 detached corruptions. Do not conflate verified original addressing with modified-run reachability, and do not dispatch new Native/CI without an evidence-backed independent hypothesis.
