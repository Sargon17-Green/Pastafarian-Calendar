# Stage56/B5 external-source semantic differential — QA-only gate

PROJECT_ID: `PC-BRANCH-PHP-MALAY`  
Branch: `PHP+Bahasa-Melayu`  
Pinned external source: `Sargon17-Green/pastafari-calendar@cc2cf0b422757a5e7c33218ce30cffa8f99c6786`  
Calculation day: `-13334246` (foundation, **scenario input**, not universal Year5000 anchor).

## Status before executing the new job

- PHP branch source checkpoint: `3768bbeaba4d7fc88330164a76cf8a1739122a21` at inspection.
- Existing canonical push CI: `44828716604`, `completed/success`, 30/30 jobs, exact SHA. B5 job: `136607842359`. Existing B5 artifact `14677696939`, digest `sha256:8c402aa2de23e69fec281d88de1d64d1c33593a47fba2373a0f60eeeba4565e3` is **synthetic input preflight**, not genuine-year acceptance.
- No live export/differential result is claimed by this document. Existing external Python exporter had only syntax/negative local checks; source-bound real years = 0 at checkpoint.

## New independently testable contract

1. A dedicated `external-reference-differential` job in the active `.github/workflows/canonical-names-lock.yml` checks out the **exact canonical commit** independently, saves source hashes, verifies `HEAD` and clean working tree, and runs existing SHA-bound external exporter against the separate checkout. It captures separate exit codes and stdout/stderr and emits external-reference JSON plus SHA-256; failures retain evidence via `upload-artifact if: always()`.
2. `tools/stage56_external_semantic_samples.py` reloads the exact Git-verified canonical Python engine and exports sampled five-component date tuples. Deterministic sample offsets include each month's first and last appearances, both year ends, and eight equal-width quantiles. It checks source SHA-256 against the upstream exporter and preserves its own output SHA-256. All 3 years, 4999/5000/5001, are generated under the **same** `calculation_jdn`.
3. `tools/stage56_verify_external_reference.mjs` independently reconstructs year 4999/5000/5001 boundaries and **complete** month-length and month-weave arrays using the Scroll-derived reference oracle, then checks every selected five-component tuple against both the Python engine and the authoritative fast JavaScript runtime. It checks sidecar digests, anchor digest, project ID, external provenance and fixed calculation context. Any mismatch causes nonzero exit. The report contains an explicit external-reference-only status.
4. The workflow stores a SHA-256 manifest, runtime logs, component exit codes, a reference JSON, sampled tuples and differential report in a GitHub Actions artifact. GitHub action execution, not local parser checks, is required for any semantic PASS claim.

## Limits and next gate

This gate does **not** authenticate a PHP `src/*.php` production year-structure provider. Its JSON carries `source.kind=external_canonical_reference` and must be rejected by the PHP B5 production provenance gate. It must never be relabeled, copied into PHP fixture input, or treated as a substitute for independent PHP source implementation. Three 900s/512MiB real-year PHP8.3/64 profiles remain separate, unopened acceptance gates. No changes to production PHP conversion or PATCH22/PATCH23 are authorized by this QA-only work. Stage56 remains **IN_PROGRESS** until all real source-bound PHP gates pass.

Local authoring checks: Python syntax (`python3 -m py_compile`), Node syntax (`node --check`) and YAML parsing; these are **static**, not differential, CI, Native, or Stage56 PASS.


## 2026-11-21: failure triage and read-only checkout fix (after run 44876679772)

- Exact PHP branch commit tested: `b515eb115d7166b748f9cefdb29223e7c2e84f97`; canonical source pinned at `cc2cf0b422757a5e7c33218ce30cffa8f99c6786`. The 30-job workflow completed **failure** with 29 success and one failed job (`external-reference-differential`, job `136762798367`).
- The real external Python reference export **succeeded** (`export.exit=0`; empty export stderr), generating `reference.json` with SHA-256 `46b2f316eb2b08c2dc99fd827d8e0a227061c9b97bbb708842318c08a7bf1880`. The year numbers and boundaries are 4999: [-13340404,-13336278] (4126 days, 34 months), 5000: [-13336278,-13332034] (4244 days, 45 months), 5001: [-13332034,-13326467] (5567 days, 46 months); calculation_jdn=-13334246. These are **external reference years only**.
- The subsequent semantic sample exporter exited 2 with `STAGE56_EXTERNAL_SAMPLE_REJECTED: external source checkout is not exact and clean`; no sampled tuple JSON or differential PASS exists on that run. Artifact `14697940676`, ZIP SHA-256 `66074ae7d4e7a027cb510040db08aaa91a2a459770883a39b7367831faf0aaee`, retains the stderr, source provenance and reference JSON. The original artifact did not retain the dirty-file list, so the precise dirty path is **not evidenced**.
- On CPython, `importlib.util.spec_from_file_location` followed by `exec_module` can create `__pycache__/*.pyc` under the loaded source tree (reproduced locally on an isolated fixture). This is the identified likely mechanism; do not equate it with a confirmed contaminated path in the old run.
- Surgical remediation in the same CI job: set `PYTHONDONTWRITEBYTECODE=1` and run both Python scripts with `-B`; audit and save `git status --porcelain --untracked-files=all` **after** the first export and **before** the second. The audit fails closed for any remaining contamination, retains evidence and does **not** waive source binding. Re-running is justified only on the new code SHA via the normal automatic push trigger; do not manually dispatch duplicate runs.
- Acceptance remains separate: the post-fix automatic run must finish, report all three external oracles and publish artifact evidence; a read-only fix alone is not semantic/differential PASS. Contextual PHP source-owned provider and the three 900s/512MiB PHP 8.3/64 real-year count/rank/unrank profiles still have no authenticated PASS. No PHP production or PATCH22/PATCH23 code was changed.
