# C++&Latina: native adapter for a future global soak

Status: Stage 56 integration helper. Not a new calendar implementation or approval of Stage 57.

Build: g++ -std=c++20 -O2 -Iinclude -Itests -I. tools/soak_vector_adapter.cpp src/monster.cpp -o soak-vector-adapter

Contract PASTAFARI_SOAK_TSV_V1: send request_id, calculation_day_c, target_day_t as three TAB-separated ASCII columns per line on stdin. c and t are signed unbounded decimal integers (boost::multiprecision::cpp_int); request IDs use [A-Za-z0-9_.:-]+.

Each successful input yields one stdout TSV row, in the exact original order: request_id, c, t, year_number, C++ std::quoted(cutlet_name), day_in_cutlet, C++ std::quoted(month_name), day_in_month. All eight columns are retained; five are the public date tuple.

Command --schema emits a deterministic version banner. Optional --timing-ns writes per-request elapsed nanoseconds as SOAK_TIMING_NS TAB id TAB value to stderr; stdout remains the canonical result stream.

Fail-closed: malformed lines, invalid integers, missing input, and calendar exceptions cause a nonzero process exit and a SOAK_ADAPTER_ERROR diagnostic on stderr. Previously emitted rows are diagnostic only: a failed shard is never certified. No heavy computation is omitted. Timeouts and performance-based scheduling belong to the central harness.

Native GCC and Clang workflow compiles the branch's public calendarDateSpaghetti API, tests three requests, compares repeated output for identical c,t, rejects malformed input, and compares outputs across compilers.

Baseline before adapter: aa129c8076b82361ae8107603ba6c9c6c97ebc18, complete 20/20 SOAK_GREEN (run 39411197744); native code is identical to code commit 0ae153157052ac221a718fcc15a19a6b0697b7c1; pinned Celeritas 30/30 pass (run 38897361174). None constitutes the future global multi-implementation soak.

The original adapter at SHA `2c314114063807057d0e469352ffa824650ae10e` passed
[39545723842](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39545723842):
GCC and Clang native stream tests; the same SHA passed the full Stage 56
[39545723761](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39545723761):
20/20 GREEN, 8/8 repeated soak, SOAK_GREEN.

**Post-certification defect (fixed here; new exact-SHA CI pending):**
Boost's `cpp_int{decimal_string}` constructor uses octal for some
leading-zero strings (`010` becomes 8; `0008` throws), despite the
adapter's input validation accepting decimal digits. The adapter now
accumulates every digit in radix ten using multiprecision arithmetic.
The native workflow exercises both positive digit 8 and negative
leading-zero representations, comparing equivalent pairs with
canonical decimal spellings on GCC and Clang. This is a transport fix,
not a change to the calendar engine. Do not claim its success before
new CI passes.

It does not alter `src/monster.cpp`, `main`, the normative Oracle or Stage 57.

## Independent streaming comparison against pinned Celeritas

A candidate machine-readable descriptor is available at `integrations/cpp-latina-soak.json`. The cross-implementation workflow now compiles the branch's independently authored `tools/soak_vector_adapter.cpp`, extracts identical `(id,c,t)` tuples from pinned Celeritas reference output, submits them through the actual stdin/stdout streaming protocol, and compares **all eight fields byte-for-byte** in five shards (30 pairs total). Timing logs and mismatch diffs are saved as artifacts. This does not run or replace the central all-implementation soak. This new workflow requires a fresh, exact-SHA CI result before claiming its new gate as PASS.
