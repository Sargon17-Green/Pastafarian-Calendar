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
