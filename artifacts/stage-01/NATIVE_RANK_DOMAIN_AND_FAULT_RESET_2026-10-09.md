# Stage 1 — Native rank-domain remediation and fault-reset evidence (2026-10-09)

## Scope and repository isolation
Canonical repository: `Sargon17-Green/Pastafarian-Calendar`.
All modifications below belong **only** to `qa-befunge98-stage1-order-isolation-20261008` and PR #17. The
`Befunge+Кыргызча` canonical implementation and `main` are **not promoted**.
`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, Stage 2 **not started**.

## Three independently reproduced rank-input defects
Native PyFunge 0.5-rc2 exposed mistakes that older zero/overflow-only
rank regression suites missed:

1. Original `reference/unrank_bounded_composition.b98` accepted rank `-1`
   (family `(5,2,1,4)`) and returned `(1,4)`.
2. Original `reference/unrank_weaving.b98` accepted rank `-1`
   (lengths `(2,2)`) and returned `(1,1,2,2)`.
3. Original `reference/unrank_distinct_names.b98` failed rank-domain
   enforcement: `(n,k,rank)=(3,2,7)`, with exactly six legal choices,
   yielded `(32,1)`, not the required `-1`. Its original `-2^127`
   input could also time out.

All three were fixed in **Befunge source**, not in Python. The first two
use native lexical signed-token scanners. The third uses a two-dimensional
native scanner followed by a **native nPk count guard**: compute the
falling product n*(n-1)*...*(n-k+1) using Funge arithmetic, reject
rank 0, negative tokens and ranks exceeding that bound, then return to
the existing reference unranking code. The rank-bearing path uses an
actual downward entry, horizontal parsing and computed `x` vector
return to the original source row. This is NOT proof of the stronger
production spaghetti acceptance criterion.

The original native references were retained, byte-for-byte, as:
- `qa/unrank_bounded_composition_pre_strict_rank_baseline.b98`
- `qa/unrank_weaving_pre_strict_rank_baseline.b98`
- `qa/unrank_distinct_names_pre_strict_rank_baseline.b98`

The QA candidates were also retained separately under
`qa/unrank_*_strict_candidate.b98`. The three promoted fixes reside
under `reference/` on the QA branch only.

## Native results proven, without Python oracle fallback

- [Run 37846463505](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37846463505):
  **13/13 jobs PASS**. The candidate rank reader passed 182 native
  invocations across nine bounded-composition, weaving and distinct-name
  families; legal lexicographic outputs were checked against the
  immutable native pre-fix references.
- [Run 37846769525](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37846769525):
  **13/13 jobs PASS**, following promotion of all three candidate sources
  to the QA branch's reference files. Native adversarial corpus remained
  PASS: 182 invocations.
- [Run 37847108651](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37847108651):
  added a fourteenth job, `native-same-program-fault-recovery`.
  Its **nine native before/after g/p injection + explicit Program reset
  and replay scenarios all passed** (job `113550609116`).
  This verifies exact same object identity, new Funge-space/semantics/I/O
  instances after explicit reset, retained dirty-space immutability, and
  independent native CLI output parity.
  The **whole 14-job run must be checked independently**; the fault job
  alone is not a blanket 14/14 claim.

All expected calendar outputs in these checks originate from original
native Befunge references, not Python calendar calculations. The QA
Python runner is an execution, observation and comparison harness only.

## Mandatory gates still OPEN

- `FULL_FUNCTIONAL_QA_PASS=NO_FINAL_ACCEPTANCE`
- `GEOMETRIC_SPAGHETTI_QA_PASS=NO` — ten native arithmetic-route samples
  showed two distinct across-input forks, one join, zero nodes both
  fork and join, and no executed mandatory advanced control-operator set
  sufficient for full architecture acceptance.
- `SEMANTIC_STATE_OWNER_VALIDATED=NO_FINAL_AUDIT`. Explicit reset after
  injected exceptions is now proven in a bounded corpus; unreset
  in-place recovery and all semantic owner cases are NOT proven.
- `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`; no Stage 2 and no merge.

This is evidence and a preserved checkpoint, not a claim of Stage 1
completion.
