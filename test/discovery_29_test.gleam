// Stadio 33: dek du sendependaj Stage21-orakolaj gleeunit-testoj.
// La orakolo rekte enumeracias originalajn fenestrojn kaj originalajn intervalojn.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_29_complement_bands
import reference/core

fn band(lower: Int, upper: Int) {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn actual(
  a: Int,
  b: Int,
  ids: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
) {
  discovery_29_complement_bands.dispatch_discovery_29(
    bootstrap.new_context(a, b),
    ids,
    bands,
  )
}

fn gaps_for(a: Int, b: Int, ids: List(Int)) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(
      bootstrap.new_context(a, b),
      ids,
    )
  list.each(samples, fn(sample) {
    {
      sample.gap >= discovery_20_gate_gap.gap_min
      && sample.gap <= discovery_20_gate_gap.gap_max
    }
    |> should.equal(True)
  })
  list.map(samples, fn(sample) { sample.gap })
}

fn inside_original(
  sum: Int,
  bands: List(discovery_27_sum_bands.SumBand),
) -> Bool {
  case bands {
    [] -> False
    [one, ..rest] ->
      case one.lower <= one.upper && one.lower <= sum && sum <= one.upper {
        True -> True
        False -> inside_original(sum, rest)
      }
  }
}

fn enumerate_ends(
  suffix: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
  sum: Int,
  inside: Int,
  outside: Int,
) -> #(Int, Int) {
  case suffix {
    [] -> #(inside, outside)
    [gap, ..rest] -> {
      let next_sum = sum + gap
      case inside_original(next_sum, bands) {
        True -> enumerate_ends(rest, bands, next_sum, inside + 1, outside)
        False -> enumerate_ends(rest, bands, next_sum, inside, outside + 1)
      }
    }
  }
}

fn enumerate_starts(
  suffix: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
  inside: Int,
  outside: Int,
) -> #(Int, Int) {
  case suffix {
    [] -> #(inside, outside)
    [_, ..rest] -> {
      let #(next_inside, next_outside) =
        enumerate_ends(suffix, bands, 0, inside, outside)
      enumerate_starts(rest, bands, next_inside, next_outside)
    }
  }
}

fn check_valid(
  a: Int,
  b: Int,
  ids: List(Int),
  original: List(discovery_27_sum_bands.SumBand),
  canonical: List(discovery_27_sum_bands.SumBand),
) -> Int {
  let gaps = gaps_for(a, b, ids)
  let #(expected_inside, expected_outside) =
    enumerate_starts(gaps, original, 0, 0)
  let k = list.length(gaps)
  let total = k * { k + 1 } / 2
  let assert Ok(value) = actual(a, b, ids, original)
  value.canonical_bands |> should.equal(canonical)
  value.inside_windows |> should.equal(expected_inside)
  value.outside_windows |> should.equal(expected_outside)
  value.total_windows |> should.equal(total)
  { value.inside_windows + value.outside_windows } |> should.equal(total)
  { value.outside_windows >= 0 && value.outside_windows <= total }
  |> should.equal(True)
  value.outside_windows
}

pub fn discovery_29_empty_ids_and_bands_test() {
  actual(11, 21, [], [])
  |> should.equal(
    Ok(discovery_29_complement_bands.ComplementWindowCount(
      canonical_bands: [],
      inside_windows: 0,
      outside_windows: 0,
      total_windows: 0,
    )),
  )
}

pub fn discovery_29_empty_ids_unused_invalid_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_29_complement_bands.dispatch_discovery_29(invalid, [], [
    band(8, 4),
    band(4, 8),
  ])
  |> should.equal(
    Ok(discovery_29_complement_bands.ComplementWindowCount(
      canonical_bands: [band(4, 8)],
      inside_windows: 0,
      outside_windows: 0,
      total_windows: 0,
    )),
  )
}

pub fn discovery_29_one_gap_inside_and_outside_test() {
  let assert [gap] = gaps_for(11, 21, [1])
  check_valid(11, 21, [1], [band(gap, gap)], [band(gap, gap)])
  |> should.equal(0)
  check_valid(11, 21, [1], [band(gap + 1, gap + 1)], [
    band(gap + 1, gap + 1),
  ])
  |> should.equal(1)
}

pub fn discovery_29_multi_gap_original_oracle_test() {
  let ids = [1, 3, 2, 6]
  let assert [first, second, _, _] = gaps_for(11, 21, ids)
  let pair = first + second
  check_valid(
    11,
    21,
    ids,
    [
      band(first, first),
      band(pair, pair),
    ],
    [band(first, first), band(pair, pair)],
  )
}

pub fn discovery_29_no_bands_outside_total_test() {
  check_valid(11, 21, [1, 2, 3, 1], [], [])
  |> should.equal(10)
}

pub fn discovery_29_inverted_bands_outside_total_test() {
  check_valid(11, 21, [1, 2, 3], [band(10, 9), band(42, 41)], [])
  |> should.equal(6)
}

pub fn discovery_29_duplicate_nested_bands_test() {
  let ids = [1, 2, 3]
  let one =
    check_valid(11, 21, ids, [band(40, 1000)], [
      band(40, 1000),
    ])
  let many =
    check_valid(
      11,
      21,
      ids,
      [
        band(100, 200),
        band(40, 1000),
        band(40, 1000),
      ],
      [band(40, 1000)],
    )
  one |> should.equal(many)
}

pub fn discovery_29_adjacent_overlapping_bands_test() {
  check_valid(
    11,
    21,
    [1, 3, 2],
    [
      band(6, 42),
      band(0, 5),
      band(42, 100),
    ],
    [band(0, 100)],
  )
}

pub fn discovery_29_disjoint_bands_with_long_windows_test() {
  check_valid(
    11,
    21,
    [1, 3, 2, 6],
    [
      band(42, 963),
      band(1926, 1926),
      band(3000, 3100),
    ],
    [band(42, 963), band(1926, 1926), band(3000, 3100)],
  )
}

pub fn discovery_29_repeated_id_positions_test() {
  let ids = [1, 1, 1, 1]
  let assert [gap, _, _, _] = gaps_for(11, 21, ids)
  check_valid(11, 21, ids, [band(gap, gap), band(gap, gap)], [
    band(gap, gap),
  ])
  |> should.equal(6)
}

pub fn discovery_29_error_priority_empty_bands_test() {
  actual(11, 21, [7], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_29_complement_bands.dispatch_discovery_29(invalid, [1], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_29_extreme_limits_monotonicity_test() {
  let huge = core.m * core.m + core.m
  let extreme = huge * huge
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3]
  check_valid(
    huge,
    -huge,
    ids,
    [
      band(-extreme, extreme),
      band(42, 963),
      band(964, 1926),
    ],
    [band(-extreme, extreme)],
  )
  |> should.equal(0)
  let narrow =
    check_valid(11, 21, ids, [band(42, 963)], [
      band(42, 963),
    ])
  let expanded =
    check_valid(11, 21, ids, [band(42, 963), band(964, 1926)], [
      band(42, 1926),
    ])
  { expanded <= narrow } |> should.equal(True)
}
