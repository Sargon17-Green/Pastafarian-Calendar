# QA31F — original-source conditional route to unobserved (10,32) (2026-10-28)

Project **PC-BRANCH-BEFUNGE98-KYRGYZ**. This is a **Stage 1-only, read-only offline** analysis of previous genuine Native evidence and the unchanged original Befunge-98 source, **not a new Native run, Stage 1 PASS, or a proven naturally reachable new input**.

## Pinned evidence, independently checked

- Original immutable \`src/interleaved_work_counts.b98\` Git blob: \`560d6aa5807a7f766213a33835cce85eab0fa40c\`, directly read as GitHub blob. No production-source edit.
- QA31A original Native [artifact 12634011438](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40280436139) (the artifact ID, not this run URL, is the pinned object): ZIP SHA-256 \`235be0d04cc2f6ab113b3a809c3a2ef93513c07cb2233b2b8b457722d409a4cd\`; extracted JSON SHA-256 \`39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c\`. ZIP CRC verified. Its original aggregate covers 136 original programs, 4,513,423 signed STEP records; all 15 original source candidates remain unvisited. For (10,32), exactly five distinct near-control prestates within L1=9 and **zero** different-input successor outcomes among them.
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

## NEXT — no ungrounded Native rerun

Audit the **actual upstream writes and state ownership for \`FungeSpace(3,49)\` before \`g(57,29)\`** in original source/previous Native events, including \`p(344,26)\` and other put sites, and establish whether a valid natural input can reach \`j(89,29)\` with \`m=1\`. A further original-Native test is justified **only** after such a valid input candidate is grounded, with full signed physical STEP capture, exact-source pin and independent adversarial audit. Otherwise explicitly close the finite-search boundary and continue the other 14 original candidate cells; do not force an IP or fake reachability.

Stage 1 remains OPEN: \`CURRENT_STAGE=1\`, \`LAST_COMPLETED_STAGE=0\`, \`FULL_FUNCTIONAL_QA_PASS=NO\`, \`GEOMETRIC_SPAGHETTI_QA_PASS=NO\`. No production/main/canonical-branch change, Stage 2, PR #17 merge, or new Native PASS claim.
