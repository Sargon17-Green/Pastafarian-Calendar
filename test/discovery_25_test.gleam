// Stadio 29: dek du testoj per sendependa Stage25-enumerada orakolo.
// La orakolo ne uzas Stage26/27/28 nek la produktan glitfenestron.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_25_shortest_window
import reference/core

fn answers(a: Int, b: Int, ids: List(Int), thresholds: List(Int)) {
  discovery_25_shortest_window.dispatch_discovery_25(
    bootstrap.new_context(a, b),
    ids,
    thresholds,
  )
}

fn get_samples(a: Int, b: Int, ids: List(Int)) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(
      bootstrap.new_context(a, b),
      ids,
    )
  samples
}

fn oracle_choice(
  best: discovery_25_shortest_window.WindowReach,
  start: Int,
  end: Int,
  sum: Int,
) -> discovery_25_shortest_window.WindowReach {
  case best {
    discovery_25_shortest_window.NoWindow ->
      discovery_25_shortest_window.WindowFound(
        start: start,
        end: end,
        total: sum,
      )
    discovery_25_shortest_window.WindowFound(
      start: old_start,
      end: old_end,
      total: _,
    ) ->
      case
        end - start < old_end - old_start
        || { end - start == old_end - old_start && start < old_start }
      {
        True ->
          discovery_25_shortest_window.WindowFound(
            start: start,
            end: end,
            total: sum,
          )
        False -> best
      }
  }
}

fn enumerate_ends(
  suffix: List(Int),
  threshold: Int,
  start: Int,
  end: Int,
  sum: Int,
  best: discovery_25_shortest_window.WindowReach,
) -> discovery_25_shortest_window.WindowReach {
  case suffix {
    [] -> best
    [gap, ..rest] -> {
      let next = sum + gap
      let end = end + 1
      let next_best = case next >= threshold {
        True -> oracle_choice(best, start, end, next)
        False -> best
      }
      enumerate_ends(rest, threshold, start, end, next, next_best)
    }
  }
}

fn enumerate_starts(
  suffix: List(Int),
  threshold: Int,
  start: Int,
  best: discovery_25_shortest_window.WindowReach,
) -> discovery_25_shortest_window.WindowReach {
  case suffix {
    [] -> best
    [_, ..rest] -> {
      let next_best = enumerate_ends(suffix, threshold, start, start, 0, best)
      enumerate_starts(rest, threshold, start + 1, next_best)
    }
  }
}

fn independent_window(
  gaps: List(Int),
  threshold: Int,
) -> discovery_25_shortest_window.WindowReach {
  case threshold <= 0 {
    True -> discovery_25_shortest_window.WindowFound(start: 0, end: 0, total: 0)
    False ->
      enumerate_starts(
        gaps,
        threshold,
        0,
        discovery_25_shortest_window.NoWindow,
      )
  }
}

fn check_valid(a: Int, b: Int, ids: List(Int), thresholds: List(Int)) {
  let context = bootstrap.new_context(a, b)
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.each(samples, fn(sample) {
    {
      sample.gap >= discovery_20_gate_gap.gap_min
      && sample.gap <= discovery_20_gate_gap.gap_max
    }
    |> should.equal(True)
  })
  let gaps = list.map(samples, fn(sample) { sample.gap })
  let expected =
    list.map(thresholds, fn(threshold) {
      discovery_25_shortest_window.ThresholdWindow(
        threshold: threshold,
        reach: independent_window(gaps, threshold),
      )
    })
  let assert Ok(actual) =
    discovery_25_shortest_window.dispatch_discovery_25(context, ids, thresholds)
  actual |> should.equal(expected)
}

pub fn discovery_25_empty_bowls_and_thresholds_test() {
  answers(11, 21, [], []) |> should.equal(Ok([]))
}

pub fn discovery_25_empty_bowls_invalid_unused_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_25_shortest_window.dispatch_discovery_25(invalid, [], [-1, 0, 1])
  |> should.equal(
    Ok([
      discovery_25_shortest_window.ThresholdWindow(
        threshold: -1,
        reach: discovery_25_shortest_window.WindowFound(
          start: 0,
          end: 0,
          total: 0,
        ),
      ),
      discovery_25_shortest_window.ThresholdWindow(
        threshold: 0,
        reach: discovery_25_shortest_window.WindowFound(
          start: 0,
          end: 0,
          total: 0,
        ),
      ),
      discovery_25_shortest_window.ThresholdWindow(
        threshold: 1,
        reach: discovery_25_shortest_window.NoWindow,
      ),
    ]),
  )
}

pub fn discovery_25_single_gap_boundaries_test() {
  let assert [sample] = get_samples(11, 21, [1])
  check_valid(11, 21, [1], [1, sample.gap, sample.gap + 1])
  answers(11, 21, [1], [sample.gap])
  |> should.equal(
    Ok([
      discovery_25_shortest_window.ThresholdWindow(
        threshold: sample.gap,
        reach: discovery_25_shortest_window.WindowFound(
          start: 0,
          end: 1,
          total: sample.gap,
        ),
      ),
    ]),
  )
}

pub fn discovery_25_multiple_gaps_total_boundary_test() {
  let ids = [1, 3, 2, 6]
  let samples = get_samples(11, 21, ids)
  let total = list.fold(samples, 0, fn(sum, sample) { sum + sample.gap })
  check_valid(11, 21, ids, [1, total, total + 1])
  let assert Ok(got) = answers(11, 21, ids, [total + 1])
  let assert [item] = got
  item.reach |> should.equal(discovery_25_shortest_window.NoWindow)
}

pub fn discovery_25_interior_optimum_independent_test() {
  let ids = [6, 2, 1, 4, 3]
  let assert [_, second, _, fourth, _] = get_samples(11, 21, ids)
  check_valid(11, 21, ids, [second.gap, fourth.gap])
}

pub fn discovery_25_tie_choose_earliest_start_test() {
  let ids = [1, 1, 1, 1]
  let assert [first, ..] = get_samples(11, 21, ids)
  check_valid(11, 21, ids, [first.gap])
  let assert Ok(got) = answers(11, 21, ids, [first.gap])
  let assert [item] = got
  item.reach
  |> should.equal(discovery_25_shortest_window.WindowFound(
    start: 0,
    end: 1,
    total: first.gap,
  ))
}

pub fn discovery_25_unsorted_duplicate_thresholds_test() {
  let thresholds = [999_999, 1, 1, 500, 0, 500, -5]
  check_valid(11, 21, [6, 2, 3], thresholds)
  let assert Ok(got) = answers(11, 21, [6, 2, 3], thresholds)
  list.map(got, fn(item) { item.threshold }) |> should.equal(thresholds)
}

pub fn discovery_25_nonpositive_thresholds_empty_window_test() {
  check_valid(11, 21, [2, 6, 1], [-10_000, -1, 0])
  let assert Ok(got) = answers(11, 21, [2, 6, 1], [-10_000, -1, 0])
  list.each(got, fn(item) {
    item.reach
    |> should.equal(discovery_25_shortest_window.WindowFound(
      start: 0,
      end: 0,
      total: 0,
    ))
  })
}

pub fn discovery_25_exact_window_and_plus_one_test() {
  let ids = [3, 1, 5]
  let assert [first, second, _] = get_samples(11, 21, ids)
  check_valid(11, 21, ids, [first.gap + second.gap, first.gap + second.gap + 1])
}

pub fn discovery_25_invalid_bowl_before_empty_thresholds_test() {
  answers(11, 21, [7], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
}

pub fn discovery_25_invalid_context_before_nonpositive_threshold_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_25_shortest_window.dispatch_discovery_25(invalid, [1], [-7, 0])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_25_huge_days_repetitions_and_large_ints_test() {
  let huge = core.m * core.m + core.m
  check_valid(huge, -huge, [1, 6, 1, 6, 2], [-huge, 0, 1, huge, huge * huge])
  check_valid(-huge, huge, [6, 6, 6], [0, 1, 9_999_999_999, -9_999_999_999])
}
