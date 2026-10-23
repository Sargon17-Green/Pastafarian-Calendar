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

**Post-certification defect (fixed and subsequently CI-verified):**
Boost's `cpp_int{decimal_string}` constructor uses octal for some
leading-zero strings (`010` becomes 8; `0008` throws), despite the
adapter's input validation accepting decimal digits. The adapter now
accumulates every digit in radix ten using multiprecision arithmetic.
The native workflow exercises both positive digit 8 and negative
leading-zero representations, comparing equivalent pairs with
canonical decimal spellings on GCC and Clang. This is a transport fix,
not a change to the calendar engine. It passed exact-SHA CI at
`888b54fc5a136144b565c39f09b8f9106a91e2bd` (native run `39552852053`, full run `39552851947`).

It does not alter `src/monster.cpp`, `main`, the normative Oracle or Stage 57.

## Independent streaming comparison against pinned Celeritas

A candidate machine-readable descriptor is available at `integrations/cpp-latina-soak.json`. The cross-implementation workflow now compiles the branch's independently authored `tools/soak_vector_adapter.cpp`, extracts identical `(id,c,t)` tuples from pinned Celeritas reference output, submits them through the actual stdin/stdout streaming protocol, and compares **all eight fields byte-for-byte** in five shards (30 pairs total). Timing logs and mismatch diffs are saved as artifacts. This does not run or replace the central all-implementation soak. The exact-SHA CI at `5d33499c9a89e3ddb8c5b1470e91eb8dc5f0cae8` is now completed successfully: workflow `39762381145`, six jobs success, V1 and adapter streaming comparison 30/30 PASS.


## Language-neutral canonical numeric protocol (V2)

V1 is retained unchanged for compatibility. Use `--schema-canonical` to print `PASTAFARI_SOAK_CANONICAL_V2`; run with `--canonical-indices` (optionally `--timing-ns`). Each input `request_id<TAB>c<TAB>t` produces eight TSV columns: request ID, c, t, year, **canonical cutlet index (1..17)**, day in cutlet, **canonical month index (1..47)**, day in month. Unlike V1, the two name columns become pure decimal integers. This is the recommended transport for the central cross-language comparison.

The adapter resolves each name returned by the existing public calendar API against unique, frozen `canonicalIndex` entries in `include/pastafari/source_language_catalog.hpp`. A missing or ambiguous match is an explicit nonzero failure; fuzzy name matching is forbidden. The calendar engine remains unchanged. `tools/validate_soak_index_modes.py` checks all eight V2 columns against V1 and the 17+47 frozen source names; GCC, Clang and the pinned Celeritas comparison use this check. **V2 is certified at exact tested commit `5d33499c9a89e3ddb8c5b1470e91eb8dc5f0cae8`**: native adapter workflow `39762381242` (GCC/Clang, canonical numeric 3/3 and 4/4 each, cross-compiler pass), cross-implementation workflow `39762381145` (V2 30/30 PASS), and full Stage 56 workflow `39762381184` (20/20 success, 8/8 repeated soak, SOAK_GREEN). This documents a tested snapshot, not a claim that the future global multi-implementation soak has run.

## Scheduler-facing machine-readable preflight

After building the native adapter, a central scheduler can run:

```sh
python3 tools/soak_global_preflight.py \
  --manifest integrations/cpp-latina-soak.json \
  --adapter ./soak-vector-adapter
```

The preflight prints exactly one JSON object on stdout and exits nonzero if
`ready` is false. It checks both schema declarations, the V2 manifest fields
and invariants, two equivalent signed decimal requests including leading
zeros, output row ordering and numeric bounds, stderr per-row nanosecond
records, and fail-closed rejection of a malformed request. It does not certify
that the checked binary came from the manifest's verified commit, compare
against another calendar implementation, or run the global soak. These are
separate duties of the central scheduler; the `engine_verified_commit` field
is an anchor, not a runtime attestation. Do not treat a successful preflight
as evidence of full cross-implementation equivalence.
