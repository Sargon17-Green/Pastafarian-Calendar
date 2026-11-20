# Stage50 / DISCOVERY46 — five live signed full-width outputs with input polarity reversal
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage49 accepted at c808be10ae308f5b49dcef1510be5bf474833dc1; CI 44700966287: 50/50 completed/success, Native 24/24, measured heap zero, verified ZIP SHA256 and CRC.
Kind: bounded independent DISCOVERY and test-only planning; NO historical defect asserted; no production change.

## Distinct hypothesis
Stage49 covered FOUR live outputs while both positive caller-owned input objects were reinitialized. It did not cover FIVE live output owners with opposite-sign operands and full-width arithmetic results while both input signs reverse. Test independent signed representation and ownership when the entire result, rather than a small offset, spans up to 8192 decimal digits. The exact signed-routine semantics are the branch's existing DISTANCE-PATCH (= |T-C|+1); the oracle never invokes the COBOL implementation.

## Inputs and expected values
Widths n = [3, 9, 128, 320, 8192], repetitions j=1..5. Let B=10^(n-1). Start C=B+4j+3 > 0 and T=-(B-(2j+1)) < 0. Both magnitudes must be within the existing 8192-decimal-digit input limit. Five output slots k=0..4 use C_k=C+k, T unchanged. For each, exact result R_k=|T-C_k|+1=2B+2j+3+k; a positive n-digit string.
Keep all FIVE caller-owned outputs live, snapshot all five descriptors and text values. Release and rebuild BOTH inputs to C'=-(B+3j+2)<0 and T'=B-(j+1)>0 using accepted service release/INIT-TEXT calls. All original five output descriptors, owners and values must remain unchanged after input destruction and sign reversal.
Attempt to compute into ONE occupied output destination while all five are live. Require a rejected occupied-output status, no owner loss, and preservation of all five exact values/descriptors. Do not presume a numeric error code without validating this branch's accepted ABI.
For case q=0..24 select slot k=q mod 5 (five selections per slot). Free only that output, assert four survivors unchanged. Recompute its result with C'_k=C'-k and T'; expected R'_k=|T'-C'_k|+1=2B+2j+2+k, while four old outputs retain R_i. Check five distinct live owned descriptors.
Restore both original inputs through safe release/reinitialize, retire only the replacement output, recreate original selected R_k, and verify five original values and four unchanged owners. Release all outputs and inputs and measure real heap live after release = 0. Include error-path cleanup. Never double-free.

## Quality/acceptance gates
25 unique ordered (C,T) pairs, exactly five at n=8192, 125 baseline and 125 sign-reversed results = 250 arithmetic comparisons. Independently check BigInt direct absolute difference against grade-school decimal digit addition with carry and symbolic closed forms; match EXACT decimal strings without production code. Counts in standalone model: 125 original owners; 100 input rebuilds (two inputs at both transitions per case); 125 preserved after polarity switch; 25 occupied rejections preserving 125 results; 100 survivors after free and 100 after reuse; 25 replacement owners, 25 restorations, 125 final restored snapshots; 25 cleanups; slot balance 5/5/5/5/5. Model reports PASS_NOT_NATIVE, never Native PASS.
Next implement test/stage50_discovery_tests.cob using the accepted interfaces of THIS COBOL branch, with independent exact text/metadata/pointer/status checks, strict -Werror GnuCOBOL, measured heap, unexpected=0, five-live no-alias assertions. Use the existing full-width evidence conventions; protect input/output pointer ownership and clean all failure paths. Native counters must equal the model counts where applicable.
Add exactly one Stage50 strict CI job to existing canonical workflow after Stage49 (expected 51/51 jobs), with bounded compile <=300 s, execution <=120 s, job <=20 min and uploaded raw evidence. Require exact HEAD and run SHA, completed native log, verified jobs pagination, ZIP SHA256 and CRC, and actual counters before accepting. No duplicate manual rerun of an already accepted SHA.
If actual Native produces a failing counter, record exact case, source and logs before classifying expected-red; investigate test errors independently of production defects. No main/merge/release.

## Current status
PLANNING_ORACLE_ONLY / NOT_NATIVE / STAGE50_NOT_ACCEPTED.
NEXT: implement isolated Stage50 COBOL Native harness and strict CI, source-oracle fixture readback, then assess exact-SHA completed logs, ZIP digest and CRC. This planning step does not imply an application release or the entire calendar implementation.
