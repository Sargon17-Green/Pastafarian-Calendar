# Stage1 hidden1..7 -> visible1 chain, Native380 candidate

PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Predecessor: 378a18c91ecceab04790b9041d43f75eafcd0f23, Native379 accepted CI44893028691.

## Input and publication contract
Inputs are signed32 offsets c,t from Foundation and a live validated ordinal/owner lease.
The chain seeds its own five normative stones (17,29,43,71,101), computes
independent i=2..7 stone states by the accepted ROMX transition, calls the
seven independently accepted hidden-drop ABIs chronologically, and keeps all
seven 16-byte results in invocation-local wCalendarHiddenRetained (112 bytes).
Only slots 1,3,7 are copied into the existing wCalendarVisibleInputs. The
existing accepted visible1 routine is called with initial stones and those
retained inputs. Published wCalendarVisibleOutput changes only after success.
Internal scratch/retention is not an externally committed bowl record. Status:
0 success, 2 invalid ordinal, 6 idle. On preflight failure, published output
is unchanged; no mutation of caller offsets, owner tags or physical SRAM.

## Independent QA oracle
Host uses Python unbounded integers for five-stone and seven hidden
recurrences and independently compares 72 signed32 offset pairs including
both endpoints. Foundation hidden1..7 16-byte LE checks and visible1 expected
3fc483d39637b7a59a465836975a9d2a. Native380 must check all seven
retained outputs (112 bytes), the exact H1/H3/H7 handoff, the first-visible
result (16 bytes), canonical seed retention, unchanged offsets, active lease,
physical SRAM sentinel, invalid negative-zero early rejection, published-output
preservation, abort/idle handling. All tests are on actual ROM: RGBDS v1.0.4,
ROM_HEADER PASS, measured ROM0 free >=10, PyBoy A5/380/40 <=30000 frames.
Standard Native370 and isolated Native371..379 remain separate unchanged
routes and must all pass on the exact commit before this milestone is accepted.

## Stage boundary
No visible2..46, simultaneous bowl updates, post-stirs, A0/direction, year
selection, main, merge, release or Stage2. If compile/runtime failure is seen,
patch only observed cause at a new SHA and do not infer PASS from Host-only QA.
