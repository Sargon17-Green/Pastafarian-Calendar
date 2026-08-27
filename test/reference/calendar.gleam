import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import pastafari/source_language_catalog
import reference/core
import reference/sauce

pub type GateState {
  GateState(values: Dict(Int, Int), min_index: Int, max_index: Int)
}

pub type Year {
  Year(
    number: Int,
    open_gate_index: Int,
    close_gate_index: Int,
    open_gate_day: Int,
    close_gate_day: Int,
  )
}

pub type YearCandidate {
  YearCandidate(open_index: Int, close_index: Int, length: Int)
}

pub type Cutlet {
  Cutlet(
    name_index: Int,
    open_gate_index: Int,
    close_gate_index: Int,
    first_day: Int,
    last_day: Int,
  )
}

pub type YearStructure {
  YearStructure(
    year: Year,
    cutlet_count: Int,
    cutlet_partition: List(Int),
    cutlet_name_indices: List(Int),
    cutlets: List(Cutlet),
    month_count: Int,
    month_lengths: List(Int),
    month_weaving: List(Int),
    month_name_indices: List(Int),
  )
}

pub type CalendarDate {
  CalendarDate(
    year_number: Int,
    cutlet_name: String,
    day_in_cutlet: Int,
    month_name: String,
    day_in_month: Int,
  )
}

pub fn new_gate_state() -> GateState {
  GateState(
    values: dict.new() |> dict.insert(0, core.foundation_day),
    min_index: 0,
    max_index: 0,
  )
}

pub fn gate_value(state: GateState, index: Int) -> Int {
  let assert Ok(value) = dict.get(state.values, index)
  value
}

fn positive_gate_gap(n: Int) -> Int {
  let result = sauce.sauce(core.foundation_day, core.foundation_day + n)
  let stream = sauce.ask_bowl(result, 1, core.seal_gate_gap)
  41 + sauce.choose_rank(stream, 922)
}

fn negative_gate_gap(n: Int) -> Int {
  let result = sauce.sauce(core.foundation_day, core.foundation_day - n)
  let stream = sauce.ask_bowl(result, 1, core.seal_gate_gap)
  41 + sauce.choose_rank(stream, 922)
}

pub fn ensure_gate_index(state: GateState, index: Int) -> GateState {
  case index > state.max_index {
    True -> {
      ensure_forward(state, state.max_index + 1, index)
    }
    False ->
      case index < state.min_index {
        True -> {
          ensure_backward(state, state.min_index - 1, index)
        }
        False -> {
          state
        }
      }
  }
}

fn ensure_forward(state: GateState, next_index: Int, wanted: Int) -> GateState {
  case next_index > wanted {
    True -> {
      state
    }
    False -> {
      let previous = gate_value(state, next_index - 1)
      let value = previous + positive_gate_gap(next_index)
      let next_state =
        GateState(
          ..state,
          values: dict.insert(state.values, next_index, value),
          max_index: next_index,
        )
      ensure_forward(next_state, next_index + 1, wanted)
    }
  }
}

fn ensure_backward(
  state: GateState,
  next_index: Int,
  wanted: Int,
) -> GateState {
  case next_index < wanted {
    True -> {
      state
    }
    False -> {
      let later = gate_value(state, next_index + 1)
      let value = later - negative_gate_gap(core.abs_int(next_index))
      let next_state =
        GateState(
          ..state,
          values: dict.insert(state.values, next_index, value),
          min_index: next_index,
        )
      ensure_backward(next_state, next_index - 1, wanted)
    }
  }
}

pub fn ensure_gates_cover(
  state: GateState,
  low_day: Int,
  high_day: Int,
) -> GateState {
  let low_gate = gate_value(state, state.min_index)
  let high_gate = gate_value(state, state.max_index)
  case low_gate > low_day {
    True -> {
      ensure_gates_cover(
        ensure_gate_index(state, state.min_index - 1),
        low_day,
        high_day,
      )
    }
    False ->
      case high_gate < high_day {
        True -> {
          ensure_gates_cover(
            ensure_gate_index(state, state.max_index + 1),
            low_day,
            high_day,
          )
        }
        False -> {
          state
        }
      }
  }
}

pub fn gate_index_at_or_before(
  state: GateState,
  day: Int,
) -> #(Int, GateState) {
  let covered = ensure_gates_cover(state, day, day)
  #(
    binary_gate_before(covered, day, covered.min_index, covered.max_index),
    covered,
  )
}

fn binary_gate_before(state: GateState, day: Int, low: Int, high: Int) -> Int {
  case low >= high {
    True -> {
      low
    }
    False -> {
      let mid = low + core.floor_div(high - low + 1, 2)
      case gate_value(state, mid) <= day {
        True -> {
          binary_gate_before(state, day, mid, high)
        }
        False -> {
          binary_gate_before(state, day, low, mid - 1)
        }
      }
    }
  }
}

pub fn gate_index_at_or_after(state: GateState, day: Int) -> #(Int, GateState) {
  let #(before, covered) = gate_index_at_or_before(state, day)
  case gate_value(covered, before) == day {
    True -> {
      #(before, covered)
    }
    False -> {
      let next = ensure_gate_index(covered, before + 1)
      #(before + 1, next)
    }
  }
}

pub fn exact_gate_index(
  state: GateState,
  day: Int,
) -> #(Option(Int), GateState) {
  let #(before, covered) = gate_index_at_or_before(state, day)
  case gate_value(covered, before) == day {
    True -> {
      #(Some(before), covered)
    }
    False -> {
      #(None, covered)
    }
  }
}

fn valid_year_pair(
  state: GateState,
  open_index: Int,
  close_index: Int,
) -> Bool {
  let gaps = close_index - open_index
  let length = gate_value(state, close_index) - gate_value(state, open_index)
  gaps >= core.min_gate_gaps_per_year
  && length >= core.year_min_days
  && length <= core.year_max_days
}

pub fn year_5000(calculation_day: Int, state: GateState) -> #(Year, GateState) {
  let covered =
    ensure_gates_cover(
      state,
      calculation_day - core.year_max_days,
      calculation_day + core.year_max_days,
    )
  let candidates =
    collect_anchor_candidates(
      covered,
      calculation_day,
      covered.min_index,
      covered.max_index,
      [],
    )
  let sorted = sort_anchor_candidates(candidates, covered, [])
  let result = sauce.sauce(calculation_day, calculation_day)
  let stream = sauce.ask_bowl(result, 1, core.seal_year_5000)
  let rank = sauce.choose_rank(stream, list.length(sorted))
  let chosen = core.at1(sorted, rank)
  #(
    Year(
      number: 5000,
      open_gate_index: chosen.open_index,
      close_gate_index: chosen.close_index,
      open_gate_day: gate_value(covered, chosen.open_index),
      close_gate_day: gate_value(covered, chosen.close_index),
    ),
    covered,
  )
}

fn collect_anchor_candidates(
  state: GateState,
  calculation_day: Int,
  open_index: Int,
  max_index: Int,
  acc: List(YearCandidate),
) -> List(YearCandidate) {
  case open_index >= max_index {
    True -> {
      acc
    }
    False -> {
      let with_open =
        collect_anchor_closes(
          state,
          calculation_day,
          open_index,
          open_index + 1,
          max_index,
          acc,
        )
      collect_anchor_candidates(
        state,
        calculation_day,
        open_index + 1,
        max_index,
        with_open,
      )
    }
  }
}

fn collect_anchor_closes(
  state: GateState,
  calculation_day: Int,
  open_index: Int,
  close_index: Int,
  max_index: Int,
  acc: List(YearCandidate),
) -> List(YearCandidate) {
  case close_index > max_index {
    True -> {
      acc
    }
    False -> {
      let length =
        gate_value(state, close_index) - gate_value(state, open_index)
      let accepted =
        valid_year_pair(state, open_index, close_index)
        && gate_value(state, open_index) < calculation_day
        && calculation_day <= gate_value(state, close_index)
      let next_acc = case accepted {
        True -> {
          [
            YearCandidate(
              open_index: open_index,
              close_index: close_index,
              length: length,
            ),
            ..acc
          ]
        }
        False -> {
          acc
        }
      }
      collect_anchor_closes(
        state,
        calculation_day,
        open_index,
        close_index + 1,
        max_index,
        next_acc,
      )
    }
  }
}

fn sort_anchor_candidates(
  items: List(YearCandidate),
  state: GateState,
  sorted: List(YearCandidate),
) -> List(YearCandidate) {
  case items {
    [] -> sorted
    [head, ..tail] ->
      sort_anchor_candidates(tail, state, insert_anchor(head, sorted, state))
  }
}

fn insert_anchor(
  candidate: YearCandidate,
  sorted: List(YearCandidate),
  state: GateState,
) -> List(YearCandidate) {
  case sorted {
    [] -> [candidate]
    [head, ..tail] -> {
      let candidate_open = gate_value(state, candidate.open_index)
      let head_open = gate_value(state, head.open_index)
      let comes_first =
        candidate.length < head.length
        || { candidate.length == head.length && candidate_open < head_open }
      case comes_first {
        True -> {
          [candidate, ..sorted]
        }
        False -> {
          [head, ..insert_anchor(candidate, tail, state)]
        }
      }
    }
  }
}

pub fn next_year(
  calculation_day: Int,
  known: Year,
  state: GateState,
) -> #(Year, GateState) {
  let open_index = known.close_gate_index
  let open_day = gate_value(state, open_index)
  let covered =
    ensure_gates_cover(
      state,
      open_day,
      open_day + core.year_max_days + core.gate_gap_max,
    )
  let candidates =
    collect_next_candidates(covered, open_index, open_index + 1, [])
    |> list.reverse
  let sorted = sort_length_stable(candidates, [])
  let result = sauce.sauce(calculation_day, open_day)
  let stream = sauce.ask_bowl(result, 1, core.seal_next_year)
  let rank = sauce.choose_rank(stream, list.length(sorted))
  let chosen = core.at1(sorted, rank)
  #(
    Year(
      number: known.number + 1,
      open_gate_index: open_index,
      close_gate_index: chosen.close_index,
      open_gate_day: open_day,
      close_gate_day: gate_value(covered, chosen.close_index),
    ),
    covered,
  )
}

fn collect_next_candidates(
  state: GateState,
  open_index: Int,
  close_index: Int,
  acc: List(YearCandidate),
) -> List(YearCandidate) {
  let length = gate_value(state, close_index) - gate_value(state, open_index)
  case length > core.year_max_days {
    True -> {
      acc
    }
    False -> {
      let next_acc = case valid_year_pair(state, open_index, close_index) {
        True -> {
          [
            YearCandidate(
              open_index: open_index,
              close_index: close_index,
              length: length,
            ),
            ..acc
          ]
        }
        False -> {
          acc
        }
      }
      collect_next_candidates(state, open_index, close_index + 1, next_acc)
    }
  }
}

pub fn previous_year(
  calculation_day: Int,
  known: Year,
  state: GateState,
) -> #(Year, GateState) {
  let close_index = known.open_gate_index
  let close_day = gate_value(state, close_index)
  let covered =
    ensure_gates_cover(
      state,
      close_day - core.year_max_days - core.gate_gap_max,
      close_day,
    )
  let candidates =
    collect_previous_candidates(covered, close_index, close_index - 1, [])
    |> list.reverse
  let sorted = sort_length_stable(candidates, [])
  let result = sauce.sauce(calculation_day, close_day)
  let stream = sauce.ask_bowl(result, 1, core.seal_previous_year)
  let rank = sauce.choose_rank(stream, list.length(sorted))
  let chosen = core.at1(sorted, rank)
  #(
    Year(
      number: known.number - 1,
      open_gate_index: chosen.open_index,
      close_gate_index: close_index,
      open_gate_day: gate_value(covered, chosen.open_index),
      close_gate_day: close_day,
    ),
    covered,
  )
}

fn collect_previous_candidates(
  state: GateState,
  close_index: Int,
  open_index: Int,
  acc: List(YearCandidate),
) -> List(YearCandidate) {
  let length = gate_value(state, close_index) - gate_value(state, open_index)
  case length > core.year_max_days {
    True -> {
      acc
    }
    False -> {
      let next_acc = case valid_year_pair(state, open_index, close_index) {
        True -> {
          [
            YearCandidate(
              open_index: open_index,
              close_index: close_index,
              length: length,
            ),
            ..acc
          ]
        }
        False -> {
          acc
        }
      }
      collect_previous_candidates(state, close_index, open_index - 1, next_acc)
    }
  }
}

fn sort_length_stable(
  items: List(YearCandidate),
  sorted: List(YearCandidate),
) -> List(YearCandidate) {
  case items {
    [] -> sorted
    [head, ..tail] ->
      sort_length_stable(tail, insert_length_stable(head, sorted))
  }
}

fn insert_length_stable(
  candidate: YearCandidate,
  sorted: List(YearCandidate),
) -> List(YearCandidate) {
  case sorted {
    [] -> [candidate]
    [head, ..tail] ->
      case candidate.length < head.length {
        True -> {
          [candidate, ..sorted]
        }
        False -> {
          [head, ..insert_length_stable(candidate, tail)]
        }
      }
  }
}

pub fn find_target_year(
  calculation_day: Int,
  target_day: Int,
  state: GateState,
) -> #(Year, GateState) {
  let #(anchor, after_anchor) = year_5000(calculation_day, state)
  walk_year(calculation_day, target_day, anchor, after_anchor)
}

fn walk_year(
  calculation_day: Int,
  target_day: Int,
  year: Year,
  state: GateState,
) -> #(Year, GateState) {
  case target_day > year.close_gate_day {
    True -> {
      let #(next, next_state) = next_year(calculation_day, year, state)
      walk_year(calculation_day, target_day, next, next_state)
    }
    False ->
      case target_day <= year.open_gate_day {
        True -> {
          let #(previous, next_state) =
            previous_year(calculation_day, year, state)
          walk_year(calculation_day, target_day, previous, next_state)
        }
        False -> {
          #(year, state)
        }
      }
  }
}

pub fn unrank_distinct_indices(
  master_count: Int,
  k: Int,
  rank1: Int,
) -> List(Int) {
  unrank_distinct_loop(core.range_inclusive(1, master_count), k, rank1, 1, [])
  |> list.reverse
}

fn unrank_distinct_loop(
  remaining: List(Int),
  k: Int,
  rank: Int,
  position: Int,
  acc: List(Int),
) -> List(Int) {
  case position > k {
    True -> {
      acc
    }
    False -> {
      let suffix_length = k - position
      let block =
        core.falling_factorial(list.length(remaining) - 1, suffix_length)
      let #(chosen_position, next_rank) = choose_block_position(rank, block, 1)
      let chosen = core.at1(remaining, chosen_position)
      unrank_distinct_loop(
        core.remove_at1(remaining, chosen_position),
        k,
        next_rank,
        position + 1,
        [chosen, ..acc],
      )
    }
  }
}

fn choose_block_position(rank: Int, block: Int, position: Int) -> #(Int, Int) {
  case rank > block {
    True -> {
      choose_block_position(rank - block, block, position + 1)
    }
    False -> {
      #(position, rank)
    }
  }
}

fn choose_cutlet_count(structure_sauce: core.SauceResult, year: Year) -> Int {
  let gate_gaps = year.close_gate_index - year.open_gate_index
  let candidates =
    core.range_inclusive(core.min_cutlets, core.max_cutlets)
    |> list.filter(fn(k) { k <= gate_gaps })
  let stream = sauce.ask_bowl(structure_sauce, 2, core.seal_cutlet_count)
  core.at1(candidates, sauce.choose_rank(stream, list.length(candidates)))
}

type CutletMemoKey =
  #(Int, Int, Int, Bool)

fn count_cutlet_partitions(
  rem: Int,
  slots: Int,
  cumulative: Int,
  hit: Bool,
  required: Option(Int),
  memo: Dict(CutletMemoKey, Int),
) -> #(Int, Dict(CutletMemoKey, Int)) {
  case slots == 0 {
    True -> {
      let value = case rem != 0 {
        True -> {
          0
        }
        False -> {
          case required {
            None -> 1
            Some(_) ->
              case hit {
                True -> {
                  1
                }
                False -> {
                  0
                }
              }
          }
        }
      }
      #(value, memo)
    }
    False ->
      case rem < slots {
        True -> {
          #(0, memo)
        }
        False -> {
          let key = #(rem, slots, cumulative, hit)
          case dict.get(memo, key) {
            Ok(value) -> #(value, memo)
            Error(_) ->
              count_cutlet_choices(
                1,
                rem - { slots - 1 },
                rem,
                slots,
                cumulative,
                hit,
                required,
                memo,
                0,
                key,
              )
          }
        }
      }
  }
}

fn count_cutlet_choices(
  x: Int,
  max_x: Int,
  rem: Int,
  slots: Int,
  cumulative: Int,
  hit: Bool,
  required: Option(Int),
  memo: Dict(CutletMemoKey, Int),
  total: Int,
  key: CutletMemoKey,
) -> #(Int, Dict(CutletMemoKey, Int)) {
  case x > max_x {
    True -> {
      #(total, dict.insert(memo, key, total))
    }
    False -> {
      let next_cumulative = cumulative + x
      let decision = case required {
        None -> #(True, hit)
        Some(boundary) ->
          case hit {
            True -> {
              #(True, True)
            }
            False ->
              case next_cumulative == boundary {
                True -> {
                  #(True, True)
                }
                False ->
                  case next_cumulative > boundary {
                    True -> {
                      #(False, False)
                    }
                    False -> {
                      #(True, False)
                    }
                  }
              }
          }
      }
      let #(allowed, next_hit) = decision
      case allowed {
        True -> {
          let #(block, next_memo) =
            count_cutlet_partitions(
              rem - x,
              slots - 1,
              next_cumulative,
              next_hit,
              required,
              memo,
            )
          count_cutlet_choices(
            x + 1,
            max_x,
            rem,
            slots,
            cumulative,
            hit,
            required,
            next_memo,
            total + block,
            key,
          )
        }
        False -> {
          count_cutlet_choices(
            x + 1,
            max_x,
            rem,
            slots,
            cumulative,
            hit,
            required,
            memo,
            total,
            key,
          )
        }
      }
    }
  }
}

fn unrank_cutlet_partition(
  gaps: Int,
  slots: Int,
  required: Option(Int),
  rank1: Int,
) -> List(Int) {
  unrank_cutlet_loop(gaps, slots, 0, False, required, rank1, dict.new(), [])
}

fn unrank_cutlet_loop(
  rem: Int,
  slots: Int,
  cumulative: Int,
  hit: Bool,
  required: Option(Int),
  rank: Int,
  memo: Dict(CutletMemoKey, Int),
  acc: List(Int),
) -> List(Int) {
  case slots == 0 {
    True -> {
      list.reverse(acc)
    }
    False -> {
      unrank_cutlet_choice(
        1,
        rem - { slots - 1 },
        rem,
        slots,
        cumulative,
        hit,
        required,
        rank,
        memo,
        acc,
      )
    }
  }
}

fn unrank_cutlet_choice(
  x: Int,
  max_x: Int,
  rem: Int,
  slots: Int,
  cumulative: Int,
  hit: Bool,
  required: Option(Int),
  rank: Int,
  memo: Dict(CutletMemoKey, Int),
  acc: List(Int),
) -> List(Int) {
  case x > max_x {
    True -> {
      panic as "Nevalida rango por kotleta dispartigo"
    }
    False -> {
      let next_cumulative = cumulative + x
      let decision = case required {
        None -> #(True, hit)
        Some(boundary) ->
          case hit {
            True -> {
              #(True, True)
            }
            False ->
              case next_cumulative == boundary {
                True -> {
                  #(True, True)
                }
                False ->
                  case next_cumulative > boundary {
                    True -> {
                      #(False, False)
                    }
                    False -> {
                      #(True, False)
                    }
                  }
              }
          }
      }
      let #(allowed, next_hit) = decision
      case allowed {
        True -> {
          let #(block, next_memo) =
            count_cutlet_partitions(
              rem - x,
              slots - 1,
              next_cumulative,
              next_hit,
              required,
              memo,
            )
          case rank > block {
            True -> {
              unrank_cutlet_choice(
                x + 1,
                max_x,
                rem,
                slots,
                cumulative,
                hit,
                required,
                rank - block,
                next_memo,
                acc,
              )
            }
            False -> {
              unrank_cutlet_loop(
                rem - x,
                slots - 1,
                next_cumulative,
                next_hit,
                required,
                rank,
                next_memo,
                [x, ..acc],
              )
            }
          }
        }
        False -> {
          unrank_cutlet_choice(
            x + 1,
            max_x,
            rem,
            slots,
            cumulative,
            hit,
            required,
            rank,
            memo,
            acc,
          )
        }
      }
    }
  }
}

fn choose_cutlet_partition(
  calculation_day: Int,
  structure_sauce: core.SauceResult,
  year: Year,
  cutlet_count: Int,
  state: GateState,
) -> #(List(Int), GateState) {
  let #(gate_option, covered) = exact_gate_index(state, calculation_day)
  let required = case gate_option {
    Some(index) ->
      case index > year.open_gate_index && index < year.close_gate_index {
        True -> {
          Some(index - year.open_gate_index)
        }
        False -> {
          None
        }
      }
    None -> None
  }
  let gaps = year.close_gate_index - year.open_gate_index
  let #(count, _) =
    count_cutlet_partitions(gaps, cutlet_count, 0, False, required, dict.new())
  let stream = sauce.ask_bowl(structure_sauce, 2, core.seal_cutlet_partition)
  let rank = sauce.choose_rank(stream, count)
  #(unrank_cutlet_partition(gaps, cutlet_count, required, rank), covered)
}

fn choose_cutlet_names(
  structure_sauce: core.SauceResult,
  cutlet_count: Int,
) -> List(Int) {
  let count = core.falling_factorial(17, cutlet_count)
  let stream = sauce.ask_bowl(structure_sauce, 5, core.seal_cutlet_names)
  unrank_distinct_indices(17, cutlet_count, sauce.choose_rank(stream, count))
}

fn materialize_cutlets(
  year: Year,
  partition: List(Int),
  names: List(Int),
  state: GateState,
) -> List(Cutlet) {
  materialize_cutlet_loop(partition, names, year.open_gate_index, state, [])
  |> list.reverse
}

fn materialize_cutlet_loop(
  partition: List(Int),
  names: List(Int),
  cursor_gate: Int,
  state: GateState,
  acc: List(Cutlet),
) -> List(Cutlet) {
  case partition, names {
    [], [] -> acc
    [part, ..parts], [name, ..rest_names] -> {
      let close_gate = cursor_gate + part
      let cutlet =
        Cutlet(
          name_index: name,
          open_gate_index: cursor_gate,
          close_gate_index: close_gate,
          first_day: gate_value(state, cursor_gate) + 1,
          last_day: gate_value(state, close_gate),
        )
      materialize_cutlet_loop(parts, rest_names, close_gate, state, [
        cutlet,
        ..acc
      ])
    }
    _, _ -> panic as "Nekongruaj kotletaj datumoj"
  }
}

fn choose_month_count(structure_sauce: core.SauceResult, year: Year) -> Int {
  let length = year.close_gate_day - year.open_gate_day
  let minimum = core.ceil_div(length, core.max_month_days)
  let maximum =
    core.min_int(core.max_months, core.floor_div(length, core.min_month_days))
  let candidates = core.range_inclusive(minimum, maximum)
  let stream = sauce.ask_bowl(structure_sauce, 3, core.seal_month_count)
  core.at1(candidates, sauce.choose_rank(stream, list.length(candidates)))
}

type BoundedMemoKey =
  #(Int, Int)

fn count_bounded(
  rem: Int,
  slots: Int,
  low: Int,
  high: Int,
  memo: Dict(BoundedMemoKey, Int),
) -> #(Int, Dict(BoundedMemoKey, Int)) {
  case slots == 0 {
    True -> {
      #(
        case rem == 0 {
          True -> {
            1
          }
          False -> {
            0
          }
        },
        memo,
      )
    }
    False ->
      case rem < slots * low || rem > slots * high {
        True -> {
          #(0, memo)
        }
        False -> {
          let key = #(rem, slots)
          case dict.get(memo, key) {
            Ok(value) -> #(value, memo)
            Error(_) ->
              count_bounded_choices(
                low,
                high,
                rem,
                slots,
                low,
                high,
                memo,
                0,
                key,
              )
          }
        }
      }
  }
}

fn count_bounded_choices(
  x: Int,
  max_x: Int,
  rem: Int,
  slots: Int,
  low: Int,
  high: Int,
  memo: Dict(BoundedMemoKey, Int),
  total: Int,
  key: BoundedMemoKey,
) -> #(Int, Dict(BoundedMemoKey, Int)) {
  case x > max_x {
    True -> {
      #(total, dict.insert(memo, key, total))
    }
    False -> {
      let #(block, next_memo) =
        count_bounded(rem - x, slots - 1, low, high, memo)
      count_bounded_choices(
        x + 1,
        max_x,
        rem,
        slots,
        low,
        high,
        next_memo,
        total + block,
        key,
      )
    }
  }
}

fn unrank_bounded(
  total: Int,
  slots: Int,
  low: Int,
  high: Int,
  rank1: Int,
) -> List(Int) {
  unrank_bounded_loop(total, slots, low, high, rank1, dict.new(), [])
}

fn unrank_bounded_loop(
  rem: Int,
  slots: Int,
  low: Int,
  high: Int,
  rank: Int,
  memo: Dict(BoundedMemoKey, Int),
  acc: List(Int),
) -> List(Int) {
  case slots == 0 {
    True -> {
      list.reverse(acc)
    }
    False -> {
      unrank_bounded_choice(low, high, rem, slots, low, high, rank, memo, acc)
    }
  }
}

fn unrank_bounded_choice(
  x: Int,
  max_x: Int,
  rem: Int,
  slots: Int,
  low: Int,
  high: Int,
  rank: Int,
  memo: Dict(BoundedMemoKey, Int),
  acc: List(Int),
) -> List(Int) {
  case x > max_x {
    True -> {
      panic as "Nevalida rango por monataj longoj"
    }
    False -> {
      let #(block, next_memo) =
        count_bounded(rem - x, slots - 1, low, high, memo)
      case rank > block {
        True -> {
          unrank_bounded_choice(
            x + 1,
            max_x,
            rem,
            slots,
            low,
            high,
            rank - block,
            next_memo,
            acc,
          )
        }
        False -> {
          unrank_bounded_loop(rem - x, slots - 1, low, high, rank, next_memo, [
            x,
            ..acc
          ])
        }
      }
    }
  }
}

fn choose_month_lengths(
  structure_sauce: core.SauceResult,
  year: Year,
  month_count: Int,
) -> List(Int) {
  let length = year.close_gate_day - year.open_gate_day
  let #(count, _) =
    count_bounded(
      length,
      month_count,
      core.min_month_days,
      core.max_month_days,
      dict.new(),
    )
  let stream = sauce.ask_bowl(structure_sauce, 3, core.seal_month_lengths)
  let rank = sauce.choose_rank(stream, count)
  unrank_bounded(
    length,
    month_count,
    core.min_month_days,
    core.max_month_days,
    rank,
  )
}

type WeaveMemoKey =
  #(List(Int), Int, Int)

fn all_zero(items: List(Int)) -> Bool {
  case items {
    [] -> True
    [head, ..tail] ->
      case head == 0 {
        True -> {
          all_zero(tail)
        }
        False -> {
          False
        }
      }
  }
}

fn legal_weave_move(
  remaining: List(Int),
  opened_up_to: Int,
  closed_up_to: Int,
  original: List(Int),
  month_id: Int,
) -> Bool {
  let rem = core.at1(remaining, month_id)
  case rem == 0 {
    True -> {
      False
    }
    False -> {
      let already_opened = rem < core.at1(original, month_id)
      case already_opened == False && month_id != opened_up_to + 1 {
        True -> {
          False
        }
        False -> {
          let will_close = rem == 1
          case will_close && month_id != closed_up_to + 1 {
            True -> {
              False
            }
            False -> {
              True
            }
          }
        }
      }
    }
  }
}

fn apply_weave_move(
  remaining: List(Int),
  opened_up_to: Int,
  closed_up_to: Int,
  original: List(Int),
  month_id: Int,
) -> #(List(Int), Int, Int) {
  let rem = core.at1(remaining, month_id)
  let next_opened = case rem == core.at1(original, month_id) {
    True -> {
      month_id
    }
    False -> {
      opened_up_to
    }
  }
  let next_remaining = core.replace_at1(remaining, month_id, rem - 1)
  let next_closed = case rem - 1 == 0 {
    True -> {
      month_id
    }
    False -> {
      closed_up_to
    }
  }
  #(next_remaining, next_opened, next_closed)
}

fn count_weavings(
  remaining: List(Int),
  opened_up_to: Int,
  closed_up_to: Int,
  original: List(Int),
  memo: Dict(WeaveMemoKey, Int),
) -> #(Int, Dict(WeaveMemoKey, Int)) {
  case all_zero(remaining) {
    True -> {
      #(1, memo)
    }
    False -> {
      let key = #(remaining, opened_up_to, closed_up_to)
      case dict.get(memo, key) {
        Ok(value) -> #(value, memo)
        Error(_) ->
          count_weave_choices(
            1,
            list.length(original),
            remaining,
            opened_up_to,
            closed_up_to,
            original,
            memo,
            0,
            key,
          )
      }
    }
  }
}

fn count_weave_choices(
  month_id: Int,
  max_month: Int,
  remaining: List(Int),
  opened_up_to: Int,
  closed_up_to: Int,
  original: List(Int),
  memo: Dict(WeaveMemoKey, Int),
  total: Int,
  key: WeaveMemoKey,
) -> #(Int, Dict(WeaveMemoKey, Int)) {
  case month_id > max_month {
    True -> {
      #(total, dict.insert(memo, key, total))
    }
    False ->
      case
        legal_weave_move(
          remaining,
          opened_up_to,
          closed_up_to,
          original,
          month_id,
        )
      {
        True -> {
          let #(next_remaining, next_opened, next_closed) =
            apply_weave_move(
              remaining,
              opened_up_to,
              closed_up_to,
              original,
              month_id,
            )
          let #(block, next_memo) =
            count_weavings(
              next_remaining,
              next_opened,
              next_closed,
              original,
              memo,
            )
          count_weave_choices(
            month_id + 1,
            max_month,
            remaining,
            opened_up_to,
            closed_up_to,
            original,
            next_memo,
            total + block,
            key,
          )
        }
        False -> {
          count_weave_choices(
            month_id + 1,
            max_month,
            remaining,
            opened_up_to,
            closed_up_to,
            original,
            memo,
            total,
            key,
          )
        }
      }
  }
}

fn unrank_weaving(lengths: List(Int), rank1: Int) -> List(Int) {
  unrank_weaving_loop(lengths, 0, 0, lengths, rank1, dict.new(), [])
}

fn unrank_weaving_loop(
  remaining: List(Int),
  opened_up_to: Int,
  closed_up_to: Int,
  original: List(Int),
  rank: Int,
  memo: Dict(WeaveMemoKey, Int),
  acc: List(Int),
) -> List(Int) {
  case all_zero(remaining) {
    True -> {
      list.reverse(acc)
    }
    False -> {
      unrank_weave_choice(
        1,
        list.length(original),
        remaining,
        opened_up_to,
        closed_up_to,
        original,
        rank,
        memo,
        acc,
      )
    }
  }
}

fn unrank_weave_choice(
  month_id: Int,
  max_month: Int,
  remaining: List(Int),
  opened_up_to: Int,
  closed_up_to: Int,
  original: List(Int),
  rank: Int,
  memo: Dict(WeaveMemoKey, Int),
  acc: List(Int),
) -> List(Int) {
  case month_id > max_month {
    True -> {
      panic as "Nevalida rango por monata teksado"
    }
    False ->
      case
        legal_weave_move(
          remaining,
          opened_up_to,
          closed_up_to,
          original,
          month_id,
        )
      {
        True -> {
          let #(next_remaining, next_opened, next_closed) =
            apply_weave_move(
              remaining,
              opened_up_to,
              closed_up_to,
              original,
              month_id,
            )
          let #(block, next_memo) =
            count_weavings(
              next_remaining,
              next_opened,
              next_closed,
              original,
              memo,
            )
          case rank > block {
            True -> {
              unrank_weave_choice(
                month_id + 1,
                max_month,
                remaining,
                opened_up_to,
                closed_up_to,
                original,
                rank - block,
                next_memo,
                acc,
              )
            }
            False -> {
              unrank_weaving_loop(
                next_remaining,
                next_opened,
                next_closed,
                original,
                rank,
                next_memo,
                [month_id, ..acc],
              )
            }
          }
        }
        False -> {
          unrank_weave_choice(
            month_id + 1,
            max_month,
            remaining,
            opened_up_to,
            closed_up_to,
            original,
            rank,
            memo,
            acc,
          )
        }
      }
  }
}

fn choose_month_weaving(
  structure_sauce: core.SauceResult,
  month_lengths: List(Int),
) -> List(Int) {
  let #(count, _) =
    count_weavings(month_lengths, 0, 0, month_lengths, dict.new())
  let stream = sauce.ask_bowl(structure_sauce, 4, core.seal_month_weaving)
  let rank = sauce.choose_rank(stream, count)
  unrank_weaving(month_lengths, rank)
}

fn choose_month_names(
  structure_sauce: core.SauceResult,
  month_count: Int,
) -> List(Int) {
  let count = core.falling_factorial(47, month_count)
  let stream = sauce.ask_bowl(structure_sauce, 5, core.seal_month_names)
  unrank_distinct_indices(47, month_count, sauce.choose_rank(stream, count))
}

pub fn build_year_structure(
  calculation_day: Int,
  year: Year,
  state: GateState,
) -> #(YearStructure, GateState) {
  let first_day = year.open_gate_day + 1
  let structure_sauce = sauce.sauce(calculation_day, first_day)
  let cutlet_count = choose_cutlet_count(structure_sauce, year)
  let #(partition, covered) =
    choose_cutlet_partition(
      calculation_day,
      structure_sauce,
      year,
      cutlet_count,
      state,
    )
  let cutlet_names = choose_cutlet_names(structure_sauce, cutlet_count)
  let cutlets = materialize_cutlets(year, partition, cutlet_names, covered)
  let month_count = choose_month_count(structure_sauce, year)
  let month_lengths = choose_month_lengths(structure_sauce, year, month_count)
  let month_weaving = choose_month_weaving(structure_sauce, month_lengths)
  let month_names = choose_month_names(structure_sauce, month_count)
  #(
    YearStructure(
      year: year,
      cutlet_count: cutlet_count,
      cutlet_partition: partition,
      cutlet_name_indices: cutlet_names,
      cutlets: cutlets,
      month_count: month_count,
      month_lengths: month_lengths,
      month_weaving: month_weaving,
      month_name_indices: month_names,
    ),
    covered,
  )
}

fn cutlet_for_day(cutlets: List(Cutlet), day: Int) -> Cutlet {
  case cutlets {
    [] -> panic as "Neniu kotleto enhavas la celan tagon"
    [head, ..tail] ->
      case head.first_day <= day && day <= head.last_day {
        True -> {
          head
        }
        False -> {
          cutlet_for_day(tail, day)
        }
      }
  }
}

fn occurrence_count(
  items: List(Int),
  wanted: Int,
  through_position: Int,
) -> Int {
  occurrence_loop(items, wanted, through_position, 1, 0)
}

fn occurrence_loop(
  items: List(Int),
  wanted: Int,
  through_position: Int,
  position: Int,
  acc: Int,
) -> Int {
  case items {
    [] -> acc
    [head, ..tail] ->
      case position > through_position {
        True -> {
          acc
        }
        False -> {
          occurrence_loop(
            tail,
            wanted,
            through_position,
            position + 1,
            case head == wanted {
              True -> {
                acc + 1
              }
              False -> {
                acc
              }
            },
          )
        }
      }
  }
}

pub fn calendar_date(calculation_day: Int, target_day: Int) -> CalendarDate {
  let initial_state = new_gate_state()
  let #(year, state) =
    find_target_year(calculation_day, target_day, initial_state)
  let #(structure, _) = build_year_structure(calculation_day, year, state)
  let cutlet = cutlet_for_day(structure.cutlets, target_day)
  let day_in_cutlet = target_day - cutlet.first_day + 1
  let year_offset0 = target_day - { year.open_gate_day + 1 }
  let month_id = core.at1(structure.month_weaving, year_offset0 + 1)
  let month_index = core.at1(structure.month_name_indices, month_id)
  let day_in_month =
    occurrence_count(structure.month_weaving, month_id, year_offset0 + 1)
  CalendarDate(
    year_number: year.number,
    cutlet_name: source_language_catalog.cutlet_name(cutlet.name_index),
    day_in_cutlet: day_in_cutlet,
    month_name: source_language_catalog.month_name(month_index),
    day_in_month: day_in_month,
  )
}
