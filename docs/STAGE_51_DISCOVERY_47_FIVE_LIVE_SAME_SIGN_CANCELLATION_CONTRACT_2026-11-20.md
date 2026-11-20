# Stage51 / DISCOVERY47 — five live same-sign full-width cancellation
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage50 accepted at b629a0f12d1afeb2a0611adeba6849bb8e9a9588, run 44716181388: 51/51, 25/25 native, heap 0, verified ZIP SHA256 and CRC.
Kind: bounded test-only DISCOVERY. No historical defect alleged. Native NOT STARTED.

## Separate hypothesis
Stage50 covered opposite-sign n-digit operands with n-digit results. It did not cover same-sign full-width inputs whose subtraction cancels up to 8192-digit magnitudes to a small result, including long decimal borrows. Stage51 tests five simultaneous owned outputs, input sign reversal and occupied-output rejection in this complementary arithmetic regime.

## Inputs, ABI and exact results
For n in [3,9,128,320,8192], j=1..5, B=10^(n-1), define C=2B, T=2B-j. Both are n-digit positive numbers; T contains a long suffix of nines. Five live slots indexed k=0..4 use C_k=C+k and same T. Expect R_k=|T-C_k|+1=j+k+1.
Snapshot all five output descriptor fields, owner identities and decimal text. Release and reinitialize BOTH input owners to C'=-(2B+2j+3) and T'=-(2B-j), again n-digit magnitudes with equal negative signs. Original five output descriptors, owners and values MUST remain unchanged. Occupied-output compute must reject without ownership or text mutation (use accepted ABI status; no invented numeric code). Select k=(caseIndex mod 5), free only selected output, check four survivors, compute C'_k=C'-k against T': R'_k=|T'-C'_k|+1=3j+4+k. Recheck all five outputs, distinct owner pointers and four old survivors. Reinitialize original C and T, free only replacement, restore original selected result, check all five snapshots and four original owner identities, then release all and measure real post-release heap=0. Clean up on every failure path.
At n=8192 the signed text including minus sign cannot fit INIT-TEXT PIC X(8192); initialize positive magnitude and change normalized SIGN=-1 using current accepted signed ABI, checking metadata without claiming 8193-byte parsing.

## Independent planning oracle and measurable gate
test/stage51_planning_oracle.mjs uses unsigned grade-school subtraction with explicit borrow and a separate +1 carry, cross-checked with BigInt absolute difference and the symbolic expressions, never invoking COBOL. Exactly 25 unique ordered pairs, five at n=8192; 250 original/reversed exact arithmetic comparisons, plus 125 global sign-symmetry metamorphic equalities. Ownership model: 125 initial owners, 100 input rebuilds, 125 snapshots after input change, 25 occupied rejects preserving 125, 100 survivors after free and after reuse, 25 replacements, 25 owner restorations, 125 restored snapshots, 25 cleanups and target balance 5,5,5,5,5. Planning result is PASS_NOT_NATIVE and cannot establish Native acceptance.

## NEXT
Implement test/stage51_discovery_tests.cob using THIS branch ABI, strict GnuCOBOL -Werror, exact strings, pointer and descriptor checks and measured heap, plus one new strict job in canonical-names-lock.yml (52/52 expected), compile timeout <=300s, executable timeout <=120s, job <=20min and uploaded raw log. Accept only exact-SHA completed/51? Check all 52 jobs, native counts, zero unexpected, heap=0, artifact ZIP byte SHA256 and CRC. If failure occurs, document exact case and exclude harness faults before a production-defect claim. No main/merge/release.
