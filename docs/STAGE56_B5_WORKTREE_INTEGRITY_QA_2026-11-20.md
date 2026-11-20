# Stage56 B5 checkout-byte integrity QA — 2026-11-20

PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: PHP+Bahasa-Melayu
Parent: f8d2468cf773cebfe9d1b66df67c56b9566a2ca5
Scope: read-only QA gate and canonical CI, **not** a production-year profile.

## Reproduced pre-patch gap
The earlier source-binding audit compared independently pinned SHA-256 values to bytes retrieved by `git show COMMIT:PATH` and required `HEAD == COMMIT`, but did not compare those bytes to the active checkout. In a fresh synthetic Git repository, editing `src/YearStructureProvider.php` after commit left the pinned Git blob unchanged, so the original Git-only checks still passed. This is a verified checkout-integrity gap, not evidence of tampering in production.

## Patch and bounded proof
The audit now rejects missing, symlinked, or byte-divergent working-tree provider/anchor files while preserving exact Git-object and out-of-band-pin checks. It checks each path segment for a symlink and compares the working bytes to independently supplied SHA-256 pins. Two new synthetic dirty-worktree negative cases run cross-platform; two additional symlink negative cases run only on POSIX. Thus the suite is 19/19 on Ubuntu and 17/17 on Windows, preserving the previous 15 cases. The source audit remains read-only and its self-test uses an isolated temporary Git repository.

The existing canonical B5 job adds Python compilation and source-binding self-test with a 60-second external timeout. Exit values and stdout/stderr are captured in the SHA-bound B5 artifact; any failed compile/test or nonempty stderr fails the job. Original PHP 8.3/64-bit B5 gates (3 lints, 16 structural preflight, 12 negative CLI) are retained. Verify the automatic push run on the new SHA before claiming new Native CI acceptance.

## Strict scope limit
These checks prove only committed/checked-out byte consistency, not canonical origin, policy authorization, provider correctness, or year-generation fidelity. No authenticated production `YearStructureProvider`, Year5000 canonical anchor, or 4999/5000/5001 actual-year export was established by this patch. Do not substitute synthetic self-test fixtures or treat this patch as Stage56 full acceptance. No main/merge or PATCH22/PATCH23 integration.
