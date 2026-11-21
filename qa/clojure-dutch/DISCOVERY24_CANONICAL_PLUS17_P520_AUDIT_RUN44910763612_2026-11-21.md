# DISCOVERY24 — canonical shifted +17 / p520 evidence audit (2026-11-21)

PROJECT_ID: `PC-BRANCH-CLOJURE-DUTCH`
Branch: `Clojure+Nederlands`
**Source SHA under test:** `faa37816ae4e1384e019d406c62415af7ab028b6`
Scope: QA evidence and next diagnostic contract only; no production change, API/budget change, full-suite rerun, or Stage2 acceptance.

## Exact run and gates

- Automatic push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910763612 ; run `completed/success`, source SHA exactly `faa37816ae4e1384e019d406c62415af7ab028b6`.
- Witness job `136865879505`: `completed/success`; job log shows `PROJECT_ID=PC-BRANCH-CLOJURE-DUTCH`, `SOURCE_SHA=faa37816ae4e1384e019d406c62415af7ab028b6` and explicit bounded refusal.
- Canonical names verify job `136865879727`: `completed/success`, checkout same SHA.
- Full `clojure-native-stage02-discovery24` job `136865915887`: `completed/skipped` as intended. Not Native test-suite PASS. Other unrelated opt-in witnesses skipped.
- Artifact `14710227259`: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910763612/artifacts/14710227259
- ZIP SHA-256 independently checked after downloading: `13a4d2855eb71dae4a3d2f526e68b6301bf41880cab9388c495226ca2202ccd4`, size 536 bytes.
- Inside ZIP: `discovery24_canonical_plus17_feasibility.edn`, 588 bytes, SHA-256 `5f9eedd6a38c411732457d0c8aaa30eb737244486e6bd263afd429bc8e89c350`.
- EDN identity: project ID and GitHub SHA match exactly. `:target-year 5000N`, `:calculation-day -15055654N`, `:target-day -15055654N`, `:position-1-based 520N`, `:search-budget 128N`, `:selective-prefix-budget 5000000N`, `:legacy-budget 100000N`.
- EDN status: `:probe-status :geweigerd`; `:probe :code :bounded-prefix-budget-unproven`; `:five-fields-proven? false`; `:selective-prefix-cell-cost :not-proven`; `:stage2-accepted? false`; legacy generic `0 proven / 7 refused`.

## Code-path audit (static inspection at exact source SHA)

- Test `test/pastafari/stage02_end_to_end_test.clj` calls `projectie/kies-prefixdag-zonder-volledige-weving` exactly once, using 128N / 5000000N. On recognized refusal it records `:not-proven` and does **not** evaluate the independent numeric insertion oracle. This matches the log and artifact.
- `src/pastafari/datumprojectie.clj` routes to `rang/prefix-op-rang-begrensd`. `src/pastafari/maandrang.clj` accumulates estimated prefix-cell cost and throws `:bounded-prefix-budget-unproven` before the candidate suffix count when the bound would be exceeded.
- Current exception and EDN do **not** provide the first over-budget prefix position or pre-refusal numerical cell upper bound. The exact first failing position and actual full-prefix cost are **unknown**; do not infer that the 520th step itself failed.
- `completed/success` here proves correct controlled refusal and evidence preservation, **not** a 520-element prefix, five-field differential equality, or Stage2 acceptance.

## Acceptance classification

**GREEN BOUNDED FEASIBILITY ONLY** for the exact p520 canonical shifted case. **NO numeric five-field proof**. Prior accepted next-year p1 is a distinct case and cannot be reused as p520 evidence. Original seven-case 100000N E2E remains 0/7; Stage2 DISCOVERY24 remains OPEN.

## Next authorized engineering contract (new information, no duplicate run)

Introduce a **test-only first-refusal accounting diagnostic**, rather than dispatching the same p520 witness or raising 5000000N. Inputs: exact source SHA and canonical year 5000 / calculation-target day -15055654N / p520 / budgets 128N and 5000000N. Output on refusal: the **first** considered position, accumulated safe cost before that candidate, proposed candidate upper cost, and named budget condition; all nonnegative integers, with `safe-cost <= 5000000N < proposed-cost`. On success: existing independent five-field and 520-element prefix checks, same limits. Validate accounting against an **independent test-only combinatorial insertion cost model** (not copied production `prefix-gedeelde-raming` or `prefix-op-rang-begrensd`); include small-family exhaustive fixtures and exact project/SHA identity. Do not claim a numeric result until a separately completed and artifact-backed CI test actually proves it. Do not change production code/API, budget limits, branch protection, main or Stage2 policy; do not rerun accepted checks merely because this QA report was committed.
