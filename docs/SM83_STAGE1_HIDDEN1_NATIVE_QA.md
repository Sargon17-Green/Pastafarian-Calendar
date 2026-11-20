# Stage1 isolated first hidden drop — candidate, not accepted

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Parent: `53dfe1b4fc597f6b72967c820a06f49d466cf676`
Issue: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

## Measurable submilestone of hidden7/visible46

Inputs: signed32 Foundation-relative c/t offsets in WRAM, active valid invocation.
Native routine computes five bounded work counters, first hidden k=1 starting
from five fixed first stones, and seven independent sequential SAVE grind steps.
Output: one canonical little-endian 16-byte residue in wCalendarHiddenOutput.
Status 0=success, 6=idle; output must not change on idle. Inputs, owner,
and physically leased SRAM are not modified. No visible drops or final bowls.

Independent Python oracle derives day counts directly from signed32 offsets,
calculates the k=1 polynomial and seven modular squares, compares the ROM
fixture only as a postcondition, then checks 72 input pairs against the
pre-existing E..K reference. A dedicated 372-case native cartridge checks
16 exact bytes, five count fields, offsets, owner, SRAM and idle immutability.

The original cartridge must remain A5/370/40 within 9000 frames. Existing
i46 variant must remain A5/371/40 within 30000 frames. The new standalone
cartridge must link with RGBDS v1.0.4, show ROM_HEADER PASS,
ROM0 free>=10, and A5/372/40 within 30000 frames in PyBoy. All jobs
verify / dmg-native-smoke / dmg-stone-i46-native / dmg-hidden1-native
must be completed/success on the exact candidate SHA to accept this
submilestone. A pending workflow is not PASS. No main/merge/Stage2.

NEXT after acceptance: generalize first drop to k=1..7 with independent
Native milestones, then implement 46 visible recurrences, the simultaneous
six-bowl snapshot updates, retained post-stirs and answer flow. Never
infer hidden7/visible46 acceptance from hidden1.
