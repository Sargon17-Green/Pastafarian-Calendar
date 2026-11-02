# Stage52 / VERIFICATION29 — second-hop fault isolation with later-hop suppression

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-11-02

## Verified entry gate
Stage51 SHA 215d97874bb9094656707df21aaf3b8a98b07621: GitHub Actions
#41355006529 completed/success 22/22. Dedicated Native PHP8.3.36/64-bit
job #124993079200: 89 checks, 20 injected failures, 20 recoveries,
two baselines, empty stderr, exit 0; artifact #13103606897,
ZIP SHA256 9a8765d344fa0242650e31c19a9f19f6e0abccc4bd40c7c16b89e15d722eb07d.

## New question and boundary
Stage51 covers one year hop. Stage52 independently checks fail-fast
and per-request recovery when a dependency fails in *the second hop*,
while a third hop might still be required. This is test-only; production
must not change. No expected-red or historical bug is assumed.

## Inputs and oracle
The test-only NormativeOracle creates genuine years 4997..5003 around
Year5000 at NormativeMath::FOUNDATION_DAY. Four valid requests:
forward and backward, exactly 2 or 3 hops, target strictly inside the
final year and maxSteps equal to the required depth. Independent output
oracle: targetYearCandidate equals year fixture, steps=depth, matching
direction, usedLegacyOutput=false. Expected provider-call sequence is
constructed from independent year fields (trusted; two anchor gates;
then proposed, canonical, opening gate, closing gate per hop).

For each of four baselines, inject four faults into *hop two*:
- proposed adjacent provider throws S52_PROPOSED_THROW;
- canonical adjacent provider throws S52_CANONICAL_THROW;
- destination opening gate throws S52_GATE_OPEN_THROW;
- destination closing gate returns off-by-one, producing
  PATCH20_GATE_DAY_MISMATCH_close.
Require exact error, exact expected call-prefix with no further
callbacks (in 3-hop cases this prohibits hop-three calls). Immediately
repeat the healthy full request and compare its entire result and
callback trace against baseline. Total four baselines, 16 rejected
faults and 16 recoveries, both directions and both depths.

Check original oracle years unchanged and no NormativeOracle/NormativeMath
dependencies in src/Patches/CanonicalAdjacentPatch22.php.

## Native acceptance
PHP 8.3 64-bit, php -l PASS, 512 MiB, 900s timeout, zero exit,
empty stderr, stdout exactly one regex-matched line:
STAGE52_LATE_HOP_ISOLATION checks=<integer> cases=4 faults=16 recovered=16 baselines=4
Save source commit SHA, runtime, stdout/stderr/exit in CI artifact;
all canonical workflow jobs completed/success on the Stage52 SHA.
No main/merge/publish or end-to-end five-field-calendar PASS claim.

## Observed Native failure and isolated test repair (2026-11-02)
The first Stage52 push run #41409176054 on f8d77b5b72a1b685da2d60f02d32a359b5f19859 finished FAILURE: 22/23 jobs succeeded; dedicated job #125158030173 completed/failure with PHP 8.3.36 lint PASS, `STAGE52_CHECK_FAILED_SHORT_CIRCUIT_forward2_open_throw`, exit 1 and artifact #13125175635 (ZIP digest c2a4b16e1719bb8eacda63b1fa964370a4a7585a60a8e2dbf1be7ca702c8f6cf). The test injection previously matched the target gate *index* alone. Adjacent years share a seam index (PATCH19 invariant), so a second-hop opening index also occurs as the previous year's closing index, and a reverse second-hop closing index occurs as the previous year's opening index. The callback could fail one hop too early. The repair uses both the independent destination index and per-request gate-call ordinal: 5=second-hop open, 6=second-hop close, following two anchor and two first-hop lookups. Counter resets on every request; explicitly assert shared seams for both directions. No changes to production code, expected provider traces or cardinalities. Await a new completed Native run on the repair SHA before accepting Stage52. This is a demonstrated test-injection defect, not evidence of a production algorithm failure.
