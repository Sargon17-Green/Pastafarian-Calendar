# Stage02 DISCOVERY01 — short q=2 backward liveness PATCH contract

- Project: `PC-BRANCH-WAT-SPANISH`; branch: `WAT+Español`.
- Verified pre-patch HEAD: `d3af15776cc0fc9383806106bdb90960dcf40c3c`.
- Existing WAT blob: `7de1a242bc9bc918ce0d6e07aa5fc915e5c5f9ab`.
- Scope: only `$choose_short` rejection handling, two new regression exports, runner numeric checks, bounded Python oracle and the branch's semantic CI workflow. Do not touch Stage01 catalog, main, or wide-selection logic.

## Inputs, output, invariants
For legal `1 <= first <= M`, `1 <= N <= M`, and `step in {-1,+1}`, put `q=floor(M/N)`, `L=qN`. The short selector must return `((x-1) mod N)+1` for the **first** ring value `x<=L` reached by advancing on `[1,M]`.

The rejection region is the contiguous suffix `(L,M]`. Thus if `first<=L`, retain `first`; otherwise `step=+1` reaches `1` first and `step=-1` reaches `L` first. Replacing the loop with this jump is semantically exact for both directions. Existing `divmod` and rank computation remain unchanged; runtime is independent of the number of rejected ring elements, with ordinary multi-limb arithmetic remaining.

For `M=2^127-1=3a+1`, `N=(M+2)/3=a+1`, `q=2`, `L=2a+2`. Starting from `M` and stepping backward requires exactly `M-L=a-1` rejected moves in the original code; starting from `M-1` requires `a-2`. Both must jump to `L`, returning rank `N` and retaining `FIRST` unmodified.

## Executable oracle and gates
- Independent Python enumeration of **40 small ring sizes**, `m=7,13,...,241`, `n=(m+2)/3`, all first points and both directions: **9,920 pairs**, **86,920 simulated rejected steps**. Simulate one step at a time and compare to the closed-form jump and rank; assert counters, zero mismatches.
- Algebraic checks of both production-size inputs without iterating them. An enormous theoretical iteration count is **not** treated as an observed timeout or a reproduced Native failure.
- Two new WAT exports compare `RESULT=N` and `CUR=LIMIT`; Node WebAssembly runner independently checks exact base-2^30 memory integers, including `FIRST`, `N`, `CUR`, `LIMIT`, and `RESULT`.
- Expected totals after patch: **51/51** WAT exports and **23/23** exact numeric probes; Python oracle pass; `wat2wasm` parse, 30-second per-export isolation, no traps, stderr or timeouts, exact source SHA, and both CI jobs completed/success on the new commit.
- CI `queued`/`in_progress` is not failure, blocker, or PASS. Maintain Stage02 DISCOVERY01 open until its independent final acceptance gate is met. Do not claim `EXPECTED_RED` without a reproduced failing run.

## Provenance
This is a new, independently derived patch contract, not a reconstruction of the unavailable historic Stage02 ZIP. Prior 49/49 successes remain historical evidence only; they do not count as a fresh 51/51 Native pass on the patched SHA.
