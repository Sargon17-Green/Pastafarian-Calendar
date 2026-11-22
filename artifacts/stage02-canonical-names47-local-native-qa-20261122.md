# Canonical month names47: Native QA evidence (2026-11-22)

Project: PC-BRANCH-WAT-SPANISH; authorized WAT+Español baseline fdc6bb4e94f3d69e229998f86e768b71e9571ae8. This QA branch is isolated. No normative WAT modification, main/merge/release or stage acceptance.

## New input, not old artificial capacity stress
Per canonical rule.structure, every valid year satisfies 252<=Y<=5778. The candidate month-count interval is ceil(Y/123)..min(47,floor(Y/4)), so m=47 is admissible in every such interval (whether a given Sauce selects it is not asserted). The month-name choice is DistinctNames(47,47), with independently checked N=47!=258623241511168180642964355153611979969197632389120000000000 (198 bits). This is an actual calendar Choose family cardinality, not 47^5778, and not the exact global N_max.

Independent oracle source: tests/stage02_canonical_names47_oracle.py. Count by Legendre prime valuations checked against sequential factorial, 5P3 brute-force, and all 5527 valid year-length integers. rank formula from rule.selection.rank, M=2^127-1, k=2:
* forward FIRST=1, step +1; no rejection, SHA256(decimal rank)=af77b83c02097ff201ed0848390024fb04773c58b236a09dfa5ea2dbf3b3adce.
* backward FIRST=M, step -1; rejection, rank=N, SHA256(decimal rank)=b3cafdb279a6d89eb83c8cf0647bdb383d73cf4102ddf07c71dc1b09f885cfc5.

## Locally completed, source-locked Node Native preflight
An immutable WAT copy was checked at SHA256 18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980 (Git blob e23f013ab96b498b0ac365dbb1b25273c845e790), from locked source commit 871f9b70216c16c57abcd552ec6fb0ed1010e305. Local Node v22.16.0 executed the same original $choose function through the validated instrumented WASM of earlier accepted focused k253 artifact 14726874775 (ZIP sha256 e52eda09f1ac32462ad6246e53b6b04437ffed664854ef9d697defa686828124; 18 files, integrity test OK). WASM SHA256 13f119dd11f3f7c281344762abd83ba466ff44976e6dae3ec648a8f961699715. It was originally compiled by WABT 1.0.34. N was injected into exported memory (7 radix-2^30 limbs) before invocation. N unchanged after call; result limbs canonical. Observed Native forward PASS, 3.89709 ms, 5 result limbs, rank 128 bits; backward PASS, 1.288942 ms, 7 limbs, rank 198 bits, exact independent rank and SHA checks. Both exit code 0.

The full separate reproducibility bundle includes two independent test scripts (Python count/rank oracle + Node Native harness), source-copy instrumenting workflow YAML, preflight compiled WASM, per-case JSON output, and SHA evidence. Its local ZIP: PC-BRANCH-WAT-SPANISH-names47-QA-20261122.zip, SHA256 82b8d72e3a660eb5db4c32ed090c6ccd8063e515e175575b77d16aa06df1d754. Do not confuse this with the missing original historical Stage02 ZIP/manifest.

Gate summary: canonical family math PASS; local Node Native against verified earlier compiled WASM PASS (2/2); **new source-fresh GitHub CI: NOT RUN**; **new WasmKit: NOT RUN**; **calendar end-to-end differential: NOT RUN**; Stage02 overall NOT ACCEPTED; original Stage02 ZIP/manifest provenance UNVERIFIED. The previous k253, k259 and 111/111 suites were not rerun.

NEXT: commit and execute the full source-fresh YAML/Node harness from the prepared bundle in this isolated QA branch, inspect exact completed run/job/log/artifact and hashes, and then decide if its evidence warrants a guarded authorized-branch fast-forward. Never claim a source-fresh CI PASS based on the local preflight.
