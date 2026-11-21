# Stage22 — isolated source-exact resource preflight and production candidate (2026-11-21)

PROJECT_ID: PC-BRANCH-PERL-GUOYU. Branch: Perl+國語. Baseline HEAD: 073ce4d33443df11dec0424de46644c93d2a9015. Previously accepted: Stage21 only. No main/merge/release/full-year acceptance.

## Source, test environment and independent oracle
* Exact Stage21 producer Git blob: 2a87cdca21914a2fd0d1704a0fc6b669c5674955, extracted and independently checked with git hash-object.
* Temporary guard-only 13/52 candidate Git blob: ca26f1b91a43a13879c10f7b641e9b7313e68fbe; changes only maximum 12→13 labels and 48→52 days.
* Candidate production implementation Git blob: 4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6; packed byte arena, explicit visited bit, no algorithmic count/transition change beyond memo representation and 13/52 guards.
* Local Perl 5.40.1 x86_64; source and test syntax OK; per-process RLIMIT_AS 393216 KiB and timeout 120 seconds, /usr/bin/time -v measured max RSS; exit and stderr captured separately.
* Independent lexical Dyck Catalan(13) cardinality 742900; full CSV+LF SHA256 67edb036b070b196c6b889b161a27baef6b0ec7852717586550ef2f8b4d7173d. Independent scratch Python reconstruction matched. This checks the 13x2 oracle, not the separate exact 13x4 count.

## Resource results

| Case | Exit | Elapsed s | Max RSS KiB | Perl stderr | Interpretation |
|---|---:|---:|---:|---|---|
| Source-exact guard-only 13x2 count + first/middle/last inverse | 0 each | 0.063–0.095 | 12544 | empty | 742900 and oracle sentinels PASS |
| Guard-only 13x1, 13x3, two heterogeneous profiles | 0 each | 0.060–0.411 | 12416–16512 | empty | bounded producer-only feasibility PASS |
| Guard-only 13x4 count | 1 | 44.561 | 388096 | Out of memory in perl:util:safesysrealloc | Resource FAIL; no computed result |
| Packed arena 13x4 count | 0 | 47.256 | 125184 | empty | 21604722570792867375065793772732 |
| Packed arena 13x4 first-rank inverse | 0 | 46.700 | 125184 | empty | rank 1 exact |
| Packed arena 13x4 middle-rank inverse | 0 | 94.487 | 125184 | empty | rank 10802361285396433687532896886366 exact |
| Packed arena 13x4 last-rank inverse | 0 | 98.689 | 125184 | empty | rank 21604722570792867375065793772732 exact |
| New Stage22 independent ballot smoke | 0 | bounded local | measured separately | empty | 61/61 TAP PASS |
| New Stage22 independent ordinal shard 0 | 0 | 57.52 | 49280 | no Perl errors | 46469/46469 TAP PASS, 23216 independent ordinal comparisons |

The 13x4 count is a producer output with inverse-rank consistency checks; it is NOT independently certified by a distinct 13x4 counting algorithm. Running all shards and mandatory jobs is reserved for canonical Native CI. Repeatedly running the resource-failing guard-only implementation is unjustified.

## Regression and Native gate
Updated legacy negative-profile fixtures that became valid when the producer domain expanded from 12/48 to 13/52. The separate MonthOccurrence 9/36 guard is not changed. Stage22 new TAP test has independent ballot-completion oracle, 32 deterministic shards and invalid-input/immutability tests. Canonical push CI has a dedicated Stage22 7-file evidence artifact (source.txt, perl-version.txt, syntax.stderr, test.stdout, test.stderr, test.exit, result.txt), per-process 120s / 393216KiB caps and all-shard checks.

Production is a candidate, not an accepted stage. A queued/running CI is not PASS. Require exact new SHA, completed mandatory jobs, raw logs, download+SHA256/ZIP CRC/source lock, and separate acceptance review before LAST_COMPLETED_STAGE may advance from 21 to 22. Full-year generator is unverified.
