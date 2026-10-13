# Stage-56 C++ branch integration — unverified candidate (2026-10-13)

This is a **QA branch only**, not a released or certified merge.

- Target QA branch: `qa/cpp-latina-celeritas-integration-20261013`.
- Base: `Celeritas-per-Sepulcra` at `32ad50c8177233adc87eed1721c1e6f34f24ced1`.
- Second input: `C++&Latina` at `9d8063a475b0c022f078b2b180551c66e5d214d3`; source-code delta last applied at `b69fdb8534a7787a5eeb9fb6f31eaf5d11ecc6da` (the later commit updates documentation only).
- The base supplies Patches 27–39, HTTP API, canonical saved-sum calculation, acceleration mode, persistent caches and hot seeds.
- This candidate imports the atomic self-eating Stage-56 post-stir dispatcher, per-invocation FinalIntegrationHandler context reset, and the Latin branch's differential, concurrency, cache/retry, far-year, and year-structure QA workers.
- The post-stir saved-sum helper and reference files were identical at both branch heads before integration.
- `patch27AncestralHit` is explicitly reset on reused contexts.
- The standalone Stage-56 local-cache audits disable global acceleration **inside their own test processes** so local manager ownership/recovery behaviour can be tested independently. The accelerated routes remain covered by the pre-existing Celeritas soak and HTTP pipelines.
- This branch enables preflight, existing Celeritas soak and HTTP build tests on push, without enabling the large 10,000-case performance comparison at this stage.
- The timed hot-seed workflow still only schedules from the default branch: this QA branch does not fix deployment scheduling or alter `main`. Address scheduling separately after CI has certified this merge.
- New source and tests are not certified by the old branch PASS histories. Only CI results on the exact integration SHA count.
- Before merge: inspect all CI runs; check HTTP smoke, concurrency and cache/ownership; compare accelerated ON/OFF outputs against normative oracle and fixed AC.1 vectors; run 10k differential; validate generated hot seeds with merged code; assess performance and asynchronous HTTP behaviour.
- No `HANDOFF_*` files, Stage 57, source-language catalog changes or changes to either parent branch.
