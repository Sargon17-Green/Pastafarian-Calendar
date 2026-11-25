# Stage09 / PATCH04 — exact-SHA Native and artifact acceptance

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE09_CODE_SHA=460c087c9cb0efb31561bcdf05efba568bbdcf8b
STAGE09_RUN_ID=45697040752
STAGE09_JOB_ID=139497033358
STAGE09_STATUS=completed
STAGE09_CONCLUSION=success
STAGE09_CHECKOUT_SHA=460c087c9cb0efb31561bcdf05efba568bbdcf8b
STAGE09_ARTIFACT_ID=15060812375
STAGE09_ARTIFACT_BYTES=52554
STAGE09_ARTIFACT_SHA256=a227bd72cdb15b9f95bf090c8c8bfb79b1aade3ad4f72102770d87a7986ca682
STAGE09_ARTIFACT_CRC=PASS
STAGE09_ARTIFACT_FILES=10
STAGE09_EXIT=0
STAGE09_RUST_TEST_TARGETS=14
STAGE09_RUST_PASSED=47
STAGE09_RUST_FAILED=0
STAGE09_RUST_IGNORED=0
STAGE09_CORRECTED_CELLS=230
STAGE09_CORRECTED_GREEN=230
STAGE09_GARBAGE_CELLS=225
STAGE09_GARBAGE_RED=180
STAGE09_GARBAGE_MATCH=45
STAGE09_PRESERVED_LEGACY_CELLS=225
STAGE09_PRESERVED_LEGACY_RED=224
STAGE09_PRESERVED_LEGACY_MATCH=1
STAGE09_LEGACY_MUTATOR_CALLS=45
STAGE09_GUARDS=5
STAGE09_PYTHON_ORACLE=PASS
STAGE09_RAW_ARTIFACT_REPLAY=PASS
STAGE09_CLOSURE=ACCEPTED

## Exact-SHA Native evidence

GitHub Actions run 45697040752/job 139497033358 completed/success on the exact checkout SHA 460c087c9cb0efb31561bcdf05efba568bbdcf8b. The workflow's scope/identity and `cargo fmt --all -- --check` step passed; the independent Python oracle self-test passed; `cargo test --all-targets -- --nocapture` completed successfully.

The raw Native output contains 14 test-target summaries: 47 passed, 0 failed, 0 ignored. The Stage09 test traversed the actual PATCH02 -> DISCOVERY03 -> PATCH03 -> DISCOVERY04 -> PATCH04 production route. It checked:
- 46 corrected rows / 230 components, all 230 GREEN against the independent BigInt snapshot oracle.
- 45 actual calls to the historical sequential mutator on clones, preserving the resulting garbage table separately: 225 compared cells, 180 RED and 45 MATCH against the corrected snapshot table.
- The unchanged Stage08 DISCOVERY04 legacy table: 225 compared cells, 224 RED and 1 MATCH against the corrected snapshot table.
- Five guards: invalid lower row, invalid upper row, duplicate invocation, missing Stage08 observation, and full-calendar BootstrapOnly.

The same exact-SHA workflow also reran the Stage05 wrapper oracle (69/69), Stage06 distance oracle (169/169, 153 RED/16 controls), Stage07 oracle (225/225, 204 mismatch/21 match), and Stage08 oracle (225/225, 224 RED/1 match). All passed. Canonical Names Lock run 45697041345 also completed/success on the same exact SHA.

## Artifact audit

Artifact 15060812375 contains 10 files and is 52,554 bytes. The downloaded ZIP SHA-256 is `a227bd72cdb15b9f95bf090c8c8bfb79b1aade3ad4f72102770d87a7986ca682`, exactly matching the GitHub artifact digest. ZIP CRC validation passed. `sha.txt` records the exact PROJECT_ID and code SHA; `exit.txt` is 0; `result.txt` records Native PASS and Oracle PASS.

The artifact's raw stdout was independently replayed against arbitrary-precision snapshot, sequential-garbage, and historical-sequential tables. All raw cell lines were parsed with exact key coverage: corrected 230/230, garbage 225/225, legacy 225/225. Every value and classification matched; totals were garbage 180 RED/45 MATCH and preserved legacy 224 RED/1 MATCH. No missing, duplicate, malformed, or unexpected cell was found.

## Diagnostic attempt

The prior attempt (run 45690301446) had passed rustfmt, its oracle self-test, and all Rust tests, but failed in the Python artifact parser: the corrected-cell regex omitted the GREEN capture group, and the garbage expected-column comparison used the wrong table. Both oracle defects were fixed in code SHA 460c087c9cb0efb31561bcdf05efba568bbdcf8b. The accepted run above then passed the corrected parser against the complete artifact.

The Stage04 whole-stage acceptance helper was separately tested on parent SHA 1ba15a59d391fec18a82b416040e989207b3a2b6: all 12 helper tests passed, including explicit recognition of Stage09 pending and accepted states. The final Stage09 code SHA differs from that parent only in the Stage09 Python oracle, so the helper implementation and its tests are unchanged.

## Scope and closure

PATCH04 corrects the Stage08 sequential-mutation defect by deriving all five corrected fields from one immutable previous-row snapshot. The original mutator is still invoked on a clone, and its garbage result is preserved as evidence; the Stage08 legacy discovery table is untouched. The historical RED remains visible and independently classified.

LAST_COMPLETED_STAGE advances to 9. CURRENT_STAGE remains 9 as the accepted hold point; Stage10/DISCOVERY05 is not started. The full calendar remains BootstrapOnly. No main update, merge, or release was performed.
