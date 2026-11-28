# Stage09 PATCH04 — Stone Snapshot
PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
Branch: Object-Pascal+Português
Parent (Stage08 accepted seeded RED only): b2d1cc1272902471ef6a78c037cf46c37eb24b2a
User authorization: 2026-11-28, Stage09 corrective patch and verification only; no Stage10 or main merge.

Contract: no date input. 46 rows x 5 exact integers. Row 1 = (17,29,43,71,101); row i uses only immutable row i-1. For j=1..5, raw = old[j]^2 + c[j]*old[(j mod 5)+1] + (i if j=1 else old[j-1]), c=(3,5,7,11,13). SAVE(x)=1+((x-1) mod (2^127-1)); every output is in [1,2^127-1]. Row 2 = (378,1073,2375,6195,10493).
Production writes directly into a distinct result row and reads only the prior row; no production calls to seeded legacy. The exact sequential update body from Stage08 is isolated in a test-only unit, with function name changed. No BigInt modification, no foreign implementation or fixture copied.
Existing independent Stage08 JS and Python oracles unchanged. The Python verifier independently checks JS against exact integer arithmetic, then checks each isolated legacy cell (224 RED, 6 MATCH). Production TSV must match normative TSV byte-for-byte, all 230 cells, exit 0; isolated probe must exit 1; both stderr empty; incomplete/incorrect output, timeout or compile error fails. Runner records source/tree, compiler and interpreter versions, logs, outputs, exit codes, checksums. Native workflow at the historical stage08 path is repurposed for Stage09 to avoid duplicate discovery CI. Original Stage08 runner/probe are historical and should be used on the accepted Stage08 SHA, not on the corrected HEAD.
Acceptance requires exact new source SHA, completed Stage09 job/log/artifact, independent artifact comparison and ZIP integrity/UTF-8/digest verification, Stage01/02/03/05/07 and Names Lock regressions. No claim of Native PASS until observed. Stage09 not accepted; Stage10 prohibited.
