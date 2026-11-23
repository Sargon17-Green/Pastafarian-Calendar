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

## 2026-11-23 — completed new-SHA artifact and QA typed-closure repair

- Run [45254801425](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45254801425) on exact commit `50d73e398731d09b9de2d54ae5c43f7a56f2df38`: **completed/failure**, 29/30 jobs successful; only `external-reference-differential` job [137973686256](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45254801425/job/137973686256) failed. This is not Stage56 acceptance.
- Exact artifact [14862000606](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45254801425/artifacts/14862000606): ZIP **71,158 bytes**, SHA-256 `232e09709e5cff0b28f8615fd2d6f35dd51a1dfe8468119aff036bf4111dba18`; downloaded and verified **74/74 ZIP CRC**. The digest matches the artifact upload log. The artifact identifies this branch SHA and pinned independent source `cc2cf0b422757a5e7c33218ce30cffa8f99c6786`.
- Genuine PHP profile exit codes: year 4999 **2**, year 5000 **2**, year 5001 **124**. Year 4999 `roundtrip_count` duration **92.263287822 s**, and year 5000 **118.933870072 s**, both ended `status:error` specifically because unqualified `BigInt` in the QA-only typed closure resolved outside the actual `Pastafari\\Stage01\\BigInt` namespace. Year 5001 timed out at **900 s** in provider `month_weaving_unrank` before independent roundtrip; no completion is inferred. 4999/5000 stderr is nonempty and contains the type error; 5001 stderr is empty.
- Source-boundary gate remains **PASS_BOUNDARY_ONLY** with 12 negative mutations; independent month-count choice stream matches pinned source for 4999/5000/5001 (34/45/46 months). External Python/Scroll/JS semantic tuple gate passes 271 samples but is not PHP provider parity. Raw PHP sauce comparator remains a **genuine MISMATCH 3/3**, `sauce-compare.exit=1`; the adapted coordinate diagnostic being equal does not waive the raw mismatch.
- QA-only repair at [`dad072d2af261ef1a17e5e61f734473e96cfa345`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/dad072d2af261ef1a17e5e61f734473e96cfa345): replace **only two** measured PHP return type annotations with fully qualified `\\Pastafari\\Stage01\\BigInt`. The returning ranker declares this exact class in `src/Patches/MonthWeavingRanker56.php`. No source pin, algorithm, profile limit, rank sequence, branch protection, or production class was modified.
- Isolated local PHP 8.4.24 typed-closure namespace smoke and lint passed using a stand-in class; this is **not** the actual PHP provider, not CI, not Native year profiling, and not Stage56 acceptance. The code-commit branch HEAD and both new closures were read back from GitHub before appending this report.

**NEXT:** Examine the automatically triggered exact-SHA CI results, if and only if completed; do not dispatch duplicate runs. Preserve the raw comparator failure and year 5001 timeout as open. Derive one bounded 512 MiB/900 s source-preserving suffix-DP performance optimization with independent small-domain oracle before claiming a real-year B5 pass. Require all three PHP years to exit 0, stderr empty, full month/weave differential and rank/unrank roundtrip; Stage56 **NOT ACCEPTED**. No main/merge/PATCH22/PATCH23/publication.
