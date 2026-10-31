# SQL+தமிழ் — Stage 2 Slice 15 contract: adjacent year navigation

## Purpose

After Slice 14's bounded year-5000 selector is accepted, implement the two adjacent-year transitions used by the normative reference: `next_year` and `previous_year`. Keep target-year traversal as a separate later unit so its potentially large number of year steps has its own explicit cost and stopping contract.

## Inputs and outputs

- `next_year(p_calculation_day numeric, p_known year_rec)` returns one `year_rec` with year number `known.year_number + 1`.
- `previous_year(p_calculation_day numeric, p_known year_rec)` returns one `year_rec` with year number `known.year_number - 1`.
- The known year is the five-field record returned by `year5000` or a validated adjacent-year transition. Reject malformed records (fractional indices/days/year number, non-increasing day bounds, index distance below 6, or day duration outside 252..5778); do not round.
- Every returned record preserves the exact five-field `year_rec` shape.

## Forward transition

Given known close gate `(i,d)`:

- Candidate close indices begin at `i+1` and end at `gate_index_at_or_after(d+5778)+1`.
- Candidate pair is `(i,j)`, with `j-i >= 6` and `252 <= gate_day(j)-d <= 5778`.
- Candidate order is `(gate_day(j)-d, j)`, ascending.
- The rank is `choose_rank(ask_bowl(sauce(p_calculation_day,d),1,11), N)`, where N is the exact candidate count.
- Output is `(known.year_number+1, i, selected_j, d, gate_day(selected_j))`.

## Backward transition

Given known open gate `(i,d)):

- Candidate open indices descend from `i-1` through `gate_index_at_or_before(d-5778)-1`.
- Candidate pair is `(j,i)`, with `i-j >= 6` and `252 <= d-gate_day(j) <= 5778`.
- Candidate order is `(d-gate_day(j), j DESC)`, matching the normative reference's `ORDER BY len, oi DESC`.
- The rank is `choose_rank(ask_bowl(sauce(p_calculation_day,d),1,12), N)`, where N is the exact candidate count.
- Output is `(known.year_number-1, selected_j, i, gate_day(selected_j), d)`.

## Boundedness

- Both transitions search a one-sided 5778-day window, not an unbounded series.
- With every adjacent gate gap in [42,963], the first gate at/after the forward upper bound is at most 138 indices beyond the known close gate; including the extra upper sentinel yields at most 139 candidate close indices.
- The backward side has the symmetric bound: at most 139 candidate open indices.
- Use one directional recursive gate walk from the known boundary to avoid recomputing `gate_day(index)` independently for every candidate.
- No cache, mutable table, dynamic SQL, or test/reference schema in production.

## Oracle and QA

- Differential oracle: `pastafari_sql_tamil_test.next_year` and `previous_year` from `sql/test/10_normative_reference.sql`, loaded only in a separate differential database.
- Native tests must include a fixed year-5000 foundation record, exact forward and backward selected records, candidate counts/rank boundaries, minimum/maximum gap lengths, invalid/malformed records, and unchanged `calendar_result` five-field shape.
- Differential tests must compare all five fields for forward and backward transitions from at least the foundation year and a year whose open/close indices cross index zero.
- Acceptance requires completed PostgreSQL 17 Native, production-only isolation, and independent Differential evidence on the exact source SHA. A queued/in-progress run is not PASS.

## Scope boundary

Slice 15 accepts only adjacent-year transitions. It does not implement the recursive `find_target_year` search or final `calendar_date_spaghetti` output. The following Slice 16 must specify a finite traversal budget and explicit out-of-range behavior before implementing `find_target_year`.
