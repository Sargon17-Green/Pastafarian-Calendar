# Stage 5 Native failure analysis — BASIC+ਪੰਜਾਬੀ (2026-11-20)

**Project:** `PC-BRANCH-BASIC-PUNJABI`  
**Status:** `STAGE5_QA_NOT_ACCEPTED` / `FULL_FIVE_FIELD_PRODUCTION_NOT_IMPLEMENTED`  
**Last tested QA HEAD:** `ebf3dcb77940ebeccc86b5bd599107d18f56240a`  
**Accepted production/source lock remains:** `74aa087b81094f34eab9a0e04e395cc693dd83b1`

## Completed CI evidence (no rerun)

- [GitHub Actions run 44633924038](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633924038), push, attempt 1, SHA `ebf3dcb77940ebeccc86b5bd599107d18f56240a`: `completed/failure` (2026-11-19).
- Jobs: `verify=success`, `stage5-semantic-native=failure`, `stage3-native-green=skipped`, `stage4-bigint-differential=skipped`. Historical accepted stages were **not** rerun.
- [Raw artifact 14584304687](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633924038/artifacts/14584304687): ZIP SHA-256 `bfe0265c16b0a0a6a2a9ee87f8b06cb61eb7f9708061aa497e8517e94206f502`, ZIP CRC PASS, seven files: `cases.tsv`, `assertions.json`, `source_metadata.json`, `status.txt`, `progress.log`, `lo-startup.log`, `error.txt`.
- Native `OracleDayCount`: **24/24 PASS** against independent Python-int formula. Native `OracleWorkCounts`: **11/11 PASS** against independent Python-int pairs. This is **35/35 for this strictly limited arithmetic scope**, not Stage5 acceptance.
- Production characterization: **2/2 FAIL**; actual `91|Object variable not set.`, expected `9302|E_STAGE_02_DISCOVERY_ONLY`. These failures must not be reclassified as PASS.
- The first `S5Gate(-3)` call hit the 240-second watchdog; the owned LibreOffice process group was killed and the UNO bridge disposed. No gate assertion was completed. Year/date probes were never reached.
- `assertions.json`: 37 recorded cases (35 PASS, 2 FAIL); `native_invocations=37`, `boundary_checks=0`, `structural_only_checks=0`, `failures=3` (two mismatches plus timeout). Required Stage5 contract: 46 distinct completed PASS cases. Thus **NOT_ACCEPTED**.

## Independently isolated error-raising discrepancy

The unmodified production module `basic/Standard/CalendarSpaghetti.xba` starts with `Option Explicit` but **does not** declare `Option VBASupport 1`; `calendarDateSpaghetti()` calls `Err.Raise 9302, "calendarDateSpaghetti", "E_STAGE_02_DISCOVERY_ONLY"`.

The official LibreOffice documentation says that the VBA `Err` object and its `Raise` method require the `Option VBASupport 1` statement:
https://help.libreoffice.org/latest/en-US/text/sbasic/shared/ErrVBA.html

An **isolated synthetic UNO macro** was executed with LibreOffice **25.2.3.2** without editing the repository. The same `Err.Raise 9302` plus `On Error GoTo` handler returned `91|Object variable not set.` with only `Option Explicit`; adding `Option VBASupport 1` to the **synthetic module** returned `9302|E_STAGE_02_DISCOVERY_ONLY`. This reproduces the mechanism but does not constitute a production fix or proof for all possible production contexts.

**Required correction path:** an explicitly scoped future production-source change must repair error raising and be validated with real UNO output. Do not weaken the native assertion to accept `91`, do not modify the QA test copy as a substitute for verifying unmodified production source, and do not treat expected `9302` as a five-field calendar success.

## Gate timeout: cause not proven

`S5Gate(-3)` invokes `OracleGateDay` / `OracleGateIndexAtOrBefore` and their underlying `OracleOneGateGap` / `OracleSauce` computations. The 240-second timeout proves the existing end-to-end gate probe did **not** complete within budget. It does **not** prove an infinite loop, an incorrect gate value, or a specific expensive subroutine. A separately bounded, instrumented diagnostic is required before changing the Oracle, relaxing the acceptance threshold or increasing the CI timeout. Any such run should keep a fresh, owned, isolated LibreOffice session and preserve raw progress.

## Scope and next permissible steps

1. Keep `Stage5=NOT_ACCEPTED`, `full production five-field calendar=NOT_IMPLEMENTED`, and keep accepted Stage2–Stage4 evidence unchanged.
2. Diagnose gate cost by narrower native timing probes under an explicit budget, and resolve the production `9302` mismatch **only** through a separately reviewed source change when authorized. The two problems are independent and should not be hidden inside the same PASS criterion.
3. After a substantive fix, use one new natural push run and inspect `completed` jobs plus all 46 raw rows, assertions, metadata, actual source locks, status and live UNO logs before accepting Stage5. Never trigger duplicate runs while queued/in-progress.

This is a **QA documentation-only** change. No production modules, canonical-name source blobs, accepted stages, `main`, merge, publication, old `D:/v17` workspace or machine-wide Windows cleanup are touched.
