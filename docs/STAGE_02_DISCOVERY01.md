# Stage 2 / DISCOVERY01 — విస్తృత ర్యాంక్ ఎంపికలో పరిమితి లేని నడక

## Scope and evidence boundary

This is a bounded, Ada-only discovery probe against the existing test-only
`Normative_Oracle.Choose_Rank_Wide` implementation. It does not modify the
normative algorithm, production bootstrap, language catalog, or Stage 1 fixtures.
It does **not** establish that this input is reachable from `Ask_Bowl`.

## Source-level counterexample

Let `M = 2**127 - 1` and `Space = M*M`.
Construct the public `Answer_Stream` value
`First = M-1, Direction_Step = -1`, and request
`N = floor(Space/2)+1`, which is greater than M.

The two stream digits are `M-1` and `M-2`. Thus, the wide
candidate is `W = Space - 2*M - 1`.
Because `Space/2 < N < Space`, the code's acceptance limit equals
`L = floor(Space/N)*N = N`.
The existing `while W > L` loop subtracts exactly one per iteration,
without wrapping before reaching `L`: it needs `W-L` iterations.
This number has 77 decimal digits, far beyond any practical bounded
runtime. This is a liveness/performance defect at the public selection
interface, not an observed native calendar-output mismatch.

## Native discovery probe

Run `sh ./run_stage02_discovery01.sh` in a GNAT Ada 2022 environment.
The test checks 8 exact-integer properties and computes `W-L` directly;
it deliberately does not invoke the pathological `Choose_Rank` loop.
No timeout or CI runner needs to wait for the bad loop.

## Acceptance and next action

Discovery01 is evidenced only when the Stage 2 native job succeeds on
the exact commit SHA. The discovery does not authorize changing the
normative oracle: any optimization must preserve the exact stream and
rank semantics, and must be guarded by a separate bounded differential
test. Prior Stage 1 native green remains a distinct gate.
