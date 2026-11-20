# Stage1 isolated second hidden drop — Native373 candidate

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Predecessor: `33634d6a9648bd8cdedb32ae1b469d0ca3718d51`
Contract: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

## Bounded interface

Inputs: active owner/ordinal invocation, signed32 Foundation-relative c,t offsets,
five canonical i=2 stones in `wCalendarStoneOutput` produced by
`CalendarStoneTransition2`, and `wCalendarStoneIteration=2`.
Output: one canonical 16-byte SAVE residue in `wCalendarHiddenOutput`.
Status: 0 success, 2 invalid source or iteration, 6 idle. Invalid/idle
must leave the previously published output unchanged. Five stone source
residues, original offsets, owner and physical SRAM are read-only.

Compute weighted k=2 expression A+5B+7C+10D+12E+sum(stones at i=2),
then seven successive SAVE(x*x+3*x+stone[(r-1)%5]+r).
Reuse the already accepted wide multiplication and modulo kernel.
The Native373 fixture checks the 16 output bytes, five stones, offsets,
count fields, owner/lease/SRAM, invalid canonical source and idle output.
The independent Host oracle uses a direct closed-form i=2 stone computation,
checks 72 signed32 pairs against the existing full E..K independent oracle;
never use expected fixture bytes to compute the model.

Acceptance: verify, normal Native370, isolated Native371, isolated Native372
and new Native373 jobs all completed/success on identical SHA. Require
ROM_HEADER PASS, measured ROM0 free>=10, PyBoy A5/373/40 <=30000 frames;
normal 370/9000 and prior standalone baselines retained. GitHub job success
is not inferred before logs confirm the individual witnesses.

This step accepts k=2 only. The remaining hidden k=3..7, visible1..46,
six-bowl simultaneous updates, 12 retained post-stirs and answer flow
remain out of scope. No Stage2, main changes, merge or release.
