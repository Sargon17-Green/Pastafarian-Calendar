# Stage27 Patch13 — Windows Native seal, 2026-10-30

Branch: PowerShell+Tagalog. Tested commit: 9d2a87dd253a6cfd911aecf2ddb6f149032c4371. Windows Native/verify run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41112165377 — completed/success on the matching head SHA; native job 124256823128 SUCCESS, verify job 124256823731 SUCCESS.

Actual Windows PowerShell 5.1 suite log:
- Stage01 73 PASS; Stage23 35 PASS; Stage24 47 PASS; Stage25 45 PASS; Stage26 39 PASS, with 4 intentional historical EXPECTED_RED, 24 accepted controls, 3 genuine precursor histories.
- Stage27 156 assertions PASS. Direct short-stream comparisons against independent iterative oracle: 56/56; rejecting cases: 20; four boundary historical mismatches repaired; three real 46-drop+12-stir predecessor histories.
- Combined Stage01+23+24+25+26+27 suite assertions 395 PASS. Stage25 full 4320-case positional successor regression remains green, while 3456 historical mismatches remain available. No log failure lines.
- Stage23 finalizer idempotency: two runs exit 0; ALREADY_FINALIZED True twice; pre/post metadata SHA256 identical F86DB1936DDC78038DDEB2322CE2634BF378246CC383FEF266BE7FC84A269EAE; RESULT=PASS.
- Evidence artifacts: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41112165377/artifacts/13003219267 (idempotency) and https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41112165377/artifacts/13002824782 (metadata).

Stage26 historic no-rejection function remains intact; Patch13 implements rejection only for 1<=N<=M=2^127-1. Wide-N stage is not claimed. No main merge. This seal changes stage metadata and regression gate compatibility, not Patch13 algorithm. Re-run verification on the seal commit SHA is required to confirm sealed metadata compatibility.
