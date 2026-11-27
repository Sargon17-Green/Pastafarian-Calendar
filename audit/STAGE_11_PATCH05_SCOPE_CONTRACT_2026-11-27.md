# Stage11 / PATCH05 — bounded successor contract and Stage10 acceptance-HEAD evidence
PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
BASE_SHA=82863ff474798da187fc9fba5824d824dc57a990
CURRENT_STAGE=10
LAST_COMPLETED_STAGE=10
STAGE11_CONTRACT=READY
STAGE11_IMPLEMENTATION=NOT_STARTED
STAGE11_NATIVE=NOT_RUN
STAGE11_ACCEPTANCE=NOT_CLAIMED

## Exact predecessor evidence
All four jobs completed/success, every step successful, decoded logs show exact checkout BASE_SHA:
- Stage04 run 45954629100 job 140358133285, ZIP 15178377159, 69066 bytes, SHA256 05a48e7076e2eb6502e9811d8aa9c88b2921b4e80f46b23c1d97226bd40c7539, CRC 21/21.
- Stage05 run 45954629237 job 140358133696, ZIP 15179040330, 53171 bytes, SHA256 3eb0e6c4928d0912c0e74b243e06f183a908d93bd1ec3700f885d4cae1955ed9, CRC 6/6.
- Stage10 run 45954629182 job 140358133670, ZIP 15178621533, 55224 bytes, SHA256 d0e99825c0892cb575b5acc5cc024b40f6a7facadaeaacb915cb72813e3a2a42, CRC 14/14.
- Names Lock run 45954629316 job 140358133976; no artifact required/emitted.
Downloaded ZIP bytes independently hashed against metadata and upload log; exact PROJECT_ID/SHA and exit 0 in all three. Stage04 independently recomputed 15/15 corrected day tags, candidate ACCEPTED, 8 RED/7 CONTROL and 128 approved reconstructed rows reported; original historical Rust RED NOT_PROVEN. Stage10 49 tests passed, 0 failed excluding intentional strict witness (101, actual hidden7 vs expected hidden1). Independent replay of raw output checked all 35 unique (case,k) pairs against reversal of emitted logical expectations, 30 RED/5 MATCH, and 8/8 foundation physical slots. This replay checks indexing, not a fresh independent recomputation of the hidden-drop mathematics. CI Python oracle independently recomputed those values and previous Stage05–09 oracles passed. No duplicate dispatch.

## Successor scope
Pinned Rust source src/discovery05_hidden_probe.rs blob 30ca8e63bfc667253229d28882d14d4dc213b36d and existing Stage10 contract audit/STAGE_10_DISCOVERY05_CONTRACT_2026-11-25.md. Input: signed arbitrary-precision calculation_day, target_day; logical k integer 1..7. Output: exact BigInt logical hidden(k), plus physical index and separate PATCH05 observation in context. Physical storage is unchanged, P[0]=0 and P[8-k]=H(k). Corrected read is P[8-k]; old read P[k] is retained as a historical DISCOVERY05 witness. Default query k=1 must yield 119390830530032782664128530203002080344 at foundation pair, not 6164285870955721082771365327359496898. Preserve corrected PATCH02/03 counts, PATCH04 snapshot, existing seven-grind calculation, coefficients, SAVE, and all physical slots; no reordering, recomputation, second builder or alteration to prior witness. Introduce separate corrected accessor/observation and handler after existing DISCOVERY05 in the real dispatcher route; expose a successor entry point and wire corrected public route only while keeping legacy discovery entry point explicitly callable (audit usages first; do not break historical tests). Keep canonical names locked; choose new names only after checking catalog. Full five-field calendar remains BootstrapOnly.

## Acceptance gates
- Use independent arithmetic oracle from specification, not production helper or another branch fixture. Compute H(k) from corrected action/target/distance/connection/direction and normative stone snapshot with coefficient row [2k+1,3k+1,4k+2,4k+4], SAVE and seven grind steps. Compare corrected output for five prior signed pairs and all seven logical indices (35/35), plus fresh independent boundary pairs (foundation +/-1, equal/reversed, +/-2^129 and +/-2^1031), all k; record raw values, k, mapped slot and legacy result. Check all 8 physical slots for each new case. Require explicit old witness remains RED for foundation k=1 and new strict GREEN passes on same inputs, k=4 control unchanged. Preserve old expected-RED suite as historical route, not as failure of the new route.
- Unit guard matrix: k=0,8,usize::MAX; storage lengths 0,1,7,9; nonzero sentinel; missing prerequisite, inconsistent counts/request, duplicate application, independent context isolation. Invalid input returns InvalidState before subtraction/index access; no mutations of observation, counters or diagnostic on rejection. Stage10 legacy behavior remains unchanged. Corrected handler requires prior valid discovery observation, records exactly one corrected read and one application, does not rebuild storage or change earlier trace.
- Native cargo fmt --check and cargo test --all-targets; exact source SHA; raw independent Python oracle checks uniqueness, complete coverage, mapping and arithmetic; Stage04/05/06/07/08/09/10 regression compatibility (including successor stage-state gates) and Names Lock. Separate expected RED on legacy route and strict GREEN on corrected route. Artifact with PROJECT_ID, SHA, toolchain, raw logs, result, exit code, SHA256 and CRC. Only after exact completed evidence may LAST_COMPLETED_STAGE advance to 11.
- Do not claim new execution or acceptance from this contract. No Stage12, main, merge, release, duplicate dispatch, or full calendar activation.
