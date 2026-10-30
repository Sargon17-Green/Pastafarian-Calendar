# QA31F — exact-source bounded incoming route for \`x(286,5)\` (2026-10-30)

Project: \`PC-BRANCH-BEFUNGE98-KYRGYZ\`; Stage 1 only. The original production source \`src/interleaved_work_counts.b98\`, Git blob SHA-1 \`560d6aa5807a7f766213a33835cce85eab0fa40c\`, was read by immutable blob ID, without production edits. Source observations use zero-based (x,y).

## Gate confirmation
The prior \`f7da1a333aa6fa2c72f6cfadbb44e9f34e6a8bd8\` exact-head CI gates are **completed/success**:
- Native Regression: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41086624267 — 29 completed successful jobs, including Native regression; **not** a specific QA31F x2865 experiment.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41086637049 — one completed successful job.
The QA31F five-signed-ZIP local CLI result at the parent report remains finite historical evidence; these workflows do not turn the offline CLI into Native testing.

## Newly derived exact-source prefix route
- Source prefix follows \`x(61,1)\` vector (-51,+1) → (10,2), then \`x(263,2)\` (-253,+3) → (10,5), with an empty operand stack at the second landing.
- At (13,5) the original \`~\` obtains an input character. At \`p(60,5)\` that value is stored at (0,49). At \`g(107,5)\` the same stored value is read at the unshifted storage offset, after four initial production \`p\` writes in row 2 to (0..3,49).
- The original arithmetic before \`j(164,5)\` gives \`61 × [g(0,49) == -1]\`. Specifically the two consecutive subtracts and logical NOT compute \`! (g + 1)\`, then the literal 61 is multiplied by that bit. This is a predicate for **-1**, not for ordinary digit \`'1'\` (49), control character U+0001 (1), or integer 0.
- For any nonnegative returned code 0..255, the \`j\` skip is 0; the original \`x(225,5)\` consumes (-215,+3) and routes to (10,8). This does **not** reach \`x(286,5)\`.
- For a *synthetic negative-one injection to the read result*, the \`j\` skip is 61, bypasses \`x(225,5)\`, lands at (226,5) and reaches the exact original \`x(286,5)\`. Its literals yield (-276,+24), routing to (10,29). This is a **model counterfactual**, not a permissible character input, not an observed Native run and not an EOF claim.

## Focused verification and scope
A separate source-faithful bounded opcode model, with default empty-stack pop, explicit \`p/g\` memory writes and reads, \`j/x\` IP movement, and fixed zero storage offset, was run in-session over all 256 nonnegative codes 0..255: **256/256 PASS**, 532 executed modeled opcodes for each, all landing (10,8), all \`j(164,5)=0\`, and no visits to (286,5). The negative-one *counterfactual* also completed 532 modeled instructions, with \`j=61\` and exit (10,29). No forced IP or source-byte edits were used in any nonnegative model input. The reproducible Python fail-closed auditor is \`qa/stage1_qa31f_x2865_prefix_probe.py\`; a short GitHub Actions job was added for independent execution on the exact committed source.

**Not established:** true PyFunge EOF behavior at \`~\`; whether stdin EOF reflects rather than returning -1; global impossibility of alternate incoming routes, self-modification or changed storage offset; any new signed Native geometry; Stage 1 completion. The 136 historical original Native cases described in QA27 and the 48 QA20 signed cases had no reported contact at (286,5), but absence in finite traces is not a global proof.

## NEXT (same Stage 1, no Stage 2)
1. Read the new targeted Python CI result on the exact new commit; if it fails, correct the specific guard, not the historical evidence. Do not relabel model proof as Native.
2. Confirm actual interpreter EOF semantics only if a legitimate EOF-based incoming route remains plausible. Without a natural \`g=-1\` input witness, do not initiate a speculative Native run for \`x(286,5)\`.
3. Move focused source/offset/actual signed incoming-edge analysis to the next QA27 unvisited original-source frontier \`x(235,23)\` (nearest signed row (235,26), distance 3), using prior signed traces before planning new Native.
4. Leave \`CURRENT_STAGE=1\`, \`LAST_COMPLETED_STAGE=0\`, \`FULL_FUNCTIONAL_QA_PASS=NO\` and \`GEOMETRIC_SPAGHETTI_QA_PASS=NO\`; no merge/main/Stage 2.
