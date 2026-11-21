# Stage 2 / Discovery 20 — bounded ANSWER-AT stream indexing (Logo+Ido)

Status: CANONICAL_NATIVE_ACCEPTED_ON_07f67dad3fde1d1a5cc6178d5c5536311638e866. Originally designed on QA branch `qa/logo-ido-d20-answer-at` forked from accepted D19 SHA `4002280506a93999e64159155f2e9f8b89ae4c23`; the resulting implementation was fast-forwarded to non-protected `Logo+Ido`. This acceptance does not advance LAST_COMPLETED_STAGE, merge anything, or imply completed Stage 2.

## Prerequisite and scope

D19 ASK on the canonical source SHA is accepted by original push run 44800092723: completed forward job 136509674985 (17 cases / 61 checks), reverse job 136509674613 (17 / 62), and dependent acceptance job 136518079924 (34 / 123 and final Native PASS). The twelve additional same-SHA workflows are completed SUCCESS with their relevant Native markers; all three D19 production/test/reference blob SHAs match the successful QA source. The D19 acceptance SHA was `4002280506a93999e64159155f2e9f8b89ae4c23`; the subsequently accepted D20 canonical implementation SHA is `07f67dad3fde1d1a5cc6178d5c5536311638e866`.

Implement *only* the next Appendix-A primitive: get the k-th value of a previously constructed two-element ASK stream. No rejection sampling, choose.short, choose.wide, unranking, year discovery, calendarDateSpaghetti, Stage 1 changes, main, or merge.

Proposed production reporter: `monster.stage02.answer.at :stream :k`.

## Exact bounded input and output contract

A valid `stream` is a list of exactly two entries `[firstValue step]` returned by accepted D19 ASK, or a synthetic equivalent: `firstValue` is a canonical exact BI integer in [1,M]; `step` is exactly the small integer -1 or +1. The index `k` is a small exact Logo integer in [0,31]. M is the frozen Appendix-A modulus used by the current branch's exact-BI functions, strictly greater than 31.

For valid inputs, return one canonical exact BI value:
`answer(k) = 1 + EuclideanMod(firstValue - 1 + step*k, M)`.
Thus the 0-based index yields firstValue at k=0. In particular the result is always within [1,M], and negative steps wrap correctly at 1. Never convert a BI value to a floating-point Logo number or make the modulus implicit in native-number arithmetic.

For the listed malformed inputs return `[]` without error, global mutation, context mutation, or test-code calls. The input boundary does not promise arbitrary corrupted BI-memory representations can be introspected; the exact BI type must come from the branch's canonical BI library.

## Independent oracle and fixed QA matrix

The D20 expected-value oracle MUST NOT call `nr.answer.at` or the new production reporter, and MUST NOT reuse their expression. Instead implement a test-only **bounded iterative walker**: begin at the independently constructed D19 `nr.ask` stream's first value; for each of k iterations, if step=+1 increment by one unless at M, in which case wrap to 1; if step=-1 decrement by one unless at 1, in which case wrap to M. All values stay exact BI. The walker performs at most 31 steps. No production stream or sauce is allowed to serve as the oracle's expected answer. Source/reference code is from this branch only, not a copied fixture from another implementation branch.

For each direction (foundation->tablets and tablets->foundation), construct the expensive production D18 sauce context ONCE and the independent raw-date `nr.sauce` ONCE. For each of the eleven frozen normative ASK selector pairs
`(1,1), (1,10), (1,11), (1,12), (2,20), (2,21), (5,22), (3,30), (3,31), (4,32), (5,33)`
test k in `{0,1,2,31}`: 44 valid cases, four assertions each (BI shape, exact iterative differential, range [1,M], repeated-call determinism) = 176 assertions. Production stream comes from `monster.stage02.ask`; oracle stream comes solely from `nr.ask` using independently generated sauce. Verify production vs independent stream equality as part of the preflight D19 source lock; do not silently accept differences.

Six direct synthetic wrap-boundary cases use three assertions each (shape, exact result, range):
- [1,+1] k=0 => 1
- [M,+1] k=1 => 1
- [1,-1] k=1 => M
- [M,-1] k=1 => M-1
- [2,-1] k=31 => M-29
- [M-1,+1] k=31 => 30

Ten rejected cases each assert exact `[]`: stream non-list; stream length 1; stream length 3; firstValue=0 BI; firstValue=M+1 BI; step=0; step=2; k=-1; k=32; fractional k=0.5. Guard tests do not define unsupported arbitrary BI-structure detection.

**Target for each direction:** 44+6+10=60 cases; 176+18+10=204 counted assertions. The reverse direction additionally verifies the workcount's direction field against independently reconstructed raw-date workcounts: 205 total checks (same 60 cases). **Dependent total:** 120 case executions, 409 checks. These were pre-execution targets; observed canonical Native PASS results and evidence are recorded below.

## Execution, source-lock and acceptance gates

Implement D20 code and its independent walker/test fixture on this QA branch first. Explicitly check D19 source/reference blob immutability before modifying anything else. For each of two naturally triggered QA Native jobs, pin headless UCBLogo 6.2.5 source `a0215433f07384e4c42fe247525867f11e6f32f7`, require job checkout SHA equals its trigger, bound the UCBLogo execution to 1800 seconds and CI job to 35 minutes, and use exact full-line markers:
- `STAGE_2_DISCOVERY_20_FORWARD_CASES_PASIS 60`
- `STAGE_2_DISCOVERY_20_FORWARD_CHECKS_PASIS 204`
- `NATIVE_STAGE_2_DISCOVERY_20_FORWARD_SHARD=PASS`
- `STAGE_2_DISCOVERY_20_REVERSE_CASES_PASIS 60`
- `STAGE_2_DISCOVERY_20_REVERSE_CHECKS_PASIS 205`
- `NATIVE_STAGE_2_DISCOVERY_20_REVERSE_SHARD=PASS`

A dependent aggregate may emit `STAGE_2_DISCOVERY_20_CASES_PASIS 120`, `STAGE_2_DISCOVERY_20_CHECKS_PASIS 409`, and `NATIVE_STAGE_2_DISCOVERY_20_VERIFICATION=PASS` only when both source-locked shards have completed successfully. Reject missing/unknown/failure/timeout markers and malformed outputs. The target counts alone are not evidence of successful execution.

QA D20 Native PASS was independently verified at run 44820146210. Canonical D20 was subsequently accepted from completed first-attempt same-SHA Native job logs and all thirteen required companion regression workflows, as documented below. No Stage 2 completion, main write, or public release is claimed. Queued/in_progress is neither PASS nor blocker.

## Next authorized action

D20 Native was accepted at canonical implementation SHA `07f67dad3fde1d1a5cc6178d5c5536311638e866`. The next actionable step within Stage 2 is to inspect the remaining Appendix-A primitive sequence, specify the next bounded input/output contract and independent oracle, and only then implement its authorized scope. D20 acceptance alone does not authorize Stage 2 completion, main, merge, or publication.

## Verified QA evidence and controlled canonical-candidate handoff (2026-11-21)

QA HEAD `19de85e8a78e8735913851fd3e50a772b621e18e` remained exactly two commits ahead of accepted canonical D19 `4002280506a93999e64159155f2e9f8b89ae4c23`, with six added files and no modified pre-existing source/reference files. Run [44820146210](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820146210) completed success on that exact QA SHA: forward job 136578625166 60/204 with authentic shard PASS, reverse job 136578624567 60/205 with authentic shard PASS, dependent job 136592092959 120/409 and NATIVE_STAGE_2_DISCOVERY_20_VERIFICATION=PASS. Artifact IDs: forward 14672692683, reverse 14673535730; both preserved in the original run. Canonical Names Lock run 44820146113/job 136578624379 completed success. These are **QA**, not canonical or Stage 2 acceptance.

The new canonical D20 workflow is a separate push-only `Logo\\+Ido` gate, derived from the validated QA workflow but additionally source-locks the newly introduced D20 production/test files by Git blob SHA. It has two independent 1800s/35min bounded Native jobs and one dependent acceptance job. The canonical gate and all thirteen companion workflows were subsequently checked against completed job logs and the identical trigger SHA before D20 was recorded ACCEPTED=YES. LAST_COMPLETED_STAGE remains 1. No main/merge.

## Canonical D20 acceptance evidence (2026-11-21)

Canonical implementation SHA `07f67dad3fde1d1a5cc6178d5c5536311638e866` was confirmed as the HEAD of unprotected `Logo+Ido` before this documentation-only acceptance update. First-attempt [run 44828444891](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828444891) completed SUCCESS with genuine source-locked UCBLogo 6.2.5 execution: forward job **136606933674** printed 60 cases / 204 checks / `NATIVE_STAGE_2_DISCOVERY_20_FORWARD_SHARD=PASS`; reverse job **136606933393** printed 60 cases / 205 checks / `NATIVE_STAGE_2_DISCOVERY_20_REVERSE_SHARD=PASS`; dependent job **136619231518** emitted 120 cases / 409 checks / `NATIVE_STAGE_2_DISCOVERY_20_VERIFICATION=PASS`. Forward log artifact **14677261158** (digest sha256:d8d48da2c9d07e212ae80d81421264c36ca387c18e4c89b8729a40075ad73b62), reverse log artifact **14675749962** (sha256:1d82b7dc5ce0cbbd51e11b5f891b7058c8862d4b6810459eabc98c8c1396c5b3), both original exact-SHA and unexpired at verification.

All **13** first-attempt companion workflows on this same SHA completed SUCCESS; job logs were inspected for Native markers or Names Lock: D19 `44828444872` (34/123 aggregate), D14 `44828444905`, D16 `44828444827`, D15 `44828444819`, D01–D09 `44828444760`, D18 `44828444778` (6/40 aggregate), Stage1 `44828444740` (`STAGE_1_TESTI_PASIS`, `NATIVE_STAGE_1_VERIFICATION=PASS`), Names Lock `44828444811`, D10 `44828444759`, D12 `44828444820`, D13 `44828444726`, D17 `44828444713`, D11 `44828444771`. Therefore **D20 ACCEPTED=YES on canonical implementation SHA**. This is a bounded D20 Native + independent differential acceptance, **not Stage 2 acceptance**; `LAST_COMPLETED_STAGE=1` remains unchanged. No manual dispatch or rerun was used.
