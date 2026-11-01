# SQL+தமிழ் — Stage 2 Slice 16 contract: bounded target-year traversal

## Preconditions and scope

- Prerequisite: Slice 14 accepted (52/52); Slice 15 accepted (44/44, workflow 41245801827, source `be0cf1983e8dd4037ba3d35a8e20fc1030ef3722`).
- Implement `pastafari_sql_tamil.find_target_year(p_calculation_day numeric, p_target_day numeric) RETURNS pastafari_sql_tamil.year_rec`.
- Return the unique year containing the target day in the half-open interval `open_gate_day < target <= close_gate_day`. The return type has exactly the five normative year fields.
- The calculation day is fixed throughout the traversal. Derive seed exactly once with production `year5000(calculation_day)`; advance only by production `next_year` or `previous_year`, chosen from target relative to current boundary. Reference function `pastafari_sql_tamil_test.find_target_year` is an independent unbounded differential oracle and must never be loaded in production-only tests.
- This slice does not compute cutlets, months, or final five-component calendar output.

## Input validation and explicit out-of-range result

- `NULL` inputs: SQL `STRICT` behavior returns SQL NULL.
- Both inputs must be exact integral NUMERIC values; fractions are rejected without rounding.
- Supported domain: `abs(p_target_day-p_calculation_day) <= 60000` days (inclusive). Outside the domain, return SQL NULL without attempting `year5000` or recursive search; this is an explicit *unsupported-target* result, not a claim that the date has no year. Invalid non-integral input also returns SQL NULL.
- If the seed is NULL, any transition is NULL, or no containing year is found inside the budget, return SQL NULL (fail closed). No silent nearest-year result.
- Signed days/indices across zero are valid. Exact close boundary belongs to the year that closes there; exact open boundary belongs to the preceding year.

## Finite-cost traversal

Let `delta = abs(target - calculation)` and `B = least(256, ceil(delta/252) + 1)` (integer, and only calculated after domain checks). Include the seed at `step=0`; allow at most `B` adjacent-year moves. Stop recursion as soon as the year contains the target.

Proof of sufficiency in supported domain: the `year5000` seed contains the calculation day; every valid adjacent-year record spans at least 252 days and all open/close bounds are monotonic in its travel direction. After `k` forward transitions, the close day has advanced at least `252k` beyond the seed close; backward, the open day decreases by at least `252k`. Because the lower bound of a year is strict, a one-step margin covers equality on an open boundary. Thus at most `ceil(delta/252)+1` moves suffice. At `delta=60000`, `B = 240` (under the fixed absolute guard of 256).

Each Slice15 transition itself has an independently proven maximum gate window of 139 directional gates, so the worst-case traversal comprises at most 240 transitions and at most 33,360 inspected gate positions. The bound is a resource contract, not a performance guarantee; measure elapsed time before considering any increase in domain.

## Algorithm, oracle, and acceptance

- Production SQL: `LANGUAGE SQL STABLE STRICT`, one `WITH RECURSIVE` walk with explicit step limit. No procedural looping, cache, mutable table, dynamic SQL, or production dependency on `pastafari_sql_tamil_test`.
- Native checks: seed/current year, single forward, single backward, exact open/close boundaries, zero-index crossing, strict-NULL, invalid fractional inputs and out-of-range (60001) short circuit, five integral fields, exact step-budget derivation, and no unexpected output when inputs invalid.
- Differential: compare all five fields to the independent `pastafari_sql_tamil_test.find_target_year` on valid, bounded samples (same-year, next-year, previous-year, cross-zero and boundary directions); do **not** run the unbounded oracle for out-of-range inputs. Use isolated PostgreSQL 17 databases.
- Isolation: production-only schema, `find_target_year` is SQL/STABLE, no reference/test schema in `pg_get_functiondef`, no unwanted mutable production objects.
- Acceptance only on the exact source SHA when Native, isolation and Differential jobs are `completed/success`, logs show assertion counts, and artifact digests are verified. CI `queued`/`in_progress` cannot be PASS.
- No main merge, publication or assumption of Stage2-wide success.

## Engineering tradeoff

A 60,000-day input domain is deliberate to make the recursive work finite and auditable. It is **not** a normative calendar limit; wider target dates need a separate future performance/contract decision, not a silent removal of the guard.
