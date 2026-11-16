// Stadio 30: dek du testoj kun sendependa Stage25-fenestro-orakolo.
// La oracle rekte enumeracias ĉiun ne-malplenan subliston; ne uzas Stage26/29.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_26_window_count
import reference/core

fn answers(a: Int, b: Int, ids: List(Int), thresholds: List(Int)) {
  discovery_26_window_count.dispatch_discovery_26(
    bootstrap.new_context(a, b),
    ids,
    thresholds,
  )
}

fn samples_for(a: Int, b: Int, ids: List(Int)) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(
      bootstrap.new_context(a, b),
      ids,
    )
  samples
}

fn enumerate_ends(
  suffix: List(Int),
  threshold: Int,
  sum: Int,
  count: Int,
) -> Int {
  case suffix {
    [] -> count
    [gap, ..rest] -> {
      let next_sum = sum + gap
      let next_count = case next_sum >= threshold {
        True -> count + 1
        False -> count
      }
      enumerate_ends(rest, threshold, next_sum, next_count)
    }
  }
}

fn enumerate_starts(suffix: List(Int), threshold: Int, count: Int) -> Int {
  case suffix {
    [] -> count
    [_, ..rest] -> {
      let next_count = count + enumerate_ends(suffix, threshold, 0, 0)
      enumerate_starts(rest, threshold, next_count)
    }
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
  let size = list.length(gaps)
  let upper = size * { size + 1 } / 2
  let expected =
    list.map(thresholds, fn(threshold) {
      discovery_26_window_count.ThresholdWindowCount(
        threshold: threshold,
        qualifying_windows: enumerate_starts(gaps, threshold, 0),
      )
    })
  let assert Ok(actual) =
    discovery_26_window_count.dispatch_discovery_26(context, ids, thresholds)
  actual |> should.equal(expected)
  list.each(actual, fn(item) {
    { item.qualifying_windows >= 0 && item.qualifying_windows <= upper }
    |> should.equal(True)
  })
}

pub fn discovery_26_empty_bowls_and_thresholds_test() {
  answers(11, 21, [], []) |> should.equal(Ok([]))
}

pub fn discovery_26_empty_bowls_invalid_unused_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_26_window_count.dispatch_discovery_26(invalid, [], [-1, 0, 1])
  |> should.equal(
    Ok([
      discovery_26_window_count.ThresholdWindowCount(
        threshold: -1,
        qualifying_windows: 0,
      ),
      discovery_26_window_count.ThresholdWindowCount(
        threshold: 0,
        qualifying_windows: 0,
      ),
      discovery_26_window_count.ThresholdWindowCount(
        threshold: 1,
        qualifying_windows: 0,
      ),
    ]),
  )
}

pub fn discovery_26_single_gap_boundary_test() {
  let assert [sample] = samples_for(11, 21, [1])
  let gap = sample.gap
  check_valid(11, 21, [1], [gap - 1, gap, gap + 1])
  let assert Ok(got) = answers(11, 21, [1], [gap - 1, gap, gap + 1])
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([1, 1, 0])
}

pub fn discovery_26_multiple_gaps_total_boundary_test() {
  let ids = [1, 3, 2, 6]
  let samples = samples_for(11, 21, ids)
  let total = list.fold(samples, 0, fn(sum, sample) { sum + sample.gap })
  check_valid(11, 21, ids, [total, total + 1, 1])
  let assert Ok(got) = answers(11, 21, ids, [total, total + 1, 1])
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([1, 0, 10])
}

pub fn discovery_26_interior_and_nonprefix_windows_test() {
  let ids = [6, 2, 1, 4, 3]
  let assert [first, second, third, _, _] = samples_for(11, 21, ids)
  check_valid(11, 21, ids, [
    second.gap,
    third.gap,
    second.gap + third.gap,
    first.gap + 1,
  ])
}

pub fn discovery_26_repeated_bowl_positions_test() {
  let ids = [1, 1, 1, 1]
  let assert [first, _, _, _] = samples_for(11, 21, ids)
  check_valid(11, 21, ids, [first.gap, first.gap * 2, 0])
  let assert Ok(got) = answers(11, 21, ids, [first.gap, 0])
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([10, 10])
}

pub fn discovery_26_unsorted_duplicate_thresholds_test() {
  let thresholds = [999_999, 1, 1, 500, 0, 500, -5]
  check_valid(11, 21, [6, 2, 3], thresholds)
  let assert Ok(got) = answers(11, 21, [6, 2, 3], thresholds)
  list.map(got, fn(item) { item.threshold }) |> should.equal(thresholds)
  let assert [_, first, second, _, _, _, _] = got
  first |> should.equal(second)
}

pub fn discovery_26_nonpositive_thresholds_count_ten_test() {
  check_valid(11, 21, [2, 6, 1, 4], [-10_000, -1, 0])
  let assert Ok(got) = answers(11, 21, [2, 6, 1, 4], [-10_000, -1, 0])
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([10, 10, 10])
}

pub fn discovery_26_single_pair_exact_and_plus_one_test() {
  let ids = [3, 1]
  let assert [first, second] = samples_for(11, 21, ids)
  let total = first.gap + second.gap
  check_valid(11, 21, ids, [first.gap, second.gap, total, total + 1])
  let assert Ok(got) = answers(11, 21, ids, [total, total + 1])
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([1, 0])
}

pub fn discovery_26_invalid_bowl_before_empty_thresholds_test() {
  answers(11, 21, [7], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
}

pub fn discovery_26_invalid_context_before_nonpositive_threshold_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_26_window_count.dispatch_discovery_26(invalid, [1], [-7, 0])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_26_huge_days_ints_and_monotonicity_test() {
  let huge = core.m * core.m + core.m
  let ids = [1, 6, 1, 6, 2]
  check_valid(huge, -huge, ids, [-huge, 0, 1, huge, huge * huge])
  check_valid(-huge, huge, [6, 6, 6], [
    -9_999_999_999,
    0,
    1,
    42,
    963,
    9_999_999_999,
  ])
  let thresholds = [1, 42, 43, 963, 964, 999_999_999]
  let assert Ok(got) = answers(11, 21, ids, thresholds)
  let assert [a, b, c, d, e, f] = got
  {
    a.qualifying_windows >= b.qualifying_windows
    && b.qualifying_windows >= c.qualifying_windows
    && c.qualifying_windows >= d.qualifying_windows
    && d.qualifying_windows >= e.qualifying_windows
    && e.qualifying_windows >= f.qualifying_windows
  }
  |> should.equal(True)
}
