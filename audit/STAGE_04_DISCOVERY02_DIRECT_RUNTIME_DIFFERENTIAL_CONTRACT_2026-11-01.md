# Stage04 / DISCOVERY02 — pinned direct Python↔Rust runtime differential

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Status: direct Python↔Rust execution and regression gates verified on code SHA bc537a6b92bacd3b5753a76c3a679af4a9b3a936; **Stage04 OPEN**.

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

## Execution evidence — 2026-11-01

- Rust code SHA **bc537a6b92bacd3b5753a76c3a679af4a9b3a936** on branch `Rust+Azərbaycan-dili` was verified. Fix from previous failed SHA `c72ca7785ff4a7a41c2f8c30b4a49371d9bdb3af` only adds `#[rustfmt::skip]` to the external independent oracle module declaration and removes an extra EOF blank line; oracle itself is unchanged.
- Five GitHub Actions runs on that exact code SHA completed/success: Stage04 [41349950368](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349950368), Stage03 [41349950359](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349950359), Stage02 [41349950367](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349950367), Stage01 [41349950360](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349950360), and Names Lock [41349950372](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349950372).
- Stage04 job **124977772981**: `cargo fmt --all -- --check` passed; **34 Rust tests passed, 0 failed** across seven counted groups (16+3+4+2+3+3+3). Markers: archived **8 RED / 7 CONTROL / 0 UNEXPECTED**, 15 patch controls; Stage02 **3 RED / 1 CONTROL / 0 UNEXPECTED**; Stage03 **BOUNDARY_OK=8**.
- Original Python archive is fetched at pinned release and commit `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4` with source Git blob `405f461b2e2cdd170ded010e6f8046b78d6b4ab6`; direct execution gate passed. All 15 signed BigInt TSV inputs: **STAGE04_CROSS_RUNTIME_RED=8 CONTROL=7 UNEXPECTED=0**, **PATCH_OK=15 CANDIDATE_OK=15**. Stage04 cross-runtime direct differential **PASS**, not Stage04 closure.
- Uploaded artifact [13100771448](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349950368/artifacts/13100771448), 17,480 bytes, SHA256 **69e8c52c4483a604a03fecd648930935aece40ae367f8f1d70578d70ffbc26b2** (GitHub artifact API digest; archive bytes were not separately rehashed).
- **CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=YES** is justified by completed/log evidence on the above code SHA. **Stage04 remains OPEN**, Rust historical prehistory is not established by an archive from a separate language branch, production remains **BootstrapOnly**, and no Stage05/main/merge was performed. This audit/documentary update does not claim new Native execution on its own documentation-only SHA.
