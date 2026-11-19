# Stage 2 Discovery18 — Appendix-A final aggregation (Logo+Ido)

Status: NATIVE_FIX_IMPLEMENTED_PENDING (2026-11-19). D17 ACCEPTED_NATIVE on 05b49e0eb730724eb3fdf66993a6314f90783a0a; original push run 44373979219/job 135048049707 completed SUCCESS with five cases, 17 checks and the genuine NATIVE_STAGE_2_DISCOVERY_17_VERIFICATION=PASS marker. Ten same-SHA regressions completed SUCCESS. Stage2 remains incomplete; LAST_COMPLETED_STAGE=1.

## Scope and boundary

This is the first post-visible-prefix aggregation step. It consumes the D17 context with status VISIBLE_FORTYSIX_ONLY and produces only the Appendix-A final six-bowl state plus the order latch from visible drop 46. It does not calculate the query stream, select a canonical index, unrank names, produce a final calendar quintet, or expose a finished calendar date. Stage1 and calendarDateSpaghetti remain unchanged. No main/merge.

## Input and output contract

Input must have:
- status VISIBLE_FORTYSIX_ONLY;
- visibleFortySix as a list of exactly 46 exact BI values;
- stoneSeries as a list of exactly 46 five-element BI stone quintets;
- the five workcounts: actionCount, targetCount, distanceCount, connectionCount, directionCount.

If status is wrong, either required list is not a list, or either list has a length other than 46, return the original context exactly unchanged, including all fields, metrics and logs.

For valid input, produce:
- sauceBowls: exactly six canonical exact BI values in [1,M], the final bowl state after all 46 drops and 12 post-stirs;
- sauceOrder46: the six-element permutation selected by visible drop 46, retained as the order latch.

Set phase SAUCE_READY, mode STAGE_2_DISCOVERY_18, status SAUCE_ONLY. Append exactly one metric stage02.sauce and one log stage02.sauce.ready. Preserve both raw and normalized dates, all workcounts, stoneSeries, hiddenSeeds, visibleFortySix, and every earlier visible-prefix field.

All arithmetic over calendar values is exact BI. Small loop indices, permutation ranks (0..719), and coefficients are bounded Logo integers. No floating point, global mutable state, test oracle calls, or cross-language artifacts are allowed in production.

## Normative Appendix-A algorithm

SAVE(x) = 1 + ((x - 1) mod M), with exact Euclidean remainder and M from the frozen normative reference.

Initial bowls, for j=1..6, with prime vector P=[17,19,23,29,31,37] and workcounts A,T,D,C,R:
- q = A + j*T + D + C + R + P[j]^2
- bowl[j] = SAVE(q^2 + j)

For each drop i=1..46:
1. Let v=visibleFortySix[i], S=stoneSeries[i], and π be the lexicographic permutation of [1,2,3,4,5,6] with zero-based rank ((v-1) mod 720).
2. From the old bowl snapshot Q, compute pours:
   - P1=SAVE(v^2 + S[1]*Q[π[1]] + 3*i)
   - P2=SAVE(v^2 + S[2]*Q[π[2]] + 5*i)
   - P3=SAVE(v^2 + S[3]*Q[π[3]] + 7*i)
   - P4=P5=P6=0.
3. For positions r=1..6, let id=π[r], prev=π[wrap(r-1)], next=π[wrap(r+1)], and kind=[1,2,3,4,5,1][r]. All reads use the same old Q. Compute:
   - x=Q[id] + 2*Q[prev] + 3*Q[next] + P[r] + v + S[kind]
   - Qnew[id]=SAVE(x^2 + 5*Q[prev]*Q[next] + i*r)
4. Replace Q only after all six positions have been computed. Retain π as sauceOrder46 only when i=46.

Then run exactly 12 post-stirs, j=1..12. For each stir:
- saved=SAVE(sum(Q) + 149*j)
- π is the lexicographic permutation of [1..6] with zero-based rank ((saved-1) mod 720).
- From the old Q snapshot, for each position r=1..6, id=π[r], prev=π[wrap(r-1)], next=π[wrap(r+1)]:
  - x=Q[id] + 3*Q[prev] + 5*Q[next] + saved + j + r^2
  - Qnew[id]=SAVE(x^2 + 7*Q[prev]*Q[next])
- Replace Q only after all six positions have been computed.

The final Q is sauceBowls. sauceOrder46 is not the final post-stir permutation; it is the separate latch from the 46th visible drop.

## Independent oracle and bounded QA

The test-only oracle is nr.sauce(calculationDay,targetDay), which independently rebuilds workcounts, stones, hidden seeds, all 46 visible drops, initial bowls, all 46 drop transitions, the drop-46 latch, and all 12 post-stirs from the two raw dates. Expected values must never be derived from production sauceBowls, production sauceOrder46, or production prefixes.

Two valid differential cases:
1. foundation_tablets (directionCount=1)
2. tablets_foundation (directionCount=3)

Each valid case has 18 checks: actual and oracle bowl shapes; six exact bowl comparisons; exact order46 comparison; permutation validity; raw/normalized dates and workcounts preservation; all stone/hidden/visible-prefix preservation; phase, mode, status; exact metric/log sequences; repeated-call determinism.

Four invalid cases each require exact context identity: wrong status, non-list visibleFortySix, 45 visible values, and 45 stone quintets. Total: 6 cases / 40 checks.

Acceptance requires the completed original push on this exact SHA with genuine markers:
- STAGE_2_DISCOVERY_18_CASES_PASIS 6
- STAGE_2_DISCOVERY_18_CHECKS_PASIS 40
- STAGE_2_DISCOVERY_18_PASIS
- NATIVE_STAGE_2_DISCOVERY_18_VERIFICATION=PASS
No fail/unknown/timeout marker may appear. Native uses pinned headless UCBLogo 6.2.5 source a0215433f07384e4c42fe247525867f11e6f32f7, test timeout <=1200s and job timeout <=25min.

All eleven same-SHA regressions must complete SUCCESS: D17, D16, D15, D14, D13, D12, D11, D10, D1-D9, Stage1 Native, and Canonical Names Lock. Queued/in_progress is neither PASS nor blocker. No duplicate manual dispatch, no main/merge. D18 acceptance does not complete Stage2.

## Evidence-based D18 native correction — 2026-11-19

Original push on `010d009956f094c0bb7152556bb1aee879dd46bb`, run 44393624959/job 135117568246 attempt 1, completed FAILURE. After `STAGE_2_DISCOVERY_18_CASE_BEGIN foundation_tablets` the genuine UCBLogo log reported `item doesn't like 2.51666666666667 as input in monster.stage02.sauce.permutation.zero` at `item (:q + 1) :items`. All eleven same-SHA regressions D17-D10, D1-D9, Stage1, Names Lock completed SUCCESS; this does not accept D18.

Root cause: production factoradic unranking used `quotient :rank0 :block` as though it returned integer division, but it returned a fractional ratio. For nonnegative rank and positive block, `int (quotient :rank0 :block)` yields the needed factoradic digit (0..5), while `remainder` continues to provide the remainder. The independent normative oracle uses repeated subtraction (`nr.small.divmod`), and no oracle code is used in production.

The native test now checks all 720 zero-based permutation ranks against the independently implemented normative unranking, before costly sauce cases. New required marker: `STAGE_2_DISCOVERY_18_PERMUTATION_CHECKS_PASIS 720`. This adds 720 permutation checks without changing the six sauce cases or their 40 assertions. Accept only if this marker, the original 6/40 markers, final Native marker, lack of failure/timeout/unknown, and all eleven new same-SHA regressions are verified on the new original push. This patch is NOT a Native PASS.
