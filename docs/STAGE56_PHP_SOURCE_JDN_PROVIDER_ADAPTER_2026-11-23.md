# Stage56 PHP source-coordinate integration — 2026-11-23

PROJECT_ID: PC-BRANCH-PHP-MALAY

## Evidence before edit

- Branch HEAD `da227806b102f0ba4c3143ca6282d0af8f9968f8`. The exact automatic push run 45086780028
  completed FAILURE, 29/30 jobs success. Job 137407104498 failed.
- Artifact 14779921939: ZIP SHA-256
  `a58debe24be579ee4792afd1661e39bcf1e09cfc5fc141d6bb478407576bbd65`;
  47/47 ZIP entries pass CRC. Source-bound boundary `exit=0`,
  empty stderr, 12 fail-closed mutations, `PASS_BOUNDARY_ONLY`,
  `stage56_accepted=false`.
- The historical raw comparator remains MISMATCH for 4999/5000/5001;
  translated coordinate diagnostic matched 3/3. The full-year
  PHP provider was skipped. This cannot be treated as Stage56 acceptance.

## Narrow implementation contract

Input: authenticated, commit-pinned source JDN pair `(c,t)` at
`cc2cf0b422757a5e7c33218ce30cffa8f99c6786`, plus bowl, seal,
positive choice-count. Canonical year/gate records remain in source-JDN
coordinates.

Opt-in transformation *only at the bowl kernel boundary*:
`php_c = c - 1721425`; `php_t = t - 1721425`.
The existing `CanonicalJdnBoundary56::translatedPair` enforces source
identity and machine-integer bounds. Null opt-in leaves historical
`YearStructureProvider56` behavior unchanged. A mismatched candidate
source commit is rejected; output rank/trace use the translated kernel
stream, not a copied Python algorithm.

Fast QA: `tests/stage56_provider_coordinate_adapter.php` checks
4999/5000/5001, pinned response witnesses, direct translated-kernel
rank, original raw PHP behavior and invalid-source rejection.
It is regression/integration QA, **not** an independent oracle.

CI arrangement: keep the raw comparison failure as a genuine failed
step, then run the independent opt-in adapter microgate even when that
step fails; run bounded genuine-year profiles (900 s, 512 MiB per year)
only when the adapter microgate passed. Preserve evidence and leave
Stage56 unaccepted until completed job logs, actual-year outputs,
month lengths/weaving differential, rank/unrank and source provenance
are independently verified. No main/merge/publication.
