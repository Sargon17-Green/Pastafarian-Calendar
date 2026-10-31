# QA31F — original x(235,23) directed two-gate frontier (2026-10-30)

Project PC-BRANCH-BEFUNGE98-KYRGYZ; Stage 1 only. Immutable original source blob 560d6aa5807a7f766213a33835cce85eab0fa40c. Previous QA branch HEAD b53e60acc7356f149a9c7fe0e67cd68d352716b5. No production or historical receipt edits.

## Prior focused CI verified
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41098103820 completed/success on code SHA 3fbcb0dbe737cb29933c58f9fc180a1249318a25. Job source-pinned-prefix verified 256 nonnegative character-model cases; -1 remains a counterfactual. Neither Native nor Stage 1 acceptance.

## Original-source gated incoming route
QA27 signed historical baseline: 136 Native runs and 4,513,423 STEP events, nearest observation (235,26) at L1=3 in QA20 valid03, no witnessed x(235,23). Absence is finite, not universal.

With entry at (10,20), empty stack, fixed zero storage offset, intact original source bytes, and fixed g(3,49)=m and g(1,49)=q in this segment:
- g(57,20) and j(89,20) compute 61*m. For m=0 x(150,20) consumes (-140,-15), exiting at (10,5); for m=1 x(211,20) consumes (-201,+3), entering (10,23).
- g(57,23) and j(113,23) compute 61*[q>3] by the original comparison instruction. For q<=3, x(174,23) consumes (-164,+3), exiting (10,26). For q>3, x(235,23) consumes (-225,+21), exiting (10,44).
- The bounded experiment covers m in {0,1} and q in 0..9: 20 model cases, six hypothetical x(235,23) traversals. The committed fail-closed Python auditor pins the source Git blob, checks all source gate opcodes, exact step counts, read values and vectors, rejects unexpected instruction/reads and residual stack, and requires three intentional opcode mutations to be detected.

## Evidence boundary and NEXT
The necessary simultaneous natural values m=1 and q>3 at these actual gates are NOT established. Nor is original static instruction-byte ownership, zero-offset and empty stack universally proven. Next: cross-index signed original STEP plus p/g receipts around actual row20/row23 entries and preceding counter writes to decide if both values co-occur in one legal input trace. Plan a narrow original Native candidate ONLY if this has source-backed input feasibility; no speculative random corpus.

No new Native, no global reachability proof, no FULL_FUNCTIONAL_QA_PASS, no GEOMETRIC_SPAGHETTI_QA_PASS, no Stage 1 PASS. Do not merge PR #17, change main or canonical Befunge branch, or open Stage 2.
