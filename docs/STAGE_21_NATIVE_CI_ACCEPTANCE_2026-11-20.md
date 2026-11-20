# Stage21 Native CI Acceptance — Perl+國語 (2026-11-20)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Exact accepted source SHA: a06fb9ee6d78c47a7abb5bf10950f45d9bf518c0
Last completed stage: 20 -> 21

## CI and source evidence
- Canonical push: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44812489647 ; attempt 1; completed/success; head_branch=Perl+國語; head_sha=a06fb9ee6d78c47a7abb5bf10950f45d9bf518c0.
- Branch HEAD independently verified equal to exact source SHA before acceptance.
- All 168 jobs fetched across two pages; 22/22 mandatory completed/success, 146 conditional skipped. All 22 mandatory raw logs independently inspected with no observed test failures, Result: FAIL or GitHub ##[error] markers.
- Perl Stage01: Files=120, Tests=243130, Result: PASS. Dedicated Stage04: 385 tests PASS.
- Stage21 dedicated native job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44812489647/job/136552329380
- Native Perl v5.40.5; three syntax OK; 16 independent Catalan12 ordinal shards: twelve with Tests=26044 and four with Tests=26042; separate t/69 mixed profiles 208/208 TAP, 74 independently enumerated valid words. Total Stage21 416904/416904 TAP, 17 PASS invocations, no TAP not ok.
- Catalan(12) ordinal oracle 208012 words; all 16 shards reproduce SHA256 0dbe36d23b6ffaa14822b1556d3eabc777d5961bdfd2fd79be39ee2daee76bbe; shard compare totals 208012.
- Bounded 4x12 count: 11105730970797793977337986040; last-rank unrank/rank inverse PASS. Earlier independent backward/forward research counts were documented in Stage21 preflight; this CI gate does not claim a newly computed independent large-count oracle.
- Separate bounded process gates complete; artifact test.exit=0, test.stderr zero bytes; native result STAGE21_NATIVE_PASS=1.

## Independently downloaded evidence
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44812489647/artifacts/14668587498
- ZIP size 1153656 bytes. SHA256 (GitHub provider metadata, workflow upload log and independent local downloaded-byte computation): 9f1473a57a9be9a5da6ebf392b745c6b5fc57b3f449c2cedddea01f731a93c16.
- ZIP contains exactly 7 files and all seven CRC checks pass (ZipFile.testzip returned no error):
  perl-version.txt, result.txt, source.txt, syntax.stderr, test.exit, test.stderr, test.stdout.
- Source exact a06fb9ee6d78c47a7abb5bf10950f45d9bf518c0; perl-version v5.40.5; syntax.stderr has exactly three syntax OK lines; exit zero, stderr empty and native marker PASS.
- Detailed machine-readable audit: qa/perl-guoyu/stage21_native_ci_acceptance_2026-11-20.json.

## Decision and scope
- Stage21 accepted. Production WeavingPrimitive bound: at most 12 months and 48 days, with mixed-radix count/rank/unrank and independent lexical tests.
- The separate MonthOccurrence bound remains 9 months and 36 days. The full-year calendar/date generator is NOT verified.
- No Stage22 initiation, main/protected branch change, merge, release, or publication. NEXT: post-acceptance Stage21 maintenance or targeted non-stage-opening regression review.
