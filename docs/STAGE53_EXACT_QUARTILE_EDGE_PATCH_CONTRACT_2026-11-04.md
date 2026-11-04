# Stage53 / PATCH26 — exact signed BigInt quarter-edge equality correction

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Locked parent: 91859ed48c951b764d09f544cf60d55bc442a1e9
Stage52 gate: run 41712123950 completed/success 81/81 on locked parent; Lua 5.3 job 126205798695 completed/success; three exact stdout PASS lines, empty stderr and exit 0 enforced in the job. Artifact 13270274651 SHA256 e691ac56b3e63790b0634c58f6b8deae4067430a2b3fb3a0e2bbed02a5b8ca3f.

## Scope and independent oracle

Input: exactly 17 ascending caller-provided signed BigInt gate records G(-8)..G(8), successive gaps 42..963; query day d in [G(-7),G(7)]. From enclosing half-open gate interval [a,b), define u=d-a and v=b-a. Q1 if 4u<v; Q2 if v<=4u<2v; Q3 if 2v<=4u<3v; Q4 otherwise. Equality at exact 1/4, 1/2 or 3/4 boundaries belongs to the right-hand bucket.

Stage52 intentionally used <= (sticky previous) at the three boundaries. Preserve its source and 15-commit historical trace. Stage53 validates authenticated Stage52 context, then adds a 16th semantic commit with corrected label and non-aliased Stage52 snapshot. Keep Stage49-51 owned snapshots and the exact Stage51 midpoint patch intact. Production uses signed BigInt add/sub/compare only; no division, floating point, GCD, normalization, test fixture import, year5000, postStir12, public sixth field or full calendarDate. The test-only independent oracle computes (4u)//v and modulo using bounded native integers after subtraction of arbitrary large signed BigInt endpoints.

## Measurable acceptance

- Canonical 15 openings and 14 closings MATCH; all 16 semantic commits in exact order.
- 96 alternating signed near-2^127 streams, gaps divisible by four: 288 exact quarter-edge Stage52 EXPECTED_RED cases repaired in Stage53, plus 576 immediate flank MATCH witnesses.
- Nine malformed/out-of-range rejects, two isolated replays with distinct owned contexts, old Stage52 probe still reproducing its controlled diagnostic and historical source SHA locked.
- GitHub Actions native Lua5.3 CI: 82/82 jobs success including lua_stage53_patch, 15 historical SHA source locks, luac on all src/test Lua files, test bounded by 1200s, precisely three PASS stdout lines, stderr empty and exit 0, six evidence files with artifact SHA256.
- Do not mark Stage53 accepted before run/job/log/artifact verification. No manual rerun of prior accepted runs, no merge/main/protected branch change/publication.
