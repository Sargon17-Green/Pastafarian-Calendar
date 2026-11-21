# Stage18 original-runtime Native failure: typed-handle comparison in fixture

PROJECT_ID: PC-BRANCH-FALSE-ARABIC
Branch: FALSE+العربية
Date: 2026-11-21
Original run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44893419729
Original job: 136813908499 (completed/failure)
Run SHA: 300cc893f1f1901cae1ad2b71835930cf8145466
Original SOURCE_PIN: 9ab8511b05158f7ddbd0c664b8d6cc9f7efc1339
Original FALSE interpreter: eb3135565a8670cced3f6bbca4dbf7b014c45634
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44893419729/artifacts/14702648556
Artifact SHA256: 7af629749fcf5437325525345c2987140237ebb174590592b929b75643c6a89f
Artifact ZIP entries: 25, CRC verified.

## Observed, not inferred
- GitHub verify job 136813908295: completed/success.
- Original FALSE interpreter compilation and UTF-8 Unicode preflight: success.
- Fixture generation: 5 chunks x 150 cases produced and SHA-tracked. This does **not** indicate Native PASS.
- First Native positive chunk `positive_0.false`: exit=1, stderr type mismatch at line 784, column 7. No positive success marker was emitted.
- Failure instruction: `b;g;!d=~["STAGE18_DROP_0000_ARG_CELL_FAIL"0 0/]?`.
- Seven immediately preceding output comparisons for case 0000 (lines 777–783) executed without the fixture's failure markers, but no complete case was accepted.
- `mutant_bad_order`: exit=1 with the expected output mismatch marker. `mutant_bad_sign`: exit=1 at the same incorrect typed comparison before reaching its expected sign failure; thus its mutation rejection is **not verified**.
- The error lies in a direct storage-handle comparison with `=`, not a demonstrated wrong op35 permutation. Original production op35 remains unmodified.

## Narrow remediation
- `tools/stage18_drop_order_fixture.py`: replace the single generator template `b;g;!d=~` with `b;g;!d;-0=~`. The `-0=` handle-equality idiom is already exercised in accepted Stage16/17 fixtures; no change to input contract or expected permutations.
- `tools/stage18_drop_order_offline_audit.py`: update the exact source commit pin and the required literal assertion marker. Auditor still independently verifies ZIP, source blobs, 750 cases, factoradic outputs, two negative controls and corrupted-oracle rejection.
- Source fix commit: 9abeace3ff87a231ef25881b06da6bbe9bb1be56.
- Audit compatibility commit: 9446b5278cb61919d2d7ba4f0a06b2b60c5b7a71.

## Gates
Static diagnosis: supported by exact stderr + artifact bytes + accepted typed-handle idiom.
Native retry on modified source: NOT_RUN at time this report is created.
Stage18 differential: NOT_RUN. Stage18 acceptance: NO.
Last accepted stage: Stage17, BOUNDED.
Physical invalid pointers and truncated tuples remain outside tested contract.
No main/merge; preserve original failing artifact for regression evidence.
