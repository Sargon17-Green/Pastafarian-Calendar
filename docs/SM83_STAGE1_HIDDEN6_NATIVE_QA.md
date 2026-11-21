# Stage1 hidden k6 — isolated Native377 candidate

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Parent: `d044b36c343c7cb7e0aa548f8435429776cf125f`
Normative contract: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

Active ordinal lease and signed32 Foundation-relative offsets c/t.
Source: 5 canonical 16-byte LE simultaneous-transition stones at i=6.
Counts A,B,C,D,E from WorkCountsFromOffsets32.
x=SAVE(A+13*B+19*C+26*D+28*E+sum(stones_i6)).
For r=1..7: x=SAVE(x*x+3*x+stones_i6[(r-1)%5]+r).
SAVE(z)=1+((z-1) mod (2^127-1)); use OLD x for both terms.
Status success0, invalid2, idle6; publish 16 LE bytes only on success.
No change to input stones, offsets, lease, work counters or physical SRAM;
rejected/idle invocation preserves previous output.

Independent Host k6 integer recurrence: 72 deterministic signed32 cases
including endpoints, checked against full normative E–K sauce oracle,
no golden-derived computation. Native377 Foundation expected 16 bytes
c07548de5caf640231077ab3ea815537, and exactly 80 bytes of i6 stones.
Native checks output/source, rejection, idle, counters, offsets, owner,
lease, physical SRAM. Nine CI jobs on exact commit must all finish
completed/success; ROM_HEADER PASS, ROM0 free >=10, Native370 A5/370/40
<=9000 frames, Native371..377 A5/<case>/40 <=30000 frames.
Before CI: source candidate only, no Native claim. This milestone does
not accept hidden7, visible, bowls, poststirs, answer, all Stage1 or Stage2.
