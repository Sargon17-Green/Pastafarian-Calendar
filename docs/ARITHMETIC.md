# SM83 arithmetic ledger — Stage 1 (unverified native)

All production operations in this ledger are SM83 instructions assembled with RGBDS.
Host Python is used only for independent fixtures and ROM inspection.

- Clear16 / FillM: write a 16-byte little-endian buffer.
- Save127: exact canonical SAVE on unsigned 128-bit inputs.
- Add16: exact 16-byte addition with the explicit 0..M input precondition.
- SaveWide256: exact canonical SAVE on unsigned 256-bit inputs by processing
  256 input bits from most to least significant. It preserves wWideInput.
- Mul128x128: exact full-width unsigned 128-bit multiplication producing 256
  bits (wWideInput); it preserves both inputs, wMulA and wMulB.
- SaveWide256(Mul128x128(A,B)) computes the exact Mersenne-SAVE for products
  without floating point or an external runtime.

Reduction invariant: after reading each input prefix, wValue contains
its modulo M representative, with zero represented as M. Doubling is
performed in full 128-bit width and Save127 folds bit 127 using the
identity 2^127 == 1 (mod M).

Multiplication invariant: after reading each bit of A from high to low,
the output accumulator is the exact product of the processed prefix of A
and B. Each step shifts the 256-bit buffer and conditionally adds B with
carry propagated through the higher bytes. 128 full bits are processed.

ROM tests 1..10 check the original 128-bit SAVE and Add16 cases.
Tests 11..16 cover wider SAVE values including 2^255 and 2^256-1.
Tests 17..22 cover exact full-width products and their reduced values.

NATIVE_STATUS=UNVERIFIED. This is a self-contained arithmetic subset,
not a completed normative oracle or calendar implementation.
Remaining work includes signed date counters, more than 256-bit math
for combinatorial counts, Year 5000, full source catalog and native QA.

## Exact banked comparison candidate (native check pending)

`BankedCmp4096` compares the 4096-byte magnitudes in SRAM banks 0 and 1,
starting at the most-significant end. It stores **0 (equal), 1 (A>B), or
2 (A<B)** in `wCmpStatus`, without writing either operand or the output
bank. The selected SRAM bank on return is 1. The test suite is expanded from
33 to 40 cases; cases 34..40 check the full-width equality scan, dominance
of the high byte, the low-byte tie-breaker, both inequality directions,
non-mutation and repeated-call status reset. Completion requires **native
PyBoy execution**, not only host reference tests.
