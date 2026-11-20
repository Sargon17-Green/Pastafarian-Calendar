# Stage1 isolated fifth hidden drop — Native376 candidate

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Parent: `ed027ca301c0e7cb369787bf2f6ee71097df02f4`
Contract: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

## Input/output
Active invocation with valid ordinal lease, signed32 Foundation-relative c/t
offsets and five canonical 16-byte little-endian stone residues at iteration
i=5 from CalendarStoneTransitionRange. Success status 0 writes exactly one
canonical 16-byte hidden result; invalid input returns 2 and idle returns 6.
On failure/idle preserve published output. In all cases source stones, c/t,
owner, lease, and physical SRAM are immutable.

Counts A=work calc, B=work target, C=distance, D=A+B, E=direction.
x=SAVE(A+11B+16C+22D+24E+sum(stones_i5));
for r=1..7: x=SAVE(x*x+3*x+stones_i5[(r-1)%5]+r),
using the prior x for BOTH terms. SAVE(y)=1+((y-1) mod (2^127-1)).
No golden-derived algorithm or fixture.

## Acceptance evidence required (not preclaimed)
CI exact HEAD SHA, eight jobs completed/success: verify,
Native370–375 regressions and new Native376. Independent Host 72/72
signed32 pairs with endpoints and full normative E–K oracle parity.
Real RGBDS/PyBoy A5/376/40 within <=30000 frames, ROM_HEADER PASS,
ROM0 measured free>=10, standard Native370 <=9000 frames and fixed
370 dispatch cases, isolated Native371..375 <=30000.
Native check 16-byte output, five i5 source stones (80 bytes),
invalid canonical source and idle preservation, counts, offsets,
lease/owner and physical SRAM. No acceptance of hidden6..7, visible,
bowls, poststirs, answer, entire Stage1, main, merge or Stage2.
