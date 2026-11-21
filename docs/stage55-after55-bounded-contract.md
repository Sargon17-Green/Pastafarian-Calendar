# Stage55 AFTER54 → AFTER55: bounded MATLAB/Python differential
PROJECT_ID: PC-BRANCH-MATLAB-POLSKI. Authorized branch: MATLAB+Polski.
Stage55 OPEN; LAST_COMPLETED_STAGE=54; no merge/main/release.

## Certified predecessor
- Parent branch commit: `7e7644fbd97660b7bc139580f469090aecb6d25d`.
- Native run 44895775469 job 136820992282 completed/success; Names Lock run 44895775329 job 136820991990 completed/success on same SHA.
- Original artifact 14704805568 (15479 bytes): SHA256 `446b12eb15775257aceda67f90e4cbbe434cadeda477d39f79f4e0864863e411`, ZIP CRC 7/7.
- AFTER54 checkpoint SHA256 `643ce151a2ab76998f4032911c5eb290d6529bc253025939f0366a6dd9cb1ae6` (AFTER53 predecessor `6392a2272478b2084f359ad1d7b7b5703f13171d462d522acc222f6a5b22858d`).
- Original archive and independent certification saved to /QA_Artifacts/PC-BRANCH-MATLAB-POLSKI.

## Independent local AFTER55 preflight (not Native)
- Bounded 22/22 exhaustive tiny words; 29/29 positive lexical child blocks and exact sum equals parent count.
- Exact rank interval selects symbol 5; opens no new month (openedUpTo=28), closedUpTo=0.
- Projection STEPS=55 REMAINING=4189; five-field row:
  `STAGE55_FIFTY_FIFTH_ROW POSITION=55 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=55 MONTH_INDEX=24 MONTH_DAY=3`.
- Independent preflight Python SHA256 `cadacc112df378ed9296efd586eb5b9d3ed6dc9c122b7cdca63d07c5710c2637`;
  log `a22da003efe730046a4af41e68ac9e436a78824aad183f83a8cfa993b9fc0778`;
  JSON `d30387474f44f6adeea8719894218e5694a694a3faef9ee5ba24b0d2280ccdc4`.
- Parent count hash f4247e38fd6b91c521a56d5792492c7a483e5bd8ba9256640bcfae8783cf673c;
  selected child count hash 6de8276ea8fc97c149854ebfaeda53fc9dc0914072525c12577a12874e023843.

## New-SHA acceptance conditions
1. Download original AFTER54 artifact from run44895775469; reject any mismatch to checkpoint SHA256 pin.
2. MATLAB R2026a: STEPS55 REMAINING4189 LETTER5 REJECTED2; require PATCH_25_OCCURRENCE_COUNT trace.
3. Python independent insertion-count witness: SMALL22 BLOCKS29, parent partition and exact selected child rank interval.
4. Strict byte-identical 5-field row from Native and Python; reject invalid positions 0 and 56.
5. Completed exact-SHA CI and Names Lock; original AFTER55 ZIP SHA/CRC7/7 and checkpoint digest verified and archived.
Queued/in_progress never PASS; do not dispatch duplicate work.
Whole-year canonical oracle and cross-engine soak remain unverified. Stage55 final acceptance remains OPEN.

## AFTER55 CI wiring correction (2026-11-21)
- Initial push run [44904948935](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44904948935), job 136848417132, completed/failure on `f24a3094e3f3ecfc5e6ef6cb1795dda981993ec5` at pinned predecessor verification; the download of certified AFTER54 artifact 14704805568 succeeded and its ZIP digest matched `446b12eb15775257aceda67f90e4cbbe434cadeda477d39f79f4e0864863e411`.
- Root cause: the new AFTER55 workflow mistakenly verified `STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_53.json` against the certified AFTER54 digest `643ce151a2ab76998f4032911c5eb290d6529bc253025939f0366a6dd9cb1ae6`; predecessor run 44895775469 independently confirms its output is `STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_54.json` with that digest. MATLAB and workflow output paths were off by one as well.
- Fix: consume `AFTER_54.json` and produce `AFTER_55.json` in both MATLAB and the workflow, preserving the certified checkpoint SHA, independent Python algorithm, and 5-field oracle. The failed run never reached MATLAB/native or Python differential and does not count as an expected-red algorithm failure.
- Acceptance remains CONDITIONAL: only a new completed exact-SHA workflow with Native/Python logs, original artifact SHA/CRC, negative cases and strict 5-field equality can certify AFTER55; full-year oracle/soak remain open.
