# Explicit correction: ordinal error and incomplete original Discovery 01 coverage

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Date: 2026-11-28
Status: OPEN corrective action; no new Native result and no canonical Stage 2 or Stage 3 acceptance asserted here.

## What went wrong

The original 06-implementation-prompt.md dated 2026-08-26, Library file_000000003bf881f5bee252b1c10017c9, lines 345–369, 626–646, 952–962 requires separate Discovery and Patch stages (2=Discovery01, 3=Patch01, 4=Discovery02) and requires M, 2M, 3M, M+1 in Discovery01. The branch incorrectly grouped both activities under Stage2. Discovery and Patch were separate actual commits, not a single code change, but the ledger and acceptance prose were wrong. Moreover the original mandatory +3M case was omitted from both historical QA datasets. This is a real coverage nonconformance, not a harmless label change. Neither historic acceptance statement can establish full canonical coverage. The user rejected cosmetic reconciliation and required visible correction against the source specification.

## Immutable historic record (not retrospectively rewritten)

- Discovery01 5a9c6387ef1a703e11bc5ddbbf7aa6111c94e6c6: CURRENT_STAGE=2, CURRENT_KIND=DISCOVERY, LAST_COMPLETED_STAGE=1. Run 46042644529 job 140653979938, artifact 15221501754 digest 8f378301bd095570d9901db03d366e34ed289bb81b8ce1ac5af54b1a69daa8d9. Observed 21 cases, 7 divergences, 14 matches. Separate run 46042644521 5 canonical jobs success; 7 canonical jobs in first run success; 8 legacy diagnostic failures not concealed.
- Patch01 0e8d906ffb197a5c1beb836304dd09be34b73c02: incorrect CURRENT_STAGE=2, CURRENT_KIND=PATCH, LAST_COMPLETED_STAGE=1. One commit after Discovery, seven files. Run 46128726615 job 140928995321, artifact 15257056514 digest c67c9bbf6e9d84f23c23a82d238343b8524f7357b10c130e14f7b2d7041b0b73. Observed 35 cases, 7 corrected, 28 preserved. Separate run 46128726613 5 canonical jobs success; 7 canonical jobs in first run success; 8 legacy diagnostic failures retained.
- b28d9c58c25471cb558748fc04a177ad7d4279e1 recorded incorrect LAST_COMPLETED_STAGE=2 and combined Stage2 acceptance. It changed only documentation. bbd46f7d6c8b805fef29b5e918c51c17acb473a1 added the Discovery02 analytic preparation, not implementation.
- In this corrective review both historical job logs, exact checkout SHA, artifact metadata and matching upload digests were re-read. Independent integer replay of all 21 and 35 distinct logged inputs passed. The original ZIP byte replay is recorded in prior register evidence, not repeated here. The original case census contains M, 2M, M+1, not 3M. All historic test files, source, logs, artifact names and commit identities remain untouched. No retroactive RED or GREEN is invented.

## Corrective action, not a new numbered stage

The active implementation is at canonical Stage3 (Patch01 already present); the last *fully evidenced* canonical stage is conservatively reset to 1 pending the gap. CURRENT_STAGE=3 identifies the physical implementation, not acceptance. Do not revert the branch or erase the historical raw route. Stage2 and Stage3 canonical acceptance reopened explicitly. Stage4 is not open. Do not proceed to Discovery02 until both corrective gates and prior canonical regression evidence are reviewed.

New tests use independently calculated exact decimal literals for +/-3M and both neighbors, not copied fixtures; 6 cases per source. Historic Discovery source is built from its exact checkout 5a9c6387ef1a703e11bc5ddbbf7aa6111c94e6c6; new QA is dated now and is not part of that old commit. Current patch is built from exact corrective commit checkout and source blob 2563ef9851e17dfd513c3f522498990cc47976e6. The historical source blob is 1381c19b0badccf25a28239d4aad6c427fab11a6. Compare input, raw result, literal expected SAVE, clean oracle, route trace, call and metrics. Predicted raw 2 divergences/4 matches per source; patch must yield corrected result for all six. Native not yet observed. Evidence: distinct checkout identities, source hashes, compiler, logs, exit, manifest, always-upload artifact, 30s/1GiB per probe. Review newly completed CI and actual logs/artifact before accepting. The correction can supply missing evidence now, never make it contemporaneous with the historical commits.

No production change, no Patch02, no history rewrite, no merge/main/release.
