# Stage2 / DISCOVERY08: first-five visible drops, Logo + Ido

Status: IMPLEMENTED_NATIVE_PENDING. Discovery07 accepted on implementation SHA 3e56c8ab5d800a9e9b8d8652d664eb295b9f0a97.
LAST_COMPLETED_STAGE=1. This is a bounded Stage2 increment, not full Stage2 acceptance.

## Contract: I/O and mutations
Input: fresh `monster.stage02.hidden :ctx` context with status=HIDDEN_SEEDS_ONLY, 46 stone quintets, 7 hidden seeds, and five intermediate workcounts.
For any other status (including FAILED_VALIDATION or STONE_SERIES_ONLY), output EXACT unchanged context without metrics/log effects.
Output on valid input: field visiblePrefix, EXACTLY 5 canonical BI values in [1,M], phase=VISIBLE_PREFIX_READY, mode=STAGE_2_DISCOVERY_08, status=VISIBLE_PREFIX_ONLY; exactly one new metric `stage02.visible` and one log `stage02.visible.prefix.ready`.
Preserve calculationDay, targetDay, both normalized days, all workcounts, full stoneSeries, full hiddenSeeds. No global state, no Stage1 API modification, no full 46-drop/final calendar output.

## Independent exact Appendix-A algorithm
For each i=1..5 with stone S[i] and prior visible prefix V:
prior(i,b) = V[i-b] when i-b>=1, otherwise hiddenSeeds[1-(i-b)].
p1=prior(i,1), p3=prior(i,3), p7=prior(i,7).
save(z)=1+((z-1) mod M), exact nonnegative BI remainder.
A,T,D,C,R = actionCount,targetCount,distanceCount,connectionCount,directionCount.
x0=save(S[i][1]*A + S[i][2]*T + S[i][3]*D + S[i][4]*C + S[i][5]*R + p1 + 3*p3 + 5*p7 + i).
For g=1..11 with tuple [ag,bg,cg,dg,kg], set:
xg=save(x(g-1)^2 + ag*x(g-1) + bg*p1 + cg*p3 + dg*p7 + S[i][kg]).
Tuples in order: [3,5,7,11,1], [5,7,11,13,2], [7,11,13,17,3], [11,13,17,19,4], [13,17,19,23,5], [17,19,23,29,1], [19,23,29,31,2], [23,29,31,37,3], [29,31,37,41,4], [31,37,41,43,5], [37,41,43,47,1].
visiblePrefix[i]=x11. Normalize AFTER EACH grind, not only at end.

## QA and independent oracle
No production call to any test-only `nr.*` oracle. Expected prefix uses only `nr.visible.one` from test/normative_reference.logo with `nr.work.counts`, `nr.stones`, `nr.hidden.build`. Different algorithm/procedures from production.
2 valid contexts: (zero, one) and (foundation, tablets); each has 5 expected-value comparisons, 10 preservation/transition assertions, 1 repeated-call determinism = 16.
2 invalid contexts: FAILED_VALIDATION and STONE_SERIES_ONLY; each must be unchanged = 2.
Total 4 cases / 34 assertions.
Required native test markers: STAGE_2_DISCOVERY_08_CASES_PASIS 4, STAGE_2_DISCOVERY_08_CHECKS_PASIS 34, STAGE_2_DISCOVERY_08_PASIS, NATIVE_STAGE_2_DISCOVERY_08_VERIFICATION=PASS.
Time bound: D8 test <=420s; total job <=20 minutes, pinned UCBLogo 6.2.5; no unbounded attempts.
Acceptance: completed SUCCESS Native Stage2 with exact real markers and D1–D7 regressions, plus Stage1 Native and Canonical Names on same implementation SHA. queued/in_progress != PASS. No reruns of prior passing SHA, no main/merge.
After acceptance, derive next bounded visible extension toward 46, guided by real runtime evidence.
