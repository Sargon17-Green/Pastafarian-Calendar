# Chapel 4244 nonmedian near-neighbor research contract

Project: PC-BRANCH-CHAPEL-UKRAINIAN. Branch: Chapel+Українська-мова.
Research only: no Stage 6 acceptance, production, main, merge or release.

## Input and exact mathematical target

The existing month-length vector contains 45 months and 4244 symbols.
Let R be the exact legal-word count (22470 bits; SHA256 of unsigned
big-endian R is 925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da).
New targets are rank0 = floor(R/2)-1 and floor(R/2)+1, not the
already-accepted median floor(R/2). Rank order is canonical ascending
month IDs, with strictly ascending first and last occurrence positions.

## Implementation boundaries

The existing Chapel research probe adds bounded unrank-only --rankDelta=-1|0|1;
zero is backward compatible. Rank consumes the full witnessed word and must
return the exact target rank, not a delegated claim. Each target has two
separate source-fresh Chapel 2.10.0 OS-supervised processes (unrank then rank).
No partial, timed-out, nonzero-exit or RSS-overrun process is PASS.
Each direction: wall <=180 seconds, maximum RSS <=524288 KiB, exit=0.
No accepted median invocation is made by the nonmedian runner.

## Independent oracles and output

Every completed word must contain exactly 4244 symbols with the locked
multiplicities and FIFO first/last positions. An independent Python dense
prefix counter validates twelve canonical checkpoints per direction, thus 24
per target / 48 total. A second Python/GMP sparse state machine computes the
entire lexical rank of each Chapel witness; equality to the exact target is
mandatory. The roots are compared by numeric value and SHA256. Canonical
stdout must have an unambiguous complete marker, exactly twelve checkpoints
and exactly one full word. Save command JSON, stdout/stderr, /usr/bin/time,
sampled peak RSS, process exit codes, Chapel binary SHA256, Git source SHA,
per-pair validated JSON and a research-only outcome. Static mutation tests
must reject malformed/truncated/changed evidence without Native acceptance.
False or missing evidence fails; incomplete resource attempts are inconclusive.

## CI and scope

Branch-only independent diagnostic in canonical-names-lock.yml, after
the preexisting median probe; no duplicate manual dispatch. Auto push CI
may rerun the median on a NEW commit SHA, but the new runner never reuses the
accepted median as a nonmedian proof. Existing legacy GateOracle 180s
timeout remains an independent inconclusive condition, never a correctness
counterexample. Stage6 is NOT_ACCEPTED regardless of this research gate.
