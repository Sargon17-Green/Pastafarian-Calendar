# Lua+Kreyòl-ayisyen — held-out one-day Native year-selection differential contract

Date: 2026-11-21
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
AUTHORIZED BRANCH: Lua+Kreyòl-ayisyen
PARENT SOURCE HEAD: 0a6cd90ece555655f4cb5225458710d490e607f4

## Scope and falsifiable claim

This is a QA-only single-day test of canonical Lua 5.3 O.year5000(-15017676) versus the independently implemented Python integer model already committed on the parent HEAD. No production Lua, stage status, normative rules, release, other branches, or full-date path is changed. The Python implementation is algorithmically separate from Lua but both implement the SAME normative source (frozen blob 8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d); equality does not independently prove that the normative specification is correct.

Input: signed integer calculationDay=-15017676 (the only accepted input), foundation day -15055671, normative constant M=2^127-1, frozen same-branch Python source blob a2d08aebd46fe2a135b3dbebf61b425204bcbe87, canonical year5000 logic, canonical seed/rank, bounded gate geometry.

Expected independent Python prediction, NOT pre-claimed Native evidence: candidateCount=69; one-based rank=56; selected gate indices=71..82; interval length=5294 days; minimumMonths=44 (>16). The Python report canonical SHA-256 is 89fae158fad5cb09fb320cef76ef801855002422624bacc135cbe34785410caf. The new Native probe captures the *actual* Lua O.chooseRank call (one call distinct from seal-gate rank with N=922), the *actual* O.year5000 interval and indexed bounds; it does not compute month structure or inject the Python answer into Lua.

## Measurable gates

1. Check exact branch, HEAD source SHA, source Git blobs, Lua syntax, Python syntax, and an adversarial 14/14 **synthetic-only** verifier selftest.
2. Re-execute frozen independent Python model: 16/16 selftests, 193 gates, old 4/4 historical selection comparisons, stable report SHA. No old Native tests rerun for this single-day gate.
3. Run ONE independent resource-limited Lua 5.3 process on day -15017676 only: timeout 120s (TERM then KILL), CPU 110s, virtual memory 131072 KiB, Lua heap budget 131072 KiB, <=200 newly calculated gate gaps, max 18528 possible candidate pairs. No month-count selection, composition or full-date.
4. Capture PROJECT_ID, source SHA, run/job IDs, stdout, stderr, exit code, GNU time/RSS, computed candidate count/rank/indices/days/length/minimum months and separate verification outcome. The Python verifier cross-compares the signed day and all fields, rejects missing/duplicate/malformed fields, nonzero exit, nonempty stderr, resource breaches, changed SHA, mismatched rank or geometry, and incomplete evidence.
5. Upload SHA256SUMS and full artifacts even if run fails. A success marker means ONLY this single held-out selected-year differential is accepted on the *exact new commit SHA*. Failure is not labelled expected-red and must be investigated rather than rerun automatically.
6. This change does not certify monthly composition, full-date, the existence of any <=16-month year for this day, universal Lua/Python equivalence, Stage56 or release readiness.

Existing accepted historical source run 44883988537/job 136785194889/artifact 14698888975 remains historical. The parent exact-SHA canonical run 44896472125 completed/success with 94/94 jobs; it does not include this new held-out Native test.

PENDING: New held-out Native job, its run ID, logs and artifact must be independently verified after a completed run. No claim of Native PASS at authoring time. No duplicate dispatch, no main/merge.
