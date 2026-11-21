# Stage51 / DISCOVERY47 — deterministic non-occupied rejection QA (2026-11-21)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Parent source commit: 3504b29766d35e20748d1c8a5aefffcce81dd6d2
Prior Native acceptance is retained; this new test-only change is NOT accepted until its own exact-SHA completed CI, job log and artifact are verified.
Scope: existing Stage51 only; no Stage52, no production/main/merge/release.

## ABI-grounded fault witness (no mock or copied fixture)

At parent source, `src/monster_distance.cob` lines 58–69 validates signed input descriptors before occupied-output and PATCHED-DISTANCE dispatch. If either input sign is outside [-1,1], it sets status 22. This is a real supported deterministic validation error, not a fabricated service error or allocation failure.

With five distinct live, correctly serialized owned outputs already present, the Stage51 test now:
1. Confirms that the probe and separate output descriptor are zero/NULL, while the valid T descriptor and five result owners remain live.
2. Passes a probe input descriptor with sign=2, zero chunks and NULL pointers, a valid T descriptor, and an unoccupied zero/NULL output to real `MONSTER-DISTANCE` on `DISTANCE-PATCH`.
3. Restores the probe sign to zero unconditionally after the call. Requires exactly status 22 and no mutation of probe pointers/chunks or output descriptor fields.
4. Calls the original CHECK-DISTINCT and CHECK-INPUT-PRESERVED: each of five live outputs must still match the independent expected decimal text, owned-head uniqueness and saved descriptor metadata; the real valid pair must retain its metadata and magnitude.
5. Continues the unchanged Stage51 successful lifecycle: occupied-output rejection, input recreation, free/reuse and restored snapshot, unconditional descriptor cleanup and measured live heap zero.

The matrix is 5 widths (3, 9, 128, 320, 8192) x 5 ordered pairs = 25 real validation rejections. The new `STAGE51_INVALID_SIGN_REJECTS=00025` counter must equal 25; the strict existing job also checks all earlier 25/25 native cases, all original counters, `UNEXPECTED_FAILURES=0`, the final measured heap zero, and independent model arithmetic/sign symmetry. The workflow adds exactly one numeric assertion to the existing Stage51 job, not a new stage or job.

## Coverage boundaries

This establishes input-sign rejection on a non-occupied output with five preserved live owners. It does not exercise injected allocator failure, forced `INIT-TEXT`, `TO-TEXT`, `FREE-A` or `HEAP-LIVE` service failures, nor does it demonstrate cleanup from an unexpected failure partway through a production operation. Those remain unsupported cases in QA51-B, not observed defects. Do not infer a positive result for them.

## Gates and provenance

Static authoring preflight: original Stage51 test blob `a397c74242f41597899d6699bd7fc573284f7837` with new source lines <=72 columns, original 52-job workflow preserving unrelated jobs, only Stage51 test and Stage51 CI assertion modified.

The predecessor's run 44876523869, attempt 1, exact 3504b29766d35e20748d1c8a5aefffcce81dd6d2, completed/success 52/52; Stage51 job 136762321604 strict GnuCOBOL 3.1.2.0 -Werror, 25/25, unexpected=0, measured heap0. Artifact 14697345247 (750-byte ZIP) independently SHA256/CRC checked; digest `cf3744045e78bd3ef469ebf73fe8b69a7ec6a567b6ec4c01c4db65d94bfe4e1f`, embedded PROJECT_ID and HEAD match. This supports the predecessor only.

NEXT: inspect the single natural push run on the new exact SHA. Require completed, all 52 jobs success, Stage51 strict native job with 25/25 cases and 25/25 real invalid-sign rejections, zero unexpected, heap0, ZIP SHA256/CRC and exact embedded project/head. Do not duplicate dispatch or mark new test Native PASS while pending.
