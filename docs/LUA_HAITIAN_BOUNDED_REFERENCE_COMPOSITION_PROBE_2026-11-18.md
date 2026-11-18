# Lua/Kreyòl ayisyen — bounded reference composition instrumentation (2026-11-18)

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Base HEAD: `d50aa4d22550adcf16992d21af3ec323195e9ead`  
Source lock: `test/normative_oracle.lua` blob `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`.

## Decision and bounds

The read-only `test/lua_haitian_bounded_reference_composition_probe.lua` implements the reference's two recurrences in separate, guarded probe functions: (remaining days, remaining composition slots), and (remaining month-length vector, last opened, last closed). It does not modify/import the reference algorithm for instrumentation, and calls the unmodified reference only on demonstrably tiny test cases for differential comparison.

Each recursive entry/transition checks Lua heap consumption via `collectgarbage("count")` (limit **128 MiB**) and process CPU time via `os.clock()` (limit **60s**). Every new memo key is reserved before descending, with a hard cap **20,000** total entries per case. The CI process is also externally killed at 60 seconds total and constrained by Linux `ulimit -v 131072` KiB virtual address space. The external limit includes the process, not just Lua heap; the interior check is the heap-specific guard.

## Self-tests and acceptance

Ten test assertions:
1. Three bounded composition cases (including impossible and uniquely feasible cases) compared to the frozen normative oracle.
2. Two small month-weave counters compared to the frozen normative oracle.
3. State-limit abort independently for composition and weaving.
4. Heap abort.
5. CPU-time abort.
6. Both real F0 lengths 4244 and 4358 are rejected at static admission before invoking either recurrence.

CI must show `REFERENCE_COMPOSITION_BOUNDED_SELFTEST_PASS: 10/10`, `F0_PROFILES_NOT_EXECUTED: 2/2`, zero exit, empty stderr, source lock, recorded stdout/stderr/exit/sha256 and artifact. Until completed CI logs prove these, all checks are **NOT_VERIFIED**; a file commit is not a pass.

## Scope boundaries

Small differential compositions are **synthetic feasibility checks, not full canonical date witnesses**. The real F0 witnesses still fail the policy gate before month computation. F1 is an interface design, F2 evidence remains synthetic; Stage55's successful native tests do not imply a complete `calendarDateSpaghetti` integration. No Stage56, production calendar computation, sixth field, postStir12, main, merge, or release.

## Next

After verified CI, derive a separate bounded *real-year interval discovery* contract with a hard search budget; only a short real reference year that passes the static admission gate may proceed to a composition probe. Never infer that rejecting F0 by a conservative resource policy proves real-year computation impossible.
