// Stadio 36: sendependa Stage21-a rekta XOR-orakolo.
// Origina membreco estas taksata por ĉiu indeksa fenestro, sen
// Stage32..36-kalkuloj en la atendataj valoroj.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_32_symmetric_difference_bands
import reference/core

type DirectCounts {
  DirectCounts(
    left: Int,
    right: Int,
    intersection: Int,
    combined: Int,
    xor: Int,
  )
}

fn band(lower: Int, upper: Int) {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn contains_directly(
  sum: Int,
  original: List(discovery_27_sum_bands.SumBand),
) -> Bool {
  case original {
    [] -> False
    [first, ..remaining] ->
      case first.lower <= sum && sum <= first.upper {
        True -> True
        False -> contains_directly(sum, remaining)
      }
  }
}

fn bit(flag: Bool) -> Int {
  case flag {
    True -> 1
    False -> 0
  }
}

fn examine_endings(
  suffix: List(Int),
  rolling_sum: Int,
  original_left: List(discovery_27_sum_bands.SumBand),
  original_right: List(discovery_27_sum_bands.SumBand),
  counts: DirectCounts,
) -> DirectCounts {
  case suffix {
    [] -> counts
    [gap, ..remaining] -> {
      let next_sum = rolling_sum + gap
      let a = contains_directly(next_sum, original_left)
      let b = contains_directly(next_sum, original_right)
      let updated =
        DirectCounts(
          left: counts.left + bit(a),
          right: counts.right + bit(b),
          intersection: counts.intersection + bit(a && b),
          combined: counts.combined + bit(a || b),
          xor: counts.xor + bit(a != b),
        )
      examine_endings(
        remaining,
        next_sum,
        original_left,
        original_right,
        updated,
      )
    }
  }
}

fn enumerate_all_starts(
  suffix: List(Int),
  original_left: List(discovery_27_sum_bands.SumBand),
  original_right: List(discovery_27_sum_bands.SumBand),
  counts: DirectCounts,
) -> DirectCounts {
  case suffix {
    [] -> counts
    [_, ..remaining] -> {
      let updated =
        examine_endings(suffix, 0, original_left, original_right, counts)
      enumerate_all_starts(remaining, original_left, original_right, updated)
    }
  }
}

fn gaps_from_stage21(context: bootstrap.MonsterContext, ids: List(Int)) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  let gaps = list.map(samples, fn(sample) { sample.gap })
  list.all(gaps, fn(gap) { gap >= 42 && gap <= 963 })
  |> should.equal(True)
  gaps
}

fn direct_check(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
  expected_a: List(discovery_27_sum_bands.SumBand),
  expected_combined: List(discovery_27_sum_bands.SumBand),
  expected_b: List(discovery_27_sum_bands.SumBand),
) -> Int {
  let gaps = gaps_from_stage21(context, ids)
  let expected = enumerate_all_starts(gaps, a, b, DirectCounts(0, 0, 0, 0, 0))
  let k = list.length(gaps)
  let assert Ok(actual) =
    discovery_32_symmetric_difference_bands.dispatch_discovery_32(
      context,
      ids,
      a,
      b,
    )
  actual.canonical_left_bands |> should.equal(expected_a)
  actual.canonical_combined_bands |> should.equal(expected_combined)
  actual.canonical_right_bands |> should.equal(expected_b)
  actual.left_windows |> should.equal(expected.left)
  actual.right_windows |> should.equal(expected.right)
  actual.intersection_windows |> should.equal(expected.intersection)
  actual.combined_windows |> should.equal(expected.combined)
  actual.symmetric_difference_windows |> should.equal(expected.xor)
  actual.total_windows |> should.equal(k * { k + 1 } / 2)
  {
    actual.symmetric_difference_windows >= 0
    && actual.symmetric_difference_windows <= actual.combined_windows
    && actual.combined_windows <= actual.total_windows
  }
  |> should.equal(True)
  expected.xor
}

pub fn discovery_32_empty_ids_and_bands_test() {
  let context = bootstrap.new_context(11, 21)
  direct_check(context, [], [], [], [], [], [])
  |> should.equal(0)
  discovery_32_symmetric_difference_bands.dispatch_discovery_32(
    context,
    [],
    [],
    [],
  )
  |> should.equal(
    Ok(discovery_32_symmetric_difference_bands.SymmetricDifferenceWindowCount(
      canonical_left_bands: [],
      canonical_combined_bands: [],
      canonical_right_bands: [],
      left_windows: 0,
      right_windows: 0,
      intersection_windows: 0,
      combined_windows: 0,
      symmetric_difference_windows: 0,
      total_windows: 0,
    )),
  )
}

pub fn discovery_32_empty_ids_unused_invalid_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  direct_check(
    invalid,
    [],
    [band(2, 4), band(9, 9), band(20, 19)],
    [band(-4, 1), band(11, 13)],
    [band(2, 4), band(9, 9)],
    [band(-4, 4), band(9, 9), band(11, 13)],
    [band(-4, 1), band(11, 13)],
  )
  |> should.equal(0)
}

pub fn discovery_32_single_gap_closed_endpoints_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_from_stage21(context, [1])
  direct_check(
    context,
    [1],
    [band(gap, gap)],
    [band(gap - 1, gap)],
    [band(gap, gap)],
    [band(gap - 1, gap)],
    [band(gap - 1, gap)],
  )
  |> should.equal(0)
  direct_check(
    context,
    [1],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
  )
  |> should.equal(0)
}

pub fn discovery_32_single_gap_one_side_and_outside_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_from_stage21(context, [1])
  direct_check(
    context,
    [1],
    [band(gap, gap)],
    [],
    [band(gap, gap)],
    [band(gap, gap)],
    [],
  )
  |> should.equal(1)
  direct_check(context, [1], [], [band(gap, gap)], [], [band(gap, gap)], [
    band(gap, gap),
  ])
  |> should.equal(1)
  direct_check(
    context,
    [1],
    [band(gap + 1, gap + 1)],
    [band(gap + 2, gap + 2)],
    [band(gap + 1, gap + 1)],
    [band(gap + 1, gap + 2)],
    [band(gap + 2, gap + 2)],
  )
  |> should.equal(0)
}

pub fn discovery_32_two_and_four_gaps_direct_enumeration_test() {
  let context = bootstrap.new_context(11, 21)
  direct_check(
    context,
    [1, 3],
    [band(42, 963)],
    [band(964, 1926)],
    [band(42, 963)],
    [band(42, 1926)],
    [band(964, 1926)],
  )
  direct_check(
    context,
    [1, 3, 2, 6],
    [band(42, 963), band(3000, 3500)],
    [band(100, 700), band(964, 1800)],
    [band(42, 963), band(3000, 3500)],
    [band(42, 1800), band(3000, 3500)],
    [band(100, 700), band(964, 1800)],
  )
}

pub fn discovery_32_empty_side_and_empty_valid_bands_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 2, 3]
  let x =
    direct_check(context, ids, [], [band(42, 963)], [], [band(42, 963)], [
      band(42, 963),
    ])
  let y =
    direct_check(
      context,
      ids,
      [band(42, 963)],
      [],
      [band(42, 963)],
      [band(42, 963)],
      [],
    )
  x |> should.equal(y)
  direct_check(context, ids, [], [], [], [], [])
  |> should.equal(0)
  direct_check(context, ids, [band(30, 29)], [], [], [], [])
  |> should.equal(0)
}

pub fn discovery_32_equal_sets_and_swapped_sides_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [6, 5, 4, 3]
  let a = [band(42, 100), band(300, 1000), band(42, 100)]
  let canonical = [band(42, 100), band(300, 1000)]
  direct_check(context, ids, a, a, canonical, canonical, canonical)
  |> should.equal(0)
  let x =
    direct_check(
      context,
      ids,
      a,
      [band(101, 299)],
      canonical,
      [band(42, 1000)],
      [band(101, 299)],
    )
  let y =
    direct_check(
      context,
      ids,
      [band(101, 299)],
      a,
      [band(101, 299)],
      [band(42, 1000)],
      canonical,
    )
  x |> should.equal(y)
}

pub fn discovery_32_inverted_negative_and_disjoint_bands_test() {
  let context = bootstrap.new_context(11, 21)
  direct_check(
    context,
    [1, 2, 3],
    [band(100, 90)],
    [band(-100, -1)],
    [],
    [band(-100, -1)],
    [band(-100, -1)],
  )
  |> should.equal(0)
  direct_check(
    context,
    [1, 2, 3],
    [band(2000, 3000)],
    [band(42, 963)],
    [band(2000, 3000)],
    [band(42, 963), band(2000, 3000)],
    [band(42, 963)],
  )
}

pub fn discovery_32_duplicates_nesting_and_cross_overlap_test() {
  direct_check(
    bootstrap.new_context(11, 21),
    [6, 2, 3, 1],
    [band(40, 700), band(80, 200), band(40, 700)],
    [band(100, 400), band(250, 1000)],
    [band(40, 700)],
    [band(40, 1000)],
    [band(100, 1000)],
  )
}

pub fn discovery_32_adjacent_closed_bands_three_canons_test() {
  direct_check(
    bootstrap.new_context(11, 21),
    [1, 3, 2, 6],
    [band(40, 100), band(101, 1000)],
    [band(101, 102), band(3000, 3100)],
    [band(40, 1000)],
    [band(40, 1000), band(3000, 3100)],
    [band(101, 102), band(3000, 3100)],
  )
}

pub fn discovery_32_repeated_ids_and_error_priority_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps_from_stage21(context, ids)
  direct_check(
    context,
    ids,
    [band(gap, gap)],
    [band(2 * gap, 2 * gap)],
    [band(gap, gap)],
    [band(gap, gap), band(2 * gap, 2 * gap)],
    [band(2 * gap, 2 * gap)],
  )
  |> should.equal(7)
  discovery_32_symmetric_difference_bands.dispatch_discovery_32(
    context,
    [7],
    [],
    [],
  )
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_32_symmetric_difference_bands.dispatch_discovery_32(
    invalid,
    [1],
    [],
    [],
  )
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_32_symmetric_difference_bands.dispatch_discovery_32(
    invalid,
    [7],
    [band(4, 3)],
    [],
  )
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_32_extreme_limits_long_sequence_symmetry_test() {
  let huge = core.m * core.m * core.m
  let wide = huge * huge
  let context = bootstrap.new_context(huge, -huge)
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3]
  let all = [band(-wide, wide)]
  direct_check(context, ids, all, [], all, all, [])
  |> should.equal(78)
  direct_check(context, ids, all, all, all, all, all)
  |> should.equal(0)
  let a = [band(42, 963)]
  let b = [band(100, 200)]
  let x = direct_check(context, ids, a, b, a, a, b)
  let y = direct_check(context, ids, b, a, b, a, a)
  x |> should.equal(y)
}
