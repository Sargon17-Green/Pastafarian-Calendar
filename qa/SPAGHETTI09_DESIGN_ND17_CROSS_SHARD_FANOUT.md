# Spaghetti 09/12 — design-only research, fan-out and multi-provenance assembly

Status: **DESIGN ONLY**; not Native tested, not implementation, not Stage 2.
Immutable proof parent: QA08 source blob
`4ba6902de08cf9483374f43a33f1d4ae7a14e3f6`;
green Native workflow 39040932851.

The next QA experiment should replace QA08's single-worker/single-parent
barrier with **several real, independently scheduled instruction pointers**
and a nontrivial 17-dimensional dependency graph. It must preserve the
exact observable results and 17D movement of the fully accepted QA08
parent before expanding the instruction schedule.

Proposed topology: a coordinator IP spawns two disjoint worker classes
using separate native Funge-98 `t` forks on distinct hyperplanes.
Each worker maintains its own cloned stack and at least two `{`/`}`
frames, uses `u` between frames, and writes *different* residue shares
to nonoverlapping 17D source cells. Each share's write must happen
strictly before that worker's independently addressable completion flag;
the coordinator must poll **all** flags, not one. A third worker may be
spawned from one of the workers, provided parent/child ownership and
gate-ready ordering are unambiguous and reproducible.

The coordinator joins by reading physical Funge-space cells, not by
asserting that independent thread stacks somehow merge. It builds a
cross-product of residue shares and earlier QA06-derived data, then
**creates a multi-instruction subprogram** on not-yet-executed 17D
coordinates. The future source must contain hostile `@` or `q` traps
and the real Funge++ program must install the complete byte sequence
before entering the relevant hyperplane. Target >48 emitted source
instructions, with several instruction families, control-flow
edges and outputs which depend jointly on at least two worker
shares. A well-tested compiler should avoid the static, short
`0$>`/`:$>` alternation becoming its only executable product.

Acceptance is deliberately demanding:
(1) exact-head source and executable pins; (2) 2D QA06 and 17D QA07/08
independent Native source receipts; (3) at least two healthy, different
branch seeds; (4) repeated Native runs in both cooperative and
OS-thread modes where supported, with an explicit deterministic
ownership proof; (5) event-level witness of every worker physical
`p`, flag `g`, compiler `p`, and later opcode execution;
(6) source-trap masking; (7) disjoint worker-shard sabotage, IP
fork suppression, under-stack transfer suppression, and per-axis
negative controls; (8) preservation of historical RED attempts;
(9) no production changes, no Stage 2, no merge of PR #17.

The Funge++ engine's cooperative scheduler has proven correctness
for QA08, but other scheduling modes and deeper branching may expose
races; never infer a concurrency proof solely from stable numeric
outputs. Start with minimal isolated, source-pinned thread fixtures
before integrating the large calendar-adjacent QA sidecar.
