# Stage45 / PATCH22 — exact nearest-boundary midpoint tie repair

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Prerequisite: Stage44 run 41239133158 completed/success, 73/73 jobs, Lua5.3 job 124668969379 completed/success, exactly three expected stdout PASS markers, exit=0, stderr empty, 6 frozen source locks; artifact 13058634525 sha256:5068ed0eadbb0bc8dea3d727d59ed7087a40aab7f965ffd682561392ca7dbf7e; HEAD verified 3f3797de09f93b8bd8cd51800bb08dd4abbecc7b.
Status: IMPLEMENTED_PENDING_NATIVE_CI — do not claim Stage45 PASS until its own completed job/log/artifact.

## Contract
Inputs: 17 caller-provided signed validated gate records G(-8)..G(8), monotone gaps 42..963, target d in locked Stage38 accepted range G(-7)..G(7). For k=-7..7, G(k)<=d<G(k+1). Outputs: string "OPENING" or "CLOSING" plus owned eight-commit diagnostic context; never calendarDate.

Stage44 deliberate bug: ordinal_onebased = d-G(k)+1, remaining=G(k+1)-d; historical returns OPENING when ordinal_onebased<=remaining, otherwise CLOSING, making even-gap midpoints wrong.

Patch22 uses two exact signed BigInt distances L=d-G(k), R=G(k+1)-d and returns OPENING iff L<=R, otherwise CLOSING. At equality, OPENING is mandatory. Validate historical output and provenance before adding exactly one eighth semantic commit; retain all seven Stage44 commits, diagnostics, metrics and independent historical probe. No production normative_oracle import.

## Measurable Native acceptance
- Canonical: 15 opening checks k=-7..7, 14 midpoint probes and 14 final-day checks k=-7..6. Midpoints with even gap must repair historical CLOSING to OPENING; odd gaps retain historical OPENING. Do not guess the count of even canonical gaps.
- Differential: 96 independent signed ~2^127 BigInt gate chains with even gaps 42..962; midpoint historical CLOSING, patch OPENING, test-only oracle independently compares L to R. Inputs do not come from outputs.
- Robustness: 9 malformed/out-of-range rejects, including G(8)-1; two independently owned replay contexts with mutation isolation; exactly 8 ordered commit tokens/diagnostics, no pending state or rollback. Preserve locked Stage38 range.
- CI: source SHA locks for seven historical modules, all src/test Lua files syntax-checked in Lua 5.3, three exact stdout markers, stderr empty, exit code 0, timeout bounded to 1200 s and job to 35 minutes. Independent six-file evidence artifact with source, runtime, stdout, stderr, exit code, result.
- Gate: a completed/success GitHub Actions run containing new job lua_stage45_patch and evidence artifact on matching source SHA. No Stage46 or PASS before those observations.

Scope exclusion: main/merge, year5000, postStir12, calendarDate, external publication.
