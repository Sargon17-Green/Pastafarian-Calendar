# DISCOVERY24 — Native cancellation and diagnostic-order audit (2026-11-21)

**Project:** `PC-BRANCH-CLOJURE-DUTCH` / `Clojure+Nederlands`  
**Audit basis / branch HEAD before this report:** `1e9a639027b8adcef222faffcd07ea115b875d23` (parent `cdef8f447cecfbad5e440b4484b15f0641e24c3e`).  
**Exact CI source SHA:** `cdef8f447cecfbad5e440b4484b15f0641e24c3e`.  
**Run:** [44890414062](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890414062) (attempt 1), `completed/cancelled`.  
**Source objects reviewed at the audit basis:** `.github/workflows/canonical-names-lock.yml` blob `094fd657ed9b376ae0d71fd72806ff64f9d9ef81`; `test/pastafari/test_runner.clj` blob `f6baa5497af6d6b7e26ce1596c6cead842408651`; `test/pastafari/stage02_end_to_end_test.clj` blob `1cc69060128e8fab714c23c227f6bd01b334f8a4`. This is **static source/log QA**, not new Native execution.

## Control-plane result

| Job | GitHub conclusion | Defensible gate |
| --- | --- | --- |
| `136804787656` — `clojure-native-stage02-discovery24` | completed/cancelled | **No aggregate Native PASS.** Step 6 (`clojure -M:test`) cancelled; no final raw tests/assertions/failures/errors |
| `136804787827` — first-day witness | completed/success | One separately archived canonical base-first position-1 bounded-prefix numeric witness |
| `136804787878` — canonical lock | completed/success | Canonical-name verify only |
| `136804789013` — older generic p16 | completed/skipped | No repeat of previously accepted opt-in probe |

The first-day artifact remains [ID 14702130498](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890414062/artifacts/14702130498): ZIP SHA-256 `7b2b424815b84545b7f68ca95c15b4433cfc8e3cdf82432003329c7fb84f2c86`, EDN member SHA-256 `e62a2608827f74a39879939612cd01d8aba56bd74b418e7067690a34b5bffc8e`, independent five fields `[5000 15 1 18 1]`, month ID 1, prefix position 1, no full weaving, `:stage2-accepted? false`. See [prior exact-SHA artifact audit](DISCOVERY24_FIRST_DAY_EVIDENCE_REVIEW_2026-11-21.md).

## Exact log chronology (UTC, Native job 136804787656)

| Time | Verifiable log event |
| --- | --- |
| 09:38:21.364 | `Run clojure -M:test` starts; the entire Native runner is a **single** Actions step |
| 09:41:14.776 | `Testing pastafari.stage02-end-to-end-test` begins, after prior Stage 1 and Stage 2 namespaces |
| 09:43:00.617 | DIAG24 prints its 1/1 bounded fifteenth-day diagnostic |
| 09:45:49.906 | DIAG23 prints its 1/1 bounded fifteenth-day diagnostic |
| 09:53:34.950 | DIAG22 prints its 1/1 bounded fifteenth-day diagnostic |
| 09:55:25.419 | Legacy `DISCOVERY24 echte E2E`: `{:bewezen 0, :geweigerd 7}`, budget `100000N` |
| 09:56:47.019 | DIAG18 prints its final `{:bewezen 3, :geweigerd 0}` diagnostic |
| 09:58:18.476669 | **Last emitted completed diagnostic**: DIAG19, `{:bewezen 3, :geweigerd 0}` for twelfth-day bounded prefix |
| 09:58:28.891 | `The operation was canceled.` (10.415 s after last diagnostic) |

The Native job config has `timeout-minutes: 20`; the recorded job setup starts at about 09:38:18 and cancellation occurs at 09:58:28. This duration is **consistent with** the 20-minute job limit, but the raw log does **not** distinguish a timeout from every possible external cancellation cause. Do not label the cause proved.

## Ordering, observability gap and what is **not** known

`test_runner.clj` calls `clojure.test/run-tests` over 25 namespaces, with `stage02-end-to-end-test` last. The test-runner does not emit a per-`deftest` result, duration, or checkpoint. The printed DIAG order is plainly not numeric (DIAG13 -> DIAG24 -> DIAG10; DIAG20 -> legacy E2E -> DIAG18 -> DIAG19). Never infer executed/skipped tests from their numeric identifier or source-line order.

Explicit DIAG-labelled output exists for IDs `02,03,04,05,06,09,10,11,12,13,15,16,18,19,20,21,22,23,24`. No DIAG-labelled line appears for `07,08,14,17`, but these have tests without guaranteed per-test print markers. **Their executed/completed status cannot be established from this log.** Other silent tests in the namespace are likewise unaccounted for. Because there is no complete `Ran ... tests containing ... assertions` footer, even previously printed successful diagnostic values are **partial observations**, not a successful full-suite assertion total.

The original seven-case canonical full E2E remains `0 proven / 7 budget-refused` at `100000N`; a budget refusal is not a numeric mismatch and is not a differential pass. Prior separately completed DIAG22/23/24 limited acceptances are preserved; the cancelled run neither upgrades nor revokes them. **Stage 2 / DISCOVERY24 remains OPEN, NOT ACCEPTED.**

## Bounded nonduplicate follow-up contract (not yet executed)

**Goal:** isolate one genuinely new canonical year-boundary category with independently checkable evidence, instead of replaying the entire `clojure -M:test` suite or re-running the accepted base-year p1 and older p16 probes.

1. **Input/identity:** on a newly committed source SHA in `Clojure+Nederlands`, select **only the next year's first day** already present in the original seven `gevallen`: calculation day `dagen/stichtingsdag`; target `(inc (:open-gate-day volgend))`, where `volgend` is derived from the real gate line as in `echte-end-to-end-jaargrenzen-met-budgetpoort`. No extra date; no pseudorandom fixture.
2. **Oracle and boundaries:** independently compute the normative year, five date fields and first month ID using test-only normative oracle (do not copy production rank/unrank). Use real production bounded-prefix path, position `1N`, gate search bound `128N`, **unchanged** cumulative cell ceiling `5000000N`; no full weaving, no production/API/name edits, no change to the legacy `100000N` gate. A zero-cell outcome is possible but **not expected or asserted beforehand**.
3. **Output:** emit one exact-SHA machine-readable EDN result containing project ID, source SHA, chosen calculation/target days, independent and actual five fields, first month ID, position, scope, full-weaving flag, reported cell cost, status and refusal code. Require exactly one outcome: `:bewezen` with genuine independent 5/5 numeric equality, exact month ID, bounded-prefix-only scope and cost <= `5000000N`; **or** `:bounded-prefix-budget-unproven`, with no success claim. Emit raw `bewezen+geweigerd=1` and nonzero exit on any false assertion.
4. **Safe isolation:** use a **single explicit opt-in** job in an *already registered* workflow; gate off `clojure -M:test` for that opt-in so the aggregate Native 20-minute step is not dispatched simultaneously. Keep `verify` enabled, keep the existing 20-minute maximum, preserve artifacts on failed steps, assert checkout SHA equals `GITHUB_SHA`, and never reuse the old p1 or p16 artifact name. A normal branch push must not start this opt-in probe; no automatic duplicate dispatch.
5. **Acceptance:** only an exact-SHA `completed/success` targeted job **and** successful canonical verify, raw logs + archived EDN ID/SHA and independent oracle comparisons allow **next-year-first-day LIMITED ACCEPTED**. A refused case is feasibility-only, not differential PASS. Do not infer aggregate Native pass from an isolated probe. Full Stage 2 requires 7/7 canonical genuine E2E proofs plus an independently approved production contract and all relevant gates.

**Next authorized implementation:** add the test-only single-case entrypoint and workflow gating/observability in the feature branch, with static syntax + exact HEAD/blob readback; do not dispatch or accept CI on a documentation-only commit. If the measured case requires an engineering decision outside the existing feature branch scope, record it before changing production. Do not alter `main`, merge or publish.
