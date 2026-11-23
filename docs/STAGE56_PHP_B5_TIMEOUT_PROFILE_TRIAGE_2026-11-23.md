# Stage56 PHP B5 — exact-SHA timeout triage and roundtrip timing contract (2026-11-23)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Authorized branch: `PHP+Bahasa-Melayu`
Evidence commit (before QA-only instrumentation): `fe8416e7769be5eaede899d6a226e67cd6a334b9`
Pinned canonical reference: `cc2cf0b422757a5e7c33218ce30cffa8f99c6786`
Source: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45133721102

## Completed evidence — not Stage56 acceptance

- Run 45133721102: completed/failure, 29/30 jobs successful, 1 failed (`external-reference-differential`, job 137554878836).
- Evidence artifact 14802010758, 70695 bytes, ZIP SHA-256 `3fba173f423a3f108b77bc0a9b5d5ddcc02c7ae9efaa846fd493affec9dcbcb3`; downloaded ZIP independently verified, 74/74 CRC good. SHA-256 equals GitHub artifact metadata and upload log.
- External semantic comparator: 271 tuples PASS for reference year 4999/5000/5001, not a PHP provider acceptance.
- Raw PHP sauce comparator remains genuine mismatch in all three years (`sauce-compare.exit=1`), with mismatch fields identified in retained JSON; do not relabel this as an expected-red PASS.
- Independent source-bound boundary: `PASS_BOUNDARY_ONLY`, 12 fail-closed mutations, `source-bound-boundary.exit=0`, empty stderr. PHP source-JDN adapter microgate: 13 checks over 3 years, step succeeded, empty stderr.
- Independent month-count/choice-stream trace: PASS for 4999=34 months/4126 days, 5000=45/4244, 5001=46/5567. This is **not** a complete month-length/weaving/rank differential.
- Genuine PHP profiles for **all** years exited 124 (900-second timeout); per-year stderr empty. No `PHP_REAL_YEAR_QA_PASS` and no Stage56 acceptance.

## Observed completed provider substages (seconds)

| year | month-length unrank | weaving count | weaving-choice | weaving unrank | what follows |
|---|---:|---:|---:|---:|---|
| 4999 | 14.533 | 136.486 | 15.170 | 323.696 | Provider completed; later independent count/rank/unrank not separately traced |
| 5000 | 54.838 | 174.927 | 17.217 | 588.231 | Provider completed; later independent count/rank/unrank not separately traced |
| 5001 | 54.489 | 390.777 | 27.530 | incomplete | Timed out in `month_weaving_unrank` |

Source: retained `stage56-php-real-evidence/<year>.json.profile.jsonl` in artifact 14802010758. No duration is imputed for an incomplete stage.

## Narrow QA-only code change

Only `tests/stage56_source_bound_php_year.php` changes; production algorithm, source input, oracle, selected SHA, count/rank/unrank calls and 900s/512MiB limits remain unchanged.

Before each of the three *post-provider* independent checks `roundtrip_count`, `roundtrip_rank`, `roundtrip_unrank`, append a JSONL `start` record with peak PHP memory. When each returns/throws, append an `end` record with monotonic elapsed seconds, peak memory, and success/error. On `timeout 900s`, the last unmatched `start` identifies the unfinished operation; this is **diagnostic only**, never PASS.

## Next gates

1. Verify automatic push run on the **new exact commit SHA** only after completed; do not duplicate-dispatch. Check changed-file syntax, logged step status and new artifact ZIP SHA-256/CRC/exits/stderr.
2. Use completed per-stage timing to design **one bounded source-preserving performance optimization** for PHP suffix-DP/count/rank/unrank, with independent small-domain oracle and fixed 512MiB memory/900s budget. Avoid changing calendar semantics or importing the independent Python reference.
3. Re-run three independent PHP actual-year profiles only on the changed implementation, requiring each `exit=0`, empty stderr, exact month count/length/weave differential, rank/unrank round trip, correct source provenance and resource bounds.
4. Preserve full Stage56 NOT ACCEPTED until all gates pass. No main/merge/PATCH22/PATCH23/publication.

This report is a completed independent artifact-and-profile audit plus a diagnostic test-only change, **not** a fix for the timeout.
