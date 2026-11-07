# QA31AZ — original-source noncanonical ingress and dynamic write inventory (2026-11-07)

Project PC-BRANCH-BEFUNGE98-KYRGYZ. Original Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c; entering QA branch SHA 7a7c13da463211d2e5840e875d3ce32cc1b767c5.

## Proven source-only, conditional results

A direction-conditional backwards stack-demand solver certifies original literal-only postfix suffixes ending at lexical x (delta x,delta y) and p (address x,y). A distinct rightward forward RPN evaluator checks those hypothetical suffix addresses. Some original outer corridors, such as row575 with the '<' at (385,575), are traversed LEFTWARD, so the computed hypothetical rightward p addresses are NOT necessarily physical p destinations. This certifies only when that complete unchanged suffix executes in its original direction, not the executability of the prefix/entry or any global memory noninterference.

There are 279 lexical x source occurrences, of which 99 have such a constant-vector certificate and **180 remain unresolved**. Among the 99 certified x vectors, precisely two land directly on row14 or row32: x(174,11) -> (10,14) and x(211,29) -> (10,32). Both are known canonical routes, with original source at the destinations beginning with '>'. This does NOT exclude an alternative from an unresolved x, from vertical fallthrough, nonempty-stack ingress or altered source.

There are 57 lexical p occurrences, 27 with rightward-only literal-address suffixes and **30 unresolved by this solver**, including the row26/35 q-variable staging writes. Of the 27 rightward-only hypothetical addresses, THREE land on protected parser/control row y=5: p(369,575) -> (5,5), p(664,860) -> (10,5), and p(1041,860) -> (10,5). These are **NOT verified original physical writes**, because reverse-oriented source traversal can invalidate rightward suffix evaluation. In particular, the original '<' at (385,575) is a concrete negative control against treating the left-neighbor p(369,575) rightward-suffix target as real. This is NOT global proof against mutation of those rows: 30 p destinations are unresolved and original production code is self-modifying. All 10 lexical j source coordinates are pinned, including the non-gate j(164,5) and j(958,1331).

Two independent original-source algorithms are included in the executable script, plus a separate pinned expectations JSON. Twenty-four deliberately altered non-no-op source values (12 certified x and 12 certified p sites) must change computed destinations and be caught. Source SHA1 Git-blob pin is checked before any tests. The original signed QA31AI 200-case / 3,628,390 STEP corpus is referenced by the prior accepted SHA256 9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49 but NOT newly downloaded or replayed. No new original Native runs, no full-corpus signed CI.

## Reproducibility and limits

Run: node qa/stage1_qa31az_original_ingress_inventory.mjs > qa31az-inventory.json. The bounded GitHub Actions workflow uploads exact-source per-site inventory, source confidence reason and hostile controls as a JSON artifact. Pass for QA31AZ requires completed/success job at the exact commit and verification of emitted inventory; a queued/in_progress job is not PASS.

This is a bounded source-byte static classification, NOT a proof of reachable IP or dynamic write targets in all programs. The previous original signed finite case observations do not close the unknown branches. Stage1 functional/geometric/global remain OPEN, no production/main/merge/Stage2.

NEXT QA31BA: investigate only the 180 unresolved x / 30 unresolved p sites, prioritizing source paths with prior signed observed physical execution and source p(1335,1354) self-modifying the selector (1500,1750). Use real input, original signed IP/stack/p events, source-pinned constraints, and independent adversarial checks. Distinguish lexical site, executed site, potential target, and true natural-input witness; do not claim unreachability or new Native without verified concrete input <=25000 STEPs.

## QA31AZ RED repaired: source direction distinction

Initial QA31AZ CI failed on an invalid overstrong assertion that zero forward-only p suffixes target a protected control row. Real CI run 42403178264 rejected it after identifying p(369,575)->(5,5). The full source inventory also identifies p(664,860)->(10,5) and p(1041,860)->(10,5). These source-syntax evaluations do not prove actual p execution targets because the original row575 region executes leftward (original source '<' at x385), and other outer segments can have different incoming directions. The fix pins all three as **rightward-syntax-only potential targets** and explicitly preserves physical target ownership UNKNOWN. No original Native execution or full signed-corpus rerun occurred during this repair.
