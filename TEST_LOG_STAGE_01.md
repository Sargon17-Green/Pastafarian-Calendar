# Native bootstrap QA ledger — ግዕዝ / SM83

Date (UTC): 2026-10-15. Branch: `SM83-Assembly+ግዕዝ`.
Total plan: 55 stages, with Stage 1 still IN_PROGRESS.

## Verified GitHub Actions evidence

- **24/24** native ROM tests at commit
  `75649df9fb0e26ac7e4805e59ae0b3e635bd1ff7`,
  [run 38634428513](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38634428513).
  Header MBC5+128KiB passed; last case 24, WRAM result A5, dispatch 40.
- **28/28** native ROM tests at commit
  `e422dde023f251d83638c3bf76aec417e03cde26`,
  [run 38684769937](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38684769937).
  Additional tests cover 4KiB+4KiB exact addition into 4097 bytes.
  Last case 28, WRAM result A5, dispatch 40, finished in 225 frames.
- **33/33** native ROM tests at commit
  `dae43f83a061a2e04deccb07f2c588c89b1011b4`,
  [run 38684917968](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38684917968).
  Additional tests 29..33 cover unsigned fixed-width subtraction,
  borrow propagation, underflow rejection and output scrub.
  `ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=33 DISPATCH_STATUS=40 FRAMES=336`.

Both jobs `verify` (canonical lock) and `dmg-native-smoke` reported
`completed/success` in run 38684917968. Native ROM building used
RGBDS 1.0.4; execution used PyBoy 2.x with an MBC5+128KiB RAM cartridge
header. The host arithmetic reference independently passed 49 boundary
pairs, 2048 pseudo-random 128-bit products and 8192 pseudo-random 256-bit
reductions. These host checks do not replace native ROM execution.

## Audit boundary

**Do not set LAST_COMPLETED_STAGE to 1.**

Passing the bootstrap smoke suite does not complete the normative
Stage-1 requirements:

1. Exact general-purpose arbitrary-length signed and unsigned integers,
   beyond the current fixed SRAM bank primitives, with ownership,
   normalization, overflow and rollback contracts.
2. Authoritative independent normative oracle and complete source fixtures.
3. Correct production calendar construction: sauce, selection,
   historical gates, cutlet/month weaving and Year 5000.
4. Fully reviewed Classical Ge'ez source-name catalog by canonical index.
5. Reentrant, failure-injection, cross-platform and end-to-end tests,
   including a real calendar date output.

Native status: BOOTSTRAP_SUBSET_PASS.
Stage status: STAGE1_INCOMPLETE.

## Comparison extension: 40-case native smoke PASS

On commit `339cdbdc048c0529e88e604cb4bef29928bfbd8d`,
[GitHub Actions run 38686711132](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38686711132)
completed with `conclusion=success` for **both** `verify` and
`dmg-native-smoke` jobs. The native ROM exercised all **40** cases,
including high-byte precedence, 4096-byte full equality, non-mutation,
comparison-direction reversal, and repeated-call status reset.

An earlier run 38686631616 for the implementation commit already showed
`ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=40 DISPATCH_STATUS=40 FRAMES=383`,
while its independent name-lock job failed because the locked README was
changed. The README change was reverted without modifying the arithmetic
implementation, and the subsequent full run 38686711132 passed both jobs.

**Interpretation:** 40-case native arithmetic/SRAM smoke PASS only.
This is not Stage 1 normative-oracle completion; `LAST_COMPLETED_STAGE=0`.

## Signed comparison extension — native CI PASS

`SignedCmp4096` reads sign flags 0/1 plus fixed-width magnitudes,
rejects negative zero and invalid sign bytes, and compares both signed
operands without SRAM mutation. ROM tests 41..52 exercise signed order,
invalid input, recovery and return bank. Run [38691700266](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38691700266)
completed with both jobs successful. Native RGBDS 1.0.4 compilation and PyBoy
2.x execution reported `ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=52
DISPATCH_STATUS=40 FRAMES=459`. Host reference independently reported
`HOST_BANKED_SIGNED_COMPARE_REFERENCE_PASS cases=375`.
This verifies the fixed-capacity comparison primitive, not the normative calendar
oracle. `LAST_COMPLETED_STAGE=0`.

## Signed exact 4096-byte sum extension — native CI PASS

SM83 `SignedAdd4096` adds two canonical signed magnitudes stored in banks 0
and 1; a complete 4097-byte unsigned magnitude and canonical sign are
written to bank 2/WRAM. Opposite signs route through a magnitude comparison
and either A-B or B-A, without changing the operands. Illegal signs and
negative zero scrub the entire output and expose an explicit failure status.
Native cases 53..66 target carry into byte 4097, both subtraction directions,
cancellation to positive zero, invalid input and recovery, plus determinism.
A separate Python reference is only host-side evidence.

GitHub Actions [run 38781963706](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38781963706),
at commit `61718272208fbe57ae04b36e844540709cb4d2fc`,
completed both `verify` and `dmg-native-smoke` jobs successfully.
Actual RGBDS v1.0.4 ROM was executed by the PyBoy 2.x emulator:

```text
ROM_HEADER=PASS DMG=YES MBC=MBC5_RAM_128K
ROM_PROGRESS_FRAME=781 CASE=66
ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=66 DISPATCH_STATUS=40 FRAMES=813
STAGE1_ARITHMETIC_SMOKE=PASS
HOST_SIGNED_SUM_REFERENCE=PASS cases=1088 capacity_bytes=4096
```

The initial new-suite run 38781831273 failed before ROM assembly:
the Python host reference mistakenly asserted `-LIMIT < value` for
two negative inputs. Corrected to the valid `-2*LIMIT < value`;
the subsequent CI run passed. This was a host-test-bound defect,
not a demonstrated failure in native SM83 arithmetic.

The fixed-capacity signed-sum primitive is native-smoke verified, but
`LAST_COMPLETED_STAGE=0`. The complete normative calendar,
arbitrary-length state ownership and verified Ge'ez names remain absent.

## Destructive-reset scratch SRAM leases — native smoke PASS

Implemented a separate bank-lease primitive with deterministic lowest-bank
allocation (banks 3..15), full 8-KiB scrub on release/reset, 0..2 reserved,
invalid-handle and double-free guards, and explicit exhaustion. Native
cases 67..80 check bank isolation, upper/lower edges, exhaustion, reallocation
and preservation of reserved bank 2. The host model is independent and is
not a substitute for native RGBDS/PyBoy execution.

Verified at commit `736eeca17e51692d1a3a77340977377332bd5641`
via [Actions run 38788682300](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38788682300).
Both `verify` and `dmg-native-smoke` concluded SUCCESS.
The actual RGBDS 1.0.4 ROM executed under PyBoy 2.x:

```text
HOST_SRAM_LEASE_MODEL=PASS randomized_transitions=600 banks=13
ROM_HEADER=PASS DMG=YES MBC=MBC5_RAM_128K
ROM_PROGRESS_FRAME=953 CASE=80
ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=80 DISPATCH_STATUS=40 FRAMES=1014
STAGE1_ARITHMETIC_SMOKE=PASS
```

Only the explicitly scoped SRAM scratch-bank lease mechanism is verified.
No variable-length BigInt objects, dynamic per-invocation state, full
normative oracle or complete Ge'ez catalog yet exist. Maintain
`LAST_COMPLETED_STAGE=0` and do not start Stage 2.

## Normative day-count signed offset subset — verified

Proposed native cases 81..92 implement the precise mapping from a 32-bit
signed offset around Foundation to its even/odd Pastafarian day number,
without mutating the input. The full signed range and 5-byte result are
tested independently on the host; subsequent native RGBDS/PyBoy execution
passed in run 38789386350. Does not imply a complete day ordinal or calendar calculation.
`STAGE1_NATIVE_92_SMOKE=PASS_GITHUB_ACTIONS_38789386350`. Stage 1 remains IN_PROGRESS.

## Verified bounded native day count — 92/92 PASS

GitHub Actions [run 38789386350](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38789386350) passed both jobs at commit `f29974497834a13227e589c66fd282c6c7228322`. The RGBDS-built DMG ROM ran under PyBoy: `ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=92 DISPATCH_STATUS=40 FRAMES=1014`. The independent host model passed 12,014 signed 32-bit offsets (`HOST_DAY_COUNT_DELTA32=PASS`). This is not an arbitrary-precision calendar or completion of Stage 1.

## Five bounded normative work counters — verified

ROM tests 93..108 cover pair reversal, same-day counters, crossing Foundation, extreme signed-32 offsets, exact 2^32 distance, sums and direction. Host oracle independently examines 14,121 pairs. Native execution passed in run 38790223535. `STAGE1_NATIVE_108_SMOKE=PASS_GITHUB_ACTIONS_38790223535`; no Stage-2 work.

## Verified native five-counter subset — 108/108 PASS

[GitHub Actions run 38790223535](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38790223535), commit `c3766c8c0b4018eee54fa0c5246a7411697d210a`, finished with both jobs successful. Actual DMG ROM output: `ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=108 DISPATCH_STATUS=40 FRAMES=1016`; independent host reference: `HOST_WORK_COUNTERS_DELTA32=PASS cases=14121`. These results verify only the signed-32 bounded numerical prefix of the normative calendar. Full Stage 1 still incomplete; Stage 2 not started.

## Canonical magnitude length extension — native CI PASS

Candidate ROM cases 109..122 exercise 8192-byte zero/boundary
normalization, 4097-byte carry, 4096-byte high byte, signed result
length metadata, cancellation, negative-zero rejection, invalid
signs and recovery. The host reference is separate evidence.
Both GitHub Actions jobs (`verify` and `dmg-native-smoke`) passed on
commit `813499265e4807fbf41ea6f5f81b071fc5ca63e4`,
[run 38794654298](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38794654298).
RGBDS v1.0.4 built the native DMG ROM, executed in PyBoy 2.x:

```text
HOST_SRAM_MAGNITUDE_LENGTH=PASS cases=1829
ROM_HEADER=PASS DMG=YES MBC=MBC5_RAM_128K
ROM_PROGRESS_FRAME=1243 CASE=122
ROM_NATIVE_STATUS=A5 LAST_TEST_CASE=122 DISPATCH_STATUS=40 FRAMES=1278
STAGE1_ARITHMETIC_SMOKE=PASS
```

The first candidate run 38794538863 failed *before building the ROM*:
a host fixture randomized the expected most significant nonzero byte and
could overwrite it with zero. The fixture generator was corrected not to
alter that byte and the next run passed. This is not evidence of a failing
SM83 routine.

**Verified scope:** 1..8192-byte SRAM scanning and exact 0..4097-byte
signed-add result-length metadata, without mutation and with fail-closed
metadata on invalid sign/negative zero. These are building blocks only;
unbounded BigInt, complete normative calendar and verified Ge'ez catalog
remain absent. `LAST_COMPLETED_STAGE=0`.

## Bounded division-by-byte candidate — pending native verification

ROM cases 123..138 cover division by one, 255, 254, two, three, four,
high-byte boundaries, exact 4096-byte operands, quotient carries,
remainder, source immutability, recovery after zero-divisor rejection
and repeated invocation. A separate host reference checks multi-byte
byte-radix division against Python arbitrary-precision math.
No native PASS is claimed before both GitHub Actions jobs succeed;
`LAST_COMPLETED_STAGE=0`.
