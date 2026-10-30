# Excel-VBA + ᐃᓄᒃᑎᑐᑦ: Stage 1 license-free QA (2026-10-30)

## Verified evidence
- User-supplied `Native_QA_Console(7).log`: Excel 16.0 opened the structurally repaired v9 workbook; six native Q/R cases were reported PASS, with 128 long-division steps each and a Python integer oracle. This is a **PASS by user console log**. The independently inspectable `stage1_native_excel_qa.json` has not been supplied.
- The v9 workbook SHA-256 was `f51271947a88f19afb8d690dfbb6e4105fba91511294ff7d0845136f53a0a7ca`; it was not rewritten for this VBA QA work.
- Source `src/PastafarianExcel.bas`: `ExactCellString` now accepts a truly empty Excel cell only as missing text, allowing per-field validation errors 514–518; numeric/formula values still fail the text-precision guard 519.
- `qa/excel-vba-inuktitut/Stage1VbaQA.bas`: 29 distinct VBA host cases, including truly empty fields, numeric values, 1,024-digit year as text, Unicode names and intentional rejection of the unimplemented canonical converter.
- `qa/excel-vba-inuktitut/verify_stage1_vba_office_free.py`: runs using Python 3 and an extracted QA package containing the v9 workbook and two BAS files. On the audit package, it returned **PASS_STATIC_ONLY: 27 checks**; 18 independent decimal specification edge fixtures are included. The ZIP contained 15 worksheets, 49,084 cells, 47,002 formulas; no inverted OOXML column ranges.

## What is NOT verified
- **VBA compilation: NOT RUN**. VBA execution of 29 cases: **NOT RUN**. They cannot be turned into PASS by the Python static verifier.
- Independent native JSON results inspection: not yet done; the console log alone is insufficient for that.
- Inuktitut linguistic and visual signoff: **NOT RUN**.
- Canonical function F(c,t) is **NOT IMPLEMENTED** in this Stage 1 host (deliberate guard).

## Environment limitation
The user's Excel license has expired. Do not require the user to buy a license or to import/compile BAS modules manually. Preserve the separate native QA bundle in `Pending_User_Execution` only for a future licensed Excel automation environment; no action is currently requested.

## Scope
Only `Excel-VBA+ᐃᓄᒃᑎᑐᑦ`; no main merge, no Stage 2, no claim of canonical date conversion.
