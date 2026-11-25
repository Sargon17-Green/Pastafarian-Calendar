# SM83 Stage1 Native393 — isolated integration candidate, NOT ACCEPTED
PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Parent: e8bc74de2f3cbee4010940a5599f1d7c7ca620af

## Native393 contract and coverage
The isolated target is `make build/calendar_bowl_answer_rank.gb`; it does not change the default ROM or earlier Native370..392 targets.

- Runtime adapter validates active ordinal, bowl 1..6, seal 10..12 and count 1..19044 before publication; it adapts Native392 A0/direction into the short-rank kernel ABI and publishes A0, direction, rank and accepted A_k atomically.
- 18 source-derived vectors use the real post-46+12 Q and orderAt46: four Foundation and fourteen nonfoundation combinations covering all six bowls and seals 10..12. Independent Python computes A0, direction, short rank and accepted A_k from the captured Q/order; the ROM bench checks the same values.
- 26 synthetic full-width boundary vectors exercise A0=1/M, L and L+1, counts 1/2/922/19044, both directions and forward/backward wrap through the same adapter/kernel path. The separate host ring oracle compares closed form with literal ring traversal, checks L-1/L/L+1 and period/reverse properties.
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
Run the expanded test suite on the exact new SHA; inspect completed CI jobs, Native log and ROM/map/sym artifact. Require RGBDS 1.0.4, ROM_HEADER, ROM0 free >=10, Native393 A5/393/40 <=120000 frames and Native370 <=9000, plus retained Native371..392 regression. A candidate run is not Stage1 acceptance. No Stage2/main/merge/release.
