# Excel-VBA + ᐃᓄᒃᑎᑐᑦ — Stage 1 native evidence hardening (2026-10-31)

## Scope and provenance
Only the existing Excel-VBA Inuktitut branch. Canonical F(c,t) is NOT IMPLEMENTED. No Stage 2, no main merge.
The user reported that the Excel license expired, so **no manual user action or license purchase is requested**.

The new Windows package is in ChatGPT Library:
`/Pending_User_Execution/PC-BRANCH-EXCEL-VBA-INUKTITUT_Stage1_VBA_QA_v5_CMD_20261031.zip`
ZIP SHA-256: `2c743412aabaf39fd0020c850a9189ebdeadb3549fe57b8b8f36e07059d8e872`.
The original v4 VBA CMD package was moved to the project archive; a separately produced `Stage1_CMD_v4` package was left unchanged and has independent acceptance behavior.

## Finding and remedy
The original automated runner checked whether the summary cell read `PASS=35/35; FAIL=0`. That alone was too weak because individual rows could be missing, duplicated, or marked FAIL.

The v5 `NativeVba.ps1` now checks all 35 nonempty case names, that they are distinct, every status is PASS, and that totals match. It writes `vba_rows_validation.json` even when the row validation fails, and fails closed.

New `verify_native_results.py` inspects a future `results.zip` or `results/` folder, checks native receipt/status/exit code, 35 ordered case names (against the supplied QA source), row statuses and validation JSON, and never claims independent full compilation or authenticated execution provenance. A positive outcome is only `PASS_REPORTED_NATIVE_ROWS_COMPILE_UNVERIFIED`.

## Portable verification evidence
- Python Stage 1 VBA and workbook source audit: **32/32 PASS_STATIC_ONLY**.
- Malformed source/workbook negative tests: **4/4 rejected**.
- CMD/PowerShell source contract inspection: **16/16 PASS_SOURCE_CONTRACT_ONLY**.
- Native report auditor synthetic positive control: 1 accepted **as synthetic**; 5 deliberately malformed receipts rejected.
- ZIP CRC: 17/17 members; SHA-256 manifest: 16/16 files verified.
- Workbook unchanged: `f51271947a88f19afb8d690dfbb6e4105fba91511294ff7d0845136f53a0a7ca`.
- Prior arithmetic Excel-native QA: six cases × 128 long-division steps PASS **according to user console**, independent detailed JSON not supplied.

## Explicitly unverified
The v5 Windows `RUN.cmd`, PowerShell scripts, fault-injection behavior, VBA compile, and 35 native VBA tests **have not run in a Windows/Office environment**. Static parser checks do not establish these runtime outcomes. Inuktitut visual and linguistic acceptance remains pending.

No automation modifies Office licensing, Excel Trust Center settings, or macro security.
