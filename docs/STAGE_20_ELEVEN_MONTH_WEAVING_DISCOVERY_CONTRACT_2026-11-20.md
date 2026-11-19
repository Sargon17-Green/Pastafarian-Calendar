# Stage20: eleven-month / 44-day weaving DISCOVERY contract (2026-11-20)

Project ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Stage19 accepted source SHA: 70ace36b86d71b83e44884e033080a491239212c
Stage19 proof: docs/STAGE_19_NATIVE_CI_ACCEPTANCE_2026-11-20.md
LAST_COMPLETED_STAGE=19. This file opens **Stage20 DISCOVERY only**.

## Choice of bounded extension

Stage16..Stage19 sequentially accepted 7/28, 8/32, 9/36 and 10/40 months/days. Stage20 selects the next same-primitive bounded extension: 11 months and at most 44 total days. This is an engineering choice, not a claim about full-year support. The existing API remains count_weavings, rank_weaving, unrank_weaving; output remains a fresh ARRAYref and counts/ranks exact Math::BigInt, 1-based lexicographic order with increasing first and last occurrences. Preserve all existing <=10 month/40 day positives and negative input behavior.

Do not expand or modify the separate MonthOccurrence API; it retains <=9 months / 36 days. Reject 12 months, 45 days, zero, negative/noninteger, invalid rank/word, and mutated inputs/outputs.

## Independent oracle completed in DISCOVERY

A fresh, standalone Python standard-library oracle is committed in qa/perl-guoyu/stage20_independent_dyck_oracle.py. It enumerates balanced-parenthesis words, transforms open/close event indices to month labels and **explicitly sorts by numerical month-label lexicographic order**. It does not call Perl or share production dynamic programming.

A preliminary oracle traversal-order assumption failed its lexical assertion: parenthesis traversal order does not preserve numerical month-label lexical order. This issue was reproduced in the independent oracle and corrected by sorting before rank assignment. It is **not** evidence of a production Perl defect.

Result on the local Python 3 runtime: for 11 months of exactly 2 days each (22 days), all **58786** legal lexicographically sorted words were generated and validated against the independent formula Catalan(11) = binomial(22,11)/12 = 58786. Each word was checked for label multiplicities, increasing first and last positions, and strict numeric lexicographic ordering.

Canonical SHA-256 of all sorted words, CSV-label line format with LF:
3b7ad5a789d66bfc799fbbc96669e79a46e551fa0d19453bdef7d228f8626c0c

Full output: qa/perl-guoyu/stage20_oracle_result.json.
**This is mathematical oracle discovery, not Stage20 Perl production/native validation.**

## Measurable NEXT and gates

1. Verify current HEAD and exact Stage19 accepted WeavingPrimitive blob 3d731e16bfd88b7ad00c9f5f04f17509467fb91a, and reconstruct an *uncommitted* candidate changing only limits 10->11 months and 40->44 days. Confirm source integrity by Git blob hash before mutation.
2. Run a bounded Perl >=5.40 local resource preflight, separately limited to 120 seconds and 393216 KiB virtual memory for each candidate: [1x11] boundary, [2x11] count=58786 with first/middle/last rank roundtrips, [3x11] and [4x11] count and rank roundtrips if resource budget permits, [34,1x10] and [44]. Record wall time, exit, stderr and peak memory; never convert timeout or test-harness failure into a fabricated production defect. [4x11] is 44 days and may exceed prior unoptimized limits.
3. On feasible preflight, implement only the validated bounded extension and newly-legal legacy negative fixtures. Keep Stage04 36-day negative tests unchanged, as Stage19 regression established.
4. Build a genuinely independent Stage20 oracle test. Compare the 58786 Catalan11 ordered words and rank/unrank indices against the separate Python oracle hash. Because 2 x 58786 position assertions may exceed a single 120-second test, shard deterministically into eight rank intervals (two shards of 7349 and six of 7348) or choose another measured bounded allocation; do not infer runtime from Stage19 alone. Add small complete-multiset-permutation exhaustive profiles and explicit negative/boundary tests. Distinguish independent comparisons from large-profile production roundtrip tests.
5. Use the canonical same-branch push workflow, retain the current 20 required jobs and add one separate Stage20 native job only after implementation and preflight. Prospective acceptance: 21/21 mandatory completed/success on exact source SHA; inspect every required raw job log, complete Stage01 suite, Stage20 native syntax/TAP/exit/stderr/resource bounds, seven-file artifact GitHub/upload/local SHA-256 and CRC, exact source and STAGE20_NATIVE_PASS=1. Do not advance LAST_COMPLETED_STAGE until all gates pass.
6. No duplicate CI dispatch; queued/in_progress never PASS or blocker. No main/merge/release/publish. Full-year generator is not verified.
