# Stage40 / DISCOVERY36 — Triple-output non-LIFO release isolation

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage39 accepted with 40/40 CI jobs, exact SHA
10e3f620cb0e944f8623f65acbbb760fa839ebb2, run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41884859684,
strict GnuCOBOL -Werror, Native 24/24, actual heap zero.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41884859684/artifacts/13350198838

## Bounded independent engineering question

Stage38 tested two outputs from one input pair. Stage39 held a result
while original inputs were freed and replaced. Stage40 must instead
retain THREE simultaneously live results with distinct values, release
the MIDDLE output first (non-LIFO), verify the two remaining outputs,
and rebuild that middle result while both neighbors remain allocated.
This targets multi-owner allocation isolation rather than a historical
defect; expected-red is not presupposed.

## Deterministic input matrix and independent oracle

For n in {3,9,320,8192} and j=1..6, define K=10^(n-1),
X=K+(5j+2), Y=K-(2j+5).
Choose C=X,T=Y for odd j; choose C=Y,T=X for even j.
Let s=+1 for odd j and s=-1 for even j. For d=0,1,2,
use pair (C+s*d, T); expected output O[d] = abs(T-(C+s*d))+1
=7j+8+d. These are three DISTINCT positive values per case.
Expected triples by j:
j1: 15,16,17; j2: 22,23,24; j3: 29,30,31;
j4: 36,37,38; j5: 43,44,45; j6: 50,51,52.

The oracle must be independently evaluated by JavaScript BigInt and
the closed form for ALL 72 expected values. Exactly 24 ordered base
cases, six with 8192-digit inputs, are required; no fixture imported
from another branch. Verify exact emitted COBOL decimal strings with
the independent oracle, not only symbolic formulas. Avoid the historical
Stage39 n vs n-1 indexing issue: position is computed from the actual
length of the edited literal, not the nominal width.

## Per-case Native contract

1. Use production BIG-INTEGER-SERVICE INIT-TEXT and MONSTER-DISTANCE
   DISTANCE-PATCH. Allocate A, B, C into three DISTINCT empty
   caller-owned result records using three deterministic input pairs.
   Free each pair's input allocations after its result is produced,
   leaving all three outputs simultaneously live.
2. Each call: assert status 0, exact PATCH03:DISTANCE-PATCH message,
   exact expected O[d] text and non-null disjoint result heads.
   Snapshot sign/chunk-count/head/tail for each output.
3. Release the MIDDLE output B first. Assert A and C pointers,
   metadata and decimal text preserved.
4. Re-create B with its same original numeric pair while A/C remain
   live; verify exact B text and mutually distinct output heads.
5. Release C, check A/B; release A, check B; release B. Probe
   BIG-INTEGER-SERVICE HEAP-LIVE and require measured zero.
6. Every mismatch must increment unexpected failures and fail
   the job; do not declare an expected-red signature without a
   genuine reproduction.

## Stage40 Native acceptance gate

Expected 41/41 GitHub CI jobs: the 40 prior jobs plus one Stage40
job on the exact new branch SHA. GnuCOBOL 3.1.2.0 strict -Werror,
compile timeout 300s, executable timeout 120s, job timeout 20min.
Preserve the log artifact even on failure.
Required unambiguous counters and markers:
STAGE40_INITIAL_OUTPUTS=24
STAGE40_TRIPLE_LIVE=24
STAGE40_MIDDLE_RELEASE_ISOLATED=24
STAGE40_MIDDLE_REBUILT=24
STAGE40_NONLIFO_CLEANUP=24
STAGE40_RUNS=24
STAGE40_PASS=24
STAGE40_UNEXPECTED_FAILURES=0
STAGE40_HEAP_MEASURED=YES
STAGE40_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE40_TRIPLE_OUTPUT_NONLIFO_DISCOVERY_NATIVE
STAGE40_NATIVE_GATE=PASS

Stage40 is a planning contract only in this commit; no code/Native
implementation or pass is asserted. No changes to main/merge/release.
