# Stage47 / DISCOVERY43 — interleaved occupied-destination probes
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage46 accepted: 7128885f1eb22f58de3e7a4523ad20b6a910ad6b, 47/47 run 43767195882.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43767195882/artifacts/14184034045
SHA256: c8ee746d32998684b2134a15e3c4f380ff739bb6dcbdd7550b529322f2965ccb

## New bounded question
Stage46 rotates a single free/recreated output slot with three survivors
but occupied-output rejection is tested only twice per case. Stage47 tests
occupied destination BEFORE each of 192 rolling free operations: all four
results are then live and must be preserved byte-exact and pointer-distinct,
caller inputs must remain allocated, and status must be 175. After the
successful reject, free one slot, verify three live, recreate the slot and
verify four distinct live. Existing two fixed occupied probes per case remain.
Expected totals: 192 new + 48 prior = 240 rejects and 240 preservation checks.

## Independent oracle, boundaries
24 unique ordered C/T cases: widths n=3/9/320/8192, offsets j=1..6.
Let X=10^(n-1)+(5j+2), Y=10^(n-1)-(2j+5);
C=X, T=Y for odd j and swapped for even j.
Output k uses C+(k-1) for odd j or C-(k-1) otherwise.
Distance+1 equals 7j+8+k-1 for 96 BigInt comparisons.
Independent source-literal Node oracle checks all 24 permutations, six
8192-digit cases, and 192 occupied-state preservation model steps followed
by 192 four->three->four transitions, using a separate Set-based oracle.
All cases are deterministic and bounded.

## Native acceptance
On exact SHA natural push, expect 48/48 completed/success jobs. Strict
GnuCOBOL 3.1.2 -Werror, compile<=300s/run<=120s/job<=20min.
Require ORACLE_PASS=96/96, PERMUTATIONS_STATIC=24/24,
OCCUPIED_MODEL=192/192, ROLLING_MODEL=192/192,
ROLL_PROBES=192, ROLL_FREES=192, ROLL_REUSES=192,
ROLL_THREE=192, ROLL_QUADS=192, OCCUPIED_REJECTS=240,
REJECTED_PRESERVED=240, prior lifecycle counters, UNEXPECTED_FAILURES=0,
HEAP_MEASURED=YES, HEAP_LIVE_POST_RELEASE=0,
RESULT=PASS_STAGE47_INTERLEAVED_OCCUPIED_PROBE_DISCOVERY_NATIVE,
STAGE47_NATIVE_GATE=PASS. Save run/job/artifact/digest/log.
No presumed bug without reproduced failure. No main/merge/release.
