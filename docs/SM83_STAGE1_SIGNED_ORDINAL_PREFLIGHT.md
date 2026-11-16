# Stage1 signed ordinal preflight — ROMX bank 1

Project: PC-BRANCH-SM83-ASSEMBLY-GEEZ; branch SM83-Assembly+ግዕዝ.
Depends on accepted Native284–289 lifecycle CI 43767640971 at 05cd129a420369235dfb93472677d3aa1285dd8c.

## Exact contract

- Input: existing active leased invocation, signed ordinal `(sign, length, magnitude)` in that invocation's SRAM; sign 0 nonnegative or 1 negative, 24-bit unsigned little-endian length, magnitude stored little-endian from logical owner offset 0.
- Capacity: limited by actual owned SRAM banks, at most 13 x 8192 = 106496 bytes; arbitrary width *within this hardware limit*, not unlimited precision.
- Canonical zero: sign=0, length=0. For length>0 the high magnitude byte must be nonzero, and the final logical byte must exist inside the same live active owner's lease.
- Output: `wCalendarStatus=0` valid; 2 invalid sign, negative zero, leading zero, out-of-capacity or unowned top byte; 6 no active invocation. No calendar date is output.
- Failure and success preserve raw leased SRAM bytes and lease tags. Owner lookup scratch and currently selected physical bank may change. `CalendarInvocationBegin` initializes metadata; successful `CalendarInvocationAbort` zeroizes the complete owned bank(s) and resets ordinal metadata; failed abort retains it.
- This is a preflight step, **not** arbitrary-length addition, signed day calculation, canonical SAVE(2^127-1), state commit, date conversion, or Ge'ez naming. All of these remain open. Production dispatcher remains 0x40.

## Evidence gates

Native cases 290–299 exercise idle, canonical zero, negative zero, +1, -1, leading zero, owner capacity overflow, sign 2, mutated request versus saved owner, and abort SRAM/metadata scrub. Host integer oracle checks >64k-bit signed magnitudes, boundary lengths, sign/length cross-product, SRAM immutability and scrub. Real RGBDS build, ROM0 measured, DMG header, PyBoy A5/299/40 <=9000 frames and exact-SHA completed CI required before accepting this increment. No main or Stage2.
