# Stage32 / Discovery17 — exact-SHA Native evidence seal candidate

Branch: `PowerShell+Tagalog`.

## Implementing SHA and completed Native evidence

Implementing SHA: `b780a7f75978318479040314e404a8e023b9ee1e`.

GitHub Actions run [41214611891](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41214611891) completed successfully on this exact SHA and branch. All six jobs completed/success:

| Job | Job ID | Result |
| --- | ---: | --- |
| Native Windows PowerShell 5.1 Stage29+Stage30 and regressions | 124576414353 | success; 664 predecessor assertions; finalizer twice |
| Stage32 bounded adjacent target transitions | 124576414557 | success; 239/239 assertions |
| verify | 124576414562 | success |
| Stage31 normative year-5000 boundary probe | 124576414588 | success; 85/85 assertions |
| Stage31 bounded ordinal First/Step research | 124576414622 | success; 309/309 assertions |
| Stage31 bounded ordinal extension | 124576414642 | success; 441/441 assertions |

Native runtime from the retained Stage32 metadata artifact: Windows PowerShell **5.1.26100.33648**. The job checked the exact checkout SHA against `GITHUB_SHA` and checked the runtime major/minor; both checks passed.

## Stage32 results

| Measure | Observed |
| --- | ---: |
| Base ordinals | 8 |
| Directed adjacent pairs | 16 |
| Endpoint computations | 32 |
| First changed / same | 16 / 0 |
| Step sign flipped / same | 6 / 10 |
| Distinct modular deltas | 16 |
| Gate-crossing pairs | 4 |
| Assertions passed / failed | 239 / 0 |

Every endpoint's First and Step matched the separate normative oracle; each context retained exactly 58 legacy order-memory writes and exactly one Patch12 invocation. Each pair's normalized modular First delta and Step-flip boolean also matched the oracle.

Stage31 research rechecked on the same implementing SHA: ordinal 50 rows/309 assertions; extension 72 rows/441 assertions; normative year-5000 boundary 12 rows/85 assertions. Stage31 research total 835/835. The predecessor Stage01–30 suite passed 664 assertions. Combined implementing-SHA total: **1738/1738**, zero failures.

Stage23 finalizer idempotency ran twice. The original, first-run and second-run SHA256 values were all `6681151DB42475F8791535C13A50C5AC4EA533019253EB5034BF410101DE8B8A`; RESULT=PASS. The separate verify job succeeded.

## Retained evidence

- Stage32 artifact [13047955179](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41214611891/artifacts/13047955179), ZIP SHA256 `3f7afd0905184a9329bdbf4dd739f7ba453516f435fc318d26e7d309f16b22cf`.
- Stage31 ordinal artifact [13048055218](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41214611891/artifacts/13048055218).
- Stage31 extension artifact [13047578897](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41214611891/artifacts/13047578897).
- Stage31 year-boundary artifact [13047459060](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41214611891/artifacts/13047459060).
- Finalizer artifact [13047508795](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41214611891/artifacts/13047508795).

## Scope and interpretation

Discovery17 is bounded research evidence only. It is not a production patch, a proof of statistical uniformity or independence, a Gregorian/civil mapping, or a proof of global five-component correctness. The production implementation and independent normative oracle were not modified. Historical Stage26 expected-red remains intact. No main merge or publication was performed.

## Exact-seal acceptance

This candidate records the completed implementing-SHA evidence. The new seal commit must receive its own completed/success Native and verify run on its exact SHA before `STAGE32_SEAL_COMMIT_NATIVE_RECHECK` can be changed from PENDING. The Stage32 workflow now emits `STAGE32_SEAL_RECHECK=PASS` only when the sealed metadata pair and the 239-assertion test both pass.