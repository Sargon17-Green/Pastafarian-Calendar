# SQL+தமிழ் — Stage 2 Slice 14 contract: bounded year-5000 integration

## Purpose

Integrate Slice 13's bounded candidate-pair enumerator with the real production gate-day window and the existing sauce-derived rank. This remains an intermediate year-selection primitive; it does not implement or accept the final five calendar components.

## Input and output

- Input: one integral PostgreSQL `numeric`, `p_calculation_day`.
- Output: `pastafari_sql_tamil.year_rec` with exactly five fields:
  `(year_number, open_gate_index, close_gate_index, open_gate_day, close_gate_day)`.
- `year_number` is 5000.
- Invalid fractional or NULL input yields NULL/no window; no implicit rounding.

## Candidate-window contract

Let `L = p_calculation_day - 5778` and `U = p_calculation_day + 5778`.

- First index: `lo = gate_index_at_or_before(L) - 1`.
- Last index: `hi = gate_index_at_or_after(U) + 1`.
- The helper returns every consecutive gate day for indices `lo..hi`, inclusive. Thus the window contains one sentinel gate strictly before L and one strictly after U.
- Adjacent gate gaps are integral and in [42,963], as established by Slice 11.
- Width is `U-L = 11556`. If i is the last gate at/before L and j the first at/after U, the gap bounds imply `12 <= j-i <= 277`; adding the two sentinels gives `15 <= hi-lo+1 <= 280`. Enforce this finite bound. Slice 13's generic array validator remains broader (7..320) for synthetic fixtures.
- The helper builds the array by one forward recursive gap walk after the lower sentinel, not by repeatedly recomputing each `gate_day(index)`.

## Candidate and selection contract

Call `year5000_gate_pairs(p_calculation_day, lo, gate_days)` from Slice 13. Candidate rows must satisfy:

- `open_gate_day < p_calculation_day <= close_gate_day`;
- `close_gate_index - open_gate_index >= 6`;
- `252 <= close_gate_day - open_gate_day <= 5778`;
- 1-based candidate rank ordered by `(close_gate_day-open_gate_day, open_gate_day)`.

Let N be the exact number of candidates. Derive the selected 1-based rank as:

`choose_rank(ask_bowl(sauce(p_calculation_day,p_calculation_day), 1, 10), N)`.

Return the unique candidate with that rank in `year_rec`. Production must not read, create, or call `pastafari_sql_tamil_test`, a cache, or a temporary reference table.

## Independent oracle and acceptance

- Native golden at the foundation day: `(5000,-4,4,-15057703,-15053459)`, previously fixed by the Stage 1 heavy reference gate.
- Differential oracle: `pastafari_sql_tamil_test.year5000` from `sql/test/10_normative_reference.sql`, in a separate differential database only. That reference independently uses its gate cache and direct nested candidate enumeration; production does not call it.
- Differential input days: foundation ±5778, foundation ±1, and foundation. Compare all five `year_rec` fields.
- Native assertions: 21, including sentinel/window bounds, 15..280 size, adjacent-gap integrity, candidate count/order, sauce-derived rank selection, invalid inputs, and unchanged five-field output type shapes.
- Isolation assertions: 4. Differential assertions: 25. Expected Stage 14 evidence total: 50/50 across the three gates, on one exact source SHA and completed PostgreSQL 17 run.

## Scope boundary

Slice 14 PASS would establish only the bounded year-5000 selection integration. It does not complete Stage 2, implement the year structure/cutlet/month selection, or prove `calendar_date_spaghetti` returns the final five calendar components. No main merge or publication is part of this contract.
