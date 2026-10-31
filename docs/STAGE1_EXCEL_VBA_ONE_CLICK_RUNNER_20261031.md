# Excel-VBA + ᐃᓄᒃᑎᑐᑦ: Stage 1 one-click Windows QA (2026-10-31)

An unattended Windows QA package is staged in the user's ChatGPT Library:

`/Pending_User_Execution/PC-BRANCH-EXCEL-VBA-INUKTITUT_Stage1_VBA_QA_v4_CMD_20261031.zip`

Package SHA-256: `45ced23512a36a772dcc92b93a687ed19a3ac72e253edbe2fd8ce06c2ad8e983`.

## Architecture

- `RUN.cmd` writes `results/status.txt`, `receipt.txt` and provisional `exit_code.txt` **before** launching any child PowerShell, then attempts `results.zip` with PowerShell and Windows tar fallback, including early startup failures.
- `Bootstrap.ps1` verifies the package's SHA256SUMS before executing code, uses installed Python 3 or tries official `winget install --id Python.Python.3.13`, runs the license-free auditor and its negative controls, and attempts isolated Excel COM.
- `NativeVba.ps1` creates a TEMPORARY `.xlsm`, imports **only** `PastafarianExcel.bas` and `Stage1VbaQA.bas` via VBProject, attempts VBE Compile control ID 578 where available, and invokes a non-modal 35-case VBA QA macro. The wrapper has a 180-second timeout.
- VBA project trust is **never** enabled programmatically and macro security is not overridden. Missing Excel, an unavailable license, or denied VBA project access produce diagnostic status rather than a false PASS. VBE command invocation alone does **not** prove compilation; full independent compile remains unverified.
- `Finalize.ps1` emits `receipt.json` and attempts `results.zip` regardless of child exit code.

## Evidence and boundaries

Portable checks passed: **32/32 PASS_STATIC_ONLY** VBA source/OOXML tests; **4/4** deliberate corruptions rejected; **14/14 PASS_SOURCE_CONTRACT_ONLY** CMD/PowerShell launcher inspections. They do **not** verify that CMD, Windows PowerShell, Excel, or VBA actually run successfully.

Existing v9 workbook remains byte-identical, SHA-256 `f51271947a88f19afb8d690dfbb6e4105fba91511294ff7d0845136f53a0a7ca`. The earlier Excel-native long-division report is PASS according to the user's console for six Q/R cases; detailed JSON has not been independently reviewed. **VBA compilation: NOT RUN. 35 VBA test cases: NOT RUN.** Inuktitut language/visual signoff: not completed. Canonical converter F(c,t): not implemented.

The user's Excel license has expired. Do **not** request a purchase or any manual import/compile step. This package is for a future authorized, licensed Windows environment; no action is currently requested. No Stage 2 and no merge to main.
