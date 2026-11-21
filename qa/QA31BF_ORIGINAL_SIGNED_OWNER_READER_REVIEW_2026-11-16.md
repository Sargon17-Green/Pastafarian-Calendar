# QA31BF — original signed owner→reader causal proof (2026-11-16)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`. QA branch: `qa-befunge98-stage1-order-isolation-20261008`. Initial verified HEAD `d19f16d8fa5013db70fe0d6d122cf67ac6f115b7`; this is a finite read-only QA review, **not** a global Stage1 PASS.

## Authentic original inputs and bounded execution

Original QA31AI 200-case ZIP SHA256 `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`; QA31BC separately saved per-case signed trace SHA index ZIP SHA256 `2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77`; original source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. SHA256 of both outer archives, nested ZIP CRC, all 200 original trace digests and all 3,628,390 contiguous physical STEP records verified. The GitHub connector returned the original source's blob identity but not its entire bytes in this cycle. Therefore **no fresh source-byte-independent RPN replay** is claimed. New Native runs: **0**.

From the original second-hop `x(540,195)→(575,670)`, 225 vertically selected windows of 256 original signed STEPs contain in strict chronological order, once each per window:

- `p(1249,1050)→(37,1700)`, writes 0.
- `g(100,656)`, reads `(29,1698)`, last writer independently identified by full reverse physical scan and forward physical-write/bisect index.
- `g(271,670)`, reads `(17,1695)`, always 1.
- `p(405,860)→(41,1701)`, value verified through symbolic stack-opcode re-execution with g29-origin taint; address is untainted.
- `g(575,1164)`, reads `(37,1700)` = 0 with last writer exactly the p above.

Across all 225 windows the physically verified bounded formula is
`p(41,1701).value = (g(29,1698).value % 10) * g(17,1695).value = g(29,1698).value % 10`.
Hence equality holds 135/225 times and differs 90/225: an expected remainder effect, not an error. The physical last writer of `(29,1698)` was `p(280,860)` 135 times and `p(399,195)` 90 times. Every physical g29 and g37 owner agreed across two independent owner-search implementations.

A separate authenticated **512-STEP** extension on the same 225 original x windows establishes two downstream `g(41,1701)` reads, at `(749,290)` and `(467,195)`, per window. All **450/450** returned the value written by `p(405,860)` as their exact last physical writer. The first read's value is symbolically carried to subsequent `p(962,480)→(43,1702)`; values at that p equal g41 in 135 windows and differ in 90. A source/trace-conditional evaluation replacing the g41 value by 0 versus 1 (while holding other signed g receipts fixed) changes this later p's value in **225/225** modeled cases. This is a **counterfactual**, not new signed Native evidence. Intermediate `x(719,290)` always has untainted vector `(-239,1235)` landing `(480,1525)`; **no direct branch effect at that x** was established.

Independent algorithm classes: (A) full physical signed time reversal versus forward writer-index oracle, (B) bounded stack/opcode interpreter and taint/counterfactual evaluator. Both ultimately consume the same signed original traces; this is algorithmic independence, not independent provenance. **16/16** deliberate non-noop physical STEP corruptions (opcode, stack, jump, writer and chronology) rejected by the primary acceptance predicate. A preliminary claim that p43 always equals g41 was actually falsified by 90 original events and was explicitly **discarded**.

## Permanent full reproducible evidence

Library: `/Befunge_QA_Artifacts/QA31BF_BEFUNGE98_KYRGYZ_ORIGINAL_SIGNED_CAUSALITY_20261116.zip`.

Evidence ZIP SHA256: `13e713c066857dd6af4c6107ebb3bde860a57a5759331a3379b6efd59bc297ca`; member CRC **8/8**, manifest member SHA256 **7/7**. Includes both executable independent QA scripts, per-witness original trace SHA-bound JSON outputs, local run logs, detailed report and manifest. Also saved standalone report `/Befunge_QA_Artifacts/QA31BF_ORIGINAL_SIGNED_OWNER_READER_REVIEW_2026-11-16.md`. Native NEW = 0. No source-only CI for this *new* artifact is claimed, and **no Stage1/global acceptance** is claimed.

Open: unseen inputs, alternate ingress, all 57 p-site dynamic target reachability, global functional/geometric completeness, and branch effects beyond this finite window. No production/main/merge/Stage2 changes.

## NEXT — QA31BG measured contract

Starting from exact signed SHA-pinned original QA31AI+QA31BC archives and verified current branch HEAD, independently audit only the same 225 vertical continuations up to **1024 original STEPs** after second x or earlier HALT. Track `p(43,1702)` last writers/readers and downstream `x`/`j` branch operand taint; independently derive physical and source-conditional counterfactual decisions, with **≥12** deliberate non-noop hostile controls. Preserve per-case compressed trace SHA linkage and strict original/conditional/unseen-input separation. Do not infer a natural stdin Native witness unless separately verified within 25,000 STEPs; no Stage2, main/merge, release or global Stage1 PASS.
