# Stage43 / PATCH21 — inclusive reverse-ordinal correction

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Prerequisite: Stage42/DISCOVERY21 on abcffc288b32a0dcbed79458e9176dfd4fd37d19, GitHub Actions run 41214222136 completed/success, 71/71 jobs; job lua_stage42_discovery 124579998791 success; exactly 3 stdout PASS markers, exit=0, stderr empty, source locks; artifact 13048000914 (sha256:3d7f246a9fa7200ab026026daf45780bdd50f325115ea3dd5d5e7854311ec6fd).
Status: IMPLEMENTED_AWAITING_NATIVE_CI — no Stage43 PASS inferred.

## Behavior and invariant
Input is 17 caller-provided signed, sorted and validated gate records indexed -8..8 and target d in the historical Stage38 accepted domain G(-7) <= d <= G(7). For interval k in [-7,7] where G(k) <= d < G(k+1), gap = G(k+1)-G(k) in [42,963].

The Stage42 historical fifth semantic commit returns reverse ordinal excluding current day:
R_old = gap - (d-G(k)+1) = G(k+1)-d-1 (deliberately wrong).
Stage43 preserves **all five** historical semantic commits in exactly their original order and appends **one sixth** patch commit with exact signed BigInt:
R_new = G(k+1)-d = R_old+1 (today included).
Required reciprocal invariant: R_new + Stage41_corrected_ordinal = gap+1.
Never call test/normative_oracle.lua from production; the test oracle independently constructs gates and directly subtracts closing bound and requested day.

## Acceptance gates
- 15 canonical interval opening checks k=-7..7: R_new=gap, R_old=gap-1. 14 canonical final-day checks k=-7..6: R_new=1, R_old=0. The missing k=7 final-day test is intentional: G(8)-1 lies beyond the locked Stage38 accepted maximum G(7). Explicitly reject it; do not broaden old validation.
- 96 deterministic signed ~2^127 BigInt 17-gate chains with valid [42,963] gaps and target G(k+1)-1 for k=-7..6; R_new=1 and R_old=0; compare against independently calculated G(k+1)-d.
- Exactly 9 rejects for malformed/out-of-range data, including G(8)-1; 2 replay contexts independently owned, mutation isolated.
- Exactly 6 committed semantic states/trace entries, last handler PATCH; five prior diagnostics retained, no pending state or rollback; Stage42's independent historical probe remains wrong by one. No year5000, postStir12, or full calendar/date integration.
- Immutable source locks on Stage38, Stage39, Stage40, Stage41 and Stage42 legacy; syntax verification of all src/test Lua; Lua 5.3 native test with exactly three stdout markers, stderr empty, exit=0, source SHA recorded.
- Separate CI artifact containing source.txt, lua-version.txt, stdout.txt, stderr.txt, exit-code.txt, result.txt. Stage43 accepted only on completed successful workflow, job logs, artifact and SHA/source confirmation.

No main/merge/publication. Stage44 must not begin before Stage43's Native acceptance; next engineering stage is derived only after its evidence gate.
