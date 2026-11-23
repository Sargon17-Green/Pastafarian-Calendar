// Stadio 39: sendependa Stage21-orakolo per rekta indeksa fenestrado.
// Atendataj frakcioj venas de minimuma denominator-serco, ne de produkta gcd.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_35_overlap_bands

type Counts {
  Counts(
    left: Int,
    right: Int,
    intersection: Int,
    combined: Int,
    difference: Int,
    total: Int,
  )
}

fn band(lower: Int, upper: Int) {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn member(original: List(discovery_27_sum_bands.SumBand), sum: Int) -> Bool {
  case original {
    [] -> False
    [first, ..tail] ->
      case first.lower <= sum && sum <= first.upper {
        True -> True
        False -> member(tail, sum)
      }
  }
}

fn indicator(found: Bool) -> Int {
  case found {
    True -> 1
    False -> 0
  }
}

fn endings(
  suffix: List(Int),
  running: Int,
  left: List(discovery_27_sum_bands.SumBand),
  right: List(discovery_27_sum_bands.SumBand),
  counts: Counts,
) -> Counts {
  case suffix {
    [] -> counts
    [gap, ..tail] -> {
      let sum = running + gap
      let a = member(left, sum)
      let b = member(right, sum)
      endings(
        tail,
        sum,
        left,
        right,
        Counts(
          left: counts.left + indicator(a),
          right: counts.right + indicator(b),
          intersection: counts.intersection + indicator(a && b),
          combined: counts.combined + indicator(a || b),
          difference: counts.difference + indicator(a != b),
          total: counts.total + 1,
        ),
      )
    }
  }
}

fn all_starts(
  suffix: List(Int),
  left: List(discovery_27_sum_bands.SumBand),
  right: List(discovery_27_sum_bands.SumBand),
  counts: Counts,
) -> Counts {
  case suffix {
    [] -> counts
    [_, ..tail] ->
      all_starts(tail, left, right, endings(suffix, 0, left, right, counts))
  }
}

fn independent_denominator(
  numerator: Int,
  denominator: Int,
  candidate: Int,
) -> Int {
  case { numerator * candidate } % denominator == 0 {
    True -> candidate
    False -> independent_denominator(numerator, denominator, candidate + 1)
  }
}

fn fraction(numerator: Int, denominator: Int) -> #(Int, Int) {
  case denominator == 0 {
    True -> #(1, 1)
    False -> {
      let q = independent_denominator(numerator, denominator, 1)
      #(numerator * q / denominator, q)
    }
  }
}

fn overlap(expected: Counts) -> #(Int, Int) {
  let minimum = case expected.left < expected.right {
    True -> expected.left
    False -> expected.right
  }
  case minimum == 0 {
    True -> case expected.left == 0 && expected.right == 0 {
      True -> #(1, 1)
      False -> #(0, 1)
    }
    False -> fraction(expected.intersection, minimum)
  }
}

fn gaps(context: bootstrap.MonsterContext, ids: List(Int)) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.map(samples, fn(sample) { sample.gap })
}

fn verify(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  original_left: List(discovery_27_sum_bands.SumBand),
  original_right: List(discovery_27_sum_bands.SumBand),
) -> discovery_35_overlap_bands.OverlapWindowSimilarity {
  let expected =
    all_starts(
      gaps(context, ids),
      original_left,
      original_right,
      Counts(
        left: 0,
        right: 0,
        intersection: 0,
        combined: 0,
        difference: 0,
        total: 0,
      ),
    )
  let #(o_p, o_q) = overlap(expected)
  let #(j_p, j_q) = fraction(expected.intersection, expected.combined)
  let #(d_p, d_q) =
    fraction(2 * expected.intersection, expected.left + expected.right)
  let assert Ok(actual) =
    discovery_35_overlap_bands.dispatch_discovery_35(
      context,
      ids,
      original_left,
      original_right,
    )
  actual.left_windows |> should.equal(expected.left)
  actual.right_windows |> should.equal(expected.right)
  actual.intersection_windows |> should.equal(expected.intersection)
  actual.combined_windows |> should.equal(expected.combined)
  actual.symmetric_difference_windows |> should.equal(expected.difference)
  actual.total_windows |> should.equal(expected.total)
  actual.overlap_numerator |> should.equal(o_p)
  actual.overlap_denominator |> should.equal(o_q)
  actual.jaccard_numerator |> should.equal(j_p)
  actual.jaccard_denominator |> should.equal(j_q)
  actual.dice_numerator |> should.equal(d_p)
  actual.dice_denominator |> should.equal(d_q)
  { o_p * d_q >= d_p * o_q && d_p * j_q >= j_p * d_q }
  |> should.equal(True)
  actual
}

fn power_ten(exponent: Int, accumulated: Int) -> Int {
  case exponent == 0 {
    True -> accumulated
    False -> power_ten(exponent - 1, accumulated * 10)
  }
}

pub fn discovery_35_empty_ids_empty_bands_test() {
  let result = verify(bootstrap.new_context(11, 21), [], [], [])
  result.total_windows |> should.equal(0)
  result.overlap_numerator |> should.equal(1)
  result.overlap_denominator |> should.equal(1)
  result.canonical_combined_bands |> should.equal([])
}

pub fn discovery_35_empty_ids_nonempty_and_inverted_bands_test() {
  let result =
    verify(
      bootstrap.new_context(11, 21),
      [],
      [band(20, 19), band(2, 4), band(9, 9)],
      [band(-4, 1), band(11, 13)],
    )
  result.overlap_numerator |> should.equal(1)
  result.overlap_denominator |> should.equal(1)
  result.canonical_left_bands |> should.equal([band(2, 4), band(9, 9)])
  result.canonical_right_bands |> should.equal([band(-4, 1), band(11, 13)])
  result.canonical_combined_bands
  |> should.equal([band(-4, 4), band(9, 9), band(11, 13)])
}

pub fn discovery_35_single_gap_closed_endpoints_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps(context, [1])
  let result = verify(context, [1], [band(gap, gap)], [band(gap, gap)])
  result.left_windows |> should.equal(1)
  result.right_windows |> should.equal(1)
  result.intersection_windows |> should.equal(1)
  result.overlap_numerator |> should.equal(1)
  result.overlap_denominator |> should.equal(1)
}

pub fn discovery_35_single_gap_one_side_and_both_absent_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps(context, [1])
  let a = verify(context, [1], [band(gap, gap)], [])
  let b = verify(context, [1], [], [band(gap, gap)])
  a.overlap_numerator |> should.equal(0)
  a.overlap_denominator |> should.equal(1)
  b.overlap_numerator |> should.equal(0)
  b.overlap_denominator |> should.equal(1)
  let neither = verify(context, [1], [band(gap + 1, gap + 1)], [
    band(gap + 2, gap + 2),
  ])
  neither.overlap_numerator |> should.equal(1)
  neither.overlap_denominator |> should.equal(1)
}

pub fn discovery_35_two_and_three_gap_independent_counts_test() {
  let context = bootstrap.new_context(11, 21)
  let two = verify(context, [1, 2], [band(42, 1200)], [band(500, 2000)])
  two.total_windows |> should.equal(3)
  let three =
    verify(context, [1, 2, 3], [band(42, 963)], [band(500, 3000)])
  three.total_windows |> should.equal(6)
  { three.intersection_windows <= three.left_windows }
  |> should.equal(True)
}

pub fn discovery_35_three_distinct_reduced_fractions_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps(context, ids)
  let half = verify(context, ids, [band(gap, 2 * gap)], [
    band(2 * gap, 4 * gap),
  ])
  half.overlap_numerator |> should.equal(1)
  half.overlap_denominator |> should.equal(2)
  let two_thirds = verify(context, ids, [band(2 * gap, 3 * gap)], [
    band(3 * gap, 4 * gap),
  ])
  two_thirds.overlap_numerator |> should.equal(2)
  two_thirds.overlap_denominator |> should.equal(3)
  let three_quarters = verify(context, ids, [
    band(2 * gap, 2 * gap),
    band(4 * gap, 4 * gap),
  ], [band(gap, 2 * gap)])
  three_quarters.overlap_numerator |> should.equal(3)
  three_quarters.overlap_denominator |> should.equal(4)
}

pub fn discovery_35_proper_subset_has_overlap_one_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps(context, ids)
  let result = verify(context, ids, [band(gap, gap)], [
    band(gap, 2 * gap),
  ])
  result.left_windows |> should.equal(4)
  result.right_windows |> should.equal(7)
  result.overlap_numerator |> should.equal(1)
  result.overlap_denominator |> should.equal(1)
  { result.jaccard_numerator < result.jaccard_denominator }
  |> should.equal(True)
  { result.dice_numerator < result.dice_denominator }
  |> should.equal(True)
}

pub fn discovery_35_duplicate_nested_and_identical_bands_test() {
  let context = bootstrap.new_context(11, 21)
  let repeated = [
    band(42, 963),
    band(80, 200),
    band(42, 963),
    band(10_000, 11_000),
  ]
  let result = verify(context, [6, 2, 3, 1], repeated, repeated)
  result.left_windows |> should.equal(result.right_windows)
  result.intersection_windows |> should.equal(result.combined_windows)
  result.overlap_numerator |> should.equal(1)
  result.canonical_left_bands
  |> should.equal([band(42, 963), band(10_000, 11_000)])
}

pub fn discovery_35_adjacent_inverted_and_wide_limits_test() {
  let context = bootstrap.new_context(11, 21)
  let wide = power_ten(70, 1)
  let left = [
    band(-wide, -wide + 1),
    band(40, 100),
    band(101, 1000),
    band(50, 49),
  ]
  let right = [band(101, 102), band(1001, 1001), band(wide, wide)]
  let result = verify(context, [1, 3, 2, 6], left, right)
  result.canonical_left_bands
  |> should.equal([band(-wide, -wide + 1), band(40, 1000)])
  result.canonical_right_bands
  |> should.equal([band(101, 102), band(1001, 1001), band(wide, wide)])
  result.canonical_combined_bands
  |> should.equal([
    band(-wide, -wide + 1),
    band(40, 1001),
    band(wide, wide),
  ])
}

pub fn discovery_35_repeated_ids_preserve_index_multiplicity_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps(context, ids)
  let result = verify(context, ids, [band(gap, gap)], [
    band(2 * gap, 2 * gap),
  ])
  result.total_windows |> should.equal(10)
  result.left_windows |> should.equal(4)
  result.right_windows |> should.equal(3)
  result.intersection_windows |> should.equal(0)
  result.overlap_numerator |> should.equal(0)
  result.overlap_denominator |> should.equal(1)
}

pub fn discovery_35_error_priority_and_invalid_context_test() {
  let context = bootstrap.new_context(11, 21)
  discovery_35_overlap_bands.dispatch_discovery_35(context, [7], [], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let retry = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_35_overlap_bands.dispatch_discovery_35(retry, [1], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_35_overlap_bands.dispatch_discovery_35(retry, [7], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  let recovery = bootstrap.MonsterContext(..context, recovery_depth: -1)
  discovery_35_overlap_bands.dispatch_discovery_35(recovery, [7], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRecoveryDepth,
    )),
  )
}

pub fn discovery_35_twelve_gaps_symmetry_identity_and_exact_order_test() {
  let context = bootstrap.new_context(11, 21)
  let wide = power_ten(70, 1)
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3]
  let all = [band(-wide, wide)]
  let outside = [band(2 * wide, 3 * wide)]
  let same = verify(context, ids, all, all)
  same.total_windows |> should.equal(78)
  same.overlap_numerator |> should.equal(1)
  same.overlap_denominator |> should.equal(1)
  let forward = verify(context, ids, all, outside)
  let reversed = verify(context, ids, outside, all)
  forward.overlap_numerator |> should.equal(reversed.overlap_numerator)
  forward.overlap_denominator |> should.equal(reversed.overlap_denominator)
  let partial = verify(context, ids, [band(42, 963)], [
    band(500, 3000),
  ])
  { partial.overlap_numerator * partial.dice_denominator
    >= partial.dice_numerator * partial.overlap_denominator }
  |> should.equal(True)
  { partial.dice_numerator * partial.jaccard_denominator
    >= partial.jaccard_numerator * partial.dice_denominator }
  |> should.equal(True)
}
