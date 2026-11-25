# SM83 Stage1 Native393 — isolated integration candidate, NOT ACCEPTED
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

## Acceptance gate still open
Run the five-pair Native matrix on the exact new SHA; inspect all five A5/393/40 completions, the independent Host comparisons, completed CI jobs and ROM/map/sym artifact. Require RGBDS 1.0.4, ROM_HEADER, ROM0 free >=10, each Native393 session <=120000 frames and Native370 <=9000, plus retained Native371..392 regression. A candidate run is not Stage1 acceptance. No Stage2/main/merge/release.
## Expanded-run diagnosis and correction
Run 45672668795 on `171b825abfa4cbbb4dcc1697be8d892781d17fc8`: 24/25 jobs succeeded; Native returned E0. Diagnostic run 45673463027 on `f5747b1c7de8b5079af75726eff037a14bb51092` showed the first nonfoundation source vector passed and the remaining-case counter reached 13, after which the table cursor was replaced by the counter address. Root cause was the test loop loading `HL=wCalendarAnswerSavedByte` before looping; the correction decrements/stores through A and preserves HL. This is a Native test-harness defect, not evidence of an A0/rank runtime failure. Re-run the expanded suite on the corrected exact SHA.

## Prior Foundation-only exact-SHA result
Run 45673927216 on `5ccf201158ee3ac1a29ff1974e5d251de81f63c0`: 25/25 jobs success; Native393 `A5/393/40` in 22,442 frames; 18 Foundation bowl/seal vectors, 26 synthetic boundaries, invalid counts, output and input snapshots passed. This was still one Foundation c/t pair; the five-pair matrix above is the next acceptance gate.
