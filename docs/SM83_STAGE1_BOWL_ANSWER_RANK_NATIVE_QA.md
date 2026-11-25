# SM83 Stage1 Native393 — final QA and acceptance record

Scope note: Native393 E–K / bowl-answer flow is accepted on the exact source SHA recorded below. This does not accept all of Stage1; gate/year generation and candidate enumeration remain a separate dependency awaiting user authorization.
PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Parent: e8bc74de2f3cbee4010940a5599f1d7c7ca620af

## Native393 contract and coverage
The isolated target is `make build/calendar_bowl_answer_rank.gb`; it does not change the default ROM or earlier Native370..392 targets.

- Runtime adapter validates active ordinal, bowl 1..6, seal 10..12 and count 1..19044 before publication; it adapts Native392 A0/direction into the short-rank kernel ABI and publishes A0, direction, rank and accepted A_k atomically.
- The ROM table covers all 18 bowl/seal answer combinations (four Foundation fixture rows plus fourteen additional combinations). The Native runner executes five independent c/t pair sessions: Foundation, (-1,+1), (+1,-1), (INT32_MIN,INT32_MAX), and the reverse endpoint pair. Each session runs all 18 bowl/seal combinations; nonfoundation sessions use dynamic Native calls and a 630-byte WRAM result capture. The independent Host sauce/selection oracles compare WorkCounts, final six Q residues, orderAt46, all 12 retained post-stir sums, and every A0/direction/rank/A_k result. This yields 90 source-derived answer comparisons across five pairs.
- 26 synthetic full-width boundary vectors exercise the selector kernel directly (the same kernel called by the adapter): A0=1/M, L and L+1, counts 1/2/922/19044, both directions and forward/backward wrap. The 18 source-derived cases exercise the adapter-to-kernel path and publication. The separate host ring oracle compares closed form with literal ring traversal, checks L-1/L/L+1 and period/reverse properties.
- Native invalid-count tests reject 0 and 19045. Invalid bowl/seal/order/residue, illegal sign and negative zero, idle calls, and output sentinels for A0/direction/rank/A_k are checked.
- Around every answer/rank call the bench snapshots and compares all six Q residues, orderAt46, ordinal sign/24-bit length and the live ordinal SRAM byte; owner lease and foreign SRAM sentinels are checked.

## Completed exact-SHA candidate evidence (pre-nonfoundation expansion)
Run 45671282163 on `e8bc74de2f3cbee4010940a5599f1d7c7ca620af`: 25/25 jobs success; Native393 `A5/393/40` in 22,112 frames; ROM_HEADER PASS; Host rank preflight PASS. This run predates the 14 additional source-derived Native vectors and is not the final gate for this expanded coverage.

Artifact 15049228236:
- ROM SHA256 `5d55f3c19e945589a0f671b18f7631e39b9d69e94b62e45d1b94cbc5426c8832`
- MAP SHA256 `0379d5fa8b61c42663bef69c84364cd3d4af3dd3c72ecec69018cfeb03678bf1`
- SYM SHA256 `9545189e4bef92154b32da53b1c3116bb4b75293df9b8254f357047a9517e6c4`
- ROM0 16,166 used / 218 free; ROMX bank 1 13,839 used / 2,545 free; WRAM0 2,232 used / 1,864 free.
- Captured Q: `0f309a1c52180eba1217e27dd2c11d31a3b9c2a87e952f06eaf69bbc25081660ca7c28be90f6d7e5e7af28309123e6282b86ea6874a845071399b59a1b14054676d8f1488faaeb3051a72706842947292781abef78b7aff67aeb338ea0bca953`; orderAt46: `040502030601`.

## Historical acceptance gate (superseded by the final exact-SHA acceptance below)
Run the five-pair Native matrix on the exact new SHA; inspect all five A5/393/40 completions, the independent Host comparisons, completed CI jobs and ROM/map/sym artifact. Require RGBDS 1.0.4, ROM_HEADER, ROM0 free >=10, each Native393 session <=120000 frames and Native370 <=9000, plus retained Native371..392 regression. A candidate run is not Stage1 acceptance. No Stage2/main/merge/release.
## Expanded-run diagnosis and correction
Run 45672668795 on `171b825abfa4cbbb4dcc1697be8d892781d17fc8`: 24/25 jobs succeeded; Native returned E0. Diagnostic run 45673463027 on `f5747b1c7de8b5079af75726eff037a14bb51092` showed the first nonfoundation source vector passed and the remaining-case counter reached 13, after which the table cursor was replaced by the counter address. Root cause was the test loop loading `HL=wCalendarAnswerSavedByte` before looping; the correction decrements/stores through A and preserves HL. This is a Native test-harness defect, not evidence of an A0/rank runtime failure. Re-run the expanded suite on the corrected exact SHA.

## Prior Foundation-only exact-SHA result
Run 45673927216 on `5ccf201158ee3ac1a29ff1974e5d251de81f63c0`: 25/25 jobs success; Native393 `A5/393/40` in 22,442 frames; 18 Foundation bowl/seal vectors, 26 synthetic boundaries, invalid counts, output and input snapshots passed. This was still one Foundation c/t pair; the five-pair matrix above is the next acceptance gate.

## Nonfoundation invalid-order harness correction
Run 1869c8ba8a94549c6a96971c11f48d0205cb5c9e: Foundation pair passed; the first nonfoundation pair completed the 18 answer calls but failed the invalid-order negative test. Its valid `orderAt46` began `06 05...`; the test's hardcoded replacement value 6 therefore made no mutation. Corrected the test to replace element 0 with element 1, guaranteeing a duplicate in every valid permutation. This is a test-harness assumption, not a source algorithm failure.


## Final exact-SHA acceptance — 2026-11-25 (supersedes earlier candidate status)

**Accepted source SHA:** `ceac4b8a143fb1ab7c1d26f5f102b74cac537a2f`  
**Branch:** `SM83-Assembly+ግዕዝ`  
**CI:** run [45677493217](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45677493217), completed/success, 25/25 jobs. All 25 job logs were fetched; each checkout log contains the exact full SHA above.

- Native393 job `139428829921`: five real `A5/393/40` sessions, frames `22443, 22442, 22448, 22442, 22447` (112,222 total). Each session ran 18 bowl/seal cases; 90 source-derived Native answer vectors matched the independent Host sauce/selection oracles.
- Compared WorkCounts, six final Q residues, `orderAt46`, all 12 retained post-stir sums, A0, direction, short rank and accepted A_k.
- Host preflight: 72 pairs / 1,296 answer queries; 1,008 numeric-successor mutants rejected. Ring preflight: 190,138 full-width boundary checks, 20,830 small-ring literal steps, 226 full-width literal steps, 56 wrap-period/reverse checks, 256 direction bytes, and 37,937 backwards-as-forward mutant cases rejected.
- Native370 job `139428829089`: `A5/370/40`, 8,585 frames. Native371–392 regression jobs completed successfully on the same source SHA.
- RGBDS 1.0.4; `ROM_HEADER=PASS`. Measured MAP: ROM0 16,166 used / 218 free; ROMX 14,531 used / 1,853 free; WRAM0 2,866 used / 1,230 free.
- Artifact `15051653823`, ZIP SHA-256 `c1a6786d11405a04b4b9d36adcab9d0fb92ecaf5b669250b150ee3292278dbf9`, downloaded and verified. Contents: 32,768-byte ROM, MAP and SYM. ROM header checksum computed and stored value both `0xF8`.

**Measurement correction:** the earlier 1,246-byte WRAM0-free figure was a 16-byte transcription error. The artifact MAP is authoritative: 2,866 used + 1,230 free = 4,096 bytes. Issue #30 comment 7171411161 and the project tracker were corrected. This does not affect the acceptance gate, which requires ROM0 free >=10.

**Acceptance boundary:** accept Native393 E–K / bowl-answer flow only. Gate/year generation and candidate enumeration remain outside Issue #30 and await explicit user authorization. No Stage2, main/merge, or release was started.
