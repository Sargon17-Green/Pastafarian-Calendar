# Stage50 / VERIFICATION27 — canonical and proposed callback invocation trace

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-11-01

## Entry gate
Stage49 at efb08f2e90f55837aa95d828ecf1f3d62242b580, GitHub Actions #41282845368 completed/success 20/20.
Dedicated PHP 8.3.36 64-bit job #124778105442: checks=150, years=7, targets=21,
orders=3, successful=63, short_rejections=6, empty stderr, exit=0.
Artifact #13073792860; upload ZIP SHA256
c403dde8dbb61ab6bff0ec9f1529557f008777a7350de64996087745faba65bc.

## Distinct verification question
Prior stages verified seam ownership, budget monotonicity and request-order
isolation, but did not assert the exact *observable invocation trace*
for the caller-owned providers. Stage50 checks that PATCH22 invokes
only the required adjacent providers, in the correct direction and order,
and never consumes a callback past an exhausted traversal budget.
No defect, witness or expected-red result is presumed.

## Test contract, inputs, outputs and independent oracle
Use the test-only NormativeOracle with FOUNDATION_DAY to construct true
Year5000 plus four real predecessors and four real successors (4996..5004).
The production route still receives caller-owned independent canonical
year providers; the oracle remains isolated to tests. For each year use
its strict-interior midpoint as target (9 distinct target days).

Instrument five provider types as external trace events:
trusted Year5000, gate-day by index, proposed next/previous and canonical
next/previous. A successful target with hop count H must emit exactly:
trusted anchor once; anchor open and close gate lookups once each;
then H repetitions of proposed adjacent-year provider, canonical provider
in the same direction, and the resulting year's two gate lookups.
There must be no unused-direction callbacks and no speculative extra hops.

For each of nine targets run at maxSteps=H. Compare complete output
to independent year record, direction, H and usedLegacyOutput=false;
verify the complete ordered callback trace. For eight off-anchor targets
also run maxSteps=H-1, require PATCH18_STEP_BUDGET_EXHAUSTED and verify
the trace terminates precisely after H-1 steps, then rerun with H and
verify identical output and trace. This yields 17 valid requests,
8 expected budget rejections, 9 independent targets and max H=4.
The rejection is an expected input-validation case, not an expected-red
historical algorithm defect. Verify input fixtures unchanged and
no test-side Oracle import in production CanonicalAdjacentPatch22.php.

## Native acceptance gate
PHP 8.3 64-bit; lint PASS; <=512 MiB, <=900 s, stderr empty, exit 0.
Single stdout line:
STAGE50_CALLBACK_TRACE checks=<N> years=9 targets=9 successful=17 rejected=8 max_hops=4
Store source SHA, PHP version, stdout, stderr and exit code. All canonical
workflow jobs for exactly the new Stage50 commit must be completed/success
before declaring Stage50 GREEN. No PHP production changes, no main/merge,
no five-component final conversion claim.
