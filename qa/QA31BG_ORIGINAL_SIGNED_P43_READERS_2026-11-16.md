# QA31BG — exact original signed p43 reader/branch extension (2026-11-16)

Project ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`  
QA branch: `qa-befunge98-stage1-order-isolation-20261008`  
Verified starting HEAD: `2917aab31268f03c120544a3d6a2b399edc2b597`  
Result: **FINITE ORIGINAL SIGNED AUDIT ACCEPTED LOCALLY; Stage1 still OPEN**.

## Scope and immutable evidence

Read only the original signed archives already preserved by QA31AI and QA31BC, not synthetic clones. Outer QA31AI SHA256: `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`; QA31BC SHA256: `2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77`. Each outer ZIP and each nested ZIP was CRC-verified; 200 compressed signed trace SHA256 values were checked against QA31BC's SHA-pinned case index. The original production source **Git blob ID** is `560d6aa5807a7f766213a33835cce85eab0fa40c`. No fresh independent source-byte reparse is claimed; executed opcodes were read from the authenticated original STEP records. No new Native runs or CI runs were performed.

Both auditors independently read 200 original HALT traces totaling 3,628,390 original STEP records, and selected the **same 225 physical second-hop** events `x(540,195)→(575,670)`; for each they audited exactly the next 1,024 signed STEPs. All 225 windows were complete: no early HALT. The primary auditor verified full original time/stack/IP continuity. The independent auditor verified on-window time/stack/IP continuity after streaming SHA-authenticated compressed traces. Neither used prior QA31BF derived per-witness result JSON as an input oracle.

## Physical owner/reader and branch outcomes

For all 225 windows exactly one `p(962,480)→(43,1702)` preceded exactly two `g(43,1702)` reads, at executed instruction positions `(958,1050)` and `(174,195)`. Physical backward last-writer search from the **complete signed original execution** identified that p as the exact last writer in **450/450** reads. A separately implemented forward per-window write journal independently confirmed **450/450**. No intervening write to `(43,1702)` was observed in those windows. The observed `g` values equaled that signed p value.

The first `g43` value was used in a later physical `p(860,99)→(53,1704)` for each window, but **simple value equality was not universal**: `p53 == g43` in 144/225 and `p53 != g43` in 81/225. The exact physical difference `p53 − g43` is 0 in 144 cases and each integer 1 through 9 in **9 cases each**. An initial equality assumption was rejected during local testing; the auditors explicitly account for these 81 legitimate different values.

Every window contained **26 physically observed `x` instructions** (5,850 signed `x` total), each checked against its signed pre-stack operands and next-IP; there were **zero** observed `j` instructions inside these finite windows. This is an observed branch-instruction count, not global reachability or proof that a counterfactual input preserves the entire executed program.

## Independent interpreter / conditional causal boundary

Oracle B reconstructs signed arithmetic, literals, `g` receipts, `p` address/value use and `x` stack operands from the exact opcode stream **without importing oracle A or QA31BF code**. Across 225 windows, the signed first `g43`→`p53` corridor replayed exactly; the p53 written value carries the first `g43` taint, while its one intervening `x` vector is untainted. With `g43` hypothetically set to 0 and 1 and **all other later `g` receipts held at the signed values**, the `p53` conditional value rises by exactly 1 in **225/225**, and the corridor's recorded `x` target remains unchanged in both hypothetical evaluations.

For the second physical `g43`, the independent interpreter continued to the 1,024-STEP boundary. Its three intervening `x` operands were untainted in **675/675** checks. Exactly one g43-dependent stack entry remained at the boundary per window (225/225), and symbolic end stacks for hypothetical values 0 versus 1 differ in **225/225**. This exposes an unclosed downstream value dependency, **not a demonstrated changed branch**. Oracle A and B agree on each of 225 signed physical witness identities, anchor timestamps/values, writer ownership, and the explicit hypothetical p53 calculation (225/225 cross-oracle comparisons).

Counterfactuals are **trace/source-conditional**, not physical observations of changed stdin or new Native executions. The preserved source blob ID is a provenance pin, not a claim of fresh source-byte independence. Algorithmic independence does **not** imply independent signed-trace provenance.

## Negative controls and executable proof

Oracle A rejected **18/18** deliberate, non-noop mutations of a real signed 1,024-step witness, including altered ticks, adjacency, stack receipts, p43 opcode/address/value, g43 addresses/values, p53 address/value, x operands/target, duplicate p43 and swapped steps. These checks target the acceptance predicate on corrupted records, not a cosmetic report field. Additional compilation and an independent 225/225 two-oracle reconciliation passed locally. No CI PASS, no fresh Native PASS and no global Stage1 PASS is claimed.

Reproduce using Python 3.10+ with only its standard library and the two exact frozen Library ZIPs:

```text
python stage1_qa31bg_signed_physical_audit.py QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip QA31BC_BEFUNGE98_KYRGYZ_ORIGINAL_SELECTOR_ROUTES_20261108.zip QA31BG_PHYSICAL.json
python stage1_qa31bg_independent_value_oracle.py QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip QA31BC_BEFUNGE98_KYRGYZ_ORIGINAL_SELECTOR_ROUTES_20261108.zip QA31BG_INDEPENDENT.json
python stage1_qa31bg_cross_oracle_check.py QA31BG_PHYSICAL.json QA31BG_INDEPENDENT.json
```

Permanent Library evidence: `/Befunge_QA_Artifacts/QA31BG_BEFUNGE98_KYRGYZ_SIGNED_P43_CONTINUATION_20261116.zip`, including code, two original-index-bound per-witness JSON results, standalone crosscheck, local logs, this report, and SHA256 member manifest. No production, `main`, merge, release, Stage2, or canonical text changes.

## NEXT — QA31BH proposed finite contract

Continue the **same 225 original signed x windows** from 1,024 to at most **1,536 physical STEPs** after the second `x`, or earlier HALT. Determine the first physical consumer or overwrite of the second `g(43,1702)`-tainted value still on the signed stack at the 1,024 boundary; classify any physical `p`, `g`, `x`, or `j` operands and changes within these 512 additional STEPs. Use two independent bounded provenance/stack algorithms, original SHA/CRC/compressed trace hashes, ≥12 effective hostile controls, and keep actual physical observations strictly separate from held-constant-receipt counterfactuals. If no such consumer is reached, report **UNKNOWN** beyond the bound rather than claiming absence. A fresh natural-stdin Native run remains conditional on independently verified ≤25,000 physical STEPs. Stage1 OPEN; no main/merge/Stage2.
