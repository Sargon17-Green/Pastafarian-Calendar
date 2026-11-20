# Stage20 Native CI Acceptance — Perl+國語 (2026-11-20)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Accepted exact source: 01f4d16e04f2225a7861076d747a669a0f00df77
Previous accepted stage: 19
Accepted stage: 20

## Canonical push, exact source and mandatory raw logs

- Run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44702256231 ; attempt1; completed/success; head_branch=Perl+國語; head_sha=01f4d16e04f2225a7861076d747a669a0f00df77.
- Branch HEAD independently read before writing, equal to exact source SHA.
- Two paginated GitHub job pages: 167 jobs total; 21/21 mandatory completed/success and 146 conditional skipped.
- All 21 required job raw logs individually fetched and screened: zero TAP 'not ok', zero 'Result: FAIL', zero GitHub error markers.
- Full Stage01 suite: Files=118, Tests=242846, Result: PASS.
- Separate Stage04 MonthOccurrence: 385/385 TAP PASS; its domain was not widened.
- Stage20 dedicated job https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44702256231/job/136173215030
- Stage20 eight disjoint deterministic rank shards: two with Tests=14737 and six with Tests=14735, total 117884/117884 TAP PASS; eight 'All tests successful.', eight 'Result: PASS', no TAP 'not ok'.
- Independent ordinal/Dyck oracle Catalan(11)=58786 rank-index words: two rank shards of 7349 and six of 7348; each shard independently reproduces the numeric-lexical CSV+LF SHA256 3b7ad5a789d66bfc799fbbc96669e79a46e551fa0d19453bdef7d228f8626c0c.
- Separate bounded [4x11] 44-day production count 6769339545226096626603442 and rank1 unrank/rank roundtrip PASS. Neither is an independently calculated expected large-profile count or expected word.
- Perl v5.40.5, syntax2/2 OK. Stage20 per-shard and large-profile processes have 120-second timeout and 393216-KiB virtual-memory budget; job exit0/stderr empty.

## Independent ZIP verification

Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44702256231/artifacts/14616455411
Archive size: 313940 bytes.
GitHub digest, workflow upload-step digest, and locally computed downloaded-byte SHA256 all match:
36870ea4b6b22470453c74dc093e5f8c77d31eff453fb280da85e99618d0432a

The downloaded ZIP contains exactly seven files; independent testzip verified all seven CRCs: perl-version.txt (v5.40.5), result.txt (STAGE20_NATIVE_PASS=1), source.txt (exact source SHA), syntax.stderr (two syntax OK lines), test.exit (0), test.stderr (zero bytes), test.stdout (8 PASS summaries, 117884 TAP, oracle, large-profile markers and STAGE20_FULL_YEAR_GENERATOR_NOT_VERIFIED).

## Decision and limits

Stage20 Native CI ACCEPTED: LAST_COMPLETED_STAGE 19 -> 20.
Production WeavingPrimitive supports at most 11 months and 44 total days; separate MonthOccurrence remains at most 9 months/36 days. This does not accept the complete five-field full-year generator, or any Stage21 12-month expansion. No main changes, merge or publication. Open Stage21 independent DISCOVERY only.
