# Stage39 / DISCOVERY35 — Input lifetime isolation across two distinct pairs

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage38 accepted on 2a40f4bdbe29f8c38fea2440ede74be3ba9675eb:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41878963075
39/39 completed/success, strict Native 24/24, heap post-release zero.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41878963075/artifacts/13349225096

## Scope and independent oracle

Stage38 held two outputs from the same immutable input pair.
Stage39 instead holds A while freeing its inputs and reinitializing
different inputs for output B. This is a bounded investigation of result
independence from input allocation and cross-pair output isolation.
No defect or expected-red status is assumed before reproduction.

For n in {3,9,320,8192} and j in {1,...,6}, K=10^(n-1),
X=K+5j+2, Y=K-(2j+5). Initial (C,T)=(X,Y) for odd j and (Y,X)
for even j. Oracle A=abs(T-C)+1=7j+8.
With A still live, free C/T; replace C by C+1 for odd j, or C-1
for even j; allocate new C and T. Oracle B=abs(T-Cnew)+1=7j+9.
Thus A is {15,22,29,36,43,50}; B is {16,23,30,37,44,51}.
Independent JavaScript BigInt evaluation must equal these two
closed forms for all 24 ordered unique cases. Six use n=8192.
Representation may include leading zeros while the parsed
numeric input remains nonnegative.

## Per-case Native assertions

1. BIG-INTEGER-SERVICE INIT-TEXT creates inputs; snapshot metadata.
2. MONSTER-DISTANCE DISTANCE-PATCH creates caller-owned A with
   status zero, PATCH03:DISTANCE-PATCH message, correct A text,
   and unchanged original inputs.
3. Keep A live, FREE-A original C/T, initialize new C/T; verify
   A text still equals the original oracle. Count successful reinitialization.
4. Produce B into a distinct empty output record; check status/message,
   distinct nonnull output heads, B text equals B oracle, unchanged A,
   and unmodified replacement inputs.
5. Snapshot B metadata, FREE-A A and demand B metadata/text unchanged;
   then free B and new inputs.
6. HEAP-LIVE must report zero allocated bytes after all 24 cases.
Every unexpected failure is an error, not an expected-red witness.

## Acceptance gate

40/40 jobs (39 previous plus Stage39); strict GnuCOBOL 3.1.2.0
-Werror; 300s compile timeout, 120s run timeout, 20 minute job.
Log artifact preserved even on failure. Exact markers:
STAGE39_INITIAL_SUCCESSES=24
STAGE39_REINITIALIZED_PAIRS=24
STAGE39_INTERLEAVED_SUCCESSES=24
STAGE39_ISOLATED_OUTPUTS=24
STAGE39_RUNS=24
STAGE39_PASS=24
STAGE39_UNEXPECTED_FAILURES=0
STAGE39_HEAP_MEASURED=YES
STAGE39_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE39_INPUT_LIFETIME_ISOLATION_DISCOVERY_NATIVE
STAGE39_NATIVE_GATE=PASS

Source/static checks are not Native PASS. Inspect a failing job's real
log before any correction. No main/merge/release, production edits
or full calendar integration claims.
