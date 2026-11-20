# Stage 2 / Discovery 19 — bounded Appendix-A ASK stream (Logo+Ido)

Status: QA_CANDIDATE_ONLY. Base branch Logo+Ido at a9de9c5beb9dc241955517d23a4f3a8964551b7f. D18 has two authentic Native shard PASS logs and all eleven same-SHA regressions SUCCESS, but its dependent acceptance job was still queued when this QA branch was authored. D19 is NOT accepted; no Stage 2 completion, main, or merge is implied.

## Scope

Implement the next independent Appendix-A operation *after* sauceBowls and sauceOrder46: ASK(sauce, queriedId, seal), as a pure two-element stream reporter. Do not implement answer-at, rejection sampling, year selection, calendarDateSpaghetti, or a full calendar date. Leave Stage 1 and D18 untouched.

Public reporter: monster.stage02.ask :ctx :queriedId :seal.

Precondition: ctx.status = SAUCE_ONLY; ctx.sauceBowls is a six-element BI list; ctx.sauceOrder46 is a permutation of [1..6]; queriedId is an integer in [1,6] and belongs to sauceOrder46; seal is an integer in [0,99]. This bounded seal domain includes the eleven actual normative selector calls (seals 1,10,11,12,20,21,22,30,31,32,33). Invalid precondition returns [] without mutation; test guard checks are implementation boundaries rather than claims of a broader Appendix-A input domain.

Valid result [firstValue, step]:
- nextId is the element cyclically following queriedId in the *drop-46 latch* sauceOrder46, NOT an order inferred from post-stirs.
- firstValue = SAVE((B[queriedId] + seal + 181 + 179*B[nextId])² + seal).
- directionValue = SAVE((firstValue + seal + 194)² + 193*firstValue + 197*B[6]).
- step = +1 if directionValue mod 2 = 1, otherwise -1.
- SAVE(x)=1+((x-1) mod M), using the branch's exact BI semantics and frozen M.
- Return firstValue as exact BI in [1,M] and step as small integer in {-1,+1}. No floating-point, oracle calls, global mutation, side effects, or context rewriting.

## Independent evidence and boundary

Reference oracle: test-only nr.ask from test/normative_reference.logo. It independently obtains sauce from the two raw normative dates using nr.sauce; it does not take production bowls or latch as expected data. Production must never load test code.

QA Native test builds the production context once for foundation->tablets, calculates the independent normative sauce once, then evaluates all eleven selectors present in the normative reference:
(1,1), (1,10), (1,11), (1,12), (2,20), (2,21), (5,22), (3,30), (3,31), (4,32), (5,33).

For each valid selector: five checks — shape, exact firstValue differential, exact step differential, BI value range, repeat-call determinism. 11 cases / 55 assertions. Six malformed inputs — wrong status, bowls non-list, 5 bowls, non-permutation latch, queriedId=7, seal=100 — must return [] without error, adding 6 cases / 6 assertions. Total QA candidate: 17 cases / 61 checks. The independent test does NOT establish D19 acceptance by itself.

QA-only CI on branch qa/logo-ido-d19-ask: natural push, pinned headless UCBLogo 6.2.5 source a0215433f07384e4c42fe247525867f11e6f32f7, SHA equality, timeout 1800s, fail/unknown detection and exact 17/61 PASS markers. A queued or in_progress job is neither PASS nor a blocker. The QA branch is separate to avoid re-triggering the still-pending canonical D18 acceptance.

## Promotion and acceptance gate

First require the original canonical D18 run 44701301631 on a9de9c5 to finish SUCCESS, with its dependent aggregation job, genuine 6/40 marker and final Native PASS; eleven already-completed same-SHA regressions must remain valid. Then perform explicit code/contract review and add reverse-direction differential coverage, if indicated by the results, before a *new* canonical Logo+Ido branch-only commit and natural push. D19 acceptance will require completed Native logs, complete same-SHA regressions, source/HEAD/branch readback, and zero errors/timeouts. Do not claim Stage2 accepted, update LAST_COMPLETED_STAGE, merge into main, or publicize based on this QA work.
