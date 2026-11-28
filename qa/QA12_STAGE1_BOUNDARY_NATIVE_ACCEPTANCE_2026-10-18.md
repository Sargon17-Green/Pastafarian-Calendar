# QA12 — Native Stage-1 finite functional boundary grid: verified PASS

**Scope:** bounded independent Native Befunge-98 regression only. **Stage 1 remains OPEN.**
No canonical-language or `main` branch changes, source changes, cross-implementation comparisons, or Stage 2.

## Frozen provenance

- Exact CI-tested QA branch commit: `1a6fc8720c9cb6303de78a80cc47266a7211e5a6`.
- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39108285681
- `src/interleaved_work_counts.b98` Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- `reference/work_counts.b98` Git blob: `f941efc793c9eee4accf5d03873f8ed029b16725`.
- `reference/save.b98` Git blob: `7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44`.
- All four matrix jobs, plus a fifth independent cross-shard receipt-audit job, completed SUCCESS.

## Native coverage actually established

- 16 distinct signed day numbers (zero, immediate neighbors, Foundation ±0/1/2, SAVE modulus ±boundary, 81-digit signed magnitudes).
- 136 unordered pairs covering **all 256 ordered orientations** of the 16-element domain.
- Each valid orientation: QA production versus independent real Befunge reference `work_counts` and two `save` executions.
- 256 Native production valid executions and 768 separate Native reference executions.
- 16 additional malformed lexical inputs rejected with exactly seven `-1` values.
- **1,040 independently invoked Native Befunge interpreter processes** across the four successful shards.
- Direction inversion, target/action swap, equal-day distance/direction, independent reference equality, and malformed-input sentinel checks passed.
- The independent receipt auditor consumed all four original GitHub artifacts, verified full deterministic pair coverage, source pins, shape and symmetry, and rejected 6/6 forged synthetic cases.
- The assistant also downloaded the original four artifacts and independently reran the Python3 receipt auditor locally. It reported `QA12_NATIVE_FINITE_BOUNDARY_GRID_RECEIPTS_PASS`.

| Shard | Native job | Original GitHub artifact |
|---|---:|---:|
| 0 | 117618758789 | 12129421901 |
| 1 | 117618758847 | 12129775823 |
| 2 | 117618758804 | 12129820616 |
| 3 | 117618758816 | 12129825146 |
| Cross-shard independent receipt audit | 117618921438 | no separate ZIP required |

## Explicit limitations and next work

This is **finite functional evidence**, not an exhaustive proof of all integers or all Stage-1 modules. It does not validate all 49 test-only reference modules, full Funge-space semantic state ownership, unrestricted object reuse, geometric crossing and live-opcode causality for every production route, or all formal Stage-1 bootstrap requirements.

The Stage-1 completeness record explicitly does **not** require full `calendarDate` orchestration at Stage 1; do not raise that out-of-scope requirement as a false blocker.

Next: analyze the remaining geometry/ownership gates on the *actual 2D production*, not solely the separate QA11B 17D experiment. Do not merge PR #17, modify signed QA10/QA11B specimens, or start Stage 2 without independent final Stage-1 acceptance.
