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

1. A dedicated job in `.github/workflows/stage56-php-malay-external-reference-qa.yml` checks out the **exact canonical commit** independently, saves source hashes, verifies `HEAD` and clean working tree, and runs existing SHA-bound external exporter against the separate checkout. It captures separate exit codes and stdout/stderr and emits external-reference JSON plus SHA-256; failures retain evidence via `upload-artifact if: always()`.
2. `tools/stage56_external_semantic_samples.py` reloads the exact Git-verified canonical Python engine and exports sampled five-component date tuples. Deterministic sample offsets include each month's first and last appearances, both year ends, and eight equal-width quantiles. It checks source SHA-256 against the upstream exporter and preserves its own output SHA-256. All 3 years, 4999/5000/5001, are generated under the **same** `calculation_jdn`.
3. `tools/stage56_verify_external_reference.mjs` independently reconstructs year 4999/5000/5001 boundaries and **complete** month-length and month-weave arrays using the Scroll-derived reference oracle, then checks every selected five-component tuple against both the Python engine and the authoritative fast JavaScript runtime. It checks sidecar digests, anchor digest, project ID, external provenance and fixed calculation context. Any mismatch causes nonzero exit. The report contains an explicit external-reference-only status.
4. The workflow stores a SHA-256 manifest, runtime logs, component exit codes, a reference JSON, sampled tuples and differential report in a GitHub Actions artifact. GitHub action execution, not local parser checks, is required for any semantic PASS claim.

## Limits and next gate

This gate does **not** authenticate a PHP `src/*.php` production year-structure provider. Its JSON carries `source.kind=external_canonical_reference` and must be rejected by the PHP B5 production provenance gate. It must never be relabeled, copied into PHP fixture input, or treated as a substitute for independent PHP source implementation. Three 900s/512MiB real-year PHP8.3/64 profiles remain separate, unopened acceptance gates. No changes to production PHP conversion or PATCH22/PATCH23 are authorized by this QA-only work. Stage56 remains **IN_PROGRESS** until all real source-bound PHP gates pass.

Local authoring checks: Python syntax (`python3 -m py_compile`), Node syntax (`node --check`) and YAML parsing; these are **static**, not differential, CI, Native, or Stage56 PASS.
