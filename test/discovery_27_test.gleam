// Stadio 31: dek du sendependaj Stage25-orakolaj gleeunit-testoj.
// La oracle rekte enumeracias ĉiujn ne-malplenajn sinsekvajn fenestrojn.
// Ĝi ne vokas Stage26, Stage27, Stage29 aŭ Stage30 por atendataj kvantoj.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import reference/core

fn band(lower: Int, upper: Int) {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn answers(a: Int, b: Int, ids: List(Int), bands: List(discovery_27_sum_bands.SumBand)) {
  discovery_27_sum_bands.dispatch_discovery_27(
    bootstrap.new_context(a, b),
    ids,
    bands,
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

fn brute_ends(
  suffix: List(Int),
  lower: Int,
  upper: Int,
  sum: Int,
  count: Int,
) -> Int {
  case suffix {
    [] -> count
    [gap, ..rest] -> {
      let next_sum = sum + gap
      let next_count = case next_sum >= lower && next_sum <= upper {
        True -> count + 1
        False -> count
      }
      brute_ends(rest, lower, upper, next_sum, next_count)
    }
  }
}

fn brute_starts(suffix: List(Int), lower: Int, upper: Int, count: Int) -> Int {
  case suffix {
    [] -> count
    [_, ..rest] -> {
      let next_count = count + brute_ends(suffix, lower, upper, 0, 0)
      brute_starts(rest, lower, upper, next_count)
    }
  }
}

fn check_valid(
  a: Int,
  b: Int,
  ids: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
) {
  let context = bootstrap.new_context(a, b)
  let assert Ok(samples) = discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.each(samples, fn(sample) {
    {
      sample.gap >= discovery_20_gate_gap.gap_min
      && sample.gap <= discovery_20_gate_gap.gap_max
    }
    |> should.equal(True)
  })
  let gaps = list.map(samples, fn(sample) { sample.gap })
  let size = list.length(gaps)
  let maximum = size * { size + 1 } / 2
  let expected =
    list.map(bands, fn(request) {
      discovery_27_sum_bands.SumBandCount(
        lower: request.lower,
        upper: request.upper,
        qualifying_windows: brute_starts(gaps, request.lower, request.upper, 0),
      )
    })
  let assert Ok(actual) =
    discovery_27_sum_bands.dispatch_discovery_27(context, ids, bands)
  actual |> should.equal(expected)
  list.each(actual, fn(item) {
    { item.qualifying_windows >= 0 && item.qualifying_windows <= maximum }
    |> should.equal(True)
  })
}

pub fn discovery_27_empty_bowls_and_bands_test() {
  answers(11, 21, [], []) |> should.equal(Ok([]))
}

pub fn discovery_27_empty_bowls_invalid_unused_context_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_27_sum_bands.dispatch_discovery_27(
    invalid,
    [],
    [band(-1, 0), band(0, 0), band(1, 10)],
  )
  |> should.equal(Ok([
    discovery_27_sum_bands.SumBandCount(-1, 0, 0),
    discovery_27_sum_bands.SumBandCount(0, 0, 0),
    discovery_27_sum_bands.SumBandCount(1, 10, 0),
  ]))
}

pub fn discovery_27_single_gap_exact_boundaries_test() {
  let assert [sample] = samples_for(11, 21, [1])
  let gap = sample.gap
  let requests = [
    band(gap, gap),
    band(gap - 1, gap - 1),
    band(gap + 1, gap + 1),
    band(gap - 1, gap),
  ]
  check_valid(11, 21, [1], requests)
  let assert Ok(got) = answers(11, 21, [1], requests)
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([1, 0, 0, 1])
}

pub fn discovery_27_multiple_gaps_total_boundary_test() {
  let ids = [1, 3, 2, 6]
  let samples = samples_for(11, 21, ids)
  let total = list.fold(samples, 0, fn(sum, sample) { sum + sample.gap })
  let requests = [
    band(total, total),
    band(total + 1, total + 1),
    band(1, total),
    band(total - 1, total + 1),
  ]
  check_valid(11, 21, ids, requests)
  let assert Ok(got) = answers(11, 21, ids, requests)
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([1, 0, 10, 1])
}

pub fn discovery_27_interior_nonprefix_windows_test() {
  let ids = [6, 2, 1, 4, 3]
  let assert [first, second, third, _, _] = samples_for(11, 21, ids)
  check_valid(11, 21, ids, [
    band(second.gap, second.gap),
    band(second.gap + third.gap, second.gap + third.gap),
    band(first.gap + 1, first.gap + second.gap),
    band(third.gap, second.gap + third.gap),
  ])
}

pub fn discovery_27_duplicate_bowl_positions_test() {
  let ids = [1, 1, 1, 1]
  let assert [first, _, _, _] = samples_for(11, 21, ids)
  let gap = first.gap
  let requests = [
    band(gap, gap),
    band(2 * gap, 2 * gap),
    band(0, 4 * gap),
  ]
  check_valid(11, 21, ids, requests)
  let assert Ok(got) = answers(11, 21, ids, requests)
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([4, 3, 10])
}

pub fn discovery_27_unsorted_duplicate_bands_test() {
  let requests = [
    band(999_999, 1_000_000),
    band(42, 963),
    band(42, 963),
    band(0, 0),
    band(963, 1926),
    band(42, 963),
  ]
  check_valid(11, 21, [6, 2, 3], requests)
  let assert Ok(got) = answers(11, 21, [6, 2, 3], requests)
  list.map(got, fn(item) { band(item.lower, item.upper) })
  |> should.equal(requests)
  let assert [_, first, second, _, _, third] = got
  first |> should.equal(second)
  second |> should.equal(third)
}

pub fn discovery_27_negative_and_inverted_bands_test() {
  let requests = [
    band(-999_999, -1),
    band(-10, 0),
    band(-1, -1),
    band(42, 41),
    band(100, -100),
  ]
  check_valid(11, 21, [2, 6, 1, 4], requests)
  let assert Ok(got) = answers(11, 21, [2, 6, 1, 4], requests)
  list.map(got, fn(item) { item.qualifying_windows })
  |> should.equal([0, 0, 0, 0, 0])
}

pub fn discovery_27_wide_band_maximum_test() {
  let ids = [6, 2, 3, 1, 4, 5]
  let huge = 999_999_999_999
  check_valid(11, 21, ids, [band(-huge, huge)])
  let assert Ok(got) = answers(11, 21, ids, [band(-huge, huge)])
  let assert [only] = got
  only.qualifying_windows |> should.equal(21)
}

pub fn discovery_27_invalid_bowl_even_when_empty_bands_test() {
  answers(11, 21, [7], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
}

pub fn discovery_27_invalid_context_even_when_inverted_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_27_sum_bands.dispatch_discovery_27(
    invalid,
    [1],
    [band(1000, 1), band(2, 1)],
  )
  |> should.equal(Error(discovery_19_interval_value.InvalidContext(
    bootstrap.InvalidRetryBudget,
  )))
}

pub fn discovery_27_huge_days_large_bands_partition_test() {
  let huge = core.m * core.m + core.m
  let ids = [1, 6, 1, 6, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 1, 3, 6, 2]
  let requests = [
    band(-huge * huge, huge * huge),
    band(42, 963),
    band(964, 1926),
    band(42, 1926),
    band(42, huge),
    band(1000, 999),
    band(0, 0),
  ]
  check_valid(huge, -huge, ids, requests)
  check_valid(-huge, huge, [6, 6, 6, 6, 6], [
    band(-huge, huge),
    band(42, 42),
    band(963, 963),
    band(964, 1926),
  ])
  let assert Ok(got) = answers(huge, -huge, ids, requests)
  let assert [whole, low, high, combined, wider, inverted, empty] = got
  whole.qualifying_windows |> should.equal(210)
  { low.qualifying_windows + high.qualifying_windows == combined.qualifying_windows }
  |> should.equal(True)
  { wider.qualifying_windows >= combined.qualifying_windows }
  |> should.equal(True)
  inverted.qualifying_windows |> should.equal(0)
  empty.qualifying_windows |> should.equal(0)
}
