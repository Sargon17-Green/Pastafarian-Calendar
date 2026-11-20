// Stadio 34: originalaj Stage21-fenestroj kaj rekta A-sed-ne-B-orakolo.
// La testo ne kalkulas la atendon per la produktaj Stage26..33-funkcioj.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_30_difference_bands
import reference/core

fn band(lower: Int, upper: Int) {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn actual(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
) {
  discovery_30_difference_bands.dispatch_discovery_30(context, ids, a, b)
}

fn gaps_for(
  context: bootstrap.MonsterContext,
  ids: List(Int),
) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.each(samples, fn(sample) {
    {
      sample.gap >= discovery_20_gate_gap.gap_min
      && sample.gap <= discovery_20_gate_gap.gap_max
    }
    |> should.equal(True)
  })
  list.map(samples, fn(sample) { sample.gap })
}

fn contains_original(
  sum: Int,
  requests: List(discovery_27_sum_bands.SumBand),
) -> Bool {
  case requests {
    [] -> False
    [one, ..rest] ->
      case one.lower <= one.upper && one.lower <= sum && sum <= one.upper {
        True -> True
        False -> contains_original(sum, rest)
      }
  }
}

fn enumerate_ends(
  suffix: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
  sum: Int,
  counts: #(Int, Int, Int),
) -> #(Int, Int, Int) {
  case suffix {
    [] -> counts
    [gap, ..rest] -> {
      let next_sum = sum + gap
      let in_a = contains_original(next_sum, a)
      let in_b = contains_original(next_sum, b)
      let #(combined, excluded, difference) = counts
      let next_combined = case in_a || in_b {
        True -> combined + 1
        False -> combined
      }
      let next_excluded = case in_b {
        True -> excluded + 1
        False -> excluded
      }
      let next_difference = case in_a && !in_b {
        True -> difference + 1
        False -> difference
      }
      enumerate_ends(
        rest,
        a,
        b,
        next_sum,
        #(next_combined, next_excluded, next_difference),
      )
    }
  }
}

fn enumerate_starts(
  suffix: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
  counts: #(Int, Int, Int),
) -> #(Int, Int, Int) {
  case suffix {
    [] -> counts
    [_, ..rest] -> {
      let next_counts = enumerate_ends(suffix, a, b, 0, counts)
      enumerate_starts(rest, a, b, next_counts)
    }
  }
}

fn check_valid(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  original_a: List(discovery_27_sum_bands.SumBand),
  original_b: List(discovery_27_sum_bands.SumBand),
  expected_combined_bands: List(discovery_27_sum_bands.SumBand),
  expected_excluded_bands: List(discovery_27_sum_bands.SumBand),
) -> Int {
  let gaps = gaps_for(context, ids)
  let #(combined, excluded, difference) =
    enumerate_starts(gaps, original_a, original_b, #(0, 0, 0))
  let k = list.length(gaps)
  let total = k * { k + 1 } / 2
  let assert Ok(value) = actual(context, ids, original_a, original_b)
  value.canonical_combined_bands |> should.equal(expected_combined_bands)
  value.canonical_excluded_bands |> should.equal(expected_excluded_bands)
  value.combined_windows |> should.equal(combined)
  value.excluded_windows |> should.equal(excluded)
  value.difference_windows |> should.equal(difference)
  value.total_windows |> should.equal(total)
  { combined >= excluded && excluded >= 0 && combined <= total }
  |> should.equal(True)
  { difference >= 0 && difference <= total }
  |> should.equal(True)
  { difference + excluded } |> should.equal(combined)
  difference
}

pub fn discovery_30_empty_ids_empty_bands_test() {
  actual(bootstrap.new_context(11, 21), [], [], [])
  |> should.equal(
    Ok(discovery_30_difference_bands.DifferenceWindowCount(
      canonical_combined_bands: [],
      canonical_excluded_bands: [],
      combined_windows: 0,
      excluded_windows: 0,
      difference_windows: 0,
      total_windows: 0,
    )),
  )
}

pub fn discovery_30_empty_ids_unused_invalid_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  check_valid(
    invalid,
    [],
    [band(2, 4), band(9, 9), band(20, 19)],
    [band(-4, 1), band(11, 13)],
    [band(-4, 4), band(9, 9), band(11, 13)],
    [band(-4, 1), band(11, 13)],
  )
  |> should.equal(0)
}

pub fn discovery_30_single_gap_inclusive_boundary_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_for(context, [1])
  check_valid(context, [1], [band(gap, gap)], [], [band(gap, gap)], [])
  |> should.equal(1)
  check_valid(
    context,
    [1],
    [band(gap + 1, gap + 1)],
    [],
    [band(gap + 1, gap + 1)],
    [],
  )
  |> should.equal(0)
}

pub fn discovery_30_single_gap_excluded_endpoint_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_for(context, [1])
  check_valid(
    context,
    [1],
    [band(gap - 1, gap)],
    [band(gap, gap + 1)],
    [band(gap - 1, gap + 1)],
    [band(gap, gap + 1)],
  )
  |> should.equal(0)
  check_valid(
    context,
    [1],
    [band(gap - 1, gap)],
    [band(gap + 1, gap + 2)],
    [band(gap - 1, gap + 2)],
    [band(gap + 1, gap + 2)],
  )
  |> should.equal(1)
}

pub fn discovery_30_two_and_four_gap_direct_oracle_test() {
  let context = bootstrap.new_context(11, 21)
  check_valid(
    context,
    [1, 3],
    [band(40, 963)],
    [band(100, 900)],
    [band(40, 963)],
    [band(100, 900)],
  )
  check_valid(
    context,
    [1, 3, 2, 6],
    [band(40, 1000), band(1001, 2000)],
    [band(1000, 1100)],
    [band(40, 2000)],
    [band(1000, 1100)],
  )
}

pub fn discovery_30_empty_left_nonempty_right_test() {
  check_valid(
    bootstrap.new_context(11, 21),
    [1, 2, 3],
    [],
    [band(40, 3000), band(3, 2)],
    [band(40, 3000)],
    [band(40, 3000)],
  )
  |> should.equal(0)
}

pub fn discovery_30_empty_right_and_both_empty_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 2, 3, 1]
  check_valid(context, ids, [band(42, 963)], [], [band(42, 963)], [])
  check_valid(context, ids, [], [], [], [])
  |> should.equal(0)
}

pub fn discovery_30_inverted_and_negative_bands_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [2, 6, 1, 4]
  check_valid(
    context,
    ids,
    [band(-400, -1), band(30, 20)],
    [band(-300, -1), band(9, 8)],
    [band(-400, -1)],
    [band(-300, -1)],
  )
  |> should.equal(0)
  check_valid(
    context,
    ids,
    [band(-1000, 1000), band(0, -1)],
    [band(-300, -1)],
    [band(-1000, 1000)],
    [band(-300, -1)],
  )
}

pub fn discovery_30_duplicate_nested_overlap_cross_bands_test() {
  check_valid(
    bootstrap.new_context(11, 21),
    [6, 2, 3, 1],
    [band(40, 700), band(80, 200), band(40, 700)],
    [band(100, 400), band(250, 1000)],
    [band(40, 1000)],
    [band(100, 1000)],
  )
}

pub fn discovery_30_adjacent_disjoint_high_sums_test() {
  check_valid(
    bootstrap.new_context(11, 21),
    [1, 3, 2, 6],
    [band(40, 100), band(101, 1000)],
    [band(101, 102), band(3000, 3100)],
    [band(40, 1000), band(3000, 3100)],
    [band(101, 102), band(3000, 3100)],
  )
}

pub fn discovery_30_repeated_ids_and_error_priority_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps_for(context, ids)
  check_valid(
    context,
    ids,
    [band(gap, gap), band(gap, gap)],
    [band(2 * gap, 2 * gap)],
    [band(gap, gap), band(2 * gap, 2 * gap)],
    [band(2 * gap, 2 * gap)],
  )
  |> should.equal(4)
  actual(context, [7], [], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  actual(invalid, [1], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  actual(invalid, [7], [band(2, 1)], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_30_huge_limits_and_monotonicity_test() {
  let huge = core.m * core.m + core.m
  let extreme = huge * huge
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3]
  let context = bootstrap.new_context(huge, -huge)
  check_valid(
    context,
    ids,
    [band(-extreme, extreme), band(0, -1)],
    [band(42, 963)],
    [band(-extreme, extreme)],
    [band(42, 963)],
  )
  let narrow = check_valid(
    context,
    ids,
    [band(42, 963)],
    [band(100, 200)],
    [band(42, 963)],
    [band(100, 200)],
  )
  let more_b = check_valid(
    context,
    ids,
    [band(42, 963)],
    [band(100, 200), band(201, 1926)],
    [band(42, 1926)],
    [band(100, 1926)],
  )
  let more_a = check_valid(
    context,
    ids,
    [band(42, 963), band(964, 1926)],
    [band(100, 200)],
    [band(42, 1926)],
    [band(100, 200)],
  )
  { more_b <= narrow } |> should.equal(True)
  { more_a >= narrow } |> should.equal(True)
  check_valid(
    bootstrap.new_context(-huge, huge),
    [6, 6, 6],
    [band(-extreme, extreme)],
    [band(-extreme, -1)],
    [band(-extreme, extreme)],
    [band(-extreme, -1)],
  )
  |> should.equal(6)
}
