# Stage20 local resource gate, repository isolation patch, and native candidate (2026-11-20)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Baseline HEAD: 160c853e6f9aafb9e0e14fa821f91dd403d5d8bc
LAST_COMPLETED_STAGE=19, unchanged. Stage20 canonical acceptance PENDING.

## Verified CI regression
Canonical docs-only run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44634283778 completed/failure on exact baseline HEAD. perl-stage01: t/00_bootstrap.t test12 failed because qa/perl-guoyu/stage20_independent_dyck_oracle.py violates the unmodified foreign-language source guard. 117 files, 242773 TAP; exactly one failed. Fix: remove .py, replace oracle with independent pure-Perl Dyck enumerator in t/67; keep JSON and oracle SHA. No production DP defect established.

## Isolated Perl5.40.1 resource gate
Exact original Stage19 source Git blob 3d731e16bfd88b7ad00c9f5f04f17509467fb91a reconstructed and independently verified before changes. Candidate source Git blob 1ec5dc479b5a91df65bab83583d75ff05bfc59b7 changes only bounds 10->11 and 40->44. Module+probe syntax 2/2 OK.
[4x11]: full resource bound 120s and ulimit -v 393216KiB. Exact count=6769339545226096626603442, exit0, Perl stderr empty, elapsed40.36s, max RSS276480KiB. Earlier 30s exit124 was an intentional timeout, now superseded. This count comes from production, NOT an independent formula.
Other profiles previously validated in scratch: [1x11]=1, [2x11]=58786 independently Catalan, [3x11]=210779736073446 roundtrip-only, [34,1x10]=1, [44]=1.

## Independent oracle and bounded local QA
t/67_stage20_weaving_eleven_months.t produces balanced parentheses independently from production suffix-state DP; maps open/close ordinals to labels, explicitly sorts numerical lexicographic order, and hashes all 58786 words. The checksum reproduces the earlier Python mathematics reference exactly: 3b7ad5a789d66bfc799fbbc96669e79a46e551fa0d19453bdef7d228f8626c0c.
t/67 Git blob d19b19ae49dc9f9f013a7c31e7cab602c04f38da matched separately compiled local source. Local Stage01-mode: 73/73 TAP PASS, ~1.42s, max RSS148480KiB. Dedicated 0/8 shard: 14737/14737 TAP PASS, ~42.04s, max RSS151720KiB, exit0 and 120s/393216KiB resource bound.
Eleven new invalid-profile fixtures rejected with corrected 12-month and 45-day boundaries. Remaining 7 shards/full CI NOT locally certified.

## Native contract / acceptance gates
Bounded Stage20 code only changes 10->11 months and 40->44 days. Previous invalid fixtures shift to genuinely invalid bounds in t/47,t/48,t/61,t/62,t/63,t/64. Stage04 MonthOccurrence and t/49 are untouched.
Stage20 job: 8 deterministic rank intervals (two of 7349, six of 7348), with each shard <=120s/393216KiB, plus separately bounded [4x11] count. Seven evidence files: source.txt, perl-version.txt, syntax.stderr, test.stdout, test.stderr, test.exit, result.txt.
Stage20_NATIVE_PASS=1 is not claimed until dedicated job checks pass; whole Stage20 acceptance needs 21/21 canonical mandatory jobs on exact SHA plus all raw logs, seven-file artifact SHA256, CRC and source checks. Full-year generator unverified. No main/merge/release.

Additional separate bounded large-profile rank check: [4x11] unrank(rank=1) followed by rank(word)=1 passed locally with 120s/393216KiB constraints, exit0, 47.67s elapsed and max RSS276736KiB. No independent rank oracle is claimed for this profile. The dedicated CI job repeats it as a separately bounded test.
