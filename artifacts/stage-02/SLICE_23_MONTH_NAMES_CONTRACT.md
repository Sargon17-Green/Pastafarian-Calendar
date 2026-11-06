# SQL+தமிழ் — Stage 2 Slice23: choose_month_names contract

**Date:** 2026-11-06. **Status:** CONTRACT ONLY; no Slice23 production or PostgreSQL test claimed.
**PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`; **work branch:** `SQL+தமிழ்`, not `main`.
**Prerequisite:** Slice22 ACCEPTED, tested source `91cb0e9ff837f8c823f7cdaa8a1992f09367f424`, PostgreSQL 17.11, 10/10 completed successful jobs, 59/59 Native + 8/8 isolation + 8/8 actual differential full-arrays, original ZIP SHA256/CRC 10/10 and generated 9/9. Acceptance: `artifacts/stage-02/POSTGRESQL_NATIVE_MONTH_WEAVING_42126854985.md`; run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42126854985 .
**Normative source lock:** `sql/test/10_normative_reference.sql` Git blob `ce17bf6fd166451b6904411c5e29d1b26d92e278`. Inspected `choose_month_names`, `falling_factorial`, `unrank_distinct_indices` and its invocation from `build_year_structure`. Production must not call or copy test-reference functions, helpers or fixtures.

## Public function and required behavior

Implement `pastafari_sql_tamil.choose_month_names(p_sauce pastafari_sql_tamil.sauce_result, p_k integer) RETURNS integer[]` with the same semantics as the normative function for reachable Stage2 inputs.

The output is an array of **k distinct indices** from `1..47`, selected in the lexicographic ascending order of all length-k sequences without repetition. In the normative function, the exact count is the falling factorial
`P(47,k)=47!/(47-k)!`; the 1-based selection rank is `choose_rank(ask_bowl(p_sauce,5,33),P(47,k))`.

Reachable month counts must derive from the already implemented `choose_month_count`, not from an invented k range. Validate the known upper bound `k<=47`; independently inspect the reachable minimum and full boundary before claiming an input range. Do not silently impose additional direct-call restrictions until differential checks against the normative implementation establish exact null/invalid semantics.

For `1<=k<=47` and legal sauce stream, output array length exactly k, all values unique and in `1..47`, deterministic across identical calls; no modulo-biased selection, float approximation or numeric rounding.

## Independent correctness argument and implementation plan

For the i-th position, `i=1..k`, with sorted remaining index set of size `47-i+1`, each candidate first index determines a block of `P(47-i,k-i)` suffixes. These blocks are disjoint, exhaustive and lexicographically ordered. For rank r initially in `1..P(47,k)`, choose zero-based candidate `q=floor((r-1)/block)`; remove that candidate from the set; update `r=(r-1) mod block + 1`. Prove the invariant `1<=r<=P(47-i,k-i)` and exact exhaustion after k choices. At k=47, largest rank has `47!` exact integer digits; use PostgreSQL `numeric` and exact `div` with integer multiplications. Avoid costly whole-permutation enumeration and persistent state. A loop over k positions with an array of 47 indices is sufficient.

Build the production SQL independently, under `sql/25_stage02_month_names.sql`, without reference-schema lookup or mutable memoization. Reuse already-accepted production `ask_bowl` and `choose_rank` only after verifying their current signatures and semantics. Any helper whose implementation is changed requires fresh source-locked evidence.

## QA and acceptance gates

1. **Independent oracle:** create a standalone new Slice23 Python oracle. Enumerate complete permutations directly using `itertools.permutations` for small source universes (e.g. n=3,4,5,6 and k=1..n), sort and check first/middle/last and every enumerated rank. The small enumerator must not implement production's block algorithm. For 47-index reachable cases, independently derive ≥50 preselected fixed full output arrays with a separate exact combinatorial model, selected before production evaluation. Include k=1, a reachable intermediate k, and the reachable upper boundary; test rank 1, middle, last and valid sauce stream cases. Preserve oracle provenance.
2. **Native PostgreSQL 17:** ≥50 independently generated full-array goldens in a new `sql/test/*_stage02_month_names_native.sql`, plus ≥20 other named gates (at least 70 named gates total) for input/shape/distinctness/rank/stream/repeatability and boundary. Check every `ok=t`, exact row count, all labels distinct, and an explicit final all-green marker; retain full `result.txt`.
3. **Isolation:** ≥5 assertions in a fresh database that loads production only. No normative test schema, no cross-call cache/registry, stable signature, strictness/null behavior according to tested reference, and repeatability. Distinguish production dependencies from the separate normative reference setup.
4. **Differential:** ≥8 real exact `integer[]` comparisons to `pastafari_sql_tamil_test.choose_month_names`, with ≥4 distinct reachable k values and two different sauce configurations per k. Compare complete arrays (`IS NOT DISTINCT FROM`), count/length, uniqueness and domain. Use a separate DB and do not treat scalar hash equality alone as an exact array comparison.
5. **Source-locked 15-minute CI:** new branch-only, exact-SHA GitHub workflow. Separate bounded Native/isolation/8 differential jobs; PostgreSQL 17 explicit version; `psql -v ON_ERROR_STOP=1`. Preserve original per-job ZIP with source SHA/version, test outputs, generated scripts and their SHA256; count gates from actual output. Do not rerun accepted Slice22 on its old SHA.
6. **Acceptance:** only after all jobs `completed/success` AND review of all original job logs, every original ZIP SHA256 checked against GitHub artifact digest and its upload-job digest, ZIP CRC, internal generated hashes, the complete 50+ golden arrays, explicit all-green, exact PG17 and tested SHA. No main/merge/publish.

## NEXT

Before implementation, inspect the Slice22-accepted branch HEAD and existing production names/stream/rank helper signatures; verify this reference blob and compute a bounded independent Python small-domain enumerator. Implement Slice23 SQL, Python oracle, Native, isolation, differential and workflow in branch-only source-locked commits. Inspect completed results rather than adopting queued/running as PASS. No standalone approval is required for routine engineering work.
