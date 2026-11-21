# Stage22 CI regression repair — exact source f5dee97df97a (2026-11-21)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Scope: Stage22 production candidate 13 months / 52 days; no change to producer or Stage21 acceptance.

## Completed canonical evidence

Canonical push run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896322930
was completed/failure at exact HEAD f5dee97df97a66adfed96bca04493f40f3d9f877, first attempt. Repository branch HEAD and run head_sha were independently checked equal.
From all 169 completed job records, failed Stage01 job 136822646118, Stage02 job 136822650105, Stage03 job 136822650148. The three raw job logs locate five failing assertions:
* Stage01 full Perl suite: t/47 tests 212-213, t/48 tests 274-276, 121 files / 243191 TAP, nonzero exit.
* Stage02 native: t/47 tests 212-213 (2/261), nonzero exit.
* Stage03 native: t/48 tests 274-276 (3/288), nonzero exit.
All remaining tests in these two files passed. There was no observed failure in the Stage22 dedicated job.

Stage22 native job 136822650301 completed/success and downloaded artifact 14705127360
(https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896322930/artifacts/14705127360):
GitHub digest = independently calculated archive SHA-256
081f5154d1633e0536d4c96a71f7ce244b827deee2cc3186aa5b9a1293cfc9ed.
Exactly seven archive members were read, all seven ZIP CRCs passed. source.txt was f5dee97df97a66adfed96bca04493f40f3d9f877;
Perl v5.40.5; test.exit=0, test.stderr empty, syntax checks OK, result.txt=STAGE22_NATIVE_PASS=1.
Independent scan of test.stdout: smoke + every integer shard 0..31 exactly once, no 'not ok',
33/33 Result: PASS; 742900 independent ballot oracle comparisons across the 32 shards;
32*46467 + 61 = 1487005 TAP assertions. Oracle count 742900 and CSV SHA256
67edb036b070b196c6b889b161a27baef6b0ec7852717586550ef2f8b4d7173d verified.
The 13x4 count was 21604722570792867375065793772732; first/middle/last rank inverse checks passed.
This is a **dedicated Stage22 Native PASS only**, not full-stage acceptance or a full-year claim.

## Reproduced cause and minimal patch

The Stage22 signed-off domain is 1..13 positive month lengths, total 1..52 days.
Both earlier tests retained negative fixtures from the prior narrower domain:
* `[49]`: valid single month with 49 days (one ordering);
* `[(1)x13]`: valid 13 months with one day each (one ordering);
* `[22,27]`: valid two-month 49-day profile (has at least one ordering).
Thus the five negative assertions contradict the new contract. No producer bug is inferred.

Only test fixtures are changed:
* t/47 invalid `[49]` -> `[53]`, `[(1)x13]` -> `[(1)x14]`;
  add two positive boundary assertions.
* t/48 invalid `[49]` -> `[53]`, `[(1)x13]` -> `[(1)x14]`,
  `[22,27]` -> `[22,31]`; add one positive 49-day two-month assertion.
Values 53, 14 months, and two-month total 53 are unambiguously beyond the Stage22 scope.
No changes to implementation, legal ordering, canonical catalog, other tests, or workflow.

## Gates and next

This repair has bounded static source-diff preflight before commit; no assertion is claimed to have
passed a newly triggered CI until its exact run/job/log/artifact is inspected. One exact-head-lease
branch push should schedule a new canonical run automatically; do not dispatch duplicates.
Require all mandatory jobs and raw logs completed/success on the NEW SHA, and re-audit the
dedicated Stage22 seven-file artifact with exact source lock before acceptance.
LAST_COMPLETED_STAGE remains 21. No merge/main/release; full-year unverified.
