// Stadio 38: sendependa orakolo de originaj Stage21-gapoj.
// Rekta indeks-fenestra enumerado kaj minimuma denominator-serco;
// neniu Stage37/38 produkto en la orakolo kaj neniu produkta gcd.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_33_jaccard_bands
import pastafari/discovery_34_dice_bands

type WindowTally {
  WindowTally(
    left: Int,
    right: Int,
    both: Int,
    either: Int,
    exclusive: Int,
    total: Int,
  )
}

fn band(lower: Int, upper: Int) {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn has_sum(original: List(discovery_27_sum_bands.SumBand), value: Int) -> Bool {
  case original {
    [] -> False
    [first, ..rest] ->
      case value >= first.lower && value <= first.upper {
        True -> True
        False -> has_sum(rest, value)
      }
  }
}

fn increment(value: Bool) -> Int {
  case value {
    True -> 1
    False -> 0
  }
}

fn walk_ending_windows(
  remaining: List(Int),
  sum: Int,
  left: List(discovery_27_sum_bands.SumBand),
  right: List(discovery_27_sum_bands.SumBand),
  tally: WindowTally,
) -> WindowTally {
  case remaining {
    [] -> tally
    [gap, ..rest] -> {
      let next = sum + gap
      let a = has_sum(left, next)
      let b = has_sum(right, next)
      let updated =
        WindowTally(
          left: tally.left + increment(a),
          right: tally.right + increment(b),
          both: tally.both + increment(a && b),
          either: tally.either + increment(a || b),
          exclusive: tally.exclusive + increment(a != b),
          total: tally.total + 1,
        )
      walk_ending_windows(rest, next, left, right, updated)
    }
  }
}

fn walk_start_windows(
  remaining: List(Int),
  left: List(discovery_27_sum_bands.SumBand),
  right: List(discovery_27_sum_bands.SumBand),
  tally: WindowTally,
) -> WindowTally {
  case remaining {
    [] -> tally
    [_, ..tail] -> {
      let counted = walk_ending_windows(remaining, 0, left, right, tally)
      walk_start_windows(tail, left, right, counted)
    }
  }
}

fn gaps(context: bootstrap.MonsterContext, ids: List(Int)) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.map(samples, fn(sample) { sample.gap })
}

fn minimum_denominator(
  numerator: Int,
  denominator: Int,
  candidate: Int,
) -> Int {
  case { numerator * candidate } % denominator == 0 {
    True -> candidate
    False -> minimum_denominator(numerator, denominator, candidate + 1)
  }
}

fn independent_fraction(numerator: Int, denominator: Int) -> #(Int, Int) {
  case denominator == 0 {
    True -> #(1, 1)
    False -> {
      let q = minimum_denominator(numerator, denominator, 1)
      #(numerator * q / denominator, q)
    }
  }
}

fn check_against_direct_windows(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  left: List(discovery_27_sum_bands.SumBand),
  right: List(discovery_27_sum_bands.SumBand),
) -> discovery_34_dice_bands.DiceWindowSimilarity {
  let expected =
    walk_start_windows(
      gaps(context, ids),
      left,
      right,
      WindowTally(left: 0, right: 0, both: 0, either: 0, exclusive: 0, total: 0),
    )
  let #(d_p, d_q) =
    independent_fraction(2 * expected.both, expected.left + expected.right)
  let #(j_p, j_q) = independent_fraction(expected.both, expected.either)
  let assert Ok(actual) =
    discovery_34_dice_bands.dispatch_discovery_34(context, ids, left, right)
  actual.left_windows |> should.equal(expected.left)
  actual.right_windows |> should.equal(expected.right)
  actual.intersection_windows |> should.equal(expected.both)
  actual.combined_windows |> should.equal(expected.either)
  actual.symmetric_difference_windows |> should.equal(expected.exclusive)
  actual.total_windows |> should.equal(expected.total)
  actual.dice_numerator |> should.equal(d_p)
  actual.dice_denominator |> should.equal(d_q)
  actual.jaccard_numerator |> should.equal(j_p)
  actual.jaccard_denominator |> should.equal(j_q)
  actual
}

fn power_of_ten(exponent: Int, value: Int) -> Int {
  case exponent == 0 {
    True -> value
    False -> power_of_ten(exponent - 1, value * 10)
  }
}

pub fn discovery_34_empty_ids_and_bands_test() {
  let output =
    check_against_direct_windows(bootstrap.new_context(11, 21), [], [], [])
  output.total_windows |> should.equal(0)
  output.dice_numerator |> should.equal(1)
  output.dice_denominator |> should.equal(1)
}

pub fn discovery_34_empty_ids_unused_bands_test() {
  let output =
    check_against_direct_windows(
      bootstrap.new_context(11, 21),
      [],
      [band(20, 19), band(2, 4), band(9, 9)],
      [band(-4, 1), band(11, 13)],
    )
  output.canonical_left_bands |> should.equal([band(2, 4), band(9, 9)])
  output.canonical_right_bands |> should.equal([band(-4, 1), band(11, 13)])
  output.dice_numerator |> should.equal(1)
}

pub fn discovery_34_single_gap_closed_endpoints_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps(context, [1])
  let output =
    check_against_direct_windows(context, [1], [band(gap, gap)], [
      band(gap, gap),
    ])
  output.left_windows |> should.equal(1)
  output.intersection_windows |> should.equal(1)
  output.dice_numerator |> should.equal(1)
  output.dice_denominator |> should.equal(1)
}

pub fn discovery_34_single_gap_disjoint_or_absent_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps(context, [1])
  let one = check_against_direct_windows(context, [1], [band(gap, gap)], [])
  one.dice_numerator |> should.equal(0)
  one.dice_denominator |> should.equal(1)
  let absent =
    check_against_direct_windows(context, [1], [band(gap + 1, gap + 1)], [
      band(gap + 2, gap + 2),
    ])
  absent.dice_numerator |> should.equal(1)
  absent.dice_denominator |> should.equal(1)
}

pub fn discovery_34_two_and_three_gap_partial_intersections_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 2, 3]
  let first =
    check_against_direct_windows(context, [1, 2], [band(42, 1200)], [
      band(500, 2000),
    ])
  { first.intersection_windows <= first.left_windows }
  |> should.equal(True)
  let second =
    check_against_direct_windows(context, ids, [band(42, 963)], [
      band(500, 3000),
    ])
  { second.combined_windows <= 6 } |> should.equal(True)
}

pub fn discovery_34_reduced_half_and_two_thirds_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps(context, ids)
  let half =
    check_against_direct_windows(context, ids, [band(3 * gap, 3 * gap)], [
      band(2 * gap, 4 * gap),
    ])
  half.dice_numerator |> should.equal(1)
  half.dice_denominator |> should.equal(2)
  let two_thirds =
    check_against_direct_windows(context, ids, [band(gap, 3 * gap)], [
      band(2 * gap, 4 * gap),
    ])
  two_thirds.dice_numerator |> should.equal(2)
  two_thirds.dice_denominator |> should.equal(3)
}

pub fn discovery_34_empty_side_swap_and_zero_union_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 2, 3]
  let a = check_against_direct_windows(context, ids, [], [band(42, 963)])
  let b = check_against_direct_windows(context, ids, [band(42, 963)], [])
  a.dice_numerator |> should.equal(0)
  a.dice_denominator |> should.equal(1)
  b.dice_numerator |> should.equal(a.dice_numerator)
  let none =
    check_against_direct_windows(context, ids, [band(-1000, -900)], [
      band(100_000, 200_000),
    ])
  none.dice_numerator |> should.equal(1)
  none.dice_denominator |> should.equal(1)
}

pub fn discovery_34_equal_bands_duplicates_and_nested_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [6, 2, 3, 1]
  let repeated = [
    band(42, 963),
    band(80, 200),
    band(42, 963),
    band(10_000, 11_000),
  ]
  let output = check_against_direct_windows(context, ids, repeated, repeated)
  output.canonical_left_bands
  |> should.equal([band(42, 963), band(10_000, 11_000)])
  output.canonical_right_bands |> should.equal(output.canonical_left_bands)
  output.dice_numerator |> should.equal(1)
  output.dice_denominator |> should.equal(1)
}

pub fn discovery_34_adjacent_inverted_negative_bands_test() {
  let context = bootstrap.new_context(11, 21)
  let left = [band(40, 100), band(101, 1000), band(50, 49)]
  let right = [
    band(101, 102),
    band(1001, 1001),
    band(3000, 3100),
    band(2000, 1999),
  ]
  let output = check_against_direct_windows(context, [1, 3, 2, 6], left, right)
  output.canonical_left_bands |> should.equal([band(40, 1000)])
  output.canonical_combined_bands
  |> should.equal([band(40, 1001), band(3000, 3100)])
  output.canonical_right_bands
  |> should.equal([band(101, 102), band(1001, 1001), band(3000, 3100)])
}

pub fn discovery_34_repeated_bowls_preserve_index_windows_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps(context, ids)
  let output =
    check_against_direct_windows(context, ids, [band(gap, gap)], [
      band(2 * gap, 2 * gap),
    ])
  output.total_windows |> should.equal(10)
  output.left_windows |> should.equal(4)
  output.right_windows |> should.equal(3)
  output.intersection_windows |> should.equal(0)
}

pub fn discovery_34_error_priority_matches_stage37_test() {
  let context = bootstrap.new_context(11, 21)
  discovery_34_dice_bands.dispatch_discovery_34(context, [7], [], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_34_dice_bands.dispatch_discovery_34(invalid, [7], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_33_jaccard_bands.dispatch_discovery_33(invalid, [7], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_34_large_limits_symmetry_and_metamorphic_test() {
  let context = bootstrap.new_context(11, 21)
  let wide = power_of_ten(70, 1)
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3]
  let all = [band(-wide, wide)]
  let outside = [band(2 * wide, 3 * wide)]
  let equal = check_against_direct_windows(context, ids, all, all)
  equal.total_windows |> should.equal(78)
  equal.dice_numerator |> should.equal(1)
  equal.dice_denominator |> should.equal(1)
  let forward = check_against_direct_windows(context, ids, all, outside)
  let swapped = check_against_direct_windows(context, ids, outside, all)
  forward.dice_numerator |> should.equal(swapped.dice_numerator)
  forward.dice_denominator |> should.equal(swapped.dice_denominator)
  let j_p = forward.jaccard_numerator
  let j_q = forward.jaccard_denominator
  { forward.dice_numerator * { j_p + j_q } }
  |> should.equal(2 * j_p * forward.dice_denominator)
}
