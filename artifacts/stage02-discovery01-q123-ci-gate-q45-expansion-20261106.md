# Stage02 DISCOVERY01 — completed q1/q2/q3 CI gate review and q4/q5 research extension

- Date: 2026-11-06; project: `PC-BRANCH-WAT-SPANISH`; branch: `WAT+Español`.
- Exact source HEAD assessed: `ad380512347e395653f9273bf016506447272123` (not an assumed later HEAD).
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42188933068 — attempt 1 `completed/success`.
- verify job https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42188933068/job/127795863082 — completed/success, checkout logged exact SHA.
- semantic job https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42188933068/job/127795863415 — completed/success, checkout and `git rev-parse HEAD` exact SHA.
- CI WAT SHA256: `dd2f35af383093c38d70e22a728b41f89c10fbffbff35291b138b4a764057d41`.
- WABT installed; Node WebAssembly native: **57/57** isolated exports succeeded; **29** independent BigInt numeric target checks succeeded as enforced by runner assertions.
- Independent Python q1/q2/q3: **252,230** small-model input/direction pairs across 45 odd moduli; **643,180** simulated rejections; zero mismatches; six production-size algebraic cases are expressly **not Python Native**.

## Scope of gate decision

The bounded q1/q2/q3 differential gate is **ACCEPTED by the completed CI evidence above**. The original `STAGE02_DISCOVERY01_CONTRACT.md` criterion 5 expressly requires expansion if the initial probes pass, and prohibits closing Stage02 on these results. Thus **overall Stage02 remains OPEN / READY, not ACCEPTED**; there is no reproduced historical defect or `EXPECTED_RED`. The unavailable historical Stage02 ZIP has not been reconstructed. No main merge or release.

## Next independent expansion: short-route q4/q5

New oracle: `tests/stage02_short_q45_extension_oracle.py`. It is a **math-only** bounded QA extension. For all odd `m=11..99`, every `n in [1,m]` such that `floor(m/n)` is 4 or 5, all starting states `first in [1,m]` and both `step=-1,+1`, independently step through the ring `[1,m]` until the first `x<=floor(m/n)*n`. Compare both accepted state and one-based rank against a separately expressed arithmetic candidate; bound rejected steps by `m`. Independent of other branches.

Measured in a separate local Python execution before commit (not Native):
- q4: 119 distinct `n` values across models, **16,162** input/direction pairs, **8,548** rejected positions.
- q5: 87 `n` values, **11,538** input/direction pairs, **4,264** rejected positions.
- Combined: **27,700/27,700**, **12,812** rejected positions, **0 mismatches**; maximum 19 rejected steps. `py_compile` succeeded.
- 16 production-size mathematical fixtures for `M=2^127-1`, `n=M//(q+1)+1`, boundary `first=1,L,L+1,M` and both directions. These cases are **not WAT/Native verification**. Values are reported as exact integers.

The CI workflow calls the new Python oracle independently of the existing seven Python checks and 57 Node/WAT tests. The new CI run on the follow-up commit must be inspected and counted only after `completed` job logs and SHA corroboration.

## Next bounded implementation contract (within DISCOVERY01, not a new stage)

Add production-size WAT short-route q4 and q5 fixtures with independently calculated exact memory fields `N, FIRST, CUR, LIMIT, RESULT` and both wrap directions. Preserve all previous 57 Native exports, 29 numeric checks, and named locks. Scope at least two new Native cases per quotient and a matching exact BigInt comparison; enforce deterministic totals in the runner. Require 30-second timeout per export, `wat2wasm` parse, local oracle gate and completed verify/semantic CI at exact checkout SHA. Do not treat mathematical-only findings as Native PASS, and do not invent a defect absent an observed reproduction.
