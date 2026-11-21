# Stage1 k7 — isolated Native378 candidate

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Parent: `c5b26281aa926bdcf5e2b4c44e633f4765cd0410`
Normative contract: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

Input: live owner/lease and signed32 c/t Foundation-relative offsets; five
canonical 16-byte LE stones at iteration 7 from a simultaneous ROMX update.
Counts A,B,C,D,E are evaluated natively using WorkCountsFromOffsets32.
Initial x=SAVE(A+15B+22C+30D+32E+sum(stones_i7)).
For r=1..7, x=SAVE(x*x+3*x+stones_i7[(r-1)%5]+r), both using OLD x.
SAVE(z)=1+((z-1) mod (2^127-1)). Output is exactly 16 LE bytes.
Status 0 success, 2 invalid, 6 idle; output published only on complete success.
Source stones, original offsets, counters, owner, lease, SRAM unchanged;
invalid and idle preserve previously published output.

Independent Foundation expected output LE: `c2d2f89286948cd48720811dc232a304`.
Five i7 stone states are checked as an 80-byte fixture. Independent Host
72 signed32 pairs including both endpoints, with full E–K sauce differential;
no computation from goldens. Native378 checks invalid/idle and state safety.

Acceptance requires all TEN exact SHA jobs completed/success, including
verify, Native370, Native371, hidden Native372..378. Host72, ROM_HEADER PASS,
ROM0 free>=10 both standard and isolated, Native370 A5/370/40 <=9000
frames, isolated Native371..378 A5/<case>/40 <=30000 frames.
Static authoring is not Native PASS. No visible46, bowls, poststirs, answer,
whole Stage1, main/merge or Stage2 acceptance is implied.
