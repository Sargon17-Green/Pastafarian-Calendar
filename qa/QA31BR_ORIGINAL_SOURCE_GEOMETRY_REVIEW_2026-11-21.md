# QA31BR — original executable-code ownership and one-step source geometry

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified entry HEAD:** `6f24125a78acf2aa76d781a49d3228e1010f7140`  
**Date:** 2026-11-21  
**Verdict:** **LOCAL FINITE QA ACCEPTED; Stage1 OPEN; new Native=0, new CI=0.**

## Trusted original inputs and method

The frozen original Befunge-98 source was read *by exact Git blob* `560d6aa5807a7f766213a33835cce85eab0fa40c` through the connected GitHub API. Its original unmodified FungeSpace has ASCII space (32) at `(1500,1860)`; source `(1501,1860)` is `>`; `(1500,1861)` is `v`; `(1500,1862)` is `7`. The embedded local excerpt in the auditor is **not** a byte-for-byte local rehash of the entire original 1.8 MB Git blob. This limitation is explicit; the excerpt is pinned to the Git blob and cross-checked with original signed physical observations.

Five independent archived inputs were SHA256-checked, all ZIP CRCs/manifests checked: QA31AI `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`; QA31BN `6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79`; QA31BO `b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de`; QA31BP `d0b7487eb3bb257fb0a89adcb3f8157c8f41caffd0c35e1f80f4a13340ddeb24`; QA31BQ `23a587a58970031d56290399aed0db6f2df55a4107e322f6baa777fb054f1620`.

The original QA31AI nested signed archive covered **200/200 HALT receipts and 3,628,390 physical STEP records**; **135/135** selected signed original gzip traces were fully decompressed, SHA-checked, and checked for contiguous `t=1..N` by the existing original corpus loader. The QA31BP and QA31BQ case records were cross-checked against each selected original compressed-trace SHA.

Two owner evaluators were deliberately different: (1) a chronological map of observed `p` writes up to original code fetch; (2) an independent backward search for the last `p` of the fetched address without using the forward map. They agreed for **135/135**. Geometry was independently checked using both the pinned source coordinates and the original signed `next`/`next_delta` plus vector step calculation. The signed original writer at `(96,480)` executed `p` with `[62,1500,1860]`, its `post=[]`, and the subsequent single code fetch at `(1500,1860)` executed `>` with no stack items. Original `next=[1501,1860]`, `next_delta=[1,0]` and the following physical instruction is the source `>` at `(1501,1860)`.

## Conditional byte and first-step geometry (NOT a changed execution)

Under the **fixed original g→p stack/address and fetched-cell assumptions** already established by QA31BQ:

| Hypothetical g(19,1696) | Mathematical p value | If this byte is fetched at (1500,1860) | One-step successor | Original source at successor |
| ---: | ---: | --- | --- | --- |
| 0 (actual signed original) | 62 | `>` east | `(1501,1860)` | `>` (physically observed) |
| 1 (source-only hypothetical) | 118 | `v` south | `(1500,1861)` | `v` (not observed as altered run) |

The source at `(1500,1862)` is `7`, but this is **not** a valid assertion about subsequent changed-run execution. For the hypothetical `g=1` case, actual reachability, control path to this `p`, writer, address, `x` vector, fetched opcode, other FungeSpace writes, and Native outputs remain **UNKNOWN**. No altered code was executed. No output sensitivity is claimed.

**Controls:** 24/24 genuine prior no-op original-source records matched their unchanged original `g` and sinks; 20/20 detached hostile modifications were rejected (18 physical STEP corruptions at g/p/fetch/neighbor and 2 source-excerpt corruptions). These controls are synthetic checks of the QA auditor; they are NOT extra Native witnesses. After a first prototype control exposed missing `p` IP verification, an explicit exact `(96,480)` `p` IP and post-stack check was added. An unrelated premature copied counter was corrected to preserve the mutable cumulative original receipt counter until all shards had been consumed. Re-run completed without error. Python `py_compile` PASS.

## Acceptance boundary and next authorized QA step

The local finite QA31BR contract is satisfied: original SHA/CRC, 135 signed trace ownership checks through two evaluators, original-vs-conditional one-step geometry, at least 12 genuine no-ops and 12 hostile controls. **Neither Stage1 nor changed-run Native/differential nor global functional/geometric correctness has passed.**

**NEXT (QA-only):** inspect whether `(1500,1861)` and the first downward static source corridor have independent original signed `p` writers *before the target code fetch* in all 135 cases, using forward and reverse owner oracles; then characterize only the bounded static corridor under a hypothetical `v` fetch. Require ≥12 unchanged-input genuine no-op and ≥12 detached hostile controls. Do not claim modified-run reachability, output effect, or Stage1 PASS. Do not run new Native/CI without distinct evidence-based justification, do not touch `main`/protected branches, merge, or Stage2.