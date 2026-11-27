# Stage 2 - Discovery 01: raw remainder

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Opened 2026-11-27 by explicit user authorization, Fortran+English only.
Accepted bootstrap tested SHA: 90aa649ab95c9f0a8c7221ccc4cc54d5d3b23fb2.
Documentation-only baseline: 9417c986b59be9055078d65ac31e2bfbc9225f9a.

Historical specification: oldRemainder(x) = regularMod(x,M_OLD); the defect is that zero remains zero. M = 2^127 - 1, decimal 170141183460469231731687303715884105727, as in the existing clean oracle. The clean SAVE is 1 + ((x-1) mod M). No correction belongs to Discovery 01.

Contract: signed arbitrary-precision integer x; raw result in [0,M-1]. The new production dispatcher invokes the neutral bootstrap and then the actual oldRemainder once, preserving input, raw result and trace in invocation-local context. It imports no test module. The clean oracle is test-only.

Independent analytic expectation: for x=q*M+d with d=-1,0,1 the raw result is M-1,0,1 and SAVE is M-1,M,1. Use q=-2,-1,0,1,2 and +/-10^40 (21 new cases; 7 exact historical divergences, 14 exact matches). Verify the clean oracle against those expectations as well as the production route. Check two context-isolation cases (including reuse) and observational dispatch/validation counters. A divergence outside exact multiples or absence of the specified divergence is failure, not EXPECTED_RED. Do not copy another implementation's code or fixtures.

CI: the discovery01-native job in the existing Canonical Names Lock workflow (push on Fortran+English only); exact checkout, Fortran native compile, 30s / 1 GiB execution, raw stdout/stderr, exit, compiler, SHA256 and artifact. Prior canonical Stage1 tests remain unchanged. The gate itself should succeed when the intentional semantic REDs are observed. Stage2 remains NOT ACCEPTED until completed exact-SHA native evidence and regression review. LAST_COMPLETED_STAGE stays 1. No Patch 01, Stage3, main, merge or release.
