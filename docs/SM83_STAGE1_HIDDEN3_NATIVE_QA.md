# Stage1 isolated k3 hidden drop — Native374 candidate

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Parent: `a3cd295eb93577428370451a5cf7ac7bf619fca6`
Contract: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

## Input/output and negative cases
Active owner/ordinal invocation, signed32 Foundation-relative c/t offsets,
five canonical i=3 source stones from CalendarStoneTransitionRange and
wCalendarStoneIteration=3. Output canonical 16-byte wCalendarHiddenOutput,
status 0 success, 2 invalid, 6 idle. Invalid/idle preserve old output;
source stones, offsets, lease/owner, SRAM must not be mutated.
Initial x=SAVE(A+7B+10C+14D+16E+sum(stones_i3)).
For r=1..7 calculate SAVE(x*x+3*x+stone_i3[(r-1)%5]+r)
using the previous round's x for both occurrences.
Reuse exact 256-bit multiplication and canonical 127-bit SAVE.

Independent Python big-int oracle evaluates i2 and i3 explicitly and
compares 72 signed32 cases including endpoints against the full independent
E–K oracle. Fixture bytes are postconditions only.
Native374 compares the 16-byte output, 80 stone bytes, offsets,
counts, owner lease, physical SRAM, invalid canonical state, and idle.

## Acceptance
Exact SHA verify+native370/371/372/373/374 completed/success.
Host k3 72/72, ROM_HEADER PASS, ROM0 free>=10, PyBoy A5/374/40
within <=30000 frames, default Native370 <=9000, Native371–373
existing 30000 bounds retained. This accepts ONLY k=3, not hidden4–7,
visible, bowls, poststirs, answer flow, full Stage1, main or Stage2.
