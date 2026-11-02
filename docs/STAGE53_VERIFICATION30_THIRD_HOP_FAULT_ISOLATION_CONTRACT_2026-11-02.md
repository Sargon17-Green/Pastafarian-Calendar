# Stage53 / VERIFICATION30 — third-hop dependency failure isolation

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-11-02

## Entry gate
Stage52 repaired SHA 1d56e975270e926f2e2c39593b2f4254e2ba872d: Actions #41503586923 completed/success 23/23; job #125477036213 PHP8.3.36 64-bit lint PASS, checks=81, 4 baselines, 16 faults, 16 recoveries, stderr empty, exit 0, artifact #13170747827 ZIP SHA256 2c6303ecf583ce1a9c94af66222ee34b6e069b3cbfab82f5331544c2acb09f7f. Previous test-injection defect is now repaired.

## New independent question and input
Stage52 tested the second hop. Stage53 checks that failure in the **third hop** prevents a fourth hop and does not poison the next request. No production change or predeclared expected-red.

Only on test side, construct genuine independent years 4996..5004 from NormativeOracle with NormativeMath::FOUNDATION_DAY. Four valid requests = forward/backward x depth 3/4; target strictly interior to destination year; budget exactly depth. Expected output: oracle year equality, steps=depth, matching direction, usedLegacyOutput=false. Derive provider call trace *independently* from oracle fields, not from tested callbacks: trusted Year5000, two anchor gates, then proposed/canonical/arrival open/arrival close per hop.

For each request, inject four third-hop faults: proposed throws S53_PROPOSED_THROW, canonical throws S53_CANONICAL_THROW, open-gate provider throws S53_GATE_OPEN_THROW, close-gate mapping returns day+1 causing PATCH20_GATE_DAY_MISMATCH_close. Shared seams between adjacent years require matching BOTH destination index and per-request gate-call ordinal: third-hop opening=7, closing=8 (two anchor, four prior-hop gate calls). Assert seam equality. Require exact error, exact trace prefix of (3+8)+(1..4) calls, and no subsequent callbacks; depth-four cases prove no fourth-hop calls. Immediately repeat healthy request, assert exact result and complete trace match baseline. Totals: 4 baselines, 16 deliberate failures, 16 recoveries. Validate unchanged oracle fixtures and no NormativeOracle/NormativeMath in production src/Patches/CanonicalAdjacentPatch22.php.

## Native contract
PHP 8.3, 64-bit; php -l PASS; 512 MiB, 900s timeout; exit 0; empty stderr; one stdout line matching:
`^STAGE53_THIRD_HOP_ISOLATION checks=[0-9]+ cases=4 faults=16 recovered=16 baselines=4$`
Save source SHA, PHP version, stdout/stderr, exit and artifact. Require 24/24 completed/success on exact new branch SHA. Queued/in_progress is not PASS or a blocker. No main/merge/publish or five-field output correctness claim. Future Stage54 requires own contract/evidence.
