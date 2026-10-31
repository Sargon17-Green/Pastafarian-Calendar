# Excel-VBA + ᐃᓄᒃᑎᑐᑦ — Stage 1 evidence QA v7 (2026-10-31)

## Artifact and scope
Full portable runner ZIP in ChatGPT Library:
`/Pending_User_Execution/PC-BRANCH-EXCEL-VBA-INUKTITUT_Stage1_VBA_QA_v7_CMD_20261031.zip`

ZIP SHA-256: `51980e57626828343deb9e15bfd1f12602859377b23d40377364d406be5d36cb`. All 17 ZIP entries passed CRC; all 16 members in `SHA256SUMS_v7.txt` passed SHA-256 verification.

This replaces **only** the previously staged `Stage1_VBA_QA_v6_CMD`. A separate `Stage1_CMD_v4` artifact and its independent resume/acceptance contract remain unchanged.

## Proven issues fixed without Excel
1. **Missing independent receipt consistency:** the old evidence verifier ignored `receipt.json`, allowing a success claim even if the CMD/finalizer receipt was missing, stale, or attributed to the wrong package. The verifier now checks project, package version, status, exit code, and declared compile limitations against `native_receipt.json` and `status.txt`.
2. **Ambiguous ZIP layouts:** the verifier previously accepted both `status.txt` and `results/status.txt` silently, prioritizing the former. The new verifier fails closed on any duplicate logical evidence item across the two layouts.
3. **Identical duplicate raw ZIP names:** constructing a dictionary directly from ZIP members silently discarded earlier repeated filenames. The verifier now enumerates entries and rejects duplicate raw names before normalizing paths.
4. **Early CMD fallback receipt ordering:** if `status.txt` remained `BOOTSTRAP_STARTED` after a child failure, CMD changed it to `BOOTSTRAP_FAILED_BEFORE_STATUS` *after* writing `receipt.json`. The order is now corrected so receipt and final status agree.

## Checks executed
- Office-free workbook/VBA source audit: **32/32 PASS_STATIC_ONLY**.
- VBA source/workbook mutation fixtures: **4/4 rejected**.
- Windows launcher source contracts: **25/25 PASS_SOURCE_CONTRACT_ONLY** (not actual CMD execution).
- SHA manifest alteration fixtures: **3/3 rejected**.
- Synthetic result artifact controls: **2 accepted** (standard and `./` tar-style), **12/12 malformed cases rejected** (including missing or wrong enclosing receipt, duplicate raw archive entry, and conflicting `results/` prefix).
- XLSX v9 unmodified, SHA-256 `f51271947a88f19afb8d690dfbb6e4105fba91511294ff7d0845136f53a0a7ca`; both BAS modules byte-identical to v6.

## Explicitly not proven
The v7 package has **not** been executed using Windows CMD/PowerShell, Excel Desktop, or VBA. VBA compilation and the 35 native host cases remain **NOT RUN**. The user-reported arithmetic Excel 6/6 PASS has console-log provenance but no supplied detailed native JSON for independent review. The Excel license reported expired; no purchase, manual import, or Trust Center changes are requested.

Stage 1 is not complete. Canonical F(c,t) is NOT IMPLEMENTED; Inuktitut visual/linguistic verification remains open. No Stage 2, no merge to main. A separately produced `Stage1_CMD_v4` package is outside this v7 runner's source-hash claim.
