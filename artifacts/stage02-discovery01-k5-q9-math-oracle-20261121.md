# Stage02 DISCOVERY01 — q8 Native acceptance and k5/q9 math-only extension
PROJECT_ID: PC-BRANCH-WAT-SPANISH
Branch: WAT+Español
Parent SHA: fdb52bc20f7add08b0c64d4c4e73f91ee16f02ac
Date: 2026-11-21

## Evidence of the accepted q8 gate
Existing automatic push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828627667
Completed/success, attempt 1, event push, exact HEAD fdb52bc20f7add08b0c64d4c4e73f91ee16f02ac.
Semantic job 136607545658: completed/success; verify job 136607546041: completed/success.
Both logs show exact checkout fdb52bc20f7add08b0c64d4c4e73f91ee16f02ac.
WABT installation 1.0.34; full Node WebAssembly via WABT report: native total=107, passed=107, failed=0; SHA256 normative_selector.wat=8092e0735f2989f8804bcb16d6a9f6e04c1089c4d2ee8fea45eafa78f51f9caa.
The 79 independent numeric-oracle entries were counted from 16 JSON groups (5+6+4+6+2+6+10+8+8*4=79); new k5/q8 group has four entries.
There were no uploaded workflow artifacts. Logs provide the detailed evidence; this is NOT WasmKit nor full Stage02 acceptance.

## Scope of the new q9 experiment
M=2^127-1, S=M^5; M mod 9 = 1.
Five consecutive answers in [1,M] are selected from FIRST=M-13, step +1 or FIRST=M-9, step -1. The positional construction is X=1+sum((a_j-1)*M^j), j=0..4. An independently derived closed polynomial is D=c*(1+M+M^2+M^3+M^4)-step*(M+2M^2+3M^3+4M^4), where c is 13 forward or 9 backward and X=S-D. The sum of D coefficients equals 55, so X mod 9=0 because M mod 9=1. Set N=X/9-delta, delta in {0,1}.
For production M, verify M^4<N<S, floor(S/N)=9 and LIMIT=9N=X-9*delta.
Delta 0: accept X and return rank=N. Delta 1 forward: wrap and accept 1; rejected steps D+1. Delta 1 backward: accept LIMIT; rejected steps 9 and rank=N.
Independent bounded ring oracle starts from S-(S mod 9) and does literal cyclic iteration, without using the stream witness.
No WAT fixture or production selector change in this commit; math-only must never be reported as Native.

## Local reproducible evidence
Runtime: Node v22.16.0, on 2026-11-21.
Command: node tests/stage02_k5_q9_boundary_oracle.cjs
Source SHA256: 44d7be6153963ffff40f344349363224687804fe5d9cdbfcfad0ada01b079ce0
Output SHA256 (local JSON): 65b5efa875128a19fd442cbc29ff4eb70bd1d52e103c60ab4bcc0a28356fb911
Actual preflight: bounded_ring_walks=16, bounded_rejection_transitions=44, small_structural_cases=8, medium_exact_q9=16, production_exact_q9=4, failed=0.
Small structural bases 28/37 are not presumed exact q9; actual quotient 13/17 and 12/14 depending on direction.
A preliminary local fixture design incorrectly assumed the k=5 domain at base 19 backward and exact q9 at bases 100..127 backward. The input domain was corrected before saving this experiment. This was a local oracle-design preflight, not a WAT failure or EXPECTED_RED.

## Gates and NEXT
q8: accepted on the exact parent SHA in Node WebAssembly/WABT CI; no global Stage02 acceptance.
q9: local independent math preflight PASS; CI gate pending a completed run on new HEAD; no q9 Native implementation or PASS yet.
NEXT: inspect the new auto-triggered CI run, both logs, exact checkout, q9 JSON and unchanged 107/79 regressions. If accepted, build separate q9 WAT witnesses with independent 8-field comparison; do not claim production correctness, WasmKit success, ZIP provenance, merge or release.
