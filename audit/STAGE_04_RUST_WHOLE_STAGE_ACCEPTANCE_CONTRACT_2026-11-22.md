# Stage04 / DISCOVERY02 — whole-stage completion evidence contract

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Decision: APPROVED_RECONSTRUCTION_SUBSTITUTE (2026-11-22), limited to the absent historical Rust RED witness.
Contract status: ACTIVE, NOT_AN_ACCEPTANCE_RECORD.
Current stage: 4; last completed: 3. No Stage05/main/merge.

## Scope and mathematical oracle
The original branch's candidate is a QA-only day-tag probe, not a full calendar production implementation.
Input: arbitrary signed BigInt day `d`, foundation F=-15055671.
Oracle: P(d)=2*abs(d-F)+[d>=F]. This is independently recomputed over 15 original-branch differential days (F+[-3..3] and F±2^127,2^1025,2^4096,2^8192). Inverse and 1025-bit boundary testing remain in the Rust Native suite.
The isolated 2026 reconstruction (not the original pre-Stage03 history) must show an executed wrong Rust dispatcher, a separately executed GREEN correction, and 128 individually observed Rust native outputs versus independently pinned expected values.

## Required gates
1. Same live original-branch HEAD at readback; exact code SHA for completed CI and logs; no stale SHA substitution.
2. Stage04 baseline source/TSV/provenance/callability unit gates pass, original Stage01-03 Native regressions pass, and `cargo fmt` passes; archive `exit.txt=0`.
3. Original direct Python↔Rust 15-day differential: exactly 8 archived Python RED, 7 CONTROL, 0 unexpected, PATCH_OK=15, CANDIDATE_OK=15. The Python RED must never be called historical Rust RED.
4. User-authorized substitution: exact Stage03/RED/GREEN/observed ancestry, original historical provenance script unchanged, 128 observed native rows and independent arithmetic 128/128 (64 before F, 64 on/after), and fail-closed negative controls.
5. Prior completed immutable records: reconstructed RED run 44937766996/job 136948055584; GREEN 44947008707/job 136976416170; observed-128 45067993657/job 137348363963. Original branch exact code SHA 756b680eb8acbd59145440e2d480dd51546b28b0: Stage04 45068619686/job 137350317045 and Names Lock 45068619709/job 137350317136; artifact 14772551617 SHA256 7135b75eb3772f38d202e23883df47952f8bce2b3e92d7d8faf12a7ea47f0de0, CRC 19/19, exit 0. These earlier completed records were independently inspected and documented in audit/STAGE_04_RUST_APPROVED_SUBSTITUTION_EXACT_CI_ARTIFACT_QA_2026-11-22.md.
6. The NEW code SHA must itself pass automated whole-stage evidence consistency checks. Its job/run/log/artifact, plus automatic Names Lock (where triggered), require separate live verification, not merely static validation.
7. Explicit subsequent Stage04 disposition: only once all gates 1-6 have evidence may a bounded branch-only acceptance record and stage-counter change be considered. No automatic stage-counter edit. Keep historical_pre_stage03_rust_red_proven=false.

## Machine-readable checker
`tools/stage04_whole_stage_acceptance.py` validates current CI workspace evidence with SHA, independent 15-case integer arithmetic, negative-control markers, and stage metadata; emits `closure_candidate=true` only when internally consistent. This is a *candidate* because that script cannot verify its own external GitHub completed job/log/artifact or new HEAD's Names Lock. Output always says `stage04_closure=NOT_CLAIMED` until a separate exact-run evidence review. Missing/contradictory data exits nonzero.

## Next
Verify the new exact-SHA Stage04 run, job, decoded logs and ZIP; verify Names Lock on the same HEAD; then decide Stage04 ACCEPTED or remain OPEN based on these named gates. A claimed PASS for a subordinate gate is not the whole-stage acceptance.
