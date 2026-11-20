// Stadio 32: dek du sendependaj Stage21-orakolaj gleeunit-testoj.
// La orakolo enumeracias la originalajn fenestrojn kaj originalajn intervalojn;
// ĝi ne uzas Stage26..31, kanonigon aŭ glitfenestran produktalgoritmon.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_28_union_bands
import reference/core

fn band(lower: Int, upper: Int) {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn answers(
  a: Int,
  b: Int,
  ids: List(Int),
  requests: List(discovery_27_sum_bands.SumBand),
) {
  discovery_28_union_bands.dispatch_discovery_28(
    bootstrap.new_context(a, b),
    ids,
    requests,
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

fn in_original_bands(
  sum: Int,
  requests: List(discovery_27_sum_bands.SumBand),
) -> Bool {
  case requests {
    [] -> False
    [request, ..rest] -> {
      case
        request.lower <= request.upper
        && sum >= request.lower
        && sum <= request.upper
      {
        True -> True
        False -> in_original_bands(sum, rest)
      }
    }
  }
}

fn enumerate_ends(
  suffix: List(Int),
  original: List(discovery_27_sum_bands.SumBand),
  sum: Int,
  count: Int,
) -> Int {
  case suffix {
    [] -> count
    [gap, ..rest] -> {
      let next_sum = sum + gap
      let next_count = case in_original_bands(next_sum, original) {
        True -> count + 1
        False -> count
      }
      enumerate_ends(rest, original, next_sum, next_count)
    }
  }
}

fn enumerate_starts(
  suffix: List(Int),
  original: List(discovery_27_sum_bands.SumBand),
  count: Int,
) -> Int {
  case suffix {
    [] -> count
    [_, ..rest] -> {
      let next_count = count + enumerate_ends(suffix, original, 0, 0)
      enumerate_starts(rest, original, next_count)
    }
  }
}

fn check_valid(
  a: Int,
  b: Int,
  ids: List(Int),
  original: List(discovery_27_sum_bands.SumBand),
  expected_canonical: List(discovery_27_sum_bands.SumBand),
) -> Int {
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
  let expected = enumerate_starts(gaps, original, 0)
  let size = list.length(gaps)
  let maximum = size * { size + 1 } / 2
  let assert Ok(actual) =
    discovery_28_union_bands.dispatch_discovery_28(context, ids, original)
  actual.canonical_bands |> should.equal(expected_canonical)
  actual.qualifying_windows |> should.equal(expected)
  { actual.qualifying_windows >= 0 && actual.qualifying_windows <= maximum }
  |> should.equal(True)
  actual.qualifying_windows
}

pub fn discovery_28_empty_ids_empty_bands_test() {
  answers(11, 21, [], [])
  |> should.equal(Ok(discovery_28_union_bands.UnionWindowCount([], 0)))
}

pub fn discovery_28_empty_ids_unused_invalid_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_28_union_bands.dispatch_discovery_28(invalid, [], [
    band(4, 8),
    band(0, 1),
    band(-5, -1),
    band(7, 6),
  ])
  |> should.equal(
    Ok(discovery_28_union_bands.UnionWindowCount(
      canonical_bands: [band(-5, 1), band(4, 8)],
      qualifying_windows: 0,
    )),
  )
}

pub fn discovery_28_single_gap_exact_and_outside_test() {
  let assert [sample] = samples_for(11, 21, [1])
  let gap = sample.gap
  check_valid(11, 21, [1], [band(gap, gap)], [band(gap, gap)])
  |> should.equal(1)
  check_valid(11, 21, [1], [band(gap - 1, gap - 1), band(gap + 1, gap + 1)], [
    band(gap - 1, gap - 1),
    band(gap + 1, gap + 1),
  ])
  |> should.equal(0)
}

pub fn discovery_28_duplicate_bands_no_double_count_test() {
  let assert [sample] = samples_for(11, 21, [1])
  let gap = sample.gap
  let single = answers(11, 21, [1], [band(gap, gap)])
  let doubled = answers(11, 21, [1], [band(gap, gap), band(gap, gap)])
  doubled |> should.equal(single)
  check_valid(11, 21, [1], [band(gap, gap), band(gap, gap)], [
    band(gap, gap),
  ])
  |> should.equal(1)
}

pub fn discovery_28_overlap_inclusive_endpoints_test() {
  let ids = [1, 3, 2]
  let assert [first, second, _] = samples_for(11, 21, ids)
  let boundary = first.gap + second.gap
  check_valid(
    11,
    21,
    ids,
    [
      band(first.gap, boundary),
      band(boundary, boundary + 1),
    ],
    [band(first.gap, boundary + 1)],
  )
}

pub fn discovery_28_adjacent_integer_bands_merge_test() {
  let assert [sample] = samples_for(11, 21, [1])
  let gap = sample.gap
  check_valid(
    11,
    21,
    [1],
    [
      band(gap - 3, gap - 2),
      band(gap - 1, gap),
    ],
    [band(gap - 3, gap)],
  )
  |> should.equal(1)
}

pub fn discovery_28_unsorted_nested_canonical_order_test() {
  let ids = [6, 2, 3, 1]
  check_valid(
    11,
    21,
    ids,
    [
      band(5000, 6000),
      band(200, 201),
      band(100, 3000),
      band(0, 20),
      band(3000, 4000),
      band(5000, 5500),
    ],
    [band(0, 20), band(100, 4000), band(5000, 6000)],
  )
}

pub fn discovery_28_negative_and_all_inverted_bands_test() {
  let ids = [2, 6, 1, 4]
  check_valid(
    11,
    21,
    ids,
    [
      band(-100, 0),
      band(10, 9),
      band(2, -2),
    ],
    [band(-100, 0)],
  )
  |> should.equal(0)
  check_valid(11, 21, ids, [band(20, 19), band(1, -1)], [])
  |> should.equal(0)
}

pub fn discovery_28_disjoint_single_and_multi_gap_windows_test() {
  let ids = [1, 3, 2, 6]
  let assert [first, second, _, _] = samples_for(11, 21, ids)
  let total = first.gap + second.gap
  check_valid(
    11,
    21,
    ids,
    [
      band(total, total),
      band(first.gap, first.gap),
    ],
    [band(first.gap, first.gap), band(total, total)],
  )
}

pub fn discovery_28_repeated_bowl_positions_distinct_windows_test() {
  let ids = [1, 1, 1, 1]
  let assert [first, _, _, _] = samples_for(11, 21, ids)
  let gap = first.gap
  check_valid(
    11,
    21,
    ids,
    [
      band(gap, gap),
      band(2 * gap, 2 * gap),
      band(gap, gap),
    ],
    [band(gap, gap), band(2 * gap, 2 * gap)],
  )
  |> should.equal(7)
}

pub fn discovery_28_invalid_ids_and_context_with_empty_union_test() {
  answers(11, 21, [7], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_28_union_bands.dispatch_discovery_28(invalid, [1], [
    band(1000, 1),
    band(3, 2),
  ])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_28_huge_limits_context_and_monotonicity_test() {
  let huge = core.m * core.m + core.m
  let extreme = huge * huge
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 1, 3, 6, 2]
  check_valid(
    huge,
    -huge,
    ids,
    [
      band(-extreme, extreme),
      band(42, 963),
      band(964, 1926),
      band(42, 1926),
      band(1000, 999),
    ],
    [band(-extreme, extreme)],
  )
  |> should.equal(210)
  check_valid(
    -huge,
    huge,
    [6, 6, 6],
    [
      band(-extreme, -1),
      band(1, extreme),
    ],
    [band(-extreme, -1), band(1, extreme)],
  )
  |> should.equal(6)
  let narrow =
    check_valid(11, 21, ids, [band(42, 963)], [
      band(42, 963),
    ])
  let expanded =
    check_valid(
      11,
      21,
      ids,
      [
        band(42, 963),
        band(964, 1926),
      ],
      [band(42, 1926)],
    )
  { expanded >= narrow } |> should.equal(True)
}
