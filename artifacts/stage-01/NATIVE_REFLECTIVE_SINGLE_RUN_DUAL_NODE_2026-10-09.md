# Stage 1 — Native single-run reflective merge-and-fork candidate (2026-10-09)

**Scope:** QA-only, draft PR #17 in Sargon17-Green/Pastafarian-Calendar.
**Canonical target:** Befunge+Кыргызча at b70592d9c5c4a84229c846ab0ec84acb1c8df610, read-only. No merge; no Stage 2.
**Status:** A candidate, NOT yet promoted into QA src. CURRENT_STAGE=1; LAST_COMPLETED_STAGE=0.

## Exact reproducible source map

- Unmodified QA production baseline: src/interleaved_work_counts.b98,
  Git blob 44c5c33f4fe88ad82b8172235f18ad5d5175e517
- Candidate: qa/interleaved_work_counts_reflective_crossing_candidate.b98,
  Git blob 8f2cf8afef61818244747582fe7c20a74ee18943.
- Both 1,836,425 bytes, grid 1531 x 2016, with precisely FIVE byte edits,
  no source widening or shifting, and no Python calendar computation:

| (x,y) | Before | After |
|---|---|---|
| (957,1324) | space | r |
| (958,1324) | 1 | [ |
| (958,1323) | c | 1 |
| (958,1322) | x | d |
| (958,1321) | space | x |

The native upper-route IP executes c at (958,1325), enters [ at (958,1324)
from the south while heading north, turns west, executes r at (957,1324),
returns east to the SAME [ cell, now turns north, executes 1 and d,
then x jumps using (dx=1,dy=13) to the pre-existing > at (959,1334).
This preserves the arithmetic stack and the old rejoin/remaining program.

The pivot (958,1324) is *one actual executed coordinate* with:
- incoming real edges from (958,1325) and (957,1324);
- outgoing real edges to (957,1324) and (958,1323).
These edges occur in a single input execution, not only across unrelated
input traces or via a decorated, never-executed source map.

## Native evidence, distinct claims

GitHub Actions on QA commit 99c819b04d17df6f7e4fdf0c8ce68d43a7f1637a:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37909760130

The focused job native-reflective-crossing-candidate provides:
- 17/17 exact seven-value Native Befunge-98 oracle comparisons
  (14 valid, 3 invalid). 11 execute the upper reflective loop,
  6 select the lower branch without executing the loop.
- Exact source-map diff and pinned Git blob IDs.
- Actual PyFunge STEP events verifying [ executed twice with distinct
  incoming velocities, r once, and real vector landing with unchanged
  arithmetic stack depth.
- An independently coded Python 3 graph/temporal-memory auditor replays ALL
  17 raw Native traces against source plus prior p writes and g reads;
  11/11 upper cases contain the single-run dual node with in=2/out=2.
- Exact-byte sham control preserves output; replacing only the executed r
  with a space changes the bounded Native behavior (the subprocess reached
  timeout exit code 124 after 8 seconds). This is *not* a mathematical
  proof of infinite looping and is never described as one.
- The existing Native overlapping two-live-Program, actual p/g fault
  injection, explicit SAME-Program reset/replay suite was run unchanged
  against candidate bytes and PASSED, without any new shared mutable cell.

QA source remains the original. The existing production Native jobs are
not a blanket acceptance proof for promoting the candidate to src.

A historical first candidate test run failed *only in test harness*
because shutil.copyfile returns None rather than the destination filename.
Its source/oracle 17/17 had already passed; the harness bug was corrected
at QA commit b50ec808888bedafadba77fb5f7b147cbd907f6b, retaining the
exact same candidate B98 Git blob.

## Acceptance and next action

Both independent Stage 1 acceptance gates remain OPEN:
FUNCTIONAL_QA_PASS=NO and GEOMETRIC_SPAGHETTI_QA_PASS=NO.

The dual merge-and-fork and executed r properties are NOW independently
evidenced at candidate level only. Do not quietly substitute candidate
metrics for the running QA src measurements. Still missing from actual
QA production: native-executed w, _, meaningful stack-stack { } u and
full cross-input semantic state/recursive-geometry acceptance. t
concurrency and () fingerprints remain separately guarded.

Before QA src promotion, reconcile every existing pinned production test
and source checkpoint, preserve earlier Native evidence, run complete
native numerical and graph regression on the new exact src bytes, confirm
controlled mutants and fault/reset, and keep GitHub optimistic ref lease.
No edits to main or Befunge+Кыргызча and no merge.
