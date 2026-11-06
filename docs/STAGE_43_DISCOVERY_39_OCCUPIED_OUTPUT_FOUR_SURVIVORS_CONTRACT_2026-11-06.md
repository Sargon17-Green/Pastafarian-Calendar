# Stage43 / DISCOVERY39 — occupied-output rejection with four live survivors
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage42 15a02b3a83ede729835b498c1077dee9c4b905bb accepted, run 42177234521 completed/success 43/43.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42177234521/artifacts/13484108040

## Scope and independently testable behavior
Stage36 verified occupied-output status 175 for a single output. Stage42
verified all 4! release orders for four outputs. Stage43 combines these
properties: reject calls targeting occupied slots while three other
independently owned results remain live, without changing any result.
No historical defect or expected-red is assumed without an actual witness.

Input basis: widths n={3,9,320,8192}, j in 1..6. X=10^(n-1)+(5j+2),
Y=10^(n-1)-(2j+5); odd j takes (C,T)=(X,Y), even j swaps.
Output slot k in 1..4 uses C'=C+(k-1) if j odd, C'=C-(k-1)
otherwise. Oracle: |T-C'|+1 = 7j+8+k-1.
An independent Node.js BigInt parser validates 96 actual COBOL-emitted
source literals against this closed form. 24 ordered distinct base pairs,
24 distinct exhaustive release permutations, six width-8192 cases.

In each case produce four results; assert exact output decimal values,
metadata sign/chunks/head/tail snapshots and disjoint live pointers.
Attempt another MONSTER-DISTANCE call into the first-to-release occupied
slot, demanding status 175, input pointers still live, and all four
survivors unchanged. Free outputs in the selected order with survivor
checks; measured HEAP-LIVE must be zero. Rebuild in reverse order and
repeat rejection on the last-to-release occupied slot, checking survivors
again. Release in original order. Thus 48 occupied-output rejections
and 48 full-survivor checks across 24 complete cases. Cleanup on failure.

Exact-SHA Native acceptance: 44/44 completed/success jobs, GnuCOBOL 3.1.2.0
strict -Werror, compile<=300s, execute<=120s, job<=20min; upload evidence
even on failure. Gate markers: ORACLE_PASS=96/96,
PERMUTATIONS_STATIC=24/24, INITIAL_OUTPUTS/QUAD_LIVE/
ORDER_COVERAGE/MID_HEAP_ZERO/REVERSE_REBUILT/FINAL_CLEANUP/
RUNS/PASS each 24; OCCUPIED_REJECTS=48; REJECTED_PRESERVED=48;
UNEXPECTED_FAILURES=0; HEAP_MEASURED=YES; HEAP_LIVE_POST_RELEASE=0;
exact Stage43 result and STAGE43_NATIVE_GATE=PASS.
Static QA is not Native evidence. No main/merge/release/production changes.
