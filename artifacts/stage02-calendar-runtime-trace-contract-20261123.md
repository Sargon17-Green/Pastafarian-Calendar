# Stage02 integrated calendar runtime trace — QA contract (2026-11-23)

PROJECT_ID: PC-BRANCH-WAT-SPANISH
Branch: WAT+Español
Parent: 57c1711fe36634ce71c61b813ddd8ebf1ea47628
Original calendar Git blob: 70267bb5730678f81d6138a2224d6b8d9a193eb8
Original isolated selector Git blob: e23f013ab96b498b0ac365dbb1b25273c845e790

This is a QA-only runner and Actions workflow. It does NOT edit the canonical calendar or isolated selector source. The runner creates an instrumented copy at run time; only hooks for year selectors, all seven structure selection call sites, and gate-gap choose_922 are inserted. The original Git blob must match before instrumentation.

Runtime instrumented callback snapshots (bowl, seal, N, first, direction, rank), before temporary memory is reused. A separately authored JavaScript BigInt rank oracle applies M=2^127-1, minimal k with M^k >= N, independent mixed-radix first/step expansion, rejection limit=floor(M^k/N)*N and one-based rank mapping. Each observation is checked for exact equality and trace order is retained. The callback treats both original small-n and calendar-local wide selectors, not isolated tests/normative_selector.wat.

Cases: foundation calculationDay=targetDay=-15055671; future targetDay=-15049671; past targetDay=-15061671 (same calculationDay). These are diagnostic probes; navigation coverage is established ONLY by observed seals 11/12, not inferred from the labels. The foundation tuple [5000,10,949,3,54] comes from the locked WAT's existing test fixture and is ONLY a regression assertion, not an independent calendar five-field oracle. The remaining cases record five fields without an independent five-field assertion. Any runtime mismatch, missing traced family, trap, tool failure, or timeout is an actual incomplete/failed QA result, not an expected-red. There is no claim that these three probes cover every extreme rank or every attainable N.

Required provenance: GitHub run, attempt, exact checkout SHA, original Git blob, sha256 for original/test/copy/wasm, tool versions, Native log, JSON trace, exit code, artifact ID/hash. The workflow uploads partial evidence also on failure. Only a completed run, successful job, checked log and inspected artifact can justify a Native PASS claim.

Existing Names47 acceptance is not rerun. This does not verify historical Stage02 ZIP/manifest provenance; Stage02 overall NOT ACCEPTED. NEXT after observed completed run: isolate any failure or gather actual coverage; independently derive complete five-field tuple from canonical calendar rules before overall acceptance. No main/merge/release.
