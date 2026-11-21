// Stadio 35: rekta Stage21-a indeksa-fenestra A-kaj-B-orakolo.
// Atendataj kalkuloj NE uzas Stage32..34 aŭ subtrahidenton.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_31_intersection_bands
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
  discovery_31_intersection_bands.dispatch_discovery_31(context, ids, a, b)
}

fn gaps_for(context: bootstrap.MonsterContext, ids: List(Int)) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.map(samples, fn(sample) { sample.gap })
}

fn in_original_bands(
  value: Int,
  bands: List(discovery_27_sum_bands.SumBand),
) -> Bool {
  case bands {
    [] -> False
    [band, ..rest] ->
      case
        band.lower <= band.upper && band.lower <= value && value <= band.upper
      {
        True -> True
        False -> in_original_bands(value, rest)
      }
  }
}

fn enumerate_ends(
  remaining: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
  sum: Int,
  counts: #(Int, Int, Int, Int),
) -> #(Int, Int, Int, Int) {
  case remaining {
    [] -> counts
    [gap, ..rest] -> {
      let next = sum + gap
      let in_a = in_original_bands(next, a)
      let in_b = in_original_bands(next, b)
      let #(ac, bc, uc, ic) = counts
      let ac = case in_a {
        True -> ac + 1
        False -> ac
      }
      let bc = case in_b {
        True -> bc + 1
        False -> bc
      }
      let uc = case in_a || in_b {
        True -> uc + 1
        False -> uc
      }
      let ic = case in_a && in_b {
        True -> ic + 1
        False -> ic
      }
      enumerate_ends(rest, a, b, next, #(ac, bc, uc, ic))
    }
  }
}

fn enumerate_starts(
  remaining: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
  counts: #(Int, Int, Int, Int),
) -> #(Int, Int, Int, Int) {
  case remaining {
    [] -> counts
    [_, ..rest] -> {
      let next = enumerate_ends(remaining, a, b, 0, counts)
      enumerate_starts(rest, a, b, next)
    }
  }
}

fn check_valid(
  context: bootstrap.MonsterContext,
  ids: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
  expected_a: List(discovery_27_sum_bands.SumBand),
  expected_union: List(discovery_27_sum_bands.SumBand),
  expected_b: List(discovery_27_sum_bands.SumBand),
) -> Int {
  let gaps = gaps_for(context, ids)
  let #(ac, bc, uc, ic) = enumerate_starts(gaps, a, b, #(0, 0, 0, 0))
  let k = list.length(gaps)
  let total = k * { k + 1 } / 2
  let assert Ok(value) = actual(context, ids, a, b)
  value.canonical_left_bands |> should.equal(expected_a)
  value.canonical_combined_bands |> should.equal(expected_union)
  value.canonical_right_bands |> should.equal(expected_b)
  value.left_windows |> should.equal(ac)
  value.right_windows |> should.equal(bc)
  value.combined_windows |> should.equal(uc)
  value.intersection_windows |> should.equal(ic)
  value.difference_windows |> should.equal(ac - ic)
  value.total_windows |> should.equal(total)
  { ic >= 0 && ic <= ac && ic <= bc && uc <= total }
  |> should.equal(True)
  ic
}

pub fn discovery_31_empty_ids_empty_bands_test() {
  actual(bootstrap.new_context(11, 21), [], [], [])
  |> should.equal(
    Ok(discovery_31_intersection_bands.IntersectionWindowCount(
      canonical_left_bands: [],
      canonical_combined_bands: [],
      canonical_right_bands: [],
      left_windows: 0,
      right_windows: 0,
      combined_windows: 0,
      difference_windows: 0,
      intersection_windows: 0,
      total_windows: 0,
    )),
  )
}

pub fn discovery_31_empty_ids_unused_invalid_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  check_valid(
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

pub fn discovery_31_single_gap_inclusive_endpoint_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_for(context, [1])
  check_valid(
    context,
    [1],
    [band(gap, gap)],
    [band(gap - 1, gap)],
    [band(gap, gap)],
    [band(gap - 1, gap)],
    [band(gap - 1, gap)],
  )
  |> should.equal(1)
  check_valid(
    context,
    [1],
    [band(gap, gap)],
    [band(gap + 1, gap + 2)],
    [band(gap, gap)],
    [band(gap, gap + 2)],
    [band(gap + 1, gap + 2)],
  )
  |> should.equal(0)
}

pub fn discovery_31_single_gap_one_side_only_test() {
  let context = bootstrap.new_context(11, 21)
  let assert [gap] = gaps_for(context, [1])
  check_valid(
    context,
    [1],
    [band(gap, gap)],
    [],
    [band(gap, gap)],
    [band(gap, gap)],
    [],
  )
  |> should.equal(0)
  check_valid(context, [1], [], [band(gap, gap)], [], [band(gap, gap)], [
    band(gap, gap),
  ])
  |> should.equal(0)
}

pub fn discovery_31_multiple_gaps_direct_oracle_test() {
  let context = bootstrap.new_context(11, 21)
  check_valid(
    context,
    [1, 3, 2, 6],
    [band(40, 1000)],
    [band(80, 2000)],
    [band(40, 1000)],
    [band(40, 2000)],
    [band(80, 2000)],
  )
  check_valid(
    context,
    [2, 6, 1, 4, 3],
    [band(42, 963), band(3000, 3500)],
    [band(100, 700), band(964, 1800)],
    [band(42, 963), band(3000, 3500)],
    [band(42, 1800), band(3000, 3500)],
    [band(100, 700), band(964, 1800)],
  )
}

pub fn discovery_31_empty_left_or_right_bands_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 2, 3]
  check_valid(context, ids, [], [band(42, 963)], [], [band(42, 963)], [
    band(42, 963),
  ])
  |> should.equal(0)
  check_valid(
    context,
    ids,
    [band(42, 963)],
    [],
    [band(42, 963)],
    [band(42, 963)],
    [],
  )
  |> should.equal(0)
  check_valid(context, ids, [], [], [], [], [])
  |> should.equal(0)
}

pub fn discovery_31_inverted_and_disjoint_bands_test() {
  let context = bootstrap.new_context(11, 21)
  check_valid(
    context,
    [1, 2, 3],
    [band(100, 90)],
    [band(42, 43)],
    [],
    [band(42, 43)],
    [band(42, 43)],
  )
  |> should.equal(0)
  check_valid(
    context,
    [1, 2, 3],
    [band(2000, 3000)],
    [band(42, 963)],
    [band(2000, 3000)],
    [band(42, 963), band(2000, 3000)],
    [band(42, 963)],
  )
  |> should.equal(0)
}

pub fn discovery_31_duplicate_nested_overlap_bands_test() {
  check_valid(
    bootstrap.new_context(11, 21),
    [6, 2, 3, 1],
    [band(40, 700), band(80, 200), band(40, 700)],
    [band(100, 400), band(250, 1000)],
    [band(40, 700)],
    [band(40, 1000)],
    [band(100, 1000)],
  )
}

pub fn discovery_31_adjacent_and_three_canonical_lists_test() {
  check_valid(
    bootstrap.new_context(11, 21),
    [1, 3, 2, 6],
    [band(40, 100), band(101, 1000)],
    [band(101, 102), band(3000, 3100)],
    [band(40, 1000)],
    [band(40, 1000), band(3000, 3100)],
    [band(101, 102), band(3000, 3100)],
  )
}

pub fn discovery_31_repeated_ids_distinct_windows_test() {
  let context = bootstrap.new_context(11, 21)
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps_for(context, ids)
  check_valid(
    context,
    ids,
    [band(gap, gap), band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
    [band(gap, gap)],
  )
  |> should.equal(4)
}

pub fn discovery_31_invalid_context_and_id_priority_test() {
  let context = bootstrap.new_context(11, 21)
  actual(context, [7], [], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  actual(invalid, [1], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  actual(invalid, [7], [band(3, 2)], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_31_extremes_commutativity_monotonicity_test() {
  let huge = core.m * core.m + core.m
  let extreme = huge * huge
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3]
  let context = bootstrap.new_context(huge, -huge)
  check_valid(
    context,
    ids,
    [band(-extreme, extreme), band(0, -1)],
    [band(-extreme, extreme)],
    [band(-extreme, extreme)],
    [band(-extreme, extreme)],
    [band(-extreme, extreme)],
  )
  |> should.equal(78)
  let a = [band(42, 963)]
  let b = [band(100, 200)]
  let base = check_valid(context, ids, a, b, a, [band(42, 963)], b)
  let reversed = check_valid(context, ids, b, a, b, [band(42, 963)], a)
  base |> should.equal(reversed)
  let larger_a =
    check_valid(
      context,
      ids,
      [band(42, 963), band(964, 1926)],
      b,
      [band(42, 1926)],
      [band(42, 1926)],
      b,
    )
  let larger_b =
    check_valid(
      context,
      ids,
      a,
      [band(100, 200), band(201, 1926)],
      a,
      [band(42, 1926)],
      [band(100, 1926)],
    )
  { larger_a >= base && larger_b >= base }
  |> should.equal(True)
}
