// Stadio 37: sendependa Stage21-orakolo per rekta indeks-fenestra enumerado.
// La atendata frakcio uzas minimuman denominator-serĉon, neniam produktan gcd.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_33_jaccard_bands
import reference/core

type DirectCounts {
  DirectCounts(
    left: Int,
    right: Int,
    intersection: Int,
    union: Int,
    xor: Int,
    total: Int,
    numerator: Int,
    denominator: Int,
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
      let in_left = contains_directly(next_sum, original_left)
      let in_right = contains_directly(next_sum, original_right)
      let updated = DirectCounts(
        left: counts.left + bit(in_left),
        right: counts.right + bit(in_right),
        intersection: counts.intersection + bit(in_left && in_right),
        union: counts.union + bit(in_left || in_right),
        xor: counts.xor + bit(in_left != in_right),
        total: counts.total,
        numerator: counts.numerator,
        denominator: counts.denominator,
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
      let updated = examine_endings(
        suffix,
        0,
        original_left,
        original_right,
        counts,
      )
      enumerate_all_starts(remaining, original_left, original_right, updated)
    }
  }
}

fn first_valid_denominator(
  intersection: Int,
  union: Int,
  candidate: Int,
) -> Int {
  case { intersection * candidate } % union == 0 {
    True -> candidate
    False -> first_valid_denominator(intersection, union, candidate + 1)
  }
}

fn direct_fraction(intersection: Int, union: Int) -> #(Int, Int) {
  case union == 0 {
    True -> #(1, 1)
    False -> {
      let denominator = first_valid_denominator(intersection, union, 1)
      let numerator = { intersection * denominator } / union
      #(numerator, denominator)
    }
  }
}

fn direct_counts(
  gaps: List(Int),
  original_left: List(discovery_27_sum_bands.SumBand),
  original_right: List(discovery_27_sum_bands.SumBand),
) -> DirectCounts {
  let raw = enumerate_all_starts(
    gaps,
    original_left,
    original_right,
    DirectCounts(
      left: 0,
      right: 0,
      intersection: 0,
      union: 0,
      xor: 0,
      total: 0,
      numerator: 0,
      denominator: 1,
    ),
  )
  let k = list.length(gaps)
  let #(numerator, denominator) = direct_fraction(raw.intersection, raw.union)
  DirectCounts(
    left: raw.left,
    right: raw.right,
    intersection: raw.intersection,
    union: raw.union,
    xor: raw.xor,
    total: k * { k + 1 } / 2,
    numerator: numerator,
    denominator: denominator,
  )
}

fn gaps_from_stage21(
  context: bootstrap.MonsterContext,
  ids: List(Int),
) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  let gaps = list.map(samples, fn(sample) { sample.gap })
  list.all(gaps, fn(gap) { gap >= 42 && gap <= 963 })
  |> should.equal(True)
  gaps
}

fn direct_check_with_gaps(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  gaps: List(Int),
  original_left: List(discovery_27_sum_bands.SumBand),
  original_right: List(discovery_27_sum_bands.SumBand),
  expected_left: List(discovery_27_sum_bands.SumBand),
  expected_combined: List(discovery_27_sum_bands.SumBand),
  expected_right: List(discovery_27_sum_bands.SumBand),
) -> DirectCounts {
  let expected = direct_counts(gaps, original_left, original_right)
  let assert Ok(actual) =
    discovery_33_jaccard_bands.dispatch_discovery_33(
      context,
      ids,
      original_left,
      original_right,
    )

  actual.canonical_left_bands |> should.equal(expected_left)
  actual.canonical_combined_bands |> should.equal(expected_combined)
  actual.canonical_right_bands |> should.equal(expected_right)
  actual.left_windows |> should.equal(expected.left)
  actual.right_windows |> should.equal(expected.right)
  actual.intersection_windows |> should.equal(expected.intersection)
  actual.combined_windows |> should.equal(expected.union)
  actual.symmetric_difference_windows |> should.equal(expected.xor)
  actual.total_windows |> should.equal(expected.total)
  actual.similarity_numerator |> should.equal(expected.numerator)
  actual.similarity_denominator |> should.equal(expected.denominator)
  expected
}

fn direct_check(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  original_left: List(discovery_27_sum_bands.SumBand),
  original_right: List(discovery_27_sum_bands.SumBand),
  expected_left: List(discovery_27_sum_bands.SumBand),
  expected_combined: List(discovery_27_sum_bands.SumBand),
  expected_right: List(discovery_27_sum_bands.SumBand),
) -> DirectCounts {
  let gaps = gaps_from_stage21(context, ids)
  direct_check_with_gaps(
    context,
    ids,
    gaps,
    original_left,
    original_right,
    expected_left,
    expected_combined,
    expected_right,
  )
}

fn find_distinct_after(
  remaining_ids: List(Int),
  remaining_gaps: List(Int),
  first_id: Int,
  first_gap: Int,
) -> #(Int, Int, Int, Int) {
  case remaining_ids, remaining_gaps {
    [id, ..rest_ids], [gap, ..rest_gaps] ->
      case gap != first_gap {
        True -> #(first_id, first_gap, id, gap)
        False ->
          find_distinct_after(rest_ids, rest_gaps, first_id, first_gap)
      }
    [], [] -> panic as "Du malsamaj Stage21-interspacoj atenditaj"
    _, _ -> panic as "Malsama longo de ID- kaj interspac-listoj"
  }
}

fn first_distinct_pair(
  ids: List(Int),
  gaps: List(Int),
) -> #(Int, Int, Int, Int) {
  case ids, gaps {
    [id, ..rest_ids], [gap, ..rest_gaps] ->
      find_distinct_after(rest_ids, rest_gaps, id, gap)
    _, _ -> panic as "Almenaŭ du bovloj atenditaj"
  }
}

pub fn discovery_33_empty_ids_and_bands_test() {
  let context = bootstrap.new_context(11, 21)
  direct_check(
    context,
    [],
    [],
    [],
    [],
    [],
    [],
  )
  |> should.equal(DirectCounts(
    left: 0,
    right: 0,
    intersection: 0,
    union: 0,
    xor: 0,
    total: 0,
    numerator: 1,
    denominator: 1,
  ))
}

pub fn discovery_33_empty_ids_unused_invalid_context_test() {
  let base = bootstrap.new_context(11, 21)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  direct_check(
    invalid,
    [],
    [band(2, 4), band(9, 9), band(20, 19)],
    [band(-4, 1), band(11, 13)],
    [band(2, 4), band(9, 9)],
    [band(-4, 4), band(9, 9), band(11, 13)],
    [band(-4, 1), band(11, 13)],
  )
  |> should.equal(DirectCounts(
    left: 0,
    right: 0,
    intersection: 0,
    union: 0,
    xor: 0,
    total: 0,
    numerator: 1,
    denominator: 1,
  ))
}

pub fn discovery_33_single_gap_closed_endpoints_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_from_stage21(context, [1])
  direct_check_with_gaps(
    context,
    [1],
    [gap],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
  )
  |> should.equal(DirectCounts(
    left: 1,
    right: 1,
    intersection: 1,
    union: 1,
    xor: 0,
    total: 1,
    numerator: 1,
    denominator: 1,
  ))
}

pub fn discovery_33_one_side_and_outside_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_from_stage21(context, [1])

  direct_check_with_gaps(
    context,
    [1],
    [gap],
    [band(gap, gap)],
    [],
    [band(gap, gap)],
    [band(gap, gap)],
    [],
  )
  |> should.equal(DirectCounts(
    left: 1,
    right: 0,
    intersection: 0,
    union: 1,
    xor: 1,
    total: 1,
    numerator: 0,
    denominator: 1,
  ))

  direct_check_with_gaps(
    context,
    [1],
    [gap],
    [],
    [band(gap, gap)],
    [],
    [band(gap, gap)],
    [band(gap, gap)],
  )
  |> should.equal(DirectCounts(
    left: 0,
    right: 1,
    intersection: 0,
    union: 1,
    xor: 1,
    total: 1,
    numerator: 0,
    denominator: 1,
  ))

  direct_check_with_gaps(
    context,
    [1],
    [gap],
    [band(gap + 1, gap + 1)],
    [band(gap + 2, gap + 2)],
    [band(gap + 1, gap + 1)],
    [band(gap + 1, gap + 2)],
    [band(gap + 2, gap + 2)],
  )
  |> should.equal(DirectCounts(
    left: 0,
    right: 0,
    intersection: 0,
    union: 0,
    xor: 0,
    total: 1,
    numerator: 1,
    denominator: 1,
  ))
}

pub fn discovery_33_two_gap_partial_overlap_reduced_half_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 2, 3, 4, 5, 6]
  let gaps = gaps_from_stage21(context, ids)
  let #(first_id, first_gap, second_id, second_gap) =
    first_distinct_pair(ids, gaps)
  let lower = case first_gap < second_gap {
    True -> first_gap
    False -> second_gap
  }
  let upper = case first_gap > second_gap {
    True -> first_gap
    False -> second_gap
  }
  direct_check_with_gaps(
    context,
    [first_id, second_id],
    [first_gap, second_gap],
    [band(lower, upper)],
    [band(lower, lower)],
    [band(lower, upper)],
    [band(lower, upper)],
    [band(lower, lower)],
  )
  |> should.equal(DirectCounts(
    left: 2,
    right: 1,
    intersection: 1,
    union: 2,
    xor: 1,
    total: 3,
    numerator: 1,
    denominator: 2,
  ))
}

pub fn discovery_33_four_equal_gaps_reduced_two_thirds_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let gaps = gaps_from_stage21(context, ids)
  let assert [gap, second, third, fourth] = gaps
  { second == gap && third == gap && fourth == gap }
  |> should.equal(True)
  direct_check_with_gaps(
    context,
    ids,
    gaps,
    [band(3 * gap, 3 * gap)],
    [band(3 * gap, 4 * gap)],
    [band(3 * gap, 3 * gap)],
    [band(3 * gap, 4 * gap)],
    [band(3 * gap, 4 * gap)],
  )
  |> should.equal(DirectCounts(
    left: 2,
    right: 3,
    intersection: 2,
    union: 3,
    xor: 1,
    total: 10,
    numerator: 2,
    denominator: 3,
  ))
}

pub fn discovery_33_empty_side_swapped_and_zero_union_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 2, 3]
  let one_side = direct_check(
    context,
    ids,
    [],
    [band(42, 963)],
    [],
    [band(42, 963)],
    [band(42, 963)],
  )
  one_side.left |> should.equal(0)
  { one_side.right > 0 } |> should.equal(True)
  one_side.numerator |> should.equal(0)
  one_side.denominator |> should.equal(1)

  let swapped = direct_check(
    context,
    ids,
    [band(42, 963)],
    [],
    [band(42, 963)],
    [band(42, 963)],
    [],
  )
  swapped.left |> should.equal(one_side.right)
  swapped.right |> should.equal(one_side.left)
  swapped.numerator |> should.equal(one_side.numerator)
  swapped.denominator |> should.equal(one_side.denominator)

  direct_check(
    context,
    ids,
    [band(-1000, -900)],
    [band(100000, 200000)],
    [band(-1000, -900)],
    [band(-1000, -900), band(100000, 200000)],
    [band(100000, 200000)],
  )
  |> should.equal(DirectCounts(
    left: 0,
    right: 0,
    intersection: 0,
    union: 0,
    xor: 0,
    total: 6,
    numerator: 1,
    denominator: 1,
  ))
}

pub fn discovery_33_equal_sets_duplicates_nested_and_disjoint_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [6, 2, 3, 1]
  let bands = [
    band(40, 700),
    band(80, 200),
    band(40, 700),
    band(900, 1000),
  ]
  let canonical = [band(40, 700), band(900, 1000)]
  let result = direct_check(
    context,
    ids,
    bands,
    bands,
    canonical,
    canonical,
    canonical,
  )
  result.left |> should.equal(result.right)
  result.intersection |> should.equal(result.union)
  result.xor |> should.equal(0)
  result.numerator |> should.equal(1)
  result.denominator |> should.equal(1)
}

pub fn discovery_33_overlapping_adjacent_inverted_canonical_bands_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 3, 2, 6]
  let left = [band(40, 100), band(101, 1000), band(50, 49)]
  let right = [
    band(101, 102),
    band(1001, 1001),
    band(3000, 3100),
    band(2000, 1999),
  ]
  direct_check(
    context,
    ids,
    left,
    right,
    [band(40, 1000)],
    [band(40, 1001), band(3000, 3100)],
    [band(101, 102), band(1001, 1001), band(3000, 3100)],
  )
}

pub fn discovery_33_repeated_ids_are_distinct_index_windows_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let gaps = gaps_from_stage21(context, ids)
  let assert [gap, _, _, _] = gaps
  direct_check_with_gaps(
    context,
    ids,
    gaps,
    [band(gap, gap)],
    [band(2 * gap, 2 * gap)],
    [band(gap, gap)],
    [band(gap, gap), band(2 * gap, 2 * gap)],
    [band(2 * gap, 2 * gap)],
  )
  |> should.equal(DirectCounts(
    left: 4,
    right: 3,
    intersection: 0,
    union: 7,
    xor: 7,
    total: 10,
    numerator: 0,
    denominator: 1,
  ))
}

pub fn discovery_33_invalid_inputs_and_stage32_error_priority_test() {
  let context = bootstrap.new_context(11, 21)
  discovery_33_jaccard_bands.dispatch_discovery_33(
    context,
    [7],
    [],
    [],
  )
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))

  let invalid_retry = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_33_jaccard_bands.dispatch_discovery_33(
    invalid_retry,
    [1],
    [],
    [],
  )
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_33_jaccard_bands.dispatch_discovery_33(
    invalid_retry,
    [7],
    [],
    [],
  )
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )

  let invalid_recovery = bootstrap.MonsterContext(..context, recovery_depth: -1)
  discovery_33_jaccard_bands.dispatch_discovery_33(
    invalid_recovery,
    [7],
    [],
    [],
  )
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRecoveryDepth,
    )),
  )
}

pub fn discovery_33_beam_large_limits_symmetry_and_no_monotonicity_claim_test() {
  let huge = core.m * core.m * core.m
  let wide = huge * huge
  let context = bootstrap.new_context(huge, -huge)
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3]
  let gaps = gaps_from_stage21(context, ids)
  let all = [band(-wide, wide)]
  let high = [band(2 * wide, 3 * wide)]

  direct_check_with_gaps(
    context,
    ids,
    gaps,
    all,
    all,
    all,
    all,
    all,
  )
  |> should.equal(DirectCounts(
    left: 78,
    right: 78,
    intersection: 78,
    union: 78,
    xor: 0,
    total: 78,
    numerator: 1,
    denominator: 1,
  ))

  let forward = direct_check_with_gaps(
    context,
    ids,
    gaps,
    all,
    high,
    all,
    [band(-wide, wide), band(2 * wide, 3 * wide)],
    high,
  )
  let reverse = direct_check_with_gaps(
    context,
    ids,
    gaps,
    high,
    all,
    high,
    [band(-wide, wide), band(2 * wide, 3 * wide)],
    all,
  )
  forward.numerator |> should.equal(reverse.numerator)
  forward.denominator |> should.equal(reverse.denominator)
  forward.numerator |> should.equal(0)
  forward.denominator |> should.equal(1)
}
