# Stage49 / PATCH24 — exact zero-based gate-phase numerator

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Locked parent: ee5b308d4ebbb3cc383c844646f15d463db0dfb0
Stage48 gate: [run 41409258404](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41409258404) completed/success **77/77** jobs; Lua 5.3 job 125175308655 completed/success with exactly three expected-RED stdout markers, empty stderr, exit 0. Evidence artifact 13127451092, zip SHA256 d75511ca9957c804132cdfe212ebfc9146ad9fc6c971071ee87f8bce01ef23f6.

## Exact input/output and independence
Input: exactly 17 strictly increasing caller-provided signed BigInt gate records G(-8)..G(8), adjacent gaps [42,963], query d in [G(-7),G(7)]. In its interval a=G(k) <= d < b=G(k+1), output exactly the unreduced decimal string "(d-a)/(b-a)", with zero-based numerator and exact denominator. The output is a *diagnostic fraction*, not a sixth public calendar-date field. No floating point, GCD, year5000, postStir12, or full calendarDate.

The authenticated Stage48 11-commit historical path returns "(d-a+1)/(b-a)" and remains unchanged, callable, and EXPECTED_RED. src/gate_phase_patch.lua validates its 11 commits, one-based provenance, source metric, and immutable owned snapshot; subtracts exactly one from the historical numerator with BigInt; dispatches the 12th semantic commit and records its own metric, diagnostic, corrected decimal values, and snapshot. Production must not require the normative oracle or any test fixture.

## Acceptance gates
- Independently computed raw-endpoint oracle: 15 openings, 14 midpoints and 14 closings, 43 corrected vs historical EXPECTED_RED witnesses; 12 ordered semantic commits.
- 96 signed near-2^127 synthetic BigInt gate streams with even gaps [42,962], all corrected against the raw-endpoint oracle and historical off-by-one result.
- Nine malformed/out-of-window rejects, two independently owned replays, historical Stage48 source unchanged and auditable, no normative oracle in production.
- Native Lua 5.3 CI: 11 historical source SHA locks, luac validation across src/test, timeout 1200s, exactly three stdout PASS lines, exit 0, empty stderr, six evidence files (source, version, stdout, stderr, exit, result) and SHA256 artifact.
- Acceptance only with **78/78 completed/success** jobs including lua_stage49_patch, matching run SHA, job logs and artifact. Queued/in_progress is never PASS or a blocker.
- No main/merge, year5000, postStir12, full calendarDate, or sixth date component. Future stage is not opened by this contract.
