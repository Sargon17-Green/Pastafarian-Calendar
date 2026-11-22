# QA31CC — Original-source stack-origin reconstruction from four archived Native traces

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Original production file:** `src/interleaved_work_counts.b98`, immutable Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Preceding executed SHA:** `faf93de8d27ec112c7c57d6fbfe193c3475a4187`  
**Native run:** [44996727508](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44996727508), completed/success, job `137129240977`; **existing artifact:** `14745206712`.  
**Downloaded artifact SHA-256:** `ea247b7c907d9cd0e1fb8e211619ff538b99b435dd43bcdaef70f084f6e499be`.

## Scope and procedure

No new Native run, CI run, production change, branch merge, or Stage gate acceptance. A new independent Python 3 offline auditor (does not import the original Native runner or QA31CB auditor) consumed the **already accepted QA31CB ZIP** and verified all 13 member CRCs and all 12 manifest hashes. It decompressed the four *retained* full physical Native traces for `1 0 0 N`, `N∈{100,199,500,999}`: **4/4**, totaling **99,412 physically read STEP rows**. Each compressed trace was matched to its individual receipt SHA-256, terminated at HALT, and the relevant event ticks and pre/post stacks were checked independently. The auditor rejects **16/16 distinct hostile mutations** (stdin, stack, physical addresses, owner values, RPN opcode and dynamically executed byte). The complete original production Git blob was also read from GitHub and matched to its Git blob SHA; the original source remains unchanged. This analysis is limited to the four retained physical traces and does not claim the 896 nonretained full traces were rewalked offline.

## Proven observed data-flow on these four original Native traces

| Native tick | Actual original-source IP/opcode | Observed physical stack/storage event |
| --- | --- | --- |
| 292 / 9598 | `(13,5)` / `~` | First `readline` consumes the literal stdin bytes, second `readline` observes EOF |
| 10579 | `(4,0)` / `>` | Before next dispatch the actual TOSS stack is exactly `[1,0,0,N]` |
| 10614 | `(384,575)` / `p` | Last stdin operand `N` is popped and written to FungeSpace `(11,1693)` |
| 10629 | `(369,575)` / `p` | Third operand `0` is popped and written to `(7,1692)` |
| 10664 | `(860,846)` / `p` | **Second stdin operand `0`** is popped and written to `(5,1691)` |
| 10900 | `(100,1057)` / `g` | The value at `(5,1691)` is read as `0`; stack after `g` is `[1,1,0]` |
| 10901–10904 | `(100,1058..1061)` / `! * ! *` | On `[a,u,b]=[1,1,0]`, the original opcode sequence produces `a * !(u * !b) = 0` (where `!` is logical NOT) |
| 11135 | `(1332,480)` / `p` | The resulting `0` is physically written to the owner cell `(19,1696)` |
| 24722 | `(677,765)` / `g` | The same owner cell `(19,1696)` is read back as `0` |
| 24723–24732 | `(678..687,765)` | Ten physically executed RPN opcodes `78**6a*2++` transform owner value `g` into `56*g+62` = `62` |
| 24795 | `(96,480)` / `p` | Value `62` is physically written to code cell `(1500,1860)` |
| 24823 | `(1500,1860)` | Instruction fetch actually reads byte 62 (`>`); trace subsequently HALTs |

All the above are **observations of four unmodified Native cases**, not input counterfactuals. Original-source FungeSpace storage offsets in this chain are `[0,0]`.

## Newly derived falsifiable candidate (not an observed Native result)

At the observed `g`/`! * ! *` gate, with unchanged route and intermediate stack prefix `[a,u] = [1,1]`, the owner equals:

```
owner = a * (NOT(u * NOT(b)))
      = 1 * (NOT(1 * NOT(b)))
      = (b != 0)
```

This yields the **source-guided candidate natural stdin `1 1 0 100`**. If the source follows the same earlier parsing, target write and gate route for this *different* input, then `b=1` would give `p(5,1691)=1 → g(5,1691)=1 → p(19,1696)=1 → g(19,1696)=1 → p(1500,1860)=118`, i.e. a dynamic `v` opcode instead of `>`. **No original Native evidence yet establishes preservation of that route, any positive owner, or a fetched opcode 118.** The new candidate can fail earlier parsing, validation or control flow; these outcomes are not equivalent to a positive witness or to global nonreachability.

## NEXT — narrowly scoped, genuinely new Native validation

1. Verify current authorized branch HEAD; pin original production Git blob and PyFunge 0.5-rc2 TAR `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac` and immutable source coordinates. Do not rerun accepted `1 0 0 100..999` corpus.
2. Execute only **new natural ASCII stdin strings** `1 1 0 100` and `1 1 0 999` (zero trailing newline, as in original corpus), with distinct fresh original-source PyFunge programs, original entry IP, 50,000 physical STEP cap, explicit `HALT`, `STEP_LIMIT`, `MULTI_IP`, `RUNTIME_ERROR` statuses. These inputs are deliberately outside the accepted 900-case corpus. Compare to previously archived `1 0 0 100/999` physical traces rather than launching redundant controls.
3. Independent auditor must rederive stdin read positions, complete STEP continuity, `p`/`g` target from pre-TOSS and offset, chain `(5,1691)→(19,1696)→(1500,1860)`, and the *actually fetched* code byte. Require source/toolchain/run SHA, ZIP SHA/CRC, manifest and detached hostile mutations. Report branch divergence, invalid inputs, premature HALT or bounds *without* calling them a witness.
4. **Witness gate** for a given input: physically observed original nonzero owner `g(19,1696)`, ordered prior owner `p`, consequent actual dynamic code `p(1500,1860)=56*g+62`, and later physical fetch of that byte. Even this would establish only bounded Native reachability; it does **not** certify all Stage 1 functional/geometric/ownership gates.

**Gate labels:** original QA31CB finite Native+CI accepted; QA31CC four-trace offline stack-origin auditor **PASS** (16/16 hostile); QA31CC new Native `NOT_RUN`; differential on new candidate `NOT_RUN`; Stage 1 `OPEN / NOT ACCEPTED`, no main/merge/Stage2.

**Standalone reproducibility:** `qa31cc_offline_stack_lineage_audit.py` (Python 3 stdlib, accepts existing ZIP path and output JSON) produced `QA31CC_offline_original_stack_lineage_results_2026-11-22.json`. File SHA-256: script `48e6507a6015a84c8364d1e2b89d03e04dc5bfe64ee2efc0c89c96d605e80e6a`; JSON `4edafabeb03633f8456c13e27f86df9cda964a568a221c888978f0ab313841d2`. These files are available as independent reproducibility attachments to this review; unless committed separately, they must not be represented as files already stored in GitHub.