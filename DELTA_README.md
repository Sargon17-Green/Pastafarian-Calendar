# DELTA README — canonical saved-sum CI follow-up R2

Repository: `Sargon17-Green/Pastafarian-Calendar`  
Branch: `Celeritas-per-Sepulcra`  
Exact base / observed HEAD: `1f4ab5e001d7578093846dc4cae981aa21654538`

This is an **incremental overlay** on top of the already-uploaded canonical saved-sum correction. It does not modify `src/monster.cpp`, `include/pastafari/monster.hpp`, or the regenerated hot seed / almanac files.

Apply only to the exact base HEAD above. Copy the repository-relative payload over the branch checkout. There are no deletions, so no `DELETE_PATHS.txt` is present.

R2 repairs stale CI assumptions exposed after the semantic correction:

- HTTP and acceleration witnesses are updated to canonical saved-sum outputs.
- The Patch40 probe retains deterministic direct shortcut tests and stops treating an obsolete raw-sum public-path witness as mandatory.
- The 10,000-pair comparison uses an independent saved-sum oracle as semantic authority; the historical `C++&Latina` executable remains only a performance/cross-check baseline.
- Historical baseline pathological shards 44 and 83 are remapped while preserving 10,000 unique `(c,t)` pairs.

See `CANONICAL_SAVED_SUM_CI_FOLLOWUP.md` for observed CI failures and the exact local verification performed.

No commit or push was performed while preparing this delta. No `HANDOFF_*`, `.git`, build products, editor files, or unrelated generated artifacts are included.
