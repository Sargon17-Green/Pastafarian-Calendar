# Stage23 independent malformed pre-audit and bounded replay/mutant design — 2026-11-28

Project PC-BRANCH-FALSE-ARABIC. Original exact gate SHA fa548e8c7d9f6a24506c60ff3834fc3c27057f01; production blob f3e51dabc3c4afc95ad75ea79c572f5024f75a38; malformed runner blob 549bd5a564839ec8a9cb4860e909c97692ce0e87. No production modification, no new Native result, no Stage23 acceptance.

## Executed independent static pre-audit

Retrieved CASES from the pinned Python runner. A separate JavaScript BigInt classifier checked sign membership, length 1..8, radix-512 digits, canonical zero, nonzero top and decoded signed mathematical value within [-2^63,2^63-1]. All 12 raw cases matched their specified reason; regenerated both argument positions, 24/24. Each model allocates eleven cells per record, padded with zero, followed by two pointer cells at relative offsets 22 and 23 pointing to 0 and 11. Valid counterpart independently encoded -15055671 as [-1,3,311,221,57]. Expected aborts by case, each in both positions: sign_positive/SIGN, sign_negative/SIGN, length_zero/LENGTH, length_nine/LENGTH, digit_negative/DIGIT, digit_512/DIGIT, zero_nonzero_digit/ZERO, zero_two_limbs/ZERO, top_zero/TOP, positive_2pow63/RANGE, negative_beyond_min/RANGE, negative_high_limb_two/RANGE. This reconstructs raw cells and expected classification only, NOT an artifact byte comparison or Native diagnostic verification. The original fixture uses x-relative addresses. Source validator order matches the six classes. No physical invalid pointer/truncation claim.

Run discovery: live branch matched exact gate SHA. GitHub connector commit workflow query (PR-only) and combined status returned empty. Public API lookup unavailable; local network DNS unavailable; both authorized desktop devices offline. No run ID or artifact independently observed; no duplicate dispatch.

## Executed mathematical mutant witness check

Independent JS BigInt recurrence used decoded mathematical days, reversed hidden history, radix-independent SAVE, factoradic unranking and ID-indexed simultaneous bowl update. Both signed extreme first-bowl anchors matched prior independently recorded signed64 gate. For C=-9223372036854775808, T=9223372036854775807:
- normative final bowl 1 = 108913163550045184146698385533806010700; order46 = [6,1,2,3,4,5].
- swapped C/T first bowl = 117012097572828239447606168473050643501.
- returning after46 rather than after12 batch first bowl = 43795601943322443886068352038643283602.
- last batch order = [4,5,3,2,6,1], distinct from order46; identity [1,2,3,4,5,6] also distinct.
All three concrete proposed source-mutant witnesses discriminate mathematically. No claim that a Native mutant has executed or been rejected.

Static anchor count exactly one in op40 for each of `x;f;!y:` and `z;r:2a;!n;a;!o;a;!`. Proposed QA-only transient copies: replace the first with `z;b:x;1+g;!a;!x;g;!a;!b;f;!y:` (swapped argument record); replace second with `z;r:2a;!p;a;!o;a;!` (after46 return); or prepend `z;b:1a;!b;34h;!!o:` to second (incorrect identity order). Before Native dispatch verify each mutated fixture compiles, only intended anchor changed, source hash preserved and expected assertion/abort attributable to the selected wrong output. Do not count a crash, timeout or setup failure as a numerical rejection. Use original runtime pin eb3135565a8670cced3f6bbca4dbf7b014c45634; isolated process, 600 s watchdog and 2 GiB address-space limit.

## Replay contract and resource constraint

Existing single epoch full call: 525.215 s, 78,166,288 heap cells, 1,834,064 KiB cumulative child RSS; instrumented differential 590.22 s; signed boundary maximum 497.97 s/1,916,240 KiB/81,672,413 heap cells. These are historical receipts, not a fresh measurement. A naive double full call in the same append-only heap is not justified under current 600 s / 2 GiB per-process cap; linear extrapolation for epoch suggests ~1050 s and ~156 million cells, not a measured failure. Do not raise caps silently.

Proposed bounded test: use a non-symmetric pair, two independent full processes with deterministic input and byte-exact value/shape/order evidence; one process interleaves cheap accepted op34 calls before and after one full op40, retains first cheap output and verifies unchanged cells, caller register/frame restoration, disjointness and both cheap results. Compare numerical result, not raw pointer addresses between processes; record process-local RSS/time/heap, exact source/program/stdout/stderr hashes and exit codes. This tests fresh-process replay and cheap-op interleaving, not two full calls in a retained heap. Retain full same-process replay as unassessed until bounded implementation or explicit policy decision; do not mark acceptance solely from the weaker test.

Next: find original malformed push run, verify completed exact SHA/job/log/artifact, regenerate exact program bytes and audit diagnostics. Independently prepare/verify replay and mutant fixtures as above without rerunning malformed gate. Stage23 NOT_ACCEPTED. No Stage24, main, merge or release.
