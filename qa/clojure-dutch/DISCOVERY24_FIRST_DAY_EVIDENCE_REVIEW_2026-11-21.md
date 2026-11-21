# DISCOVERY24 first-day witness — exact-SHA evidence review (2026-11-21)

**Project:** `PC-BRANCH-CLOJURE-DUTCH` / `Clojure+Nederlands`
**Reviewed source SHA:** `cdef8f447cecfbad5e440b4484b15f0641e24c3e`
**CI run:** [44890414062](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890414062), automatic push, attempt 1.
**Review type:** completed CI jobs + raw logs + downloaded ZIP/EDN artifact verification. This is not a new Native execution, a full Stage 2 acceptance, or a new differential test.

## Completed jobs

| Job ID | Job | GitHub status / conclusion | Evidence boundary |
|---|---|---|---|
| 136804787827 | clojure-dutch-first-day-e2e-witness | completed / success | One independent, canonical, base-first `p=1` bounded-prefix numeric witness |
| 136804787878 | verify | completed / success | Canonical names lock |
| 136804787656 | clojure-native-stage02-discovery24 | completed / cancelled | Partial diagnostic log **only**; no Native-suite PASS |
| 136804789013 | clojure-dutch-generic-e2e-feasibility | completed / skipped | Previously accepted `p=16` not rerun |

The Native job emitted `The operation was canceled` at 2026-11-21T09:58:28Z, after diagnostics spanning around 20 minutes. Do not infer a definitive cancellation cause or Native PASS from these partial diagnostics. No final raw test/assertion/failure/error totals were emitted for the cancelled job; the first-day job emits a witness, not a general Clojure test-suite counter. The Native log reports the legacy generic 7 cases as `{:bewezen 0, :geweigerd 7}` at budget `100000N`: refusal is not equivalent to numeric mismatch.

## Downloaded witness provenance and machine-data review

- Artifact: [clojure-dutch-first-day-e2e-witness](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890414062/artifacts/14702130498), artifact ID `14702130498`.
- ZIP length: **7,342 bytes**; SHA-256 **`7b2b424815b84545b7f68ca95c15b4433cfc8e3cdf82432003329c7fb84f2c86`**, matching GitHub's artifact digest.
- ZIP member: `discovery24_first_day_feasibility.edn`, **21,059 UTF-8 bytes**; extracted member SHA-256 **`e62a2608827f74a39879939612cd01d8aba56bd74b418e7067690a34b5bffc8e`**.
- EDN identity: `:project-id "PC-BRANCH-CLOJURE-DUTCH"`, `:github-sha "cdef8f447cecfbad5e440b4484b15f0641e24c3e"`.
- Witness: `:case :base-first`, `:status :bewezen`, `:probe-status :bewezen`, `:five-fields-proven? true`, `:stage2-accepted? false`.
- Calendar target: `:calculation-day -15055671N`, `:target-day -15057702N`, `:position-1-based 1N`.
- Independent expected fields `[5000 15 1N 18 1N]` equal the production actual fields `[5000N 15 1N 18 1N]` (numeric equivalence); actual month prefix `[1N]`, independent month ID `1N`.
- `:scope :bounded-prefix-only`, `:full-weaving-computed? false`; budget `5000000N`, reported prefix cells `0N`, search budget `128N`. A zero-cell first-month prefix is admissible; it does **not** prove full weaving.
- No `:bounded-prefix-budget-unproven` refusal marker in this artifact. Legacy generic E2E: `:legacy-generic-e2e-proven 0` and `:legacy-generic-e2e-refused 7`.

The raw first-day job log explicitly printed `DISCOVERY24 FIRST DAY independent five-field match` with matching fields, month ID and cells 0, then `DISCOVERY24 FIRST DAY FINAL {:case :base-first, :status :bewezen, :five-fields-proven? true, :stage2-accepted? false}`. These are corroborated by the archived EDN. The artifact structural review validates the evidence package, **not** independent re-execution of the calendar algorithm.

## Gate decision

- **Static / source:** exact SHA and tracked test/workflow blob identities were checked against branch source.
- **CI:** first-day witness and canonical lock completed/success; the aggregate Native job completed/cancelled.
- **Native:** only the narrow first-day witness is supported by this run. The full Native suite is not accepted.
- **Differential:** one independent `p=1` five-field+month-ID match for the bounded prefix is supported, with no full weaving.
- **Stage 2:** **OPEN / NOT ACCEPTED**. The legacy generic E2E 7/7 condition is not met.

## Authorized next step (no duplicate dispatch)

Diagnose why the already-running full Native workflow was cancelled and how to make its diagnostic chain yield bounded, independently reportable results **without increasing existing computation budgets**. Start by statically inspecting the Native workflow's job timeout and diagnostic ordering; propose a narrow QA/workflow-only isolation of the remaining unreported checks, preserving the source and canonical invariants. Do not re-run the already accepted `p=16`, do not treat completed/cancelled as PASS, and do not merge to `main` or change production/API. Retain the first-day witness as a separate accepted *narrow* result; do not conflate it with Stage 2 7/7.
