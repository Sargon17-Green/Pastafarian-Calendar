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
* Full Stage-1 native verification beyond the successful 66-case arithmetic/SRAM ROM smoke suite.

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

## Fixed 4096-byte banked magnitude comparison — native smoke passed

`BankedCmp4096` does an unsigned, high-to-low comparison of little-endian
SRAM bank 0 and 1 operands and writes only `wCmpStatus` (0/1/2). The
operation cannot be confused with signed date ordering: a signed-magnitude
layer is now documented below. Cases 34..40 passed under the native emulator in run 38686711132.
This subroutine has a 4096-byte fixed capacity, so Stage 1 remains open.

## Signed 4096-byte comparison candidate

`SignedCmp4096` consumes two 4096-byte unsigned magnitudes in initialized
MBC5 banks 0/1 and sign flags `wSignedSignA/B` (0=nonnegative,1=negative).
Negative zero and other sign values are invalid; result byte 3 is
fail-closed. Otherwise 0=equal,1=A>B,2=A<B. Inputs are unchanged and
bank 1 is selected on return. This is a fixed-capacity primitive,
not a general BigInt allocator or a complete signed/calendar engine.
Native tests 41..52 passed in GitHub Actions run 38691700266; the
complete 52-case arithmetic smoke suite is verified. Stage 1 remains incomplete.

## Exact signed addition, fixed-width SRAM operands — native smoke verified

`SignedAdd4096` accepts two initialized, canonical signed-magnitude
integers in SRAM banks 0 and 1 (4096 little-endian bytes each). Signs in
`wSignedSignA/B` are 0 or 1; negative zero and other sign bytes are invalid.
The exact result uses all 4097 output bytes in SRAM bank 2, with a separate
`wSignedResultSign`. If invalid, `wSignedAddStatus=1` and the full output
is scrubbed; if valid, `wSignedAddStatus=0` and zero always has sign 0.
Input banks remain unchanged; bank 2 is selected on return. This requires
MBC5 RAM enabled by caller and does not provide variable-length allocation,
reentrancy or an interface for feeding a 4097-byte result into another
4096-byte operation. Native ROM cases 53..66 passed in Actions run 38781963706. These are fixed-capacity tests, not complete Stage-1 verification.

## MBC5 scratch-bank lease manager — candidate, Stage 1

`LeaseResetAll` (destructive, explicit) zeroizes scratch SRAM banks 3..15
and marks them free; banks 0..2 are reserved for the established fixed-width
arithmetic engine and are not scrubbed by a lease reset. Each scratch bank
contains 8 KiB. `LeaseAlloc` deterministically leases the lowest available
bank, zeroizing it before exposing the handle; status 1 means exhaustion.
`LeaseFree` takes a bank number in A, scrubs the full 8 KiB before release,
and rejects reserved/invalid banks (status 2) or unleased/double-free handles
(status 3), without changing selected-bank mapping on rejection.
The caller MUST enable MBC5 RAM and serialize these operations; a reset is
not safe during a live invocation. Lease status, last handle and per-bank
states are WRAM fields. These primitives are not yet a variable-length
BigInt type, a reentrant frame system, or an invocation rollback mechanism.

Native ROM cases 67..80 and an independent host transition model are
blocking gates before calling this extension verified.
