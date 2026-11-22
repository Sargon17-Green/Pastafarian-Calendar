# Stage22 Perl-only maximal-arena isolated Native acceptance (post-acceptance QA)

Date: 2026-11-23
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: `Perl+國語`
Exact tested source HEAD: `3df76ff3a6e98fcd5b650f0b18a1da203ec8be39`
Source tree: `95e733cb0b0cb7b6541ace038621d260975467ca`
Scope: one previously scheduled isolated 12-month/52-day Perl-only QA run; Stage22 was already accepted at source `e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a`. This is NOT Stage23, full-year, main, or release acceptance.

## Immutable GitHub evidence

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068493142
- Event: push, attempt 1, head_sha `3df76ff3a6e98fcd5b650f0b18a1da203ec8be39`; run status `completed`, conclusion `success` (2026-11-22T20:53:54Z).
- All 170 jobs retrieved through GitHub REST pagination (100 + 70); 169 completed/skipped; exactly one isolated job completed/success.
- Isolated job: `137349926607` — "Stage22 12x52 maximal arena — isolated source-locked Native". All job steps succeeded, and the decoded raw job log ends with `RESULT=PASS`.
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068493142/artifacts/14771599777
- Artifact name: `perl-stage22-max-arena-source-locked-native`; 12,979 bytes; GitHub provider/upload log/local downloaded ZIP SHA-256 all equal `8c98e159cd47918d3401eae8da956f971da1fab2d80296de869e1cf8a6d2d28e`.
- Independent ZIP check: 72/72 entries CRC OK, 17/17 process exit files contain 0, `harness.exit=0`, `STAGE22_MAX_ARENA_NATIVE=PASS`.
- Exact identity inside artifact: PROJECT_ID, branch and HEAD/GITHUB_SHA all matched; production Git blob `4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6`; independent Perl oracle Git blob `6745f95942bd3376185ce0bc822f15271806bf4f`; Perl v5.40.5 on Linux x86_64. The preexisting production and bootstrap files were not changed by the tested commit.

## Verified native outcomes

1. Unmodified `t/00_bootstrap.t`: all 13/13 TAP checks pass; assertion #12 (no foreign-language source) passes; exit 0, stderr empty.
2. Separate independent brute-force contract `stage22_perl_only_small_contract.pl`: 45/45 TAP pass and exit 0, stderr empty.
3. Independent forward-transfer Perl count and the unchanged production reverse-memo producer agree exactly:
   `214592873590014046152008360029870`.
4. First, midpoint, and last lexical ranks verified with independent Perl oracle and production rank/unrank:
   - first: `1`
   - midpoint: `107296436795007023076004180014935`
   - last: `214592873590014046152008360029870`.
   All three recorded CSV words match the production unrank outputs, 52 month labels each.
5. Forward oracle reports 4,021,367 packed arena slots, 4,021,366 reachable non-terminal states, and 33,497,104 transitions.
6. All 17 process records have zero exit status; all per-process wall times are <120s and max RSS is <=393,216 KiB. Highest recorded RSS: 181,300 KiB (oracle count); oracle count wall time 37.24s, producer count 33.81s. `ulimit -v 393216` is applied inside the exact committed runner to every process; a numeric peak VSZ was not captured separately. Nonempty oracle stderr contains intentional statistics, not exceptions; producer, bootstrap and small-contract stderr are empty. Perl syntax output is on stderr with exit 0.

## Gate decision and scope

**PASS — the specific isolated source-locked Perl-only Stage22 12/52 maximal-arena Native QA gate.**

This does not supersede the already accepted canonical Stage22 evidence (run 44904659215, 23/23 required successful, artifact 14708038426 on historical source e28e6186), and does not assert a new canonical Stage22 run or a global differential sweep.

Residual QA gaps identified by earlier static audit remain independent of this successful bound: the small-case suite currently has no malformed-input negatives; `lex` reads the first CSV line without rejecting trailing lines. These are not observed failures in the accepted 12/52 positive contract. Do not mark such absent coverage as PASS or as a produced defect without a reproducer.

No production edit, no Catalan13 or 13x4 rerun, no new test dispatch, no Stage23, no merge/main/release. This report is evidence-only; the commit should use `[skip ci]` to avoid re-running accepted tests after a documentation-only edit.

NEXT: preserve this accepted evidence; consider a focused negative-input parser/QA contract separately under the same branch if authorized by the existing maintenance scope, without treating it as Stage23 or changing the already accepted Stage22 source.
