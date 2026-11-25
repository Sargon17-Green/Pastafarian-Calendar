# Stage 02 — DISCOVERY 01: REMAINDER_SAVE

PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE  
Branch: Object-Pascal+Português  
Contract status: ACCEPTED on exact tested code SHA c9bd7243924efee710cb9437bacc5971027d190d. Stage03 PATCH 01 is next and has not started.  
Production algorithm status: unchanged. Stage 03 PATCH 01 has not started.

## 1. Normative sources

1. The common normative specification is the repository README pinned at main commit 56bc4173aae4975ded019ef5ab5a36249f1424df. Section D defines:

   ~~~text
   M = 2^127 - 1
   SAVE(x) = 1 + ((x-1) mod M)
   ~~~

   It explicitly gives SAVE(M)=M, SAVE(2M)=M, SAVE(M+1)=1 and SAVE(0)=M. The complete specification is in that pinned README; no separate Appendix A file is tracked in the Object Pascal branch tree.
2. The machine-readable 55-stage plan is docs/CALENDAR_55_STAGES.csv at commit 0c2bad7393f4d66b77f884520f8ab6f5025feedd on the shared SystemVerilog+Kalaallisut design branch. Its Stage 2 row is DISCOVERY / 01_REMAINDER_SAVE / EXPECTED_RED_AND_LIVE_LEGACY_PATH. Stage 3 is PATCH / 01_REMAINDER_SAVE / LEGACY_RETAINED_AND_FULL_REGRESSION_GREEN. The common plan is also described in master handoff issue #19.
3. Stage 1 acceptance remains limited to the user-approved exact SHA 50db302e2588dcdbbae7ac5dad2ebfc0a9e8d2d4, as recorded in issue #37. The Stage 1 regression workflow also completed successfully on the exact Stage02 tested code SHA c9bd7243924efee710cb9437bacc5971027d190d (run 45673284058, job 139414000630). This does not widen the historical provenance exception to any other SHA.

Links:
- Normative specification: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/56bc4173aae4975ded019ef5ab5a36249f1424df/README.md
- 55-stage plan: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/0c2bad7393f4d66b77f884520f8ab6f5025feedd/docs/CALENDAR_55_STAGES.csv
- Plan handoff: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/19
- Stage 1 acceptance boundary: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/37

## 2. Reconciliation of the earlier branch-local Stage02 work

The three existing suites are valid supporting QA, not the canonical Stage 2 discovery:
- WorkCounts: 1,449 checks.
- Context integration: 1,730 checks.
- Lifecycle boundaries: 3,654 checks.
- Total: 6,833 checks, previously accepted on SHA 1afc1b5c287bc59d865b05a19eefb11ddebf3563.

Their previous evidence was exact-SHA:
- Stage02 Native run 45551741739, job 138994262859, completed/success.
- Names Lock run 45551741769, job 138994263105, completed/success.
- Stage01 regression run 45551741751, job 138994262631, completed/success.
All three were on SHA 1afc1b5c287bc59d865b05a19eefb11ddebf3563. These accepted runs are not being manually redispatched on that SHA.

The earlier STAGE02_WORKCOUNTS_READINESS, STAGE02_CONTEXT_INTEGRATION and STAGE02_BOUNDARY_AUDIT documents define bounded preparatory slices. Their 6,833 checks do not exhaust Stage 2 in the common 55-stage plan. This document supplies the missing mapping; the older audit files are retained unchanged as history.

## 3. HEAD mapping and the live legacy primitive

At the previous Object Pascal HEAD 1afc1b5c287bc59d865b05a19eefb11ddebf3563:

- src/BigInt.pas exports and implements BigRegularModPositive(A,D). It is a correct ordinary Euclidean remainder operation with results in 0..D-1 for positive D.
- test/NormativeOracle.pas contains NormativeSave(X), implemented as BigRegularModPositive(X-1,M)+1. It is test-only.
- There is no production SAVE function and no calendar-level oldRemainder adapter in PastafariCalendar. The Stage 2 discovery therefore exercises the existing production primitive directly; it does not fabricate a second adapter or alter production semantics.
- The defect under discovery is not a defect in BigRegularModPositive itself. It is the semantic mismatch caused by using ordinary remainder directly where the normative contract requires SAVE.

The new Pascal test calls the real BigRegularModPositive from src/BigInt.pas. It does not import NormativeOracle and does not copy implementation code or fixtures from another language branch.

## 4. Measurable Discovery 01 contract

Input: the fixed positive modulus M=2^127-1 and four canonical input values derived directly from the normative Section D examples.

| Case | x | Ordinary remainder x mod M | Normative SAVE(x) | Classification |
|---|---:|---:|---:|---|
| ZERO | 0 | 0 | M | EXPECTED_RED |
| M | M | 0 | M | EXPECTED_RED |
| 2M | 2M | 0 | M | EXPECTED_RED |
| M_PLUS_1 | M+1 | 1 | 1 | MATCH |

The first three rows must diverge; the final row is a control that must match. This is an expected-RED discovery, not a failing build. The discovery test exits zero only when all four actual legacy outputs match the independently generated ordinary-remainder column, the three divergences are observed against SAVE, the control matches, and all counters are exact.

### Oracle

docs/stage02_discovery01_oracle.py uses Python arbitrary-precision integers only:
- legacy(x) = x % M
- save(x) = 1 + ((x-1) % M)

It generates a deterministic UTF-8 TSV and checks it byte-for-byte. Expected TSV SHA-256:
1434ebaab9a2f3bc92e74f11192b99e1ce53e4cad39ceacea767a0f1583b9fed

The Pascal test consumes that TSV and calls the production BigRegularModPositive primitive. It checks 41 assertions, four rows, three EXPECTED_RED classifications, one MATCH, and zero unexpected failures.

## 5. Native acceptance gate

The Stage02 acceptance gate was met on exact tested code SHA c9bd7243924efee710cb9437bacc5971027d190d:
- Native run 45673284010, job 139414000590, completed/success; FPC 3.2.2.
- WorkCounts 1,449/1,449; Context 1,730/1,730; Lifecycle 3,654/3,654.
- Discovery01: 41/41 assertions; four cases; three EXPECTED_RED and one MATCH; zero unexpected failures; STAGE02_EXIT=0.
- Names Lock run 45673284053, job 139414001154, completed/success on the same SHA.
- Stage01 regression run 45673284058, job 139414000630, completed/success on the same SHA; STAGE01_EXIT=0, static UTF-8 7/7 and dynamic UTF-8 12/12.
- Stage02 artifact 15050083370, 4,511 bytes, SHA-256 8ba1c24da6364b4b58ec3694c505afd8f40932b6211080269fcc849156de36cf. Local ZIP test passed; all three members decoded as strict UTF-8. Discovery TSV SHA-256 1434ebaab9a2f3bc92e74f11192b99e1ce53e4cad39ceacea767a0f1583b9fed; WorkCounts TSV SHA-256 1a25f13aacd70d3cf23458d331c7a9148c5d749994099c2c9c9c4849ce674d12.

The branch's current HEAD after this follow-up is a documentation-only status commit whose parent is the tested code SHA above; no production, test, oracle, runner or workflow file changes in the follow-up. CI is intentionally skipped for this documentation-only update; the acceptance evidence remains pinned to the exact tested code SHA.

## 6. Explicit limits

- This is Stage 2 DISCOVERY 01 only. Do not implement the SAVE correction in this change; that belongs to Stage 3 PATCH 01.
- Do not change BigRegularModPositive, add a production SAVE function, alter the source-language catalog, or change the normative oracle.
- Do not merge, create a PR, modify main, publish a release, or start Stage 3 in this discovery change.
- The expected RED is a mathematically specified mismatch, not a fabricated error. The production primitive remains unchanged so the original behavior stays observable.
