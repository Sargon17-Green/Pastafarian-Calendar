# Stage04 closure eligibility and strict TSV QA — 2026-11-01

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Reviewed prior HEAD: 61fde18162689a53bb4d8c7b93605c85dbe0aca0
Reviewed code SHA: bc537a6b92bacd3b5753a76c3a679af4a9b3a936
Conclusion: Stage04 OPEN; no Stage05, main, merge or production wiring.

## Targeted eligibility decision

The immutable Stage04 baseline contract has three closure conditions. The live branch's direct Python↔Rust comparison proves a real defect in a pinned *Python+Türkçe* archived route, but does not identify a historical Rust day-tag production route. The independent Rust candidate matches the normative day-count oracle; this is a positive result, not a historical Rust RED.

A targeted GitHub comparison of the archived Python commit 0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4 against the Rust branch HEAD gave status=diverged, merge_base=24dee49db9ddc0ea55bdaacabd1738786282ad46, ahead_by=48, behind_by=97. Thus the archived commit is not an ancestor of this Rust HEAD. The Stage3 closure commit 716e5a6f335b1a15464029b446edb468f3a8482c *is* an ancestor: status=ahead, ahead_by=16, behind_by=0, merge_base exactly that Stage3 commit. This is ancestry evidence, not a proof that every conceivable untracked Rust archive is absent.

Closure gate decisions:
1. Verified earlier Rust legacy day-tag route / historical Rust change: NOT ESTABLISHED. Python archive is not the required Rust lineage witness.
2. Observed difference in a historical Rust running route against independent oracle: NOT ESTABLISHED. Python RED=8 / CONTROL=7 cannot be transferred to Rust history.
3. Existing behavior preserved: last verified code SHA passed cargo fmt, 34/34 Rust tests, 15 signed BigInt direct cross-runtime comparisons and Names Lock. Production entry still returns BootstrapOnly; Stage3 SAVE remains guarded. PASS only for these tested gates, not Stage04 closure.

Therefore Stage04 remains OPEN, LAST_COMPLETED_STAGE=3, CURRENT_STAGE=4. Do not mark EXPECTED_RED for an unobserved Rust route. NEXT: continue only on a new concrete Rust historical source/revision or independently reproducible Rust legacy-route witness; pin its SHA and demonstrate exact mismatches before changing eligibility.

## Newly reproduced input-verifier defect and narrow repair

The exact original tools/stage04_cross_runtime_diff.py load_rust_rows used csv.DictReader and rejected only missing values/row count. A malformed 15-row TSV with the required four header columns but a fifth undeclared field on each data row was ACCEPTED: DictReader stores the overflow under key None, with a list value rather than a None value. This violates the direct-runtime contract's requirement to reject malformed TSV.

Repair: require for each row exactly the four declared keys and nonempty string values for all four; retain the separate 15-row and ordered header checks. The test-only Rust oracle and candidate, historical Python archive, arithmetic fixtures, data generation, and production code are unchanged. Add six Python unittest cases: valid 15 rows; surplus row field; missing field; empty field; surplus header; 14 rows. The dedicated Stage04 workflow now runs these tests with a 30-second timeout and uploads their log in the existing evidence artifact.

Isolated local reproduction on the original parser: malformed 15-row TSV ACCEPTED. Isolated local run of the patched input predicate: 6/6 PASS. These local checks are not a GitHub Actions PASS. Native Rust tests and direct-runtime differential on the forthcoming commit must be judged only from completed CI and logs. Do not re-dispatch earlier successful code SHA.

Evidence:
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/61fde18162689a53bb4d8c7b93605c85dbe0aca0/audit/STAGE_04_DISCOVERY02_BASELINE_CONTRACT_2026-10-31.md
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/61fde18162689a53bb4d8c7b93605c85dbe0aca0/audit/STAGE_04_DISCOVERY02_DIRECT_RUNTIME_DIFFERENTIAL_CONTRACT_2026-11-01.md
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349950368
