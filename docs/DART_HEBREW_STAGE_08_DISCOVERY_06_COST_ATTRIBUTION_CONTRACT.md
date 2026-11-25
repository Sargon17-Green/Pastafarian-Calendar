# Dart+עברית — Stage8 / DISCOVERY06 — §V cost attribution

PROJECT_ID: PC-BRANCH-DART-HEBREW  
BRANCH: Dart+עברית  
BASE_SOURCE_HEAD: 31441f767f0aca16ae3f163406809edb47acf9e1  
MODE: Branch-only, QA-only, temporary instrumentation.  
STATUS: Candidate until exact-SHA Native CI and uploaded evidence complete.

## Why Stage8 follows Stage7

Stage7 was accepted at the restored-A HEAD. Its five paired A-versus-legacy
measurements yielded median 14,890 ms versus 14,519 ms, a 2.49% reduction.
This is a small observed difference, not proof of a material optimization.
The accepted Stage7 follow-up contract explicitly directs the next experiment
to Candidate B attribution before any speculative rewrite.

## Scope

Do not change production algorithms, production files, public APIs, selection
policy, or cache behavior. The Python runner copies the complete lib tree
into two temporary package roots. One copy remains byte-identical; the other
receives wrappers around only these existing functions:

- MonsterMonthWeavePlanner._activeChildren
- MonsterMonthWeavePlanner._unopenedFactor
- MonsterMonthWeaveCounter.countCompletions

The wrappers time the original function bodies, count calls, and record
input-state and BigInt bit-length histograms. Nested countCompletions calls
are attributed to _unopenedFactor. The metrics helper is kept under tool/ as QA support. Instrumentation wrappers
are generated only in temporary source copies; no instrumented lib/ source is
committed. No memoization or recurrence change is attempted.

## Input and measured phases

Canonical immutable input: calculation day -15055671, requested day
-15055671, zero year transitions; year 5000, 45 months, 4,244 days.
Use the accepted Stage7 planner and bowl 4 / seal 32 canonical selection.

Run the same four phases in both source copies:

1. COUNT: exact countWholeWeaves once.
2. FIRST: public unrankFull at rank 1.
3. LAST: public unrankFull at the exact final rank.
4. CANONICAL: MonsterMonthWeavePlanner.plan with the normative bowl choice.

For each phase emit elapsed microseconds and, in the instrumented copy:
call counts, inclusive elapsed microseconds for each target function,
(opened, nextActiveLength, remainingMonths) histogram for _unopenedFactor,
active-color/day histogram for _activeChildren, countCompletions origin
and state histogram, and BigInt bit-length distributions for active bases,
active children, unopened factors, and completion counts.

Timings are diagnostic only. Function timings are inclusive: a
countCompletions measurement made inside _unopenedFactor is also contained
in the _unopenedFactor time. Never add these nested timings together.

## Correctness oracle

The uninstrumented and instrumented copies must produce byte-equivalent
semantic outputs for year metadata, month-length vector, exact count, FIRST,
LAST, canonical rank/modulus and CANONICAL word.

Lock the four outputs to the already accepted Stage7 SHA-256 values:

- COUNT: c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8
- FIRST: dc2dabc1c69f5007425c032e576577195ea6cf7b1d1054a9faca74e025aaf13c
- LAST: 71b78eb2ce0c68252f404e6c6d34b52a2f8f2b834eb6a2eff687bbc6c0bccdd8
- CANONICAL: 7093c6c666dc19642d650fe7fd8a9bbe43cd12238ac4f563ebe668d370eacdda

Also validate all three full-year words independently of the profiler:
exact length, month-ID range, exact multiplicities, ascending first and last
occurrences; verify the literal lexicographic FIRST word, year 5000, exact
count above 127 bits, canonical count/modulus equality and rank bounds.
The Stage7 exhaustive small-domain oracle remains accepted evidence; this
Stage8 diagnostic does not replace or reclassify it.

## Acceptance gates

One new job, dart-hebrew-stage8-cost-attribution, on the natural push to
this branch only when the commit message contains [stage8-cost-only]:

- Dart SDK 3.13.2; Python syntax check clean.
- All 19 production lib/src/*.dart Git blob locks match the accepted
  Stage7 source; the current event SHA matches checked-out HEAD.
- Both temporary copies resolve packages and complete all four phases.
- Baseline metrics are all zero; instrumented call/state/bit-length
  histogram totals reconcile exactly.
- COUNT and FIRST preserve their expected zero-factor paths; LAST and
  CANONICAL exercise _unopenedFactor and nested completion attribution.
- All four output SHA-256 locks and instrumented-versus-baseline equality pass.
- Upload baseline.json, instrumented.json, and summary.json as the
  immutable run artifact. Acceptance requires completed/success job logs,
  exact commit SHA, and artifact; queued/in_progress is not PASS.

No manual dispatch or duplicate run. No main, merge, release, or production
algorithm change.

## NEXT after Stage8

Inspect the measured state repetition, call frequencies, elapsed attribution,
and BigInt distributions. If repeated expensive suffix states are genuinely
present, design a bounded exact memo keyed by every input affecting
countCompletions (full remaining vector plus opened/closed boundaries),
with explicit entry/byte caps, hit-rate and eviction measurements. If not,
derive and prove a recurrence or stop optimization. Do not infer that a cache
will help merely from a large call count.
