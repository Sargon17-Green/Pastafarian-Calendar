# Stage46 / DISCOVERY23 — loss of direction in signed nearest-gate offset

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Gate: Stage45 Native run 41282811370 completed/success 74/74; job 124789215381 completed/success, Lua 5.3, exactly three PASS lines, 15 opening + 14 midpoint + 14 final probes, 96 synthetic signed BigInt midpoint corrections, nine rejects and two isolated replays, seven frozen-source locks, code 0 and empty stderr. Artifact 13075827057 SHA256 3cb73ca751e5842abb09de2486e77df8ff5a9e598a0f96cbe51497636460ff90. Predecessor HEAD: 4d681c0b65959f162ded7c538b087139ece3f22b.
Status: IMPLEMENTED_PENDING_NATIVE_CI; no Stage46 PASS yet.

## Independent new behavior

Inputs: the same 17 caller-supplied indexed signed gate positions G(-8)..G(8), gaps in [42,963], query d in the Stage38-locked range [G(-7),G(7)]. The preceding corrected Stage45 nearest-gate result is OPENING when L=d-G(k) <= R=G(k+1)-d, otherwise CLOSING; ties go OPENING.

New output is a signed *decimal integer string* describing d minus its nearest gate: +L for OPENING, -R for CLOSING. Zero on a gate is exactly "0". This diagnostic is not a sixth calendar date component and does not expose calendarDate.

Deliberate DISCOVERY23 defect: the new legacy signed-offset projection discards direction, returns only positive |offset| for CLOSING; it is correct for OPENING (including midpoint ties). This is a newly introduced controlled defect, NOT evidence of a pre-existing historic bug. A later PATCH23, not Stage46, may correct it after independent reproduction.

## Acceptance contract

- Canonical: 15 opening exact MATCH, 14 midpoint MATCH, 14 final day EXPECTED_RED (closing), with nine ordered semantic commits and independent oracle from raw inputs.
- Synthetic: 96 independent signed ~2^127 BigInt gate sequences with even gaps in [42,962]; 96 closing-direction EXPECTED_RED witnesses, not generated from production results.
- Robustness: 9 invalid/out-of-window rejects (including G(8)-1), two separately owned replay contexts, 8 historical commits preserved, exact trace/diagnostics and no pending/rollback state.
- Native: Lua 5.3, source-lock 8 historical modules (including Stage45 repair), syntax-check every src/test Lua file, exactly 3 expected stdout markers, stderr empty, exit 0, bounded 1200 seconds/job 35 minutes, six-file evidence artifact with tested SHA.
- Gate: completed/success workflow on the new HEAD, expected 75/75 jobs, lua_stage46_discovery success with log and artifact. Until then, Native is NOT_VERIFIED and no Stage47 acceptance/claim.
- Exclusions: no main/merge, year5000, postStir12, full calendarDate, production oracle import, or sixth returned date component.
