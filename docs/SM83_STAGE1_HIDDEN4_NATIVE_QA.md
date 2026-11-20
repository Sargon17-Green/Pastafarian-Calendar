# Stage1 isolated k4 hidden drop — Native375 candidate

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Parent: `fafb10650e32c4da7a40692aea566285b1347021`
Contract: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

## Input/output and negative cases
Active owner/ordinal invocation, signed32 Foundation-relative c/t offsets,
five canonical i=4 source stones from CalendarStoneTransitionRange and
wCalendarStoneIteration=3. Output canonical 16-byte wCalendarHiddenOutput,
status 0 success, 2 invalid, 6 idle. Invalid/idle preserve old output;
source stones, offsets, lease/owner, SRAM must not be mutated.
Initial x=SAVE(A+9B+13C+18D+20E+sum(stones_i3)).
For r=1..7 calculate SAVE(x*x+3*x+stone_i3[(r-1)%5]+r)
using the previous round's x for both occurrences.
Reuse exact 256-bit multiplication and canonical 127-bit SAVE.

Independent Python big-int oracle evaluates i2, i3 and i4 explicitly and
compares 72 signed32 cases including endpoints against the full independent
E–K oracle. Fixture bytes are postconditions only.
Native375 compares the 16-byte output, 80 stone bytes, offsets,
counts, owner lease, physical SRAM, invalid canonical state, and idle.

## Acceptance
Exact SHA verify+native370/371/372/373/375 completed/success.
Host k4 72/72, ROM_HEADER PASS, ROM0 free>=10, PyBoy A5/375/40
within <=30000 frames, default Native370 <=9000, Native371–373
existing 30000 bounds retained. This accepts ONLY k=4, not hidden5–7,
visible, bowls, poststirs, answer flow, full Stage1, main or Stage2.
