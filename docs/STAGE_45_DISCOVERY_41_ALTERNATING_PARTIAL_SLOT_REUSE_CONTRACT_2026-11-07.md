# Stage45 / DISCOVERY41 — alternating complementary partial-slot reuse
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage44 accepted on 51b3694ca4f2e76ca4973091bc4fc29b8bd582a7, 45/45 completed/success in 42251510849.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42251510849/artifacts/13521243677
SHA256 from upload: 031871f2e7408c2161ee64b1bff153db30f68bde5f63022d3e34439218a5e136

## New behavior
Stage44 freed/reused only permutation positions 1,2 while 3,4 survived.
Stage45 first frees 1,2 forward and re-creates them in reverse, THEN frees
3,4 forward and re-creates them in reverse, keeping the complementary pair
alive throughout each phase. No all-four-free intermediate step between the
two partial cycles. For each operation check exact surviving result decimal
text, sign, chunk count and pointer identity. After each pair recreation
check all four distinct non-null heads. Preserve complete Stage44 full
release/rebuild, occupied-output rejection, and cleanup tests. This is
new cross-pair lifetime interference coverage, not a known historical bug.

## Oracle and boundaries
n in {3,9,320,8192}, j=1..6: 24 unique ordered (C,T) pairs.
X=10^(n-1)+(5j+2), Y=10^(n-1)-(2j+5), odd j uses C=X,T=Y,
even j uses C=Y,T=X. Output k=1..4 uses C'=C+(k-1) for odd j,
C'=C-(k-1) otherwise. Expected |T-C'|+1=7j+8+k-1.
Independent test-only Node BigInt validates all 96 source literals
against the closed form, plus an independently enumerated set of all
24 4! release permutations. Six cases have width 8192.

## Exact-SHA Native acceptance
46/46 completed/success jobs, GnuCOBOL strict -Werror, compile<=300s,
execution<=120s, native job<=20 min; log artifact and upload SHA256.
Static ORACLE_PASS=96/96, PERMUTATIONS_STATIC=24/24.
Native INITIAL_OUTPUTS,QUAD_LIVE,ORDER_COVERAGE,REVERSE_REBUILT,
MID_HEAP_ZERO,FINAL_CLEANUP,RUNS,PASS each 24;
PARTIAL_FREES=96, PARTIAL_REUSES=96, PARTIAL_CYCLES=48,
PAIR_SWITCHES=24, OCCUPIED_REJECTS=48, REJECTED_PRESERVED=48,
UNEXPECTED_FAILURES=0, HEAP_MEASURED=YES, HEAP_LIVE_POST_RELEASE=0,
RESULT=PASS_STAGE45_ALTERNATING_PARTIAL_SLOT_REUSE_DISCOVERY_NATIVE,
STAGE45_NATIVE_GATE=PASS. Failure paths release caller-owned results.
No Stage46 prior to Stage45 acceptance; no production/main/merge/release
or integrated five-field calendar claims.
