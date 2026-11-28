# QA31CB — completed run 44958764254 diagnosis and repair (2026-11-22)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
QA branch: `qa-befunge98-stage1-order-isolation-20261008`
Immutable run HEAD: `96981dd17e0c151513dce571aa245cc348048b04`
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958764254
Job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958764254/job/137012653103
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958764254/artifacts/14731250209

## Verified finite evidence (not full acceptance)
- Run job completed FAILURE. Source/metadata preflight and immutable PyFunge 0.5-rc2 fetch passed. Native execution step completed success; independent auditor failed at `qa/qa31cb_independent_audit.py:379` with `PermissionError: [Errno 13] Permission denied: 'qa31cb-out/token_100.jsonl.gz'`.
- Docker-produced boundary trace was already present and readable, but owned by the container user; host Python 3 attempted a second `shutil.copyfile` to the same destination. The full independent 900-trace audit and its 20 detached hostile controls DID NOT complete.
- GitHub artifact 14731250209 digest: `7ce12a3522030efbdf2c6ae0c34f9e2b6f53afae8fc27522fcf3b56ff0b1301c`; ZIP CRC PASS, all 10 manifest SHA-256 hashes PASS.
- Artifact has 900 ordered receipts, tokens 100..999; all 900 status HALT, 24,853 STEP receipts each, total 22,367,700 reported steps; 0 STEP_LIMIT/MULTI_IP/RUNTIME_ERROR. All 900 receipt summaries: 2 input reads, 2 owner-cell p/g events (initial p=0 then g=0), 1 dynamic-cell p=62, 1 dynamic-cell fetch op=62. Four saved boundary `.jsonl.gz` traces (100,199,500,999) were independently checked against their receipt SHA and 24,853 decompressed STEP lines each. This does NOT verify the other 896 physical compressed traces; those temporary files were not preserved after the completed run.
- Production source Git blob pin: `560d6aa5807a7f766213a33835cce85eab0fa40c`. The run preserved the original source and normal stdin; there is no positive natural reachability witness in the finite receipt corpus.
- `stage1_accepted=false`, `global_reachability_proven=false`.

## Minimal QA-only repair
- Preserve output trace by verifying the SHA-256 of an already present copy; never overwrite it. Reject existing mismatches, nonfiles and symlinks. For missing files, copy and verify the output SHA.
- Archive each trace at most once even when both boundary and anomaly apply.
- Gate long Native execution behind a Python 3 archive self-test covering first copy, read-only existing copy, tamper rejection and symlink rejection.
- No production code, original source, main/merge or Stage policy change.

## Evidence gate / NEXT
One new exact-SHA run is justified by this proven permission/duplicate-copy failure and the repair; do not manually dispatch a duplicate. Require completed run/job/log, 900 full trace SHA/STEP audits, 20/20 detached hostile rejections, ZIP SHA/CRC and source/PyFunge pins. The previous 900-case runner success alone is not independent Native acceptance, and QA31CB/Stage1 remain OPEN until the relevant evidence gates are satisfied. No cleanup/deletion of user-execution packages is justified without the specified result comparison.
