# Stage44 standalone preflight boundary audit — 2026-11-28

## Exact gateway regression evidence
Source a55cf61bbd9a2c281434490fbb892fbd63263618; automatic push run 46071987931, completed success, 18/18 jobs and 20 unexpired exact-source artifacts.
- Job 140750870337: classifier 240/0 PASS_SHAPE_ONLY (artifact 15233660689, sha256 6d0562027b9288afd3490f7f08caacafc5b6a8bd49542beab10ce80cf4b0d2e3); Stage43 2215/0 (artifact 15234140353, sha256 abb9c837ae0d13ca9c920fe650d38792f8972054ecb6c673ff8e3c5509facbc5).
- Job 140750870558: 5027/0, 72 source and 72 oracle contexts, 720 endpoints, 320 rectangles, 67 guards; BOUNDED_ORACLE_PASS, NOT_ACTIVATED. Artifact 15234135057, sha256 c371f5298e8a68088c6ef3ac4138c07699bd705c9c74e4f64ac8729af1e672ea.
- Job 140750870303: Stage30 96/0; Stage23 finalizer twice exit 0, stderr 0, already finalized true, identical metadata SHA256 EF31C98A432EBF68275014FDBAC26EE3927E5C5A5B1E0829A20779EA968D18AC. Artifact 15232889432, sha256 53f8ac30eb7876224808885c2ac8b5b2da977ceccf7d7cf40a1b9fb45860c8b8.
Upload log digests matched artifact API digests; ZIP bytes not independently rehashed.

## Audit and bounded fix
The Stage44 test entry point had a predecessor-only gate at line 9, followed by unconditional NOT_ACTIVATED and BOUNDED_ORACLE_PASS output. A valid Stage44 pending, implementing or sealed shape projects the same SEALED_SHAPE_ONLY Stage43 predecessor. This could mislabel a direct run; the reusable workflow currently rejects a changed HEAD metadata blob before the test. Neither condition authorizes a phase transition.
The standalone entry point now rejects any projected Stage44Profile and requires byte-for-byte equality with the Git-hash-pinned frozen Stage43 blob before entering the numeric tests. The numerical oracle, 5027 assertion count, workflow and lifecycle metadata are unchanged.
Stage01.Tests.ps1 lines 95–96 use first regex match of CURRENT_STAGE directly for historical future-name audit; this is an outstanding direct pointer consumer (not a demonstrated runtime failure). Stage41 and Stage42 tests invoke the gateway before historical raw checks. Canonical workflow has repeated direct historical pointer expressions after gateway calls; their fallback routing requires a further scoped audit. Dedicated reusable Stage44 workflow lines 21–36 is still preflight-only.

## Acceptance matrix for this increment
1. Exact frozen Stage43 bytes: allow preflight only, 5027/0 expected.
2. Mutated but otherwise valid sealed Stage43 bytes: reject before numerical work.
3. Stage44 pending, implementing and sealed shapes: reject before numerical work until phase-specific entry point/output is wired.
4. Invalid metadata: gateway rejects; no preflight result.
These are contractual expectations, not newly executed results. No activation, source algorithm, oracle or release change. Exact new SHA CI and direct negative-case execution remain necessary. Next: exercise these entry-point cases, then route dedicated workflow/test output by independently validated lifecycle phase and audit remaining raw pointers before PENDING_NATIVE.
