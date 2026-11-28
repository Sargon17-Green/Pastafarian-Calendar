# Stage 4 — Discovery 02 implementation

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Baseline: aa645f555d8444996565d28f7f34ad802fe606be
Date: 2026-11-28
Contract: test/DISCOVERY02_DAY_TAG_PREIMPLEMENTATION_CONTRACT.md; prior ordinal correction accepted in baseline. Original prompt sections 5, 9 and Appendix B authorize Discovery 02 as stage 4, separate from Patch 02. Prior user authorization recorded in pre-implementation contract.

Introduces only oldDayTag and invocation-owned dispatcher. No corrective code. All previous production, oracle and canonical CI jobs unchanged. Seventeen independently derived literal inputs/raw/rank predictions (rank-inverse checked by the new QA); 9 predicted RED, 8 predicted matches, 8 mirrored collisions, zero at foundation, two isolation/reuse checks and exact dispatch metrics. These are predictions until completed Native evidence. New dedicated push workflow locks exact commit, compiler, source hashes, compile/native exit, stdout/stderr, 30s/1GiB native cap, manifest and always-upload artifact. No manual dispatch, no merge/main/release. LAST_COMPLETED_STAGE=3. Native not observed at implementation time. Acceptance requires review of actual run/job/log/artifact and all prior canonical regressions. No Patch02.
