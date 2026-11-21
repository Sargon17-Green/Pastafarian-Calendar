# Stage22 maintenance: intermediate CI bootstrap language-invariant conflict

Date: 2026-11-21
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: `Perl+國語`
Inspected live HEAD before documentation: `5de3eca341117ba255f0f5213e438381dd5fe646`
This is a post-acceptance diagnostic record. It does not change Stage22's accepted source, production implementation, gate status, or any test policy.

## Evidence and scope

- Intermediate unisolated push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44946754710 ; associated commit `4312b89b5fb7a95b4585f7eacbe4710fa2464908`. This run is NOT Stage22 acceptance evidence.
- Failing completed job: `perl-stage01`, job `136975642275`; raw job log inspected.
- `prove -e 'perl -CS -Ilib -It/lib' -lr t`: `t/00_bootstrap.t` test 12 failed, at line 31. The reported only differing entry was `./qa/perl-guoyu/stage22_max_arena_forward_oracle.cpp`. 121 files, 243194 assertions in the Stage01 suite; one failed assertion. All other listed test files in this job reported `ok`. This is a language-invariant/test-organization conflict, not demonstrated bad producer arithmetic.
- Current `t/00_bootstrap.t` blob `c157f381e85fbbf6fb6350d0cfb2f307b01d9822`: recursively rejects any files ending in listed foreign-language extensions, including `.cpp`, anywhere in the repository.
- Current independent QA oracle path `qa/perl-guoyu/stage22_max_arena_forward_oracle.cpp`, blob `9270a948805da5f0caf28db96c07ad51880dac78`, lives outside `lib/` and is compiled by the isolated Stage22 harness.
- Stage22 isolated source-locked 12/52 acceptance witness: run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44946966161 , completed-success job `136976291477`, whose decoded log states `RESULT=PASS`, `PRODUCER_BLOB=4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6`, `ORACLE_BLOB=9270a948805da5f0caf28db96c07ad51880dac78`, and exact count `214592873590014046152008360029870`.
- Witness artifact `14723629431`, GitHub/provider digest `sha256:00bf63a5c6fc6a200917a4a72a06ff5a8053c52e614d6c244cdd23640a20df4c`, matching the checksum printed at upload. Prior complete inspection/CRC is recorded in the tracker; this diagnostic did not re-download or re-run the already accepted witness.
- GitHub connector returned the *first page* of jobs for the intermediate run, not an exhaustive page traversal. Do not infer the run's overall conclusion or all other job conclusions from this subset.

## Policy choice required before any source modification

The original Stage01 check states that the repository has no non-Perl source code. A C++ test-only independent oracle was subsequently checked into `qa/`. Two valid engineering policies give different fixes:

1. **Allow a narrowly named QA-only C++ oracle** while keeping all non-Perl production code disallowed: change the Stage01 check to exempt exactly the documented `qa/perl-guoyu/stage22_max_arena_forward_oracle.cpp`, never blanket-exempt `qa/`. Regression check: a synthetic second `.cpp` in `qa/` or `lib/` must still fail, and the allowed path must be the sole exception.
2. **Keep the repository-wide Perl-only rule**: replace the QA C++ oracle with a separately reasoned Perl forward-DP oracle and remove the tracked `.cpp`; independently validate exact 12/52 count and first/middle/last lexical ordinals and bounded resources. Existing Stage22 acceptance remains historical; a new oracle requires its own scoped QA evidence.

Choice (1) changes the existing language-policy scope; choice (2) changes the oracle implementation and demands fresh evidence. This diagnostic does not assume permission for either policy change.

## Gates

- No source/test/workflow modification here. No extra dispatch, 13x4 or Catalan13 rerun, Stage23, main merge, or release.
- Stage22 accepted source remains `e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a` (canonical run `44904659215`, acceptance artifact `14708038426`).
- Full-year conversion remains unverified.
- Next permissible action: obtain/identify the language-policy decision before modifying the bootstrap invariant or the independent oracle. The decision must also specify a focused regression gate; the rest of accepted Stage22 should not be re-run automatically.
