# Stage21 12-Month / 48-Day Resource Preflight — 2026-11-20

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Verified source branch HEAD (before this evidence-only commit): `a9d28ff3d41a4d6111aa478e7dbdf7cd97388fec`.
Exact Stage20 production `lib/Pastafari/Monster/WeavingPrimitive.pm` Git blob: `1ec5dc479b5a91df65bab83583d75ff05bfc59b7` (local Git hash-object matched fetched source).
Previous gate: Stage20 accepted by canonical run 44702256231; `LAST_COMPLETED_STAGE=20`. Stage21 is DISCOVERY only.

## Experiment and constraints

Local GNU/Linux Perl v5.40.1; each process separately bounded by `timeout -k 3s 120s` and `ulimit -v 393216` (KiB). Elapsed and maximum RSS from `/usr/bin/time`; stdout, stderr and exit recorded separately. The candidate was created in scratch, changing only `_counts` limits from 11/44 to 12/48. There was **no production code change**. MonthOccurrence domain remains unchanged.

| Profile | Count result | Count wall (s) | Count max RSS (KiB) | Rank-1 roundtrip |
|---|---:|---:|---:|---|
| [1×12] | 1 | 0.04 | 10496 | PASS, 0.05s |
| [2×12] | 208012 | 0.03 | 10624 | PASS, 0.03s |
| [3×12] | 13903319821066836 | 0.98 | 20992 | PASS, 0.97s |
| [37,1×11] | 1 | 0.03 | 10624 | PASS, 0.03s |
| [48] | 1 | 0.03 | 10624 | PASS, 0.03s |

All ten bounded light processes returned exit 0 and empty stderr. The [3×12] large count is an implementation result and roundtrip check, **not** independently verified by a large-count oracle.

Independent ordinal Dyck enumeration for [2×12] gave Catalan(12)=208012 and SHA-256 `0dbe36d23b6ffaa14822b1556d3eabc777d5961bdfd2fd79be39ee2daee76bbe`. Four independent first/middle/last sentinels at ranks 1, 104006, 104007 and 208012 matched both unrank and inverse rank against the scratch candidate; also matched the compact-memory candidate. This is not an exhaustive 208012-rank differential production test.

## Heavy 4×12 count: three bounded candidate variants

| Candidate | Scratch-only blob | Exit | Wall (s) | Max RSS (KiB) | Finding |
|---|---|---:|---:|---:|---|
| Bounds-only | `ad83c07cc2507429f30c6f51f6f80da0a50c7bc3` | 1 | 42.36 | 388224 | `Out of memory in perl:util:safesysmalloc` |
| `pack('C*',…)` memo key | `2790770bd480120c4b4325b4272a13b50e1a525c` | 1 | 40.33 | 388352 | Same OOM |
| Packed key + decimal-string memo values + omit caching single-choice states | `46a81fc12a2c11b831f2e6f92be59d0893cd5919` | 124 | 120.01 | 230528 | Timeout; no count |

The second variant substituted a compact fixed-width binary memo key for the comma-separated string. The third also cached decimal representations of Math::BigInt results and bypassed memoization of deterministic single-choice states. All were exploratory; none was committed as production.

**Interpretation:** First and second variants reproduced a resource failure under the VM cap; the third reduced peak RSS but did not meet the 120-second limit. No exact 4×12 result was produced. This is a measured resource feasibility failure, **not evidence of a mathematical defect or expected-red**. Rank1 for [4×12] was not repeated after the required count prerequisite failed; no assertion of rank1 PASS.

## Decision / NEXT

Keep production at accepted Stage20 (11 months / 44 days). Keep Stage21 DISCOVERY open and READY, no Native or full-year PASS, no main/merge/release. Next: design a substantially faster and memory-bounded exact counting/ranking DP for 12×4; preflight count and rank1 independently at <=120s and <=393216KiB VSZ; preserve an independent oracle and only then consider 12/48 production bounds, exhaustive 208012-rank shards, canonical Stage21 job and acceptance.

Reproduction: start from exact source blob, make a scratch-only 11→12 / 44→48 bounds patch, execute each profile in a separate Perl process under the above timeout and ulimit, and record stdout/stderr/exit/time. The numerical experiment results are recorded in `qa/perl-guoyu/stage21_resource_preflight_2026-11-20.json`.
