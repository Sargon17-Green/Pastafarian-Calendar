# QA31BP — original signed pre-first-sink writer to terminal-code boundary

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized QA branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified entry HEAD:** `e9857c49ebf4b3f1acb85ca33507cdb2ac30df7f`  
**Date:** 2026-11-20  
**Classification:** QA-only, finite original-signed trace audit. **Stage1 OPEN.** No fresh Native, no new CI, no production/main/merge/Stage2.

## Inputs and boundary

Source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. The original 200-case signed record is archived within QA31AI → QA31AH → QA31Y → eight QA31V shard ZIPs; original receipts total **200 HALT and 3,628,390 physical STEPs**. Each nested ZIP's SHA-256/CRC and original compressed trace SHA are checked, while 135 selected traces are fully decompressed and checked for contiguous STEP numbers.

Immutable inputs (SHA256):
- QA31AI `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`.
- QA31BN `6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79`.
- QA31BO `b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de`.

QA31BN's 446 changed numerical predictions are used **only to select the original 135 signed cases**; no substituted `g` value is represented as executed Native. Its 24 genuine no-op records are also checked.

## Physical evidence and two distinct checks

1. **Forward physical owner and conservative value taint:** On each signed physical trace, walk the `p` updates before the post-second-sink `g(19,1696)`, record the last physical owner, and then execute a constrained exact-stack provenance replay on the signed suffix. Every pre/post stack is compared to the signed event. Taint is conservatively propagated through arithmetic even if it is multiplied by zero.
2. **Reverse physical last writer and output/code slicing:** Search backwards from the `g` and the later instruction fetch to find their last physical `p` owners, independently of the forward owner map. Independently recognize each output's signed `0 1 - .` stack-reset window and ensure that its numerical value is a literal -1, not carried stack data.

Results on **135/135** selected original traces:

- Exactly one downstream `g` reads `(19,1696)` and returns `0`. The last preceding `p` wrote `0` **before the first sink**: 99 cases at STEP 11,135 and 36 at STEP 11,287. Forward and reverse last-writer scans agree.
- Its value flows into a `p` after the second sink. In **135/135** cases the physical `p` writes **62 (ASCII `>`)** into FungeSpace `(1500,1860)` and the provenance tag from that `g` reaches this `p`. The exact cell `(1500,1860)` is subsequently fetched as the `>` instruction, **before** the first terminal output. Independent backward code-writer scan agrees.
- **945/945** printed numbers are `-1` (seven per original case). The direct stack operand of each `.` comes from a checked literal `0 1 - .` window with empty stack at its start: 945/945 local output windows. Therefore **no direct stack-value dependency from this pre-first-sink `g` to `.`** exists on the recorded original route.
- Crucially, **an observed data-to-code/control dependency DOES exist**: pre-first-sink writer → downstream `g` → arithmetic → `p(1500,1860)` → subsequent instruction fetch at that very address → terminal output block. Thus the direct-stack negative must **never** be reported as full output independence. It is an original physical *structural path*, **not** a proof that changing the initial input changes terminal output.
- 24/24 genuine no-op controls pass; **16/16** detached hostile STEP mutations (physical writer, signed `g`, sink, reset, output, executable write/fetch) are rejected. These hostile copies are not original Native records.

## Unknowns and acceptance boundary

Only original signed instruction paths, stack states, memory `p/g` writes, and instruction fetches were observed. Changed input, source bytes, control transfer, `x` vector, memory addresses, instruction opcodes, or run-time writing to `(1500,1860)` may reroute an altered execution. **Those effects are UNKNOWN.** No global source reachability, complete functional and geometric QA gates, or Stage1 acceptance is claimed. The existing original Native run is neither rerun nor duplicated.

## Reproduction and persistence

The QA31BP evidence ZIP contains the self-contained Python 3.11+ auditor, this report, a precise RUN contract, 135 machine case records, 16 hostile-control records, aggregate summary, and SHA-256 manifest. The 46 MB original QA31AI archive and independent QA31BN/BO archives remain outside the evidence ZIP at their existing Library locations. Reproduction exits nonzero on any missing/mismatched SHA, invalid ZIP, altered source witness, changed stack/original output, missing tainted code fetch, or failed control.

**NEXT — QA31BQ (QA-only, Stage1 OPEN):** source-only independent arithmetic/counterfactual study of the `g(19,1696)` value-to-`p(1500,1860)` executable-byte and downstream `x`/code-fetch gate. Pin original 135 receipts and original source, classify which numerically varied `g` values would change the executable opcode under the **fixed original route**, distinguish conditional opcode predictions from actual reachable input and altered Native. Require two independently implemented evaluators, ≥12 no-op and ≥12 hostile controls, and stop at UNKNOWN on any changed route, address, writer, or instruction fetch. Do not launch Native/CI or touch protected branches without separate evidence-based justification.