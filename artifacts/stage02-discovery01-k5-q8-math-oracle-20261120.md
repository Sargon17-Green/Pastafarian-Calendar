# Stage02 DISCOVERY01 — q7 Native gate and independent k5/q8 discovery (2026-11-20)

PROJECT_ID: PC-BRANCH-WAT-SPANISH. Branch: WAT+Español. Verified parent: 68e38250019c056d0e804659eaf82200dbea4ea4.
The q7 run is https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44800265568 .

## Completed q7 evidence
- Run 44800265568 attempt 1; jobs semantic 136510280219 and verify 136510280603: both completed/success.
- Both checkout logs contain the exact parent SHA; the branch was equal to the parent at gate verification (ahead=0, behind=0).
- Semantic job: WABT 1.0.34 and Node WebAssembly; 103/103 Native tests passed, zero failed; 75 BigInt exact-memory-field oracles across the logged groups.
- WAT source SHA256 in the semantic JSON: 6a39c2bd27b48b202febdb984017d97166d7edd0132113231c0b5b9bbeabfb63.
- No job artifact was uploaded. Logs and the source commit are the evidence. This is q7 gate acceptance only; Node WebAssembly does not retroactively certify q7 on WasmKit.

## New independent math-only k=5, q=8 oracle
- Production radix M=2^127-1, S=M^5; first values M-9 for step +1 and M-5 for step -1, with five consecutive responses.
- Separate deficit identity: forward D=5M^4+6M^3+7M^2+8M+9, backward D=9M^4+8M^3+7M^2+6M+5.
- Since M mod 8 = 7, both constructed candidates X=S-D satisfy X mod 8=0. With N=X/8-delta, delta=0 or 1, verify M^4<N<S and floor(S/N)=8.
- Boundaries: delta=0 exact acceptance rank=N; delta=1 forward wrap rank=1 after D+1 rejections; delta=1 backward rank=N after eight rejections.
- Local Node 22 independent preflight: 16 bounded ring-walk cases with 64 explicit rejection transitions; 8 small structural cases (not called normative k5/q8), 16 medium exact-q8 cases, 4 production exact-q8 cases; zero failures.
- Local source SHA256: bd718c69d3323b15bb09a83044e589320081e88e8d962eefd4e3e80c95f10f12; JSON output SHA256 b15f4d51671445f86f25b0aa62e0dd6bb73af7618bf1467a2d420e921e7c463c.
- The new source is standalone and is added to the existing CI oracle step. Production WAT and Native runner are untouched: 103/75 remains the existing Native target, not a q8 Native claim.

## Acceptance boundary and NEXT
Stage02 remains OPEN / READY and globally NOT ACCEPTED. Historical ZIP provenance/equivalence is unresolved; no main, merge, release, or EXPECTED_RED.
NEXT: require completed GitHub CI on this new exact commit, verify both job logs and q8 math JSON; then construct four q8 end-to-end WAT witnesses with an independent eight-field memory oracle and rerun Native only on their new SHA. Preserve the distinction between Node WebAssembly and WasmKit evidence.
