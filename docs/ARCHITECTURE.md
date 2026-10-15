# SM83 / DMG architecture — Stage 1 bootstrap

The production target is the original monochrome Game Boy (DMG), with its
Sharp SM83 8-bit CPU. There is no GBC-only mode, host CPU code, or C runtime.
RGBASM, RGBLINK and RGBFIX are build-time tools, not code executed on
the console. Optional PyBoy is test infrastructure only.

## State contract

Each later calendar invocation must own its semantic context, and must not
share mutable state with previous invocations. The bootstrap has one static
WRAM frame because it runs only at startup; it is not yet an invocation engine.
Future stages must establish a per-call memory ownership and rollback model
before reentrancy is claimed.

WRAM observable bootstrap locations:

| Address | Name | Meaning |
|---|---|---|
| C000 | wTestResult | A5 arithmetic smoke PASS; E0 failure; 00 unstarted |
| C001 | wTestCase | currently executed test (1..33) |
| C002 | wRunStatus | 40 means calendar engine deliberately not implemented |
| C003..C012 | wValue | 128-bit LE working value |
| C013..C022 | wAddend | 128-bit LE addend |
| C023..C032 | wExpected | 128-bit LE expected result |

Save127 handles a single 128-bit unsigned input, exactly, with
M=2^127-1; it is not a substitute for arbitrary precision.
Add16 has the explicit precondition 0 <= a,b <= M; it does not support
unrestricted 128-bit addition with overflow.

## DMG-compatible external scratch memory

The DMG offers 8 KiB internal WRAM, which is insufficient for multiple
simultaneously live multi-kilobyte exact integers. This branch therefore
selects an MBC5+RAM cartridge (header 0147=1A, RAM-size 0149=04)
with 16 banks of 8 KiB = 128 KiB external RAM. This remains compatible
with the original monochrome DMG; it is a *cartridge* feature and does
not rely on Game Boy Color WRAM banking.

The representative bound 47^5778 is smaller than 2^32095, or 4012 bytes,
so a single 8 KiB SRAM bank can contain such an unsigned integer; its
scratch copies and additional operands require distinct banks. This is
only a conservative architectural example, not a proof of the full
normative upper bound for all intermediate quantities.

The bootstrap SRAM test stores unique bytes into all 16 bank-0 offsets,
then confirms bank isolation; it separately tests the upper address BFFF
in banks 0 and 15. Future dynamic bank ownership and cleanup are NOT
implemented. Cartridge RAM must be initialized before semantic use.
See [Pan Docs MBC5](https://gbdev.io/pandocs/MBC5.html) and
[Cartridge Header](https://gbdev.io/pandocs/The_Cartridge_Header.html).

## Main correctness boundaries not yet met

* SM83-native arbitrary precision over inputs beyond 128 bits and wide-selection
  integers (including months and year weaving).
* Complete independent normative oracle and full golden fixtures.
* Canonical Ge'ez name catalog with canonicalIndex and native language QA.
* Real calendar invocation path, ancient/negative and far-date conversion.
* Full Stage-1 native verification beyond the successful 33-case arithmetic/SRAM ROM smoke suite.

The cartridge self-tests do not imply Stage 1 PASS. The historical
DISCOVERY/PATCH stages may begin only after a complete and verified Stage 1.

## Fixed 4096-byte banked addition (Stage 1 extension)

`BankedAdd4096` adds two full-width unsigned 4096-byte operands, stored
little-endian in separate cartridge SRAM banks 0 and 1. Its exact result
occupies 4097 bytes of bank 2, including the carry byte at B000.

Preconditions: MBC5 external RAM has been enabled and each operand has
been explicitly initialized. It does not allocate semantic state, normalize
lengths or implement the unrestricted BigInt API. This is intentionally a
low-level independently testable building block.

Tests 25..28 validate zero, a carry across all 4096 bytes, a two-byte
carry chain, input immutability and reinitialization of carry across calls.
These tests must pass natively in PyBoy before this extension is considered
verified. A much larger memory allocator, signed integers, more operations
and full calendar oracle remain outstanding.

## Exact fixed-width nonnegative subtraction

`BankedSub4096` reads unsigned operands in banks 0 and 1 and computes
A-B into bank 2. It returns an explicit wBankStatus byte:
0 for success, 1 for underflow. On underflow the entire output span
of 4097 bytes is scrubbed, preventing a modular negative result
from being misinterpreted as a valid nonnegative BigInt.

Tests 29..33 check no-op subtraction, borrow across 4095 bytes,
underflow fail-closed behavior, reset of carry and status after a
failure, and immediate determinism of repeated calls.

The operation is unsigned and fixed-capacity; this DOES NOT complete
signed ordinal handling, arbitrary precision, or the calendar oracle.

## Fixed 4096-byte banked magnitude comparison — candidate

`BankedCmp4096` does an unsigned, high-to-low comparison of little-endian
SRAM bank 0 and 1 operands and writes only `wCmpStatus` (0/1/2). The
operation cannot be confused with signed date ordering: a signed-magnitude
layer has not yet been built. Cases 34..40 are added to the native harness.
This subroutine has a 4096-byte fixed capacity, so Stage 1 remains open.
