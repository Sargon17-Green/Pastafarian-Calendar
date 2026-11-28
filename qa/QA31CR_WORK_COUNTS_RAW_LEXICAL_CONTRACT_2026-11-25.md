# QA31CR — Native lexical contract for the active work_counts entry point

Date: 2026-11-25  
Scope: existing Stage 1 only. QA-only qualification; no Stage 2, merge, main-branch write, or production-source mutation.

## Source and independent oracle identity

- Production entry point: src/work_counts.b98; Git blob 7418e1ec5fe88fe5c14b75710dea2d5607527f28; 1,837,194 bytes; SHA-256 a59c1066843abfde9b059e9ec62b2c9daf0483f116095bbd78c19cf28ab59137.
- Five-field Native reference: reference/work_counts.b98; blob f941efc793c9eee4accf5d03873f8ed029b16725.
- Save-field Native reference: reference/save.b98; blob 7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44.
- Interpreter: PyFunge 0.5-rc2; tarball SHA-256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac.

The oracle is not the production entry point. For every legal positive control, Native reference/work_counts.b98 supplies the first five fields and two separate Native reference/save.b98 invocations supply the final two fields. The production output must match all seven fields exactly.

## Measurable input/output contract

Input is exactly four nonnegative decimal tokens: (signC, magnitudeC, signT, magnitudeT). The sign slots are 0 or 1; a leading minus is forbidden in every raw token, including -0. A malformed raw-negative input must terminate normally and emit exactly seven tokens, each -1.

For each malformed input, the positive control differs in exactly one position: its leading minus is removed. The positive control must be accepted by production and its seven outputs must equal the independent Native oracle.

## Nine raw-negative probes

| # | Token slot | Malformed input | Positive control |
|---:|---:|---|---|
| 1 | 1 — signC | -0 1 0 1 | 0 1 0 1 |
| 2 | 1 — signC | -1 15055671 0 1 | 1 15055671 0 1 |
| 3 | 2 — magnitudeC | 0 -1 0 1 | 0 1 0 1 |
| 4 | 2 — magnitudeC | 0 -0 0 1 | 0 0 0 1 |
| 5 | 2 — magnitudeC | 0 -15055671 0 1 | 0 15055671 0 1 |
| 6 | 3 — signT | 0 1 -0 1 | 0 1 0 1 |
| 7 | 3 — signT | 0 1 -1 15055671 | 0 1 1 15055671 |
| 8 | 4 — magnitudeT | 0 1 0 -0 | 0 1 0 0 |
| 9 | 4 — magnitudeT | 0 15055671 0 -170141183460469231731687303715884105727 | 0 15055671 0 170141183460469231731687303715884105727 |

This matrix covers every token slot, both sign-token values, negative zero, the calendar boundary 15055671, and the signed-magnitude upper boundary 2^127−1.

## Acceptance conditions

1. The exact production blob and both reference blobs match their pinned Git identities and SHA-256 values.
2. All nine malformed raw inputs return exactly ["-1","-1","-1","-1","-1","-1","-1"]; no extra output token is permitted.
3. Each of the nine positive controls returns exactly seven fields and matches the independent Native reference tuple.
4. The Native job is completed/success on the exact pushed SHA; its job log, JSON receipts, artifact metadata digest, downloaded ZIP SHA-256, and ZIP CRC are checked independently.
5. This is a lexical transport contract only. It does not replace invalid numeric sign/magnitude tests, does not imply full Stage 1 acceptance, and does not authorize Stage 2 or merge.

## Execution artifacts

The dedicated workflow is .github/workflows/befunge-qa31cr-work-counts-lexical.yml. It pins the interpreter and source/reference identities, records per-case Native receipts, preserves the log and exit code, and uploads the evidence ZIP even when the job fails.
