# Stage 4 / DISCOVERY02 — చిన్న ర్యాంక్ ఎంపికలో అనంతర నిరాకరణ

## Prerequisite, ownership and scope

Stage 3 PATCH01 was accepted for its **test-only wide-rank** change only:
GitHub Actions run 41091304089 completed 4/4 SUCCESS at
a5f26ad413a3c18bc506ef5ed4b4956a454ca44e; GNAT 13 logged
STAGE03_PATCH01_ASSERTIONS=1471. Closure commit
100a51cf88074974305c58820ea6f7efd2a5faba preserved that gate.
This independent DISCOVERY02 examines the still-unmodified
`Normative_Oracle.Choose_Rank_Short` in `src/normative_oracle.adb`.
No production code, wide-rank fix, canonical names, or Stage 1 fixtures
are changed here.

## Precise source witness (not a calendar-date claim)

Let M = 2**127 - 1 and let N = floor(M/2) + 1, so 1 < N < M.
For the public Answer_Stream record choose
First=M-1 and Direction_Step=-1. The short-rank code uses
L=floor(M/N)*N=N and checks x(k)=1+((First-1-k) mod M)
until x(k)<=L. Since the first candidate is M-1, and no wrapping
occurs before acceptance, the **first** accepted k is

    k = M - 1 - N
      = 85070591730234615865843651857942052862.

Thus the historical one-step retry loop requires more than 10**30
rejections for a syntactically valid Answer_Stream. It has not been
executed for this astronomical count. A distinct short-rank liveness
defect remains after the wide-rank Stage 3 patch. This is a
source-level, exact-integer liveness witness at the public selection
interface; it is **not** evidence that Ask_Bowl emits this stream or
that Calendar_Date returns a wrong value.

The independent numeric preflight used Python arbitrary-precision
integers and divmod: M=170141183460469231731687303715884105727,
N=L=85070591730234615865843651857942052864, and
M-1-L=85070591730234615865843651857942052862.

## API, bounded reproduction and controls

The tested API is
`Normative_Oracle.Choose_Rank(Stream: Answer_Stream; N: Big_Integer)`;
it selects `Choose_Rank_Short` because N<=M. Input domain is
1<=N<=M, 1<=First<=M, Direction_Step in {-1,0,1}. The
short-route specification is the first x(k)<=L in the cyclic
Answer_At stream followed by 1+((x(k)-1) mod N).

An **independent bounded reconstruction** `Legacy_Short_Bounded`
checks at most 64 candidates directly through `Answer_At` (never
calling the pathological `Choose_Rank`). It reports exhausted
budget for the negative-direction witness; this is the bounded
legacy **expected-red** condition, not an observed hang of the
unbounded production/oracle function. Positive control: from M-1
with +1, the accepted candidate is 1 at k=2; the real
`Choose_Rank` call is executed and expected to return 1.
An immediately acceptable candidate (First=N) also calls the real
function and must return N. A stationary rejected record demonstrates
the domain boundary without invoking an infinite loop.

The Native suite should report exactly 18 successful assertions,
compile with GNAT Ada 2022, and complete under a 10-minute CI job
timeout, normally without any long walk. The suite verifies limits,
exact witness magnitude, bounded-negative and positive controls,
and actual safe short-route calls. No large-loop expected-red
test is executed. Distinguish mathematical proof, bounded surrogate,
GNAT PASS, and completed Stage 4 acceptance.

## Test, oracle and gates

Run `sh ./run_stage04_discovery02.sh`, requiring `gnatmake`
(GNAT 13 or compatible, Ada 2022) on Ubuntu 24.04.
CI job: `native-stage04-discovery02` in
`.github/workflows/canonical-names-lock.yml`.
For Stage 4 acceptance require: (1) completed/success Native job
and verify on the exact stage-4 HEAD, (2) compile/bind/link/run,
(3) log `STAGE04_DISCOVERY02_ASSERTIONS= 18`,
(4) source witness and honest reachability limits preserved.
CI pending is neither a blocker nor PASS. A potential later PATCH02
must have its own separately reviewed exact-semantic equivalence,
bounded differential tests, gates, and new stage; no production
mutation is authorized here. Do not merge main.

## Completed Stage 4 acceptance, 2026-10-31 (Asia/Jerusalem)

GitHub Actions [41136407730](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41136407730)
completed 5/5 jobs successfully at
`43c5fc2687ecd2d711f6d5732512ebdfda0f3dc7`.
The `native-stage04-discovery02` GNAT 13 log explicitly contains
compilation, `gnatbind-13`, `gnatlink-13`, and
`STAGE04_DISCOVERY02_ASSERTIONS= 18`.
The bounded discovery and its source-level witness are ACCEPTED.
This does not verify the hostile short stream's reachability from
Ask_Bowl, nor any full Calendar_Date output. The old pathological
short loop was intentionally never executed. A later patch needs
separate acceptance gates; production and main are untouched.
