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
| C001 | wTestCase | currently executed test (1..10) |
| C002 | wRunStatus | 40 means calendar engine deliberately not implemented |
| C003..C012 | wValue | 128-bit LE working value |
| C013..C022 | wAddend | 128-bit LE addend |
| C023..C032 | wExpected | 128-bit LE expected result |

Save127 handles a single 128-bit unsigned input, exactly, with
M=2^127-1; it is not a substitute for arbitrary precision.
Add16 has the explicit precondition 0 <= a,b <= M; it does not support
unrestricted 128-bit addition with overflow.

## Main correctness boundaries not yet met

* SM83-native arbitrary precision over inputs beyond 128 bits and wide-selection
  integers (including months and year weaving).
* Complete independent normative oracle and full golden fixtures.
* Canonical Ge'ez name catalog with canonicalIndex and native language QA.
* Real calendar invocation path, ancient/negative and far-date conversion.
* Stage-1 native ROM assembly, emulator run and toolchain logs.

The cartridge self-tests do not imply Stage 1 PASS. The historical
DISCOVERY/PATCH stages may begin only after a complete and verified Stage 1.
