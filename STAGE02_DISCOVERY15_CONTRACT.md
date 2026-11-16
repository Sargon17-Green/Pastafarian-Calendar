# Stage2 Discovery15 — exact visible drops 36–40 (Logo+Ido)
Status: IMPLEMENTED_NATIVE_PENDING (2026-11-16). D14 ACCEPTED_NATIVE at 0a3011e8d4f99c3848c703ae8521f8881889a1b6, first original fixed-SHA push run 43938841193/job 133550576798 completed SUCCESS (5 cases/21 checks and genuine native PASS), and seven same-SHA regression runs completed SUCCESS. LAST_COMPLETED_STAGE=1, entire Stage2 incomplete.

## Input/output and identity
Input: D14-valid context with status VISIBLE_THIRTYFIVE_ONLY, exactly 35 canonical BI visibleThirtyFive entries, 46 stone quintets, 7 hidden seeds and five workcounts. Wrong status, non-list prefix, or prefix length !=35 => return context exactly unchanged (including metrics and logs).
Valid output: visibleForty with 40 exact canonical BI entries in [1,M], retaining the first 35 unchanged. Set phase VISIBLE_FORTY_READY, mode STAGE_2_DISCOVERY_15, status VISIBLE_FORTY_ONLY; append exactly once metric stage02.visible.forty and log stage02.visible.forty.ready. Preserve raw/normalized days, five workcounts, stoneSeries, hiddenSeeds and visiblePrefix/visibleTen/visibleFifteen/visibleTwenty/visibleTwentyFive/visibleThirty/visibleThirtyFive. No Stage1 API, Stage2 complete, or final calendar changes.

## Independent exact Appendix-A oracle
For i=36..40, p1=V[i-1], p3=V[i-3], p7=V[i-7], stone quintet S[i], counts A/T/D/C/R; save(z)=1+((z-1) mod M) exact BigInteger.
x0=save(S1*A+S2*T+S3*D+S4*C+S5*R+p1+3*p3+5*p7+i).
Apply exactly 11 quadratic rounds xg=save(xprev^2+ag*xprev+bg*p1+cg*p3+dg*p7+S[kg]) using immutable ordered coefficients in STAGE02_DISCOVERY08_CONTRACT.md, saving after each round. Production may reuse existing D8 production-only prior/initial/grind, NEVER nr.*. Test-only normative oracle independently computes ALL 1..40 from raw dates via nr.work.counts, nr.stones, nr.hidden.build and nr.visible.one; expected values must not derive from production prefixes.

## Bounded QA and acceptance
One valid foundation/tablets case: five exact value comparisons 36..40, eleven independent state-preservation/transition assertions, one repeated-call determinism =17. Four invalid cases: FAILED_VALIDATION, HIDDEN_SEEDS_ONLY, a 34-element list in visibleThirtyFive, and a non-list visibleThirtyFive; exact object identity without logs/metrics changes. Total 5 cases / 21 checks.
Only a completed original push of the D15 candidate SHA with real log markers STAGE_2_DISCOVERY_15_CASES_PASIS 5, STAGE_2_DISCOVERY_15_CHECKS_PASIS 21, STAGE_2_DISCOVERY_15_PASIS and NATIVE_STAGE_2_DISCOVERY_15_VERIFICATION=PASS may accept D15. No error markers/unknown procedures/timeouts. UCBLogo 6.2.5 pinned at a0215433f07384e4c42fe247525867f11e6f32f7, D15 test <=1200 seconds and job <=25 minutes. Same-SHA D14, D13, D12, D11, D10, D1–D9, Stage1 native and Names Lock must all complete SUCCESS; queued/in_progress are neither PASS nor blocker. No manual duplicate, no main/merge. After acceptance, plan bounded 41..45 D16.
