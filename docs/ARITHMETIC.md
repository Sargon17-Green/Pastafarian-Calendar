# SM83 arithmetic ledger — Stage 1 (native smoke subset verified)

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

NATIVE_STATUS=BOOTSTRAP_SMOKE_VERIFIED_66_CASES_RUN_38781963706. This is a self-contained arithmetic subset,
not a completed normative oracle or calendar implementation.
Remaining work includes signed date counters, more than 256-bit math
for combinatorial counts, Year 5000, full source catalog and native QA.

## Exact banked comparison (native smoke passed)

`BankedCmp4096` compares the 4096-byte magnitudes in SRAM banks 0 and 1,
starting at the most-significant end. It stores **0 (equal), 1 (A>B), or
2 (A<B)** in `wCmpStatus`, without writing either operand or the output
bank. The selected SRAM bank on return is 1. The test suite is expanded from
33 to 40 cases; cases 34..40 check the full-width equality scan, dominance
of the high byte, the low-byte tie-breaker, both inequality directions,
non-mutation and repeated-call status reset. The seven ROM tests passed under **native SM83 emulation** in GitHub
Actions run 38686711132. This is still only a fixed-capacity primitive.

## Exact signed-magnitude 4096-byte sum (native smoke verified)

`SignedAdd4096` combines canonical signs 0/1 with 4096-byte magnitudes
from SRAM banks 0 and 1. The exact output is up to 4097 bytes in bank 2,
with the canonical zero sign 0. Opposite signs use exact unsigned magnitude
comparison and either A-B or B-A. Negative zero and invalid sign bytes
produce an explicit status and scrub the output. Inputs are preserved.

Native ROM cases 53..66 passed in GitHub Actions run 38781963706
(RGBDS v1.0.4 / PyBoy 2.x, case 66, A5, 813 frames);
the independent host reference passed 1,088 cases.
This does not imply unrestricted BigInt arithmetic, ownership, full
selection/weaving or a completed normative calendar.
