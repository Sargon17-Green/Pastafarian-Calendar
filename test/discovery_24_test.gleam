// Stadio 28: 12 sendependaj sojlotestoj laŭ Stage25-orakolo.
// La orakolo ne uzas Stage26, Stage27 aŭ produktan Stage28-porrezulton.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_24_threshold_reach
import reference/core

fn answers(a: Int, b: Int, ids: List(Int), thresholds: List(Int)) {
  discovery_24_threshold_reach.dispatch_discovery_24(
    bootstrap.new_context(a, b),
    ids,
    thresholds,
  )
}

fn independent_reach(
  samples: List(discovery_20_gate_gap.GateGapOutput),
  threshold: Int,
) -> discovery_24_threshold_reach.Reach {
  case threshold <= 0 {
    True -> discovery_24_threshold_reach.ReachedAt(prefix_size: 0)
    False -> independent_scan(samples, threshold, 0, 0)
  }
}

fn independent_scan(
  samples: List(discovery_20_gate_gap.GateGapOutput),
  threshold: Int,
  running: Int,
  index: Int,
) -> discovery_24_threshold_reach.Reach {
  case samples {
    [] -> discovery_24_threshold_reach.NotReached
    [sample, ..rest] -> {
      let next = running + sample.gap
      case next >= threshold {
        True -> discovery_24_threshold_reach.ReachedAt(prefix_size: index + 1)
        False -> independent_scan(rest, threshold, next, index + 1)
      }
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
  let expected =
    list.map(thresholds, fn(threshold) {
      discovery_24_threshold_reach.ThresholdFinding(
        threshold: threshold,
        reach: independent_reach(samples, threshold),
      )
    })
  let assert Ok(actual) =
    discovery_24_threshold_reach.dispatch_discovery_24(context, ids, thresholds)
  actual |> should.equal(expected)
}

pub fn discovery_24_empty_bowls_and_thresholds_test() {
  answers(11, 21, [], []) |> should.equal(Ok([]))
}

pub fn discovery_24_empty_bowls_invalid_unused_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_24_threshold_reach.dispatch_discovery_24(invalid, [], [-1, 0, 1])
  |> should.equal(
    Ok([
      discovery_24_threshold_reach.ThresholdFinding(
        threshold: -1,
        reach: discovery_24_threshold_reach.ReachedAt(prefix_size: 0),
      ),
      discovery_24_threshold_reach.ThresholdFinding(
        threshold: 0,
        reach: discovery_24_threshold_reach.ReachedAt(prefix_size: 0),
      ),
      discovery_24_threshold_reach.ThresholdFinding(
        threshold: 1,
        reach: discovery_24_threshold_reach.NotReached,
      ),
    ]),
  )
}

pub fn discovery_24_single_gap_boundary_test() {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(
      bootstrap.new_context(11, 21),
      [1],
    )
  let assert [sample] = samples
  check_valid(11, 21, [1], [1, sample.gap, sample.gap + 1])
  answers(11, 21, [1], [sample.gap + 1])
  |> should.equal(
    Ok([
      discovery_24_threshold_reach.ThresholdFinding(
        threshold: sample.gap + 1,
        reach: discovery_24_threshold_reach.NotReached,
      ),
    ]),
  )
}

pub fn discovery_24_multiple_gaps_total_boundary_test() {
  let ids = [1, 3, 2, 6]
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(
      bootstrap.new_context(11, 21),
      ids,
    )
  let total = samples |> list.fold(0, fn(sum, sample) { sum + sample.gap })
  check_valid(11, 21, ids, [0, 1, total, total + 1])
  let assert Ok(got) = answers(11, 21, ids, [total, total + 1])
  let assert [last, missing] = got
  last.reach
  |> should.equal(discovery_24_threshold_reach.ReachedAt(prefix_size: 4))
  missing.reach |> should.equal(discovery_24_threshold_reach.NotReached)
}

pub fn discovery_24_unsorted_thresholds_preserved_test() {
  let thresholds = [999_999, 1, 420, 0, 150, -50]
  check_valid(11, 21, [6, 2, 3], thresholds)
  let assert Ok(got) = answers(11, 21, [6, 2, 3], thresholds)
  list.map(got, fn(item) { item.threshold }) |> should.equal(thresholds)
}

pub fn discovery_24_duplicate_thresholds_preserved_test() {
  let thresholds = [42, 42, 42, 1]
  check_valid(11, 21, [1, 2], thresholds)
  let assert Ok(got) = answers(11, 21, [1, 2], thresholds)
  let assert [first, second, third, _] = got
  first |> should.equal(second)
  first |> should.equal(third)
}

pub fn discovery_24_nonpositive_thresholds_hit_zero_test() {
  check_valid(11, 21, [1, 6], [-100, -1, 0])
  let assert Ok(got) = answers(11, 21, [1, 6], [-100, -1, 0])
  list.each(got, fn(item) {
    item.reach
    |> should.equal(discovery_24_threshold_reach.ReachedAt(prefix_size: 0))
  })
}

pub fn discovery_24_exact_positive_prefix_earliest_test() {
  let ids = [2, 5, 1]
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(
      bootstrap.new_context(11, 21),
      ids,
    )
  let assert [first, ..] = samples
  check_valid(11, 21, ids, [first.gap])
  let assert Ok(got) = answers(11, 21, ids, [first.gap])
  let assert [item] = got
  item.reach
  |> should.equal(discovery_24_threshold_reach.ReachedAt(prefix_size: 1))
}

pub fn discovery_24_after_prefix_requires_later_test() {
  let ids = [3, 5, 4]
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(
      bootstrap.new_context(11, 21),
      ids,
    )
  let assert [first, second, third] = samples
  let total = first.gap + second.gap + third.gap
  check_valid(11, 21, ids, [first.gap + 1, total + 1])
  let assert Ok(got) = answers(11, 21, ids, [first.gap + 1])
  let assert [item] = got
  item.reach
  |> should.equal(discovery_24_threshold_reach.ReachedAt(prefix_size: 2))
}

pub fn discovery_24_invalid_bowl_before_empty_thresholds_test() {
  answers(11, 21, [7], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
}

pub fn discovery_24_invalid_context_before_negative_threshold_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_24_threshold_reach.dispatch_discovery_24(invalid, [1], [-7])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_24_huge_days_repeated_bowls_and_ints_test() {
  let huge = core.m * core.m + core.m
  let ids = [1, 6, 1, 6, 2]
  check_valid(huge, -huge, ids, [-huge, 0, 1, huge, huge * huge])
  check_valid(-huge, huge, [6, 6, 6], [0, 1, 9_999_999_999, -9_999_999_999])
}
