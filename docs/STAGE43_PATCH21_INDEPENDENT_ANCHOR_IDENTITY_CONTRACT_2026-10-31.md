# Stage43 / PATCH21 — independent Year5000 anchor identity

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31

## Evidence gate
Stage42/DISCOVERY21 at SHA c4e14f56d9021f53be572d93761541581cf55faa completed 13/13 jobs
in run 41192299864. Native job 124511375213 ran PHP 8.3.36/64-bit,
exit=0 and empty stderr, controls=12 candidates=2 reproduced=2 rejected=0.
Witnesses: Year5001 relabelled 5000 returned 5000 instead of 5001
(target=-15053458), and Year4999 relabelled 5000 returned 5000
instead of 4999 (target=-15057703). No claim that a valid trusted
Year5000 anchor ever produced an incorrect result.
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41192299864
Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41192299864/job/124511375213
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41192299864/artifacts/13039146723
Artifact SHA256: 6cb277b01d892fce403b532c1a837f3de9c8e10d4f8358e89704d8cc3ae68aef

## Contract and trust boundary
New opt-in route TARGET_YEAR_PATCH_21 accepts (calculationDay,targetDay,
year5000Anchor,nextYearProvider,previousYearProvider,gateDayByIndexProvider,
trustedYear5000Provider,maxSteps). The new zero-argument provider MUST be
trusted, separately derived, return a canonical physical Year5000 record,
and MUST NOT simply echo the caller's anchor or adjacent-year callbacks.
For physical anchor identity, compare exactly five typed integer fields:
number (must equal 5000), openGateIndex, closeGateIndex, openGateDay,
closeGateDay. Reject mismatches before invoking PATCH20. Then preserve
PATCH20 mapped gate days, PATCH19 physical seam checks, PATCH18 real
year traversal, and Stage36 legacy output without modifying them.
If the trusted provider itself lies or derives from an untrusted input,
no integrity guarantee is possible: this is a documented external
precondition, NOT an authenticated cryptographic proof. The production
implementation never imports test-only Oracle oracles.

## Measured gates, not inferred status
PHP 8.3 64-bit: syntax lint on new patch/kernel/test/bootstrap;
7 actual target days across Year4999/5000/5001 checked against test-only
independent NormativeOracle, equal to PATCH20 for valid inputs;
the two archived Stage42 false-anchor reproductions must remain visible
on PATCH20, while PATCH21 rejects both; 8 additional typed,
provenance and callback rejections (10 negatives total); immutable
test records; no production test-oracle dependency. Native job must
produce SHA-bound source evidence, stdout, stderr, exit code and version,
with timeout <=900s and memory <=512 MiB. All previous CI jobs must
succeed on the new commit. Stage43 remains AWAITING_NATIVE until
completed/log evidence is read; no main, merge, publication, or global
five-component calendar PASS asserted.
