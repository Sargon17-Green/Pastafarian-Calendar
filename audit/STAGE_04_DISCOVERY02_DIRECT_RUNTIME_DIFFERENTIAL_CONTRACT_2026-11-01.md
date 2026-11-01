# Stage04 / DISCOVERY02 — pinned direct Python↔Rust runtime differential

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Status: implementation pending GitHub Actions evidence; **Stage04 OPEN**.

## Provenance, input, and independent outputs

- Original Python source comes from release tag python-turkish-v1.0.0-verified-20261030, resolving exactly to commit 0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4.
- File src/pastafari_calendar/legacy_day_counts.py must have Git blob SHA-1 405f461b2e2cdd170ded010e6f8046b78d6b4ab6, verified by git hash-object and by the Python verifier's independent Git-blob hash computation. Failure of either check forbids PASS.
- Python compiles and runs the *original* oldDayTag and dayTagWithFoundationScar functions, with the original capture list, rather than a Rust translation or a local mathematical reconstruction.
- A Rust QA-only binary src/bin/stage04_diff_emit.rs emits signed decimal BigInt TSV columns index,day,oracle,candidate. The oracle is imported unchanged from tests/support/normative_oracle.rs, and candidate comes from src/discovery02_day_tag_probe.rs.

## Bounded input domain and acceptance

- F=-15,055,671. Precisely 15 days in fixed order: F+[-3,-2,-1,0,1,2,3], then F-2^127,F+2^127,F-2^1025,F+2^1025,F-2^4096,F+2^4096,F-2^8192,F+2^8192.
- Each direct Python legacy output is compared with the Rust independent oracle; direct Python patched output and Rust candidate are also compared to that oracle, while the legacy capture must contain exactly the observed original output.
- Expected: 8 RED witnesses (day >= F, oracle-old=1); 7 CONTROL witnesses (day < F, oracle=old); UNEXPECTED=0; PATCH_OK=15; CANDIDATE_OK=15. Every oracle result must be positive. Input index and signed day must match exactly.
- Source/commit mismatch, malformed TSV, wrong row count, wrong arithmetic, wrong capture or wrong marker must return nonzero. No partial result constitutes PASS.
- CI acceptance requires completed/success on the exact code SHA, cargo fmt --check, regression tests, verified differential stdout/JSON and uploaded evidence; the JSON report stores all 15 inputs and outputs.

## Constraints and next gate

This witnesses a separate archived Python language branch, **not historical Rust legacy provenance**. Stage04 remains open, production stays BootstrapOnly, CURRENT_STAGE=4 and LAST_COMPLETED_STAGE=3; do not open Stage05 or alter main, merge or publish.

Only after verified completed CI may CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS be recorded as YES in a later documentation-only update; do not infer Stage04 closure from differential PASS alone.

