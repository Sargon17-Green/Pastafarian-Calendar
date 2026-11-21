# Stage19 first-match Native follow-up failure — 2026-11-21
PROJECT_ID: PC-BRANCH-FALSE-ARABIC; branch FALSE+العربية.

The prior selected run 44940370617 failed with a FALSE stack-type error in a twice-dereferenced scalar fixture. Exactly three fixture sites were corrected at SHA 5cdac0433bc3dc7a7679385b7b96a29b3f9b2d81, without changing the production operation.

The correction run 44947045684, job 136976531475, completed/failure on that exact SHA. Runtime eb3135565a8670cced3f6bbca4dbf7b014c45634 compiled; Unicode preflight succeeded; mathematical JS oracle and Python fixture generation succeeded. Artifact 14723998006: ZIP SHA256 aff177402b87be57bc6f0b3741cad46777a64a23d64bbba7eb758301f329ed90; 40/40 ZIP entry CRC PASS.

Actual first positive stdout: STAGE19_CASE_0000_POSITION_FAIL, stderr: divide by zero at first expected-position assertion. First non-permutation probe likewise fails at STAGE19_PROBE_000_POSITION_FAIL. The wrongly expected-result mutant rejects at its target marker, but the duplicate/last-match mutant fails earlier at PROBE_000, so that control is NOT verified. Header-5 and header-7 controls print STAGE19_BAD_LENGTH_ACCEPTED, followed by stack-not-empty, so required E_BOWL_POSITION_LENGTH never appears. Thus Stage19 Native and negative controls FAIL, not PASS.

The next diagnostic commit adds an on-failure, original-runtime, **single-case** trace to Stage19's test runner only. It reports actual op36 scalar, directly read table header, and both argument tuple cells, retaining original source/runtime pins. The standard exhaustive fixture is unchanged. This generates new evidence to distinguish wrong op36 computation from incorrect fixture layout. No source production change, no main/merge, Stage18 last bounded accepted, Stage19 NOT_ACCEPTED.
