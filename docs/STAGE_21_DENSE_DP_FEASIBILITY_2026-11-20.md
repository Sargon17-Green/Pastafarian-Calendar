# Stage21 Dense-State Exact-DP Feasibility — 2026-11-20

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Verified branch HEAD at experiment start: a17514f75e928d8b1bef4592fd5e04f2fa3a4eff
Accepted production source blob: 1ec5dc479b5a91df65bab83583d75ff05bfc59b7
LAST_COMPLETED_STAGE=20. Stage21 remains DISCOVERY; no production code change.

## Prior resource problem

The bounded [4×12] suffix-count preflight on the accepted recursive hash/Math::BigInt algorithm had three scratch variants: 42.36 s/RSS 388224 KiB/exit1 OOM; 40.33 s/RSS 388352 KiB/exit1 OOM; compact string memo 120.01 s/RSS 230528 KiB/exit124 timeout. None counted [4×12].

## New, algorithmically distinct exact count

Two new standalone **Perl** scripts (Git blob SHAs independently checked against local git hash-object):
- qa/perl-guoyu/stage21_dense_backwards_count.pl — blob e3c40d156dbb67308278e1fdcc7e9dc5da44339c. Top-down memo on (opened, closed, ternary active interval); dense array offset and four 12-digit integer limbs, not per-state Math::BigInt/hash.
- qa/perl-guoyu/stage21_independent_forward_count.pl — blob c5a88e3c8e1285f4391c7801688d71745c6b3981. Independent, iterative **forward** accumulation on base-five per-symbol progress; hash keyed by total progress word, four integer limbs; no calls to the backward algorithm or production.

The base-10^12 four-limb representation is sufficient because the total number of length-48 words on 12 positive labels is bounded by 48!/(4!)^12 < 10^45. Limb accumulation never exceeds exact integer width.

Local GNU/Linux Perl 5.40.1. Each 12-month run executed with timeout -k 3s 120s and ulimit -v 393216 KiB; /usr/bin/time measured wall and peak RSS:
| Experiment | Count | Wall (s) | Peak RSS (KiB) | Exit |
|---|---:|---:|---:|---|
| Backward ternary DP [4×12] | 11105730970797793977337986040 | 13.43 | 146944 | 0 |
| Forward base-five DP [4×12] | 11105730970797793977337986040 | 23.69 | 82304 | 0 |

Backward: exactly 1,195,735 memo states and 9,565,932 processed transitions. Forward: 1,195,734 expanded nonterminal states. Results agree digit-for-digit. Both also independently reproduced accepted Stage20 [4×11] count 6769339545226096626603442; their smaller-month outputs match for 1, 2, 3, 4, and 6 months. Independent ephemeral C++ forward iterator also reproduced the [4×12] count in 0.43s/RSS23092 KiB; C++ source deliberately NOT committed to the Perl branch.

This is independent algorithmic numerical agreement, not a known closed-form proof for [4×12]. The accepted independent Catalan12 oracle remains C(12)=208012 with hash 0dbe36d23b6ffaa14822b1556d3eabc777d5961bdfd2fd79be39ee2daee76bbe for [2×12]; no substitution of the [4×12] result for that oracle.

## Generalized scratch candidate (not production)

A mixed-radix extension supports arbitrary positive lengths, <=12 months, <=48 total days; public count/rank/unrank return exact Math::BigInt and fresh words. The candidate was compiled locally (Perl syntax OK) and passed [4×12] count separately at 20.79 s/RSS141952 KiB, exit0. A separate [4×12] last-rank unrank/rank inverse passed at 32.96 s/RSS273408 KiB, exit0. A focused TAP stream reported 599/599 ok covering small-profile independent brute counts, heterogeneous profiles, accepted 11×4 count, new 12×4 count, rank1 inverse, and untouched inputs. The TAP wrapper did not independently capture final process exit, so these are TAP results only. No claim of a full repository test run.

The generalized scratch candidate is retained in the conversation ZIP with its test and TAP log, not installed as an accepted module and not pushed as production.

## Existing documentation-only CI

Canonical push run 44734662656 on exact SHA a17514f75e928d8b1bef4592fd5e04f2fa3a4eff finished completed/success. Its two non-skipped jobs were verify and perl-stage01, both completed/success; their logs were read. It is *not* Stage21 Native acceptance; no duplicate dispatch performed.

## Decision and NEXT

Resource feasibility of exact [4×12] count has been demonstrated by two independently written Perl algorithms under the original 120s / 393216KiB process limits. Stage20 remains the accepted production domain 11/44. Stage21 status remains OPEN/READY, not ACCEPTED; no full-year generator proof.

NEXT: integrate the general mixed-radix algorithm in a stage21-specific production candidate only after running original Stage20 and legacy tests, prove first/middle/last ranking with independent small exhaustive profiles, validate >11-month/44-day bounds and error fixtures, then implement 208012-rank independent Catalan12 oracle shards with <=120s/393216KiB per shard and dedicated Stage21 canonical Native job. Acceptance remains subject to 22/22 mandatory completed/success jobs, inspected raw logs and verified seven-file artifact SHA256/CRC/source. No main/merge/release.

Local research archive: PC_BRANCH_PERL_GUOYU_STAGE21_DENSE_DISCOVERY_20261120.zip
Archive SHA256: a9a555d38162c9253954d18eb335d691744c37a1dbf95416c3916d68157e4dcd
