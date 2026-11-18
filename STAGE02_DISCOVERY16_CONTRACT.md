# Stage2 Discovery16 — exact visible drops 41–45 (Logo+Ido)
Status: ACCEPTED_NATIVE (2026-11-18); D15 ACCEPTED_NATIVE, SHA e84607fa9e4dfe19ad08f5956f3b0704956ef90c, original push 43960869831/job 133627582019 completed SUCCESS with native 5 cases/21 checks/PASS and eight same-SHA completed SUCCESS regressions. LAST_COMPLETED_STAGE=1. Stage2 remains incomplete.

## Input/output
Input D15-valid context: status VISIBLE_FORTY_ONLY, exactly 40 canonical exact-BI visibleForty entries, 46 stone quintets, seven hidden seeds, five workcounts. Wrong status, non-list or wrong-length visibleForty yields the exact original context, including logs/metrics. Valid output visibleFortyFive has 45 canonical BI entries in [1,M], first 40 unchanged. Phase VISIBLE_FORTYFIVE_READY; mode STAGE_2_DISCOVERY_16; status VISIBLE_FORTYFIVE_ONLY. Append once metric stage02.visible.fortyfive and log stage02.visible.fortyfive.ready. Preserve dates, normalized dates, workcounts, stones, hidden and all earlier prefixes. No Stage1/calendar API changes or claims of Stage2 completion.

## Independent oracle
For i=41..45, p1=V[i-1],p3=V[i-3],p7=V[i-7], stone quintet S[i], workcounts A/T/D/C/R, save(z)=1+((z-1) mod M) exact BI.
x0=save(S1*A+S2*T+S3*D+S4*C+S5*R+p1+3*p3+5*p7+i).
Eleven rounds xg=save(xprev²+ag*xprev+bg*p1+cg*p3+dg*p7+S[kg]) with the unchanged coefficient vectors in STAGE02_DISCOVERY08_CONTRACT.md. Production uses existing D8 prior/initial/grind only; never nr.*. Test-only independent normative_reference builds ALL 1..45 from raw dates via nr.work.counts, nr.stones, nr.hidden.build and nr.visible.one; expected output is never derived from production prefixes.

## Bounded QA and acceptance
One valid foundation/tablets case = five exact values 41..45, eleven state/transition/identity/metric/log preservation checks, one determinism check (17). Four invalid exact-identity cases: FAILED_VALIDATION, HIDDEN_SEEDS_ONLY, 39-element visibleForty and non-list visibleForty. Total 5 cases/21 checks. Accept D16 only on completed original push of candidate SHA and genuine log markers STAGE_2_DISCOVERY_16_CASES_PASIS 5, STAGE_2_DISCOVERY_16_CHECKS_PASIS 21, STAGE_2_DISCOVERY_16_PASIS, NATIVE_STAGE_2_DISCOVERY_16_VERIFICATION=PASS, without fail/unknown/timeout. UCBLogo 6.2.5 headless pinned source a0215433f07384e4c42fe247525867f11e6f32f7, test <=1200s, job <=25min. All same-SHA D15–D10, D1–D9, Stage1 and Names must complete SUCCESS. No manual duplicate CI, main/merge.

## Acceptance evidence — 2026-11-18
Original push SHA 239ee1b5f8bcc51f108e42b4c004021ae969b4af, run 44364739926/job 135015353772 completed SUCCESS attempt 1: STAGE_2_DISCOVERY_16_CASES_PASIS 5, STAGE_2_DISCOVERY_16_CHECKS_PASIS 21, STAGE_2_DISCOVERY_16_PASIS, NATIVE_STAGE_2_DISCOVERY_16_VERIFICATION=PASS. Same-SHA regressions D15 44364739685, D14 44364739840, D13 44364739911, D12 44364739711, D11 44364739682, D10 44364740227, D1–D9 44364739842, Stage1 44364740179, Names 44364739883 all completed SUCCESS attempt 1. Stage2 overall incomplete.
