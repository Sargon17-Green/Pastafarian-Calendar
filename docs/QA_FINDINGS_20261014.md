# Stage 1 ROM QA findings — 2026-10-14

## Prior native execution failure, run 38623711346

Evidence from the actual GitHub Actions log:

- Native RGBDS v1.0.4 ROM assembly and linking completed successfully.
- RGBFIX header generation completed; Python ROM header verification passed.
- PyBoy 2.8.1 was installed successfully.
- At the original 30-frame snapshot, WRAM C000/C001/C002 were 00/00/00.
- Test script failed because C000 had not become A5.

This is **not evidence of a failing arithmetic test**, because no native test
number was observed. A boot ROM delay is one possible explanation, but not
yet demonstrated; the original test also failed to wait for completion.

## Correction

Replace the fixed 30-frame assumption with an explicit polling gate:
only consider the ROM finished after both the dispatcher marker C002=40 and
the result marker C000=A5 (PASS) or C000=E0 (FAIL) are observed.
The test case in C001 remains visible even on failure. A maximum-frame
timeout fails closed and includes all three observed WRAM values.

The polling logic has dependency-free simulated tests covering a delayed
bootstrap, native failure preservation and missing completion.
These are tests of the *harness*, not a substitute for running the compiled
ROM on a Game Boy emulator.

## Next native gate

Require CI execution of the latest commit on an actual DMG-compatible
emulator, a successful ROM header check, all 22 SM83 tests, and the
expected unimplemented calendar dispatcher response before claiming
the arithmetic smoke suite has passed. Stage 1 itself also requires
the normative oracle, source-language catalog, and full calendar code.

STATUS: NATIVE_SMOKE_PENDING. LAST_COMPLETED_STAGE=0.
