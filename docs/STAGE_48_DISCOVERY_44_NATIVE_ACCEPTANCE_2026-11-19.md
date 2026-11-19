# Stage48 / DISCOVERY44 — native acceptance (2026-11-19)
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Accepted exact SHA: 9413a74c17faaf302e4a922cddf40e2ae31b3600
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44392104589
Run attempt 1: completed/success; GitHub /jobs?per_page=100 shows 49/49 completed/success.
Native job: 135112206876 stage48-full-occupied-matrix-discovery-native, completed/success.
GnuCOBOL: cobc (GnuCOBOL) 3.1.2.0; strict -Werror compile and test succeeded.
Planning + independent static markers asserted by the native CI gate:
STAGE48_PLANNING_ORACLE=96/96
STAGE48_PLANNING_OCCUPIED_MATRIX=768/768
STAGE48_PLANNING_ROLLING_MODEL=192/192
STAGE48_PLANNING_PERMUTATIONS=24/24
STAGE48_ORACLE_PASS=96/96
STAGE48_PERMUTATIONS_STATIC=24/24
STAGE48_OCCUPIED_MATRIX_MODEL=768/768
STAGE48_ROLLING_MODEL=192/192
Native evidence:
STAGE48_INITIAL_OUTPUTS=24
STAGE48_QUAD_LIVE=24
STAGE48_ORDER_COVERAGE=24
STAGE48_REVERSE_REBUILT=24
STAGE48_MID_HEAP_ZERO=24
STAGE48_FINAL_CLEANUP=24
STAGE48_OCCUPIED_REJECTS=816
STAGE48_REJECTED_PRESERVED=816
STAGE48_PARTIAL_FREES=96
STAGE48_PARTIAL_REUSES=96
STAGE48_PARTIAL_CYCLES=48
STAGE48_PAIR_SWITCHES=24
STAGE48_ROLL_FREES=192
STAGE48_ROLL_REUSES=192
STAGE48_ROLL_THREE=192
STAGE48_ROLL_QUADS=192
STAGE48_ROLL_PROBES=768
STAGE48_TARGET_SLOT_1=192
STAGE48_TARGET_SLOT_2=192
STAGE48_TARGET_SLOT_3=192
STAGE48_TARGET_SLOT_4=192
STAGE48_RUNS=24
STAGE48_PASS=24
STAGE48_UNEXPECTED_FAILURES=0
STAGE48_HEAP_MEASURED=YES
STAGE48_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE48_FULL_OCCUPIED_MATRIX_DISCOVERY_NATIVE
STAGE48_NATIVE_GATE=PASS
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44392104589/artifacts/14469173883
Artifact ZIP SHA256: 2b3381833534a1c32ff6dbe9c7cead7db2af309e41ec948c0859a579468fc95e
Artifact ZIP verified locally: SHA256 matches GitHub run API digest; ZIP CRC PASS (single stage48-native.log member, 2078 uncompressed bytes); embedded PROJECT_ID and HEAD match.
Verdict: ACCEPTED_NO_DEFECT_REPRODUCED_IN_24_BOUNDED_CASES; evidence supports Stage48 only, not full-calendar integration.
Prior parent run 44370189160 lacked four contract assertions and was NOT used as final acceptance evidence.
Host warnings about _FORTIFY_SOURCE and Node.js deprecation do not imply a COBOL compilation failure; these are retained as non-blocking observations.
No main/merge/release or production source modification.
