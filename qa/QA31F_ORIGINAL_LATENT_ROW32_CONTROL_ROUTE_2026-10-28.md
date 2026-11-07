# QA31F — original-source conditional route to unobserved (10,32) (2026-10-28)

Project **PC-BRANCH-BEFUNGE98-KYRGYZ**. This is a **Stage 1-only, read-only offline** analysis of previous genuine Native evidence and the unchanged original Befunge-98 source, **not a new Native run, Stage 1 PASS, or a proven naturally reachable new input**.

## Pinned evidence, independently checked

- Original immutable \`src/interleaved_work_counts.b98\` Git blob: \`560d6aa5807a7f766213a33835cce85eab0fa40c\`, directly read as GitHub blob. No production-source edit.
- QA31A original Native artifact ID `12634011438` (the associated run URL was not independently established) (the artifact ID, not this run URL, is the pinned object): ZIP SHA-256 \`235be0d04cc2f6ab113b3a809c3a2ef93513c07cb2233b2b8b457722d409a4cd\`; extracted JSON SHA-256 \`39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c\`. ZIP CRC verified. Its original aggregate covers 136 original programs, 4,513,423 signed STEP records; all 15 original source candidates remain unvisited. For (10,32), exactly five distinct near-control prestates within L1=9 and **zero** different-input successor outcomes among them.
- Original QA20 [run 39761821210](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210), four artifacts 12417714729 / 12418676466 / 12418536785 / 12417633980. Exact ZIP SHA-256 respectively: \`0487e7b6c65134a69d6ac7b313d332e6cb5c966b9fea0124ae60a28d45f11076\`, \`0d39bebd0e2b28976f77a38f8f1c0113ec8ad5d2de08f53415179277135bf5ea\`, \`d511c5cbde86b850224851d27ddc994e5689019c0af93aea9d5c5df92f33f16c\`, \`d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07\`. All four downloaded ZIP SHA, CRC, manifest source blob, per-case compressed STEP SHA and sequential decompressed STEP records checked in this continuation.
- Reproducible scoped checker: [\`qa/stage1_qa31f_original_latent_row32_audit.py\`](../qa/stage1_qa31f_original_latent_row32_audit.py). Its first proof component was exercised locally on the four pinned QA20 ZIPs and QA31A ZIP; the source-blob check is specified in the committed checker, and the source geometry was separately evaluated against the GitHub original blob. No fresh Native execution or claim of a new CI PASS.

## New static original-source geometric fact

The original **row y=29**, with normal Befunge-98 stack arithmetic and unshifted storage coordinates:

1. \`(10..56,29)\` constructs \`x=3,y=49\`; the actual \`g\` at \`(57,29)\` reads \`m=FungeSpace(3,49)\`.
2. \`(58..88,29)\` constructs \`61\` and multiplies \`61*m\`; \`j\` is at \`(89,29)\`. Given incoming direction \`(1,0)\`, its next executed x-coordinate is \`90+61*m\`.
3. **For m=0**: next instruction is at \`(90,29)\`. The arithmetic-only builder \`(90..149,29)\` constructs the vector \`(-140,+9)\`; \`x\` at \`(150,29)\` transfers the IP to \`(10,38)\`.
4. **For m=1**: next instruction would be \`(151,29)\`. The arithmetic-only builder \`(151..210,29)\` constructs \`(-201,+3)\`; \`x\` at \`(211,29)\` would transfer the IP to **\`(10,32)\`**, where the original immutable opcode is \`>\`.

The \`m=1\` geometry identifies a **specific original-source conditional route**, not an observed route or naturally reachable input. The \`x\` at \`(211,29)\` is itself among the original unobserved 15 source cells. This explains a dependency between two unvisited source cells: evidence of a feasible original state at \`j(89,29)\` is necessary before proposing a fresh input-origin Native experiment targeting \`(10,32)\`.

## New finite original Native finding

Re-examining all 48 QA20 original signed physical STEP traces (27 valid and 21 invalid):

| Finite physical observation | Count |
| --- | ---: |
| Valid cases reaching \`j(89,29)\` | **27/27** |
| Invalid cases reaching the same \`j\` | **9/21** |
| Total executions of \`j(89,29)\` | **36** |
| Actual successor \`(90,29)\` immediately after that \`j\` | **36/36** |
| Actual executions of \`x(150,29)\` | **36** |
| Actual executions of \`x(211,29)\` | **0** |
| Actual executions of \`>(10,32)\` | **0** |

All 36 observed \`j\` sites had a preceding original \`g(57,29)\` and all 36 took the zero-jump successor. Under the original static builder \`61*m\`, this is consistent with \`m=0\` on these routes. **No independent FungeSpace read-value probe is asserted**: the value follows from source semantics plus actual signed successor coordinates. The other 12 QA20 invalid routes did not reach this gate.

The original source has \`p(344,26)\` with a literal zero/value-address suffix writing \`(3,49)\` during the known row-26 route. Whether a different natural route, runtime write, storage-offset change, or valid input can make the gate's \`m\` equal one at the relevant time **remains unproven**.

## QA31F continuation — signed upstream zero-put ownership, finite 48-case audit (2026-10-30)

This is a **read-only analysis of existing Native evidence**, not a new Native run. The four original QA20 ZIPs were re-read locally, pinned to the **four SHA-256 values already recorded above**, with ZIP CRC, original source blob ID, per-case compressed STEP SHA-256 and signed STEP sequence checks. The independent scoped extraction examined all 48 cases and all 36 physical executions of `j(89,29)`. The immutable original Git blob was separately read from GitHub and checked for the static operands described below. This is **not a full post-change acceptance run of the five-input QA31F CLI**, nor a new CI PASS.

**Pinned original-source literal operands, with storage offset assumed unchanged:**
- `p(202,2)`: literal suffix `(value=0,x=3,y=49)` — startup initialization of the cell subsequently read by `g(57,29)`.
- `p(344,26)`: the same literal `(0,3,49)` — a later reset on the observed row-26 route.
- `p(60,5)`: input-dependent value but literal destination `(x=0,y=49)`, **not** the gate's `(3,49)`.

| Actual QA20 signed STEP outcome before `j(89,29)` | Valid | Invalid | Total |
| --- | ---: | ---: | ---: |
| Startup `p(202,2)` followed by later `p(344,26)` | 27 | 7 | **34** |
| Startup `p(202,2)` with no `p(344,26)`; 1 or 2 intervening `p(60,5)` | 0 | 2 | **2** |
| Reached `j(89,29)` without `p(202,2)` | 0 | 0 | **0** |
| All `j(89,29)` witnesses | **27** | **9** | **36** |

For the 34 routes with later `p(344,26)`, the final zero-put occurs exactly **172 signed STEP ticks** before `j(89,29)`; **no subsequent `p`** occurs between that put and the gate. In the two exceptional invalid cases `invalid18` and `invalid19`, the only subsequent put locations are `p(60,5)`, executed once and twice respectively, targeting `(0,49)`. All **36** routes have no recorded `{`, `}` or `u` instruction between startup `p(202,2)` and the gate; no observed relative storage-offset rebase is needed to explain this bounded provenance.

Thus **each of the 36 observed zero-branch successors now has a concrete preceding original-source zero-write witness**, in addition to the previously established `g`/`j` geometric inference. The evidence supports the observed `m=0` finite routes but **does not prove `m=1` impossible** for another naturally accepted input, nor exclude uninstrumented memory mutation APIs, changed runtime opcodes in hypothetical paths, or a different earlier control route.

The existing checker [`stage1_qa31f_original_latent_row32_audit.py`](stage1_qa31f_original_latent_row32_audit.py) was **extended in place**, not duplicated: source-literal checks, original signed zero-put ancestry, intervening put-site restriction and offset-control guard, plus expected 34/2 partition and explicit bounded counters. The four-ZIP focused checks above ran locally; the complete QA31F CLI with its separate QA31A ZIP and source file still requires a fresh independent end-to-end execution before claiming that *revised CLI* PASS.

**NEXT refinement:** No grounded naturally valid `m=1` pre-gate route was identified in the signed 48-case sample. Check other already accepted original Native memory-event receipts for a later write targeting physical `(3,49)` or a reachable storage-offset rebase **before** `g(57,29)`, without starting a random-input run. If none exists, retain this finite-boundary finding and continue a distinct original-source candidate among the other fourteen. Stage 1 remains OPEN.

## QA31F continuation — direct historical Native FungeSpace.put lineage (2026-10-30)

**Source-geometry correction and refinement.** The original immutable source blob `560d6aa5807a7f766213a33835cce85eab0fa40c` contains **three** relevant physical literal put sites, not just the previously identified zero writes: `p(202,2)` constructs `(0,3,49)`; `p(248,14)` constructs **`(1,3,49)`**; and `p(344,26)` constructs `(0,3,49)`. The original source slices were read directly from the pinned GitHub blob. This is a **transient source-defined 0→1→0 possibility**; the value one must not be conflated with a proven one-valued arrival at the later `j(89,29)`.

**Existing original Native evidence, independently cross-indexed (no new Native run).** From previously accepted QA30B run [40488476653](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40488476653), artifact `12725439728`, exact ZIP SHA-256 `dd84fea04224066bb60849c3d250df7f3059c630bea9bdf768300a5b7bcb0997`, ZIP CRC verified. Inner `qa30b_live_source_frontier.json` SHA-256 `54006c8f886c67967c6f98b618a1ee6f7c87d8cdb4e902fd533e292433cb029d`; `qa30b_independent_audit.json` SHA-256 `528a415cb1a12c6f2224d27b6858cdf8622d6cca9644b9e7f36234b111442460`. The original 2 Native replays contain **18,859 signed physical STEPs, 73 physical put events**, with 41 adversarial controls rejected in the *historical independent audit*. The pre-existing signed QA20 original STEP archives were reloaded with their four original SHA-256 values and matching compressed STEP digests. Every QA30B put tick was matched to an actual signed QA20 `p` opcode; event `before/after` values were checked for chronological consistency. This corroborates the historical QA30B evidence but does not newly rerun the Native interpreter.

| Exact historical input | Actual writes to physical FungeSpace (3,49) | Actual row29 read / jump |
| --- | --- | --- |
| `invalid00` | tick 242: `p(202,2)` 32→0; tick 1082: `p(248,14)` 0→1; tick 2504: `p(344,26)` 1→0; tick 3344: 0→1; tick 4766: 1→0; tick 5606: 0→1; tick 7028: 1→0; tick 7868: 0→1; tick 9290: 1→0 | `g(57,29)` tick 9437; `j(89,29)` tick 9462; actual next STEP `(90,29)` |
| `invalid18` | only tick 242: `p(202,2)` 32→0 | `g(57,29)` tick 1285; `j(89,29)` tick 1310; actual next STEP `(90,29)` |

**Full 48-case QA20 signed STEP scope (not 48 direct live-write probes):** 45/48 original programs executed the `p(248,14)` location at least once; all those 45 also executed `p(344,26)` at least once. **34/36** original programs that reached `j(89,29)` executed both sites with the *last* observed `p(248,14)` preceding the *last* `p(344,26)` by **1,422** signed STEP ticks, and the latter preceding `j` by **172** ticks. The other **2/36** reached the gate after startup zero initialization with neither site. Crucially, long routes can execute `p(248,14)` many times between zero writes, so it is **incorrect** to claim a globally alternating one-to-one sequence for all 45 programs; the exact 0→1→0 values above are directly measured only on QA30B's `invalid00` replay.

The reproducible narrowly scoped [QA31F ↔ QA30B signed live-put auditor](stage1_qa31f_qa30b_live_put_lineage.py) was saved in the QA branch. A local independently implemented offline SHA/ZIP/STEP/put cross-index succeeded on the five pinned ZIPs; the separately committed auditor has **not** yet been independently executed end-to-end in CI, and no new QA PASS is claimed for that commit. The new data show that **`m=1` is real in earlier original live memory**, but all observed subsequent row29 gates still read after the zero reset or startup zero. This does **not** establish global impossibility of `m=1` at the gate, a valid input witness for `x(211,29)`, or Stage 1 acceptance.

**NEXT:** identify whether any previously accepted source/Native memory receipt shows a **different input-driven path that enters row29 before its preceding reset** or writes a nonzero physical `(3,49)` after the last reset; do not repeat this finite search or start speculative Native reruns. If no such grounded predecessor is found, preserve the bounded conclusion and continue another original one of the fourteen remaining unvisited source coordinates. No main, canonical branch, Stage 2 or PR merge change.

## NEXT — no ungrounded Native rerun

Audit the **actual upstream writes and state ownership for \`FungeSpace(3,49)\` before \`g(57,29)\`** in original source/previous Native events, including \`p(344,26)\` and other put sites, and establish whether a valid natural input can reach \`j(89,29)\` with \`m=1\`. A further original-Native test is justified **only** after such a valid input candidate is grounded, with full signed physical STEP capture, exact-source pin and independent adversarial audit. Otherwise explicitly close the finite-search boundary and continue the other 14 original candidate cells; do not force an IP or fake reachability.

Stage 1 remains OPEN: \`CURRENT_STAGE=1\`, \`LAST_COMPLETED_STAGE=0\`, \`FULL_FUNCTIONAL_QA_PASS=NO\`, \`GEOMETRIC_SPAGHETTI_QA_PASS=NO\`. No production/main/canonical-branch change, Stage 2, PR #17 merge, or new Native PASS claim.
