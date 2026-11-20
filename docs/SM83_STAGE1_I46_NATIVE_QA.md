# SM83 Stage1 — isolated Native i=46 endpoint acceptance

PROJECT_ID: `PC-BRANCH-SM83-ASSEMBLY-GEEZ`
Branch: `SM83-Assembly+ግዕዝ`
Base: `cd75f3e0862d85cd2839f71e62d92b60657e106c`; accepted Native365–370 in CI44701281113.

## Isolation and measurement

The existing `build/calendar.gb` still executes Native cases 1–370
with `MAX_BOOT_AND_TEST_FRAMES=9000`. The optional macro
`STAGE1_I46_NATIVE_BENCH` replaces only the boot test dispatch in
`build/calendar_i46.gb`; it does not append the expensive 46-round
calculation to the standard path. `make build/calendar_i46.gb`
selects the variant; `tests/test_rom_i46.py` observes actual PyBoy
markers (A5/371/40), bounded at 30000 frames. An independent CI job
builds the variant with RGBDS v1.0.4, measures ROM0 from the linker
map, and runs the emulator.

## Contract

Seed: five nonzero 127-bit residues (17,29,43,71,101); target 46.
For i=2..46, apply five named simultaneous polynomial residues modulo
M=2^127-1 with SAVE(0)=M. Expected output is five little-endian 16-byte
integers computed by a Python bigint oracle, *not* the algorithm under test.
Native371 checks all 80 output bytes, preserved 80-byte source, owner-tag
and physical SRAM witness, abort scrub, and output immutability on idle.
No claim about seven hidden drops, 46 visible drops or calendar fields.

## Gates

- Host fixture oracle: 5/5 independent bigint residues plus static wiring.
- Default workflow: both verify and dmg-native-smoke completed/success;
  `ROM_HEADER=PASS`, ROM0 measured free>=10, A5/370/40 <=9000 frames.
- Separate workflow: dmg-stone-i46-native completed/success on exact SHA;
  `ROM_HEADER=PASS`, ROM0 free>=10, and A5/371/40 <=30000 frames.
- A queued or in-progress job is not acceptance. Do not open Stage2.
