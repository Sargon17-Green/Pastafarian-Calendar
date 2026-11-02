# Stage31 / DISCOVERY27 — 仿射距离变换与跨零测试 (2026-11-02)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage30 accepted on exact SHA 695fac56c40a649a84c6f42aa45d6576a474b749, 31/31 CI success, 24/24 native, unexpected 0, measured heap post-release 0.
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41507996546
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41507996546/artifacts/13171647759

## Measurable, independent bounded contract
Production under test (unchanged): MONSTER-DISTANCE / DISTANCE-PATCH f(c,t) = |c−t|+1. The native test calls the existing COBOL implementation, checks input sign/chunk/head/tail nonmutation, output ownership release, and real heap-live post-release measurement.

Six decimal-width witnesses (n, d, z, k):
- (9, 17, -5, 1)
- (18, -31, 7, 3)
- (37, 999, -500, 8)
- (73, -1001, 250, 9)
- (127, 1234567, -600000, 19)
- (290, -99999999, 125, 28)

For each row let A=10^n−1, B=A+d, S=10^k; independently fix four distinct ordered pairs:
1. (A,B) base;
2. (z,z+d) translation by T=z−A, crossing zero;
3. (−A,−B) simultaneous sign reflection;
4. (S×A,S×B) decimal dilation.
Total 6×4=24 unique ordered native calls. Each expected output is independently formed from decimal digits |d| followed by k zeros (scale case) then incremented by one with manual single-digit carry; verify against an independent JavaScript BigInt implementation of |c−t|+1 for all 24 fixtures. Neither uses COBOL production as oracle.

Metamorphic checks (three per row, 18 total):
f(A,B)=f(z,z+d);
f(A,B)=f(−A,−B);
f(S×A,S×B)=S×(f(A,B)−1)+1.
This checks simultaneous translation, sign reflection and decimal dilation, including cross-zero orientation; unlike Stage30's cyclic prefix near-neighbor boundaries. Input signs are explicit. No bug/expected-red without native observed failure.

Static gates: 24/24 BigInt-vs-manual-digit expected, 18/18 identities, 24 distinct pairs, max signed literal width 319≤320, maximum expected width 36≤320, max COBOL source line 103≤115, exactly 24 RUN-PAIR calls. Fixed fixtures, no runtime random data.

## Native and acceptance
ubuntu-24.04 / GnuCOBOL 3.1.2, strict -Werror; compile timeout 300s; runtime timeout 120s; job 20min; artifact uploaded on success or failure.
Requires exact pushed branch head, 32/32 jobs completed/success, native job stage31-affine-distance-metamorphic-discovery-native, and log markers:
STAGE31_RUNS=24
STAGE31_PASS=24
STAGE31_UNEXPECTED_FAILURES=0
STAGE31_HEAP_MEASURED=YES
STAGE31_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE31_AFFINE_DISTANCE_METAMORPHIC_DISCOVERY_NATIVE
STAGE31_NATIVE_GATE=PASS
Static preflight != Native PASS. No production/main/merge/release; no full five-component calendar claim.
