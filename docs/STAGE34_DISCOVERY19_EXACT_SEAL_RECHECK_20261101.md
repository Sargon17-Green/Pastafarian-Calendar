# Stage34 / Discovery19 — exact-seal SHA adjudication (2026-11-01)

Project: PC-BRANCH-POWERSHELL-TAGALOG
Branch: `PowerShell+Tagalog`

## Exact SHA and CI evidence

- Implementing-SHA prior Native evidence: [run 41244612808](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41244612808), SHA `371bd1c709daf87223ec80835dc9fa17b75ae27b`.
- Corrected seal commit: [682dcb21a164ebfd924a48a565f6e90ac63dd314](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/682dcb21a164ebfd924a48a565f6e90ac63dd314).
- Exact-seal CI: [41246559244](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41246559244) — `completed/success`, on `PowerShell+Tagalog`, `head_sha=682dcb21a164ebfd924a48a565f6e90ac63dd314`; live HEAD matched at inspection.
- Eight of eight jobs `completed/success`; reviewed their individual logs. Job IDs: Stage32 `124671093720`, verify `124671093909`, Stage31 ordinal `124671093954`, Stage33 `124671093960`, Stage31 boundary `124671093974`, native predecessor + finalizer `124671094019`, Stage31 extension `124671094038`, Stage34 `124671094573`.
- Run `41246370126` is superseded intermediate-SHA evidence and was not accepted.

## Exact Native assertions and gates

| Suite | Assertions | Failures |
|---|---:|---:|
| Stages01–30 predecessor | 664 | 0 |
| Stage31 ordinal / extension / year boundary | 309 + 441 + 85 = 835 | 0 |
| Stage32 | 239 | 0 |
| Stage33 | 560 | 0 |
| Stage34 | 448 | 0 |
| **Total** | **2746** | **0** |

- Stage32, Stage33 and Stage34 logs each emitted `STAGExx_SEAL_RECHECK=PASS`.
- Stage34 reports 8 cubes, 32 labeled contexts (24 distinct numeric calculation-target pairs), 64 endpoints, 32 seal edges, 16 faces, 8 nonzero E values, and Step R flipped in 5/8; the 448 tests succeeded.
- Canonical `verify` job succeeded.
- Stage23 finalizer idempotency: `RUN_1_EXIT_CODE=0`, `RUN_2_EXIT_CODE=0`, both `ALREADY_FINALIZED=True`, both `STDERR_LENGTH=0`, `RESULT=PASS`. Before/after1/after2 SHA256 identical: `980727351BB10E5AFE7D6E0F5C904EFB03AD0B3A1A5F777044A4FAE788BC76BD`.

## Interpretation and continuation

This closes the **exact-seal check for commit 682dcb21**. This document and Stage35 planning contract are additional changes in a later commit; this note does not imply Native PASS on that later commit. Evidence is limited to the explicitly bounded finite inquiry, not statistical uniformity, independence, Gregorian mapping, or general calendar behavior. No change to production, oracle, main, or any other branch.
