# Stage22 post-acceptance: focused lexical CSV regression — local QA PASS

Date: 2026-11-23  
PROJECT_ID: PC-BRANCH-PERL-GUOYU  
Branch: `Perl+國語`  
SOURCE_COMMIT_LOCK: `bb49201411b6397819c97e5fc2b40238251e48ce`  
Scope: QA-only maintenance of previously accepted Stage22; **no Stage23**, full-year, production changes, merge, main, or release.

## Source identity and environment

- GitHub branch `Perl+國語` versus locked source commit: identical; ahead=0, behind=0 before evidence write.
- Local runtime: Linux x86_64, Perl v5.40.1.
- Three exact fetched Git blobs checked against local `git hash-object` before execution and again during evidence packaging:
  - `qa/perl-guoyu/stage22_max_arena_forward_oracle.pl`: `b6f6e055c41e31be369b11fbacc33f6d0279856e`.
  - `qa/perl-guoyu/stage22_oracle_csv_negative_input.t`: `b41ae40b2b04a07a6b3eb385b2f246097bb5f036`.
  - `qa/perl-guoyu/stage22_perl_only_small_contract.pl`: `85d055ae9dfec705105109195b8ed259c552d39c`.
- No producer implementation was copied, edited, compiled or run for this post-acceptance narrow QA.

## Commands and observed results

In a local directory containing only the three exact source files:

```sh
perl -c stage22_max_arena_forward_oracle.pl
perl -c stage22_oracle_csv_negative_input.t
perl -c stage22_perl_only_small_contract.pl
perl stage22_oracle_csv_negative_input.t > test.tap 2> test.stderr
perl stage22_perl_only_small_contract.pl > small.tap 2> small.stderr
```

- Syntax: **3/3** `syntax OK`, all three syntax exits 0.
- Negative/positive lexical CSV fixture regression: **66/66 TAP PASS**, exit 0; TAP plan `1..66`; all `ok 1` through `ok 66` contiguous; zero `not ok`; `STAGE22_ORACLE_CSV_NEGATIVE_CONTRACT=PASS`; stderr zero bytes.
- Original independent brute-force small-profile oracle contract against the **new exact oracle blob**: **45/45 TAP PASS**, exit 0; plan `1..45`; all 45 `ok` contiguous; zero `not ok`; `STAGE22_PERL_ORACLE_BRUTE_FORCE_CONTRACT=PASS`; stderr zero bytes.
- Local total **111/111 TAP PASS**. The oracle's input reader rejected malformed extra physical lines while accepting LF, CRLF, and no-terminal-newline valid single records.
- The TAP logs were independently parsed after execution for strict contiguous sequence, plan counts, failure absence and empty stderr.

## Verifiable log digests

| File | SHA-256 |
| --- | --- |
| `test.tap` | `c72e9d76f83696f279d9c0232e86816b36bb0bba4718f3f516235a2881f12e98` |
| `test.stderr` (empty) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `small.tap` | `a9f8b6e44d4e6b1274ca762c408d761425d1f479991192b68767197c0656bfe8` |
| `small.stderr` (empty) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

Evidence bundle `PC-BRANCH-PERL-GUOYU_stage22_csv_QA_2026-11-23.zip`:
SHA-256 `83d1f5b65e991349b74a50e39bb124cf8a9afa6d87946551a5ae8d461b2763c5`; includes exact source files, TAP/stderr, syntax output and machine-readable `qa_run_summary.json`. The ZIP was generated as an assistant conversation attachment, **not** uploaded to GitHub.

## Gate classification

- **QA code**: already committed in locked source SHA; unchanged in this evidence-only commit.
- **Static identity**: PASS (all three exact Git blobs).
- **Local focused QA / independent small oracle**: PASS (66/66 + 45/45; 3 syntax checks).
- **GitHub Actions CI**, **GitHub-hosted Native**, **full 12/52 oracle**, **13x4**, **repository-wide bootstrap**, and **cross-implementation differential on this source**: **NOT RUN / NOT CLAIMED**.
- Historical Stage22 Native acceptance (run `44904659215`, artifact `14708038426`) and historical isolated 12/52 Native acceptance (run `45068493142`, job `137349926607`, artifact `14771599777`) are unaffected. This evidence does **not** upgrade these older results to the new SHA.
- Stage22 remains accepted on the prior accepted source; this document accepts only the **focused post-acceptance local QA**. Full-year remains unverified.

NEXT: if further corroboration is necessary, add or trigger a **distinct minimal QA-only** workflow/job bound to the current source and verify its completed job/log/artifact; do not re-run accepted 12/52, Catalan13 or 13x4, and do not create Stage23 or alter main.
