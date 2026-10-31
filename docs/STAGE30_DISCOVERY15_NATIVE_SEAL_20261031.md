# Stage30 / Discovery15 — Native distribution research evidence seal (PowerShell+Tagalog)

## Provenance and conclusion

- Scoped research implementation and fixed test SHA: [`0c2b6d5d438cd82d0d06e198a9ff16e2fd4adb62`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/0c2b6d5d438cd82d0d06e198a9ff16e2fd4adb62); HEAD was verified on branch `PowerShell+Tagalog` before seal. No production change or merge.
- Exact-SHA Windows PowerShell 5.1 and verify: [GitHub Actions run 41187209526](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187209526), status `completed`, conclusion `success`. Native job 124496449769 and verify job 124496449912 both completed/success. Native runner version `5.1.26100.33648`.
- [Independent research contract](STAGE30_DISCOVERY15_DISTRIBUTION_CONTRACT_20261031.md) and [executable Stage30 test](../tests/Stage30.Tests.ps1): finite toy enumeration 56 states, 8 real-M analytical witnesses with `M=2^127-1`, 96 assertions passed and zero failed. Balanced-sign toy `M=7,N=8` yielded TVD=`17/28`.
- Preserved predecessor tests: Stage01=73, Stage23=35, Stage24=47, Stage25=45, Stage26=39 (including intentional historical RED), Stage27=156, Stage28=71 (evidence-only), Stage29=102. Total 568 assertions; aggregate with Stage30: 664, all green. The Stage29 oracle compatibility and Stage26 historical scar remain unchanged.
- Stage23 finalizer idempotency ran twice; both reported AlreadyFinalized=True; the initial and both resulting SHA-256 values were identical: `176F816BC1C50EA3F872CAA14958AC2EA8209597475BE0E503CC3A0563E3F581`. `RESULT=PASS`.
- Persisted [finalizer evidence artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187209526/artifacts/13037710417) and [runner-side stage metadata artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187209526/artifacts/13037615608). Artifact ZIP digests as reported: `sha256:d6c387c89f94306e13b3dcc81cc5cfaf2f14f38a51e0f2600383f56862bb93a6`, `sha256:b80f5812ba29d66d44cf9cfeaf1782c2832cba6c683e065e7ef0d684df59f350`, respectively.

## Scope and acceptance

Stage30 is `EVIDENCE_ONLY_CONFIRMED` and not a production bug fix, a statistical uniformity proof for real calendar dates, or a demonstration of independent entropy. The exact formulas apply ONLY to a declared hypothetical law: First uniform on 1..M and Step independently fixed or balanced ±1. The actual law of date-derived First/Step has NOT been measured or established.

This seal records Native proof on the implementing SHA, not fictitious validation of this new seal commit. The seal commit requires its OWN completed/success Windows PowerShell 5.1 and verify on its exact SHA. The active workflow retains every Stage01–29 regression and the Stage30 evidence-only gate for CURRENT_STAGE=30, and also rechecks Stage23 finalizer idempotency twice. Until that new run completes, `STAGE30_SEAL_COMMIT_NATIVE_RECHECK=PENDING` is deliberate.

## Proposed Stage31 / Discovery16 inquiry (not yet implemented)

Investigate the *actual date-derived* First/Step support and dependence without assuming independent randomness or copying any other branch's oracle. Candidate bounded protocol: select deterministic dates straddling 1-, 2-, 4- and 100-year boundaries plus a reproducible short contiguous window; extract First/Step via the branch's existing public computation, verify both against independent algebraic invariants / manual small examples, and tabulate distinct values, repeated states, and sign/frequency counts. Report scope and sample cardinality; do not infer global uniformity from finite fixtures. If required extraction depends on hidden intermediate state, first create a test-only instrument without changing the five final date outputs. Contract and executable probe are the NEXT step only after exact seal CI evidence.

No main change, protected ref change, publication, or claims of new Stage31 PASS.
