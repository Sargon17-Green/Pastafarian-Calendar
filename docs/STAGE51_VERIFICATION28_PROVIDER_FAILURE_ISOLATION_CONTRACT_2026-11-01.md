# Stage51 / VERIFICATION28 — failing provider short circuit and per-call recovery

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-11-01

## Entry gate, exactly verified
Stage50 code SHA 50cdaf5f52f803763bdcb0d00403d4120db79ca9;
Actions #41350019540 completed/success 21/21 jobs.
Dedicated native PHP8.3.36/64-bit job #124977978607:
STAGE50_CALLBACK_TRACE checks=73 years=9 targets=9 successful=17 rejected=8 max_hops=4.
Exit 0, no stderr, lint passes. Artifact #13101446147, upload ZIP digest
61cf285ff1ba786fe9a47913e31851989ebe79d61dd3fdb948c5c3b1a56012b1.

## Distinct verification hypothesis and operational boundary
Stage50 verified normal and step-budget provider invocation order.
Stage51 tests *fault atomicity*: with one trusted, proposed,
canonical, or gate provider deliberately failing, the traversal must
emit only the trace prefix up to the failing operation. No unused
direction calls, no subsequent provider calls, and a clean later call
must recover exactly as an independent healthy baseline.

This is valid input with deliberately malfunctioning dependencies;
do not call these expected test rejections historical expected-red bugs.
The provider failures are injected only in tests; production remains
unchanged.

## Independent test input, oracle, and outputs
Construct Year5000 from test-only NormativeOracle at FOUNDATION_DAY, plus
one independently determined previous (4999) and next (5001) year.
For each direction use the strict interior midpoint of that year,
traverse from genuine Year5000, and require one step and exactly:
trusted anchor; anchor open/close gates; proposed adjacent provider;
independent canonical adjacent provider; destination open/close gates.

For each of two directions inject 10 distinct cases:
- trusted provider throws; trusted identity reports number 5001
- maxSteps=0: budget exhausted without adjacent callbacks
- proposed provider throws; proposed provider returns a non-array
- canonical provider throws; canonical provider returns a non-array;
  canonical number disagrees with proposed
- destination open-gate lookup throws; destination close-gate lookup
  returns a mismatched day

Each case must produce its exact documented exception string, the
entire expected trace prefix, and no later callbacks. Run a healthy
one-hop request immediately after every failed call; its full result
and complete provider trace must equal the original baseline.
Expect 20 fault rejections, 20 independent recoveries and 2 baselines.
Require unchanged input years and absence of test-only Oracle imports
in src/Patches/CanonicalAdjacentPatch22.php. The test selects one
well-defined operation order from the verified Stage50 callback contract.

## Acceptance
PHP 8.3 64-bit, syntax lint PASS, 512 MiB, bounded by 900 seconds,
exit 0 and empty stderr. Native stdout single line:
STAGE51_FAILURE_ISOLATION checks=<integer> directions=2 faults=20 recovered=20 baseline=2
Artifact stores source SHA, runtime version, stdout, stderr, exit code.
Entire workflow must be completed/success on exact Stage51 SHA.
No production route change, no main/merge, no claim of final five-field
calendar until independently demonstrated.
