# Stage44 / DISCOVERY40 — partial-gap reuse with live output survivors
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage43 accepted at 04dca8d047ab5e7d8ab477cf00516e8aa42fc3d2, 44/44 run 42188702823, evidence https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42188702823/artifacts/13489192366 SHA256 f38efb668ecff3c04ad2d680e0518028a87c3183df029c7bb7ca150b3dec3a02.

## Distinct behavior
Stage43 re-created the four output slots only after *all* four were freed.
Stage44 releases the FIRST TWO slots in each of the 24 different 4! orders,
checks each surviving output's decimal text, metadata, and pointer identity,
then RE-CREATES those two slots in REVERSE ORDER while the other two original
outputs remain live. Assert all four disjoint valid pointers and exact text
after regeneration. Subsequently execute the full Stage43 all-four
release/rebuild/occupied-rejection/cleanup sequence. This is a new partial
reuse/lifetime test, not a claim of a historical defect.

## Oracle and boundaries
Width n in {3,9,320,8192}, six j per width => 24 unique pairs.
X=10^(n-1)+(5j+2), Y=10^(n-1)-(2j+5); odd j takes (C,T)=(X,Y),
even j swaps. For output slot k=1..4 take C'=C+s(k-1), s=+1 odd and
-1 even. Exact |T-C'|+1=7j+8+k-1. Independent test-only Node.js BigInt
parses the 96 source decimal literals and verifies this closed form.
A separately enumerated permutation oracle checks all 24 unique orders.
Six width-8192 tests. Native partial counters must be 48 successful frees,
48 successful recreations, 24 complete partial cycles; 48 occupied-output
status-175 rejections and 48 all-survivor checks remain required.
All failure paths release caller-owned memory.

## CI acceptance
On exact Stage44 SHA require 45/45 completed/success jobs, GnuCOBOL
3.1.2 strict -Werror, compile<=300s, run<=120s, job<=20min;
artifact uploaded even on failure and a recorded SHA256.
ORACLE_PASS=96/96, PERMUTATIONS_STATIC=24/24;
INITIAL_OUTPUTS/QUAD_LIVE/ORDER_COVERAGE/MID_HEAP_ZERO/
REVERSE_REBUILT/FINAL_CLEANUP/RUNS/PASS each 24.
PARTIAL_FREES=48, PARTIAL_REUSES=48, PARTIAL_CYCLES=24,
OCCUPIED_REJECTS=48, REJECTED_PRESERVED=48,
UNEXPECTED_FAILURES=0, HEAP_MEASURED=YES,
HEAP_LIVE_POST_RELEASE=0; exact Stage44 result and native PASS marker.
No presumed expected-red without witness. No changes to production,
main, merge, release or full-calendar integration.
