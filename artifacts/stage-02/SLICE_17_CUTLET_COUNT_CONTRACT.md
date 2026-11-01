# SQL+தமிழ் — Stage 2 Slice 17: cutlet-count selector contract

## Dependency and scope

- Prerequisite is Slice 16 acceptance, PostgreSQL 17.11 run 41283131434, 27/27 (18 Native, 4 isolation, 5 differential), accepted source `d6c0c3e05d371c5d04a8ef300149da8bf06fc07d`, permanent report `artifacts/stage-02/POSTGRESQL_NATIVE_TARGET_YEAR_41283131434.md`.
- Next normative function in existing same-branch `sql/test/10_normative_reference.sql` at `choose_cutlet_count` (immediately after `find_target_year`).
- Implement `pastafari_sql_tamil.choose_cutlet_count(p_sauce pastafari_sql_tamil.sauce_result, p_year pastafari_sql_tamil.year_rec) RETURNS integer`. Output only the cutlet count. Do not introduce a sixth date component or claim the final five-component calendar exists.
- Source prerequisites: `sql/10_stage02_sauce.sql` defines `sauce_result`; `sql/11_stage02_answer_stream.sql` defines `ask_bowl`; `sql/12_stage02_choose_rank.sql` defines `choose_rank`; `sql/16_stage02_year5000.sql` defines `year_rec`. Production must never load or reference `pastafari_sql_tamil_test`.

## Normative arithmetic / output contract

Let `g = close_gate_index - open_gate_index`, computed with exact PostgreSQL NUMERIC (not float). For supported valid-year inputs require both indices integral and `g >= 6`. Let `n = min(17, g) - 5`, hence `1 <= n <= 12`. Derive the input stream by querying **bowl 2, seal 20**:
`s = ask_bowl(p_sauce, 2, 20)`.
Compute `r = choose_rank(s, n)`, then output `5 + r` as integer.

On valid input `1 <= r <= n`, so `6 <= output <= 17`. For `g > 17` the rank-space saturates at 12; do not increase it with `g`. This follows the existing same-branch normative formula `greatest(0,least(17,g)-5)`; narrowing the accepted domain to `g >= 6` avoids the reference's undefined rank at `n=0`. No change to the normative function.

SQL NULL for NULL arguments (`STRICT`), fractional or reversed/out-of-domain indices, invalid sauce permutation/bowls, or a NULL child computation. Invalid-record behavior is an explicit safe production guard; do not claim the reference oracle specifies results on malformed inputs.

The production implementation is pure, immutable, no cache/table mutation, exact integer arithmetic and explicit validation of parent records. No reliance on precomputed cutlet partitions or future Slice 18 artifacts.

## QA: precise bounded gates

- Native fixture set: one valid `sauce_result` with 1-based, length-6, distinct order 1..6 and integral, positive in-SAVE bowls. Use controlled year-record indices with `g=6,7,17,18` to test rank-space sizes 1,2,12,12, including the 17→18 saturation invariant; cross-zero year indices also tested.
- Positive assertions must compare against a separately computed oracle expression using `ask_bowl` and `choose_rank`, rather than merely checking non-null. Compare bounds `6 <= count <= min(17,g)`, deterministic repeat, and sensitivity to permuted bowl order when the oracle calls for it.
- Negative cases: NULL sauce/year, fractional gate indices, inverted or `g<6` year records, invalid bowl vector, invalid permutation; all must fail closed. No use of `pastafari_sql_tamil_test` in Native.
- Differential independently evaluate at least four valid same-domain cases against `pastafari_sql_tamil_test.choose_cutlet_count`, using an explicit field-by-field `sauce_result`/year conversion only for the oracle input, never shared production source or duplicated expected constants. Separate production-only and reference-loaded PostgreSQL 17 databases. Oracle must be loaded from the historical reference file without edits.
- Isolation: at least four explicit checks: production-only schema loads, function exists, `pg_get_functiondef` contains no test-schema or mutable table dependency, and volatility/strictness are correct.
- CI must log exact Native, isolation and differential counts, exact source SHA, all job conclusions and per-job ZIP SHA-256; uploads must preserve SQL fixture and PostgreSQL version. Require ZIP CRC and independent digest verification before Slice17 PASS.
- Native and differential CI must be bounded; do not expand beyond four comparison cases without performance evidence.
- Scope of this contract is Slice 17 only; output function is **not** a full date, cutlet partition, month or five-component result.

## Implementation order

1. Write production `sql/19_stage02_cutlet_count.sql` and narrowly bounded unit fixtures.
2. Add a dedicated PostgreSQL 17 Native/differential workflow with correct `SQL\\+தமிழ்` branch filter and immutable expected counters. Do not rerun Slice 16.
3. Read back every source blob; inspect the triggered run's exact source SHA; repair only observed failures; accept only after completed log+ZIP evidence.
4. Commit a permanent Slice17 report, then plan the independently contracted cutlet partition selector (the next reference function) without copying a foreign-branch algorithm.

No main/merge/publication, no assumed Stage2-wide PASS.
