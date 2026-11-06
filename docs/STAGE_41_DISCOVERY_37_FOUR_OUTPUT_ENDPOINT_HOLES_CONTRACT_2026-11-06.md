# Stage41 / DISCOVERY37 — four-output endpoint-holes isolation

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage40 accepted in run 42125099817 on 414a344565db2e82d591e551aeb99419853f1015,
41/41 jobs, strict Native 24/24, independently verified 72/72,
unexpected=0, measured heap=0, artifact 13462355441.

## Question
Stage40 held three live outputs and reclaimed the middle slot.
Stage41 tests FOUR simultaneously independent outputs, frees BOTH
endpoints while interior outputs remain live, rebuilds freed endpoints
in reverse order, then frees interior slots before the new endpoints.
No historical failure or expected-red is presumed.

## Measurable contract
Input widths n in {3,9,320,8192}; j=1..6. Generate X=10^(n-1)+(5j+2),
Y=10^(n-1)-(2j+5), C/T ordered by j parity, and four emitted input
pairs C+s*d,T with d=0..3, s=+1 for odd j and -1 for even j.
Independent JS BigInt and algebraic closed form must both yield
abs(T-(C+s*d))+1 = 7j+8+d for all 96 emitted decimal strings.
Require 24 unique ordered base pairs, six 8192-digit base pairs.
The test and oracle belong exclusively to COBOL+简体中文.

For each of 24 cases:
1. Allocate output records 1..4 independently via real INIT-TEXT and
   MONSTER-DISTANCE DISTANCE-PATCH. Free temporary inputs immediately.
   Assert status=0, exact PATCH03 message, sign/chunk/head/tail, exact
   two-digit string for each, and pairwise-distinct live output heads.
2. Free endpoint 1 and endpoint 4, both explicitly zeroed. Reinspect
   the two still-live interior outputs 2 and 3.
3. Reconstruct endpoint 4, THEN endpoint 1, using fresh input pairs.
   Inspect all four, including pairwise distinct heads.
4. Free interior 2; recheck 1,3,4. Free interior 3; recheck 1,4.
5. Free endpoint 4; recheck 1. Free 1. Verify measured heap live zero
   after the full bounded suite. All failure paths perform cleanup.

Native gate: 42/42 jobs completed/success on the exact commit.
Strict GnuCOBOL 3.1.2.0 -Werror; compile <=300s, execute <=120s,
job <=20min, preserve logs including failures.
Required markers:
STAGE41_ORACLE_PASS=96/96
STAGE41_INITIAL_OUTPUTS=24
STAGE41_QUAD_LIVE=24
STAGE41_ENDPOINTS_ISOLATED=24
STAGE41_REVERSE_REBUILT=24
STAGE41_INTERIOR_ISOLATED=24
STAGE41_FINAL_CLEANUP=24
STAGE41_RUNS=24
STAGE41_PASS=24
STAGE41_UNEXPECTED_FAILURES=0
STAGE41_HEAP_MEASURED=YES
STAGE41_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE41_FOUR_OUTPUT_ENDPOINT_HOLES_DISCOVERY_NATIVE
STAGE41_NATIVE_GATE=PASS

No production change, no main/merge/release, and no Stage41 Native PASS
before exact completed/log evidence. If failed, diagnose actual error.
