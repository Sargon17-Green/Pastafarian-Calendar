# Stage02 DISCOVERY01 — k5/q7 Native WAT candidate (2026-11-20)

PROJECT_ID: PC-BRANCH-WAT-SPANISH. Branch: `WAT+Español`. Parent exact HEAD: `223ea24033b095792b3c06d69083a9c457bf84e2`.

## Verified prerequisite
The q6 Native gate is independently recorded at run [44715966354](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44715966354), attempt 1 completed/success on historical SHA `083c3a2181d05a610f18f0339f6d7ee1102992bb` (99 Native/71 BigInt). The q7 independent math-only oracle at parent `223ea24033b095792b3c06d69083a9c457bf84e2` was accepted in [CI 44734188691](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734188691), attempt 1 completed/success. These do not establish q7 Native acceptance.

## Native fixtures and field oracle
Use M=2^127−1, S=M^5. Forward FIRST=M−5 yields X=S−(M^4+2M^3+3M^2+4M+5), backward FIRST=M−1 yields X=S−(5M^4+4M^3+3M^2+2M+1). For direction ±1 and δ=0/1, take N=X/7−δ; enforce N>M^4, q=floor(S/N)=7, LIMIT=7N. Native fixtures divide the radix limbs exactly by seven (nonzero remainder traps), call unchanged production `$choose`, and export the four corresponding cases. The Node independent BigInt checker reconstructs the candidate from the five digits, checks the separate deficit polynomial, verifies the quotient, and checks all eight WebAssembly memory fields `M,FIRST,CUR,N,SPACE,LIMIT,WIDE,RESULT`. For δ=1 forward wrap, accepted=1 and rank=1; δ=1 backward, accepted=LIMIT after seven rejected steps and rank=N.

## Pre-push bounded checks (not Native)
- Existing 99 exports preserved; 4 additional q7 exports; 103 unique test export names by static scan.
- WAT parentheses balanced with comments and strings ignored; original production `$choose`/`$choose_wide` body untouched.
- 4/4 production q7 BigInt boundary constructions passed independent arithmetic preflight; both step directions and both deltas.
- Workflow and runner targets updated to 103 Native WAT / 75 BigInt exact-memory checks; these are target counts, **not a reported CI PASS**.

## Acceptance and exclusions
Require push-triggered CI on the new exact SHA, completed/success, both verify and semantic job logs proving exact checkout SHA, WABT version and native 103/103 and 75 exact BigInt comparisons. Do not infer global Stage02 ACCEPTED or historical ZIP equivalence; no main/merge, no EXPECTED_RED. No local WABT/Native execution is claimed by this report.
