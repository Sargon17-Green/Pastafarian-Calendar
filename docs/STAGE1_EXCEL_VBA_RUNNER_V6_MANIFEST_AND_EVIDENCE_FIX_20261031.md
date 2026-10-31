# Stage 1 — Excel-VBA Inuktitut v6 Windows QA runner (2026-10-31)

## Reproducible artifact
ChatGPT Library: `/Pending_User_Execution/PC-BRANCH-EXCEL-VBA-INUKTITUT_Stage1_VBA_QA_v6_CMD_20261031.zip`

ZIP SHA-256: `1291f6828343239f38c992896c3ccc7a71167b4df0a1177227ae24aad9aaef18`

The independently produced `Stage1_CMD_v4_20261031.zip` remains in the same folder, unchanged, with separate source-SHA gating and resume instructions. This v6 package supersedes **only** the parallel VBA_QA_v5_CMD package; no existing checkpoint or test result was overwritten.

## Proven errors corrected (v5 to v6)

1. **Fatal wrong manifest filename.** `Bootstrap.ps1` attempted to open `SHA256SUMS_v4.txt` while the shipped v5 archive contained `SHA256SUMS_v5.txt`. It would fail the manifest stage even with all program files intact. v6 refers to the actually packaged `SHA256SUMS_v6.txt`.
2. **tar.exe archive-path compatibility.** If the PowerShell ZIP finalizer is unavailable and Windows tar writes `./status.txt`, the old independent Python evidence checker rejected otherwise valid files. The verifier now normalizes only leading `./` and refuses path traversal, absolute paths, and duplicate canonical names.
3. **Early JSON receipt.** `RUN.cmd` now writes a provisional JSON receipt **before** launching PowerShell and a fallback receipt after the child; `Finalize.ps1` still replaces it with the detailed receipt when available. This is source-audited, not yet runtime-tested.

## Tests performed (not Windows-native)

- Workbook v9 immutable SHA-256: `f51271947a88f19afb8d690dfbb6e4105fba91511294ff7d0845136f53a0a7ca`.
- ZIP integrity: **17/17** entries CRC; **16/16** packaged member SHA-256 hashes.
- Existing Office-free VBA/XLSX checks: **32/32 PASS_STATIC_ONLY**; existing deliberate corruption controls: **4/4 rejected**.
- Windows CMD/PowerShell **source contracts: 21/21 PASS_SOURCE_CONTRACT_ONLY**, including manifest reference and every hashed file. Positive unmodified manifest fixture accepted; **3/3 mutated manifest fixtures rejected** (wrong path, corrupted BAS, corrupted hash).
- Synthetic native evidence verifier: original positive fixture and `./` tar-style positive fixture accepted; **7/7** malformed synthetic evidence fixtures rejected (including aliases and path traversal).
- No Windows CMD, PowerShell, licensed Excel, VBA compile, or 35/35 VBA tests executed in the model environment.

The user has reported an expired Excel license. Do not request buying software, changing macro security or manually importing VBA. A verified VBA compile remains a separate acceptance gate. Prior Excel arithmetic 6/6 PASS is grounded only in the user's Windows console log (detailed JSON not supplied). Inuktitut linguistic/visual signoff and canonical date converter F(c,t) are NOT COMPLETE. Do not advance to Stage 2 or merge to main.
