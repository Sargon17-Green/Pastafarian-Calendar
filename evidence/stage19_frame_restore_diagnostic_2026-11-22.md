# Stage19: completed Native failure and isolated caller-frame fix (2026-11-22)

PROJECT_ID: PC-BRANCH-FALSE-ARABIC  
Branch: `FALSE+العربية`  
Acceptance: **NOT_ACCEPTED**; last accepted stage remains Stage18 BOUNDED.

## Immutable evidence reviewed

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954239260
- Native job: 136998711271; **completed/failure**. Verify job 136998710809 **completed/success**; the latter is not a Native PASS.
- Exact run SHA: `a078dd9002f67055106917d5795fe231c8d54575`.
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954239260/artifacts/14727522957
- Downloaded archive SHA-256: `2dc50cdf47b892c39261270a0c5b87552ee9e9172149fa5dcedd01a26ff903c2`, matching GitHub's artifact digest. 44 ZIP entries, CRC verified for all.
- Original FALSE runtime pinned `eb3135565a8670cced3f6bbca4dbf7b014c45634`; compilation and Unicode preflight passed.
- Independent JavaScript design oracle emitted 720 permutations, 4320 pairs, 12 probes. Python generated six chunks, but the original interpreter failed immediately in positive chunk 0 at `STAGE19_CASE_0000_POSITION_FAIL` (expected 1). No completed exhaustive Native check may be claimed.
- `diagnostic_first_scalar.stdout.txt`: `STAGE19_DIAG_RESULT_ZERO`, not expected 1. The follow-up heap read had `stack type mismatch` at `d;g;!6=`.
- The first probe also failed at `STAGE19_PROBE_000_POSITION_FAIL`. The `wrong_duplicate_last` mutant exited 1 at probe 000, not its required probe 005; its rejection gate therefore failed. Both invalid-header cases (5 and 7) exited 1 with `E_BOWL_POSITION_LENGTH`, but those isolated negatives are not a Stage19 PASS.
- CI evidence JSON explicitly says `native_gate_passed=false`, `stage19_accepted=false`.

## Scoped production correction

A separate static comparison with the accepted op32–op35 frame-restoration epilogues found a missing `k;` in op36's final cleanup. The exact one-line code change on commit
https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/56b3647a5ad5821bbd1adc964398a63d94a99a75
replaces the suffix `21+g;!y:g;!k:z;1-g;!` with `21+g;!y:k;g;!k:z;1-g;!`. GitHub commit readback confirms exactly one modified file, `src/monster_bootstrap.false`, and the changed blob SHA `0619f901ba065c7849ca445c9abb04e3e8b2b871`.

This is a **source fix, not a Native result**. The prior failed run is not reclassified. The commit message carries exactly the existing Stage19 auto-push marker. Do not dispatch a duplicate run; check the run attached to this source SHA, then require original-runtime Native 4320 cases +12 probes, all invalid controls/mutants, source lock, artifact SHA/CRC and independent offline trace audit before accepting Stage19. No main/merge, no invalid-pointer safety claim.
