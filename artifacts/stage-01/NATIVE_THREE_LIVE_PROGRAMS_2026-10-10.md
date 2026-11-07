# Stage 1: Native three simultaneously live Programs — QA trial

This Stage-1-only addition extends already passing two-program concurrency
evidence to THREE PyFunge-98 Program objects live in the same interpreter.
The 25 deliberately distinct input triads include all 21 malformed inputs
plus six valid inputs; two asymmetric Native quantum/turn-order schedules
exercise 50 triple trials and 150 actual Native Program executions.

After each scheduled quantum, both passive Program states (IP, stack,
delta, source guard cells, Funge-space bounds, stdin/stdout cursors) must
remain unchanged. Additionally, periodically snapshot and compare EVERY
previously visited Funge-space.put target of the two passive Programs.

Every real Native Funge-space.get / .put / .putspace made during a step
is attributed to the correct active private space; putspace is forbidden
in the observed corpus, and each put must match an actually executed p.
Input step/get/put/output signatures must not change with peers, ordering
or quantums; expected values for six valid forms arise only from
independent test-only Native Befunge work_counts/save programs.

The separate Python-3 reviewer checks all 50 triads / 150 Native runs,
27 independent input signatures, all 21 invalid forms, source/blob and
negative report scope, and rejects 16 forged evidence variants.

This bounded result cannot establish universal ownership, undocumented
interpreter APIs, completeness of Stage 1 functional/geometric requirements,
or permission to merge draft PR #17 or begin Stage 2. No production source,
canonical branch or main edits are authorized.

Status: exact-head CI verification required before PASS.
