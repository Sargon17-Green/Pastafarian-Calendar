# QA31AI — 29-case physical input owners and 200-case signed q-gate extension (2026-11-06)

Project: `PC-BRANCH-BEFUNGE98-KYRGYZ` / Befunge-98+Кыргызча. Existing QA branch: `qa-befunge98-stage1-order-isolation-20261008`. Verified starting HEAD `63e5ea67ab6ebbc82f6ca2fd47dcf7ab21cce02d`.

**QA-only finite evidence review:** production code untouched. No new Native run, no main/merge/Stage2, and no Stage1/global PASS.

## Input pinning and independent reproduction

- Frozen QA31AH standalone archive SHA256: `4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271`. Nested frozen QA31Y SHA256: `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`.
- 8/8 original historical QA31V shard SHA256/ZIP CRC checks; raw stdin, HALT receipts, gzip STEP SHA256, exact tick continuity and next→IP checks on **200/200 original signed Native traces, 3,628,390 STEPs**. These are rechecked historical receipts, not new Native.
- 29-case independent owner verifier: 29/29 original traces, 510,835 STEPs; 261 raw-byte→`~(13,5)`→`p(60,5)`(0,49) physical chains (exact +47 STEP distance), 522 matching row8 `g` reads, 20 EOF reads, 53 original readline receipts, 11/11 synthetic negative invariant checks rejected. The negative checks are **not** original-source Native perturbations.
- 29-case row23 `q` now independently extracted from original signed physical `g(57,23)` (the missing read site in the previous QA31AH table). `q23` counts: 0:29, 1:29, 2:29, 3:13. `q32`: 3:13. Original `p` last writers and jump displacement independently checked.

## Targeted 200-case gate extension

Only unresolved row23/row32 `q>3` gates and corresponding m routes were expanded across all 200 frozen cases:

| Original site | Events | Values |
|---|---:|---|
| `j(89,20)` / `m` | 680 | `m=1`: 680 |
| `j(113,23)` / `q` | 680 | `q=0`: 200; `q=1`: 200; `q=2`: 200; `q=3`: 80 |
| `j(89,29)` / `m` | 140 | `m=1`: 100; `m=0`: 40 |
| `j(113,32)` / `q` | 100 | `q=3`: 100 |

Thus **zero of 780 observed row23/row32 gate encounters had `q>3`**, and there is no natural `m=1 AND q>3` witness in the **frozen 200-case corpus**. This is finite evidence only; no proof of global unreachability or complete stdin ownership.

## Complete reusable delivery

Persistent ChatGPT Library file:
`/Befunge_QA_Artifacts/QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip`

ZIP SHA256: `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`. 46,470,983 bytes; 12 ZIP members, ZIP CRC PASS; 11/11 member SHA256 manifest checks PASS. Includes the complete original QA31AH evidence ZIP, two complete stdlib Python 3.10+ verification scripts, Windows `RUN_QA31AI.cmd`, original-case gate CSV, 200-case gate CSV, both JSON summaries and original local logs.

This result changes the **research evidence** only; `Stage1` remains **OPEN**, including global reachability and functional/geometric acceptance.

**Next QA31AJ:** source-pin exact alternate ingress/loop boundary at `p(248,26)` and row20→23 / row29→32, seeking a feasible original-source transition from `q=3` to `q>=4` with `m=1` before the gate. Design finite state/stack oracle and independent adversarial checks. No new Native unless a concrete natural-input candidate is derived; any new Native must be ≤25,000 STEP/case and independently audited.