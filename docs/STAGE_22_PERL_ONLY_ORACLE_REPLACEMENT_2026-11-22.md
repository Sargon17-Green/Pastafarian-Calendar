# Stage22 Perl-only QA oracle replacement — decision 2

Date: 2026-11-22  
PROJECT_ID: PC-BRANCH-PERL-GUOYU  
Branch: `Perl+國語`  
Parent HEAD: `a90c15af1277b14ab01bdbc4a4fb93bbcb0b3b8e`  
Scope: post-acceptance Stage22 12/52 maintenance; **no Stage23 or full-year claim**.

## Authorized language-policy resolution

User explicitly chose **option 2: retain repository-wide Perl-only**. This decision does NOT authorize any C++ test-only exemption. `t/00_bootstrap.t` remains unchanged at blob `c157f381e85fbbf6fb6350d0cfb2f307b01d9822` (its assertion 12 rejects non-Perl source across the whole repository).

This commit removes `qa/perl-guoyu/stage22_max_arena_forward_oracle.cpp`, adds `qa/perl-guoyu/stage22_max_arena_forward_oracle.pl` and its independent small-case contract suite, and changes only the isolated 12/52 CI harness. The producer module remains unchanged at blob `4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6`. The preexisting canonical Stage22 source `e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a`, successful run `44904659215`, and artifact `14708038426` retain their historical acceptance; they are not re-run.

## Independent design and bounded contract

**Input:** fixed 12-month/52-day profile `[3,4,4,5,5,5,5,5,5,4,4,3]`; either `count` or `lex WORD_CSV`, where the word has exactly 52 integer month labels. A test-only environment override accepts profiles of 1–13 months and at most 52 days for independent small brute-force controls.

**Output:** exact count as decimal text; in `lex` mode additionally `lexical_ordinal=<positive decimal rank>`. Illegal CSV/profile/event order must fail nonzero. Exact reference count: `214592873590014046152008360029870`, midpoint rank `107296436795007023076004180014935`; tested ordinal witnesses are first, midpoint and last.

**Independent method:** chronological **forward** state transfer counts paths from an empty event prefix. This differs from the production recursive suffix-count memoization and uses four little-endian unsigned **base-2^32** limbs with checked carry instead of production decimal base-10^12 limbs. For lexicographic ordinals a separately computed bottom-up reverse table sums branch suffixes; it never imports or invokes production code. Small controls use a distinct brute-force oracle: enumerate all multiset permutations and independently retain words whose first and last occurrence orders both increase. Source-locked QA also checks that producer and oracle Git blobs are the exact recorded versions.

**Resource boundaries:** each process has 120 seconds, VSZ <= 393216 KiB, observed RSS <=393216 KiB; record exit, stderr, time, RSS, input and source hashes in an artifact. The packed oracle arena is 4,021,367 states; forward count traverses 33,497,104 transitions. A new isolated job includes unchanged `t/00_bootstrap.t` (13 TAP checks), the small independent brute-force contract (45 TAP), both Perl syntax checks, oracle/producer count comparison and three first/middle/last rank/unrank and independent lexical checks. A failure leaves `STAGE22_MAX_ARENA_NATIVE=FAIL`.

## Evidence before this commit

- Local Perl 5.40.1 source compilation: oracle and small-case contract syntax OK; bash harness syntax OK.
- Small brute-force contract: **45/45 TAP PASS**, exit 0, no stderr, for seven profiles including `[2,2]`=2, `[2,2,2]`=5, `[3,2,3]`=19, and singletons. Numeric lexicographic ordinal comparison is performed for every brute-force legal word.
- 12/52 oracle forward count output matched exact historical independent C++/Perl value; 4,021,366 reachable nonterminal states and 33,497,104 transitions. This is **local QA**, not a new GitHub CI result.
- 12/52 first lexical word `[1x3,2x4,...,12x3]`: oracle printed count and `lexical_ordinal=1`, exit0, wall 32.89s, max RSS 178720 KiB, under the 120s / 393216 KiB limits. The two other 12/52 ordinal witnesses remain reserved for the new source-locked CI harness.
- The earlier run `44946754710` failed its unisolated `perl-stage01` job `136975642275` solely on `t/00_bootstrap.t` assertion 12 because of the now-deleted C++ file. The isolated C++-oracle 12/52 job `136976291477` from run `44946966161` previously passed; this does not prove the new Perl oracle's Native gate.

## CI and gate interpretation

Commit subject includes `[stage22-maxarena-only]` so the existing workflow runs **only** the isolated 12/52 job instead of the accepted Catalan13/13x4 32-shard jobs. Any auto-push run must be inspected after completion for exact SHA, job, raw log, and source-locked artifact SHA256/CRC/exit evidence before claiming new Perl-only Native PASS. This documentation does not constitute Native acceptance. There is no main merge, publication, production change, Stage23, or full-year verification.
