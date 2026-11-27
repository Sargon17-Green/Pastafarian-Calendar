// Stadio 46: sendependa XOR-orakolo per ordigitaj indeksaj paroj.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_41_joint_directional_deficit
import pastafari/discovery_42_mixed_directional_coverage

fn band(lower: Int, upper: Int) -> discovery_27_sum_bands.SumBand {
  discovery_27_sum_bands.SumBand(lower: lower, upper: upper)
}

fn value_at(values: List(Int), index: Int) -> Int {
  let assert [value, ..] = list.drop(values, index)
  value
}

fn sum_index_range(values: List(Int), current: Int, end: Int) -> Int {
  case current >= end {
    True -> 0
    False ->
      value_at(values, current) + sum_index_range(values, current + 1, end)
  }
}

fn collect_indexed_windows(
  gaps: List(Int),
  start: Int,
  end: Int,
  size: Int,
  reversed: List(Int),
) -> List(Int) {
  case start >= size {
    True -> list.reverse(reversed)
    False ->
      case end > size {
        True ->
          collect_indexed_windows(gaps, start + 1, start + 2, size, reversed)
        False ->
          collect_indexed_windows(gaps, start, end + 1, size, [
            sum_index_range(gaps, start, end),
            ..reversed
          ])
      }
  }
}

fn indexed_windows(gaps: List(Int)) -> List(Int) {
  collect_indexed_windows(gaps, 0, 1, list.length(gaps), [])
}

fn member(bands: List(discovery_27_sum_bands.SumBand), value: Int) -> Bool {
  list.any(bands, fn(item) { item.lower <= value && value <= item.upper })
}

fn minimum_denominator(
  numerator: Int,
  denominator: Int,
  candidate: Int,
) -> Int {
  case numerator * candidate % denominator == 0 {
    True -> candidate
    False -> minimum_denominator(numerator, denominator, candidate + 1)
  }
}

fn fraction(numerator: Int, denominator: Int) -> #(Int, Int) {
  case denominator == 0 {
    True -> #(1, 1)
    False -> {
      let q = minimum_denominator(numerator, denominator, 1)
      #(numerator * q / denominator, q)
    }
  }
}

fn gaps(context: bootstrap.MonsterContext, ids: List(Int)) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.map(samples, fn(sample) { sample.gap })
}

fn indicators(
  windows: List(Int),
  own: List(discovery_27_sum_bands.SumBand),
  other: List(discovery_27_sum_bands.SumBand),
) -> List(Bool) {
  let selected = list.filter(windows, fn(value) { member(own, value) })
  case selected {
    [] -> [True]
    _ -> list.map(selected, fn(value) { member(other, value) })
  }
}

fn pair_count(
  left: List(Bool),
  right: List(Bool),
  predicate: fn(Bool, Bool) -> Bool,
) -> Int {
  list.fold(left, 0, fn(acc, a) {
    list.fold(right, acc, fn(inner, b) {
      case predicate(a, b) {
        True -> inner + 1
        False -> inner
      }
    })
  })
}

fn verify(
  ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> #(Int, Int, #(Int, Int)) {
  let context = bootstrap.new_context(11, 21)
  let windows = indexed_windows(gaps(context, ids))
  let left_count =
    list.length(list.filter(windows, fn(value) { member(left_bands, value) }))
  let right_count =
    list.length(list.filter(windows, fn(value) { member(right_bands, value) }))
  let intersection =
    list.length(
      list.filter(windows, fn(value) {
        member(left_bands, value) && member(right_bands, value)
      }),
    )
  let ls = indicators(windows, left_bands, right_bands)
  let rs = indicators(windows, right_bands, left_bands)
  let total_pairs = list.length(ls) * list.length(rs)
  let xor = pair_count(ls, rs, fn(a, b) { a != b })
  let both = pair_count(ls, rs, fn(a, b) { a && b })
  let neither = pair_count(ls, rs, fn(a, b) { !a && !b })
  xor + both + neither |> should.equal(total_pairs)

  let assert Ok(result) =
    discovery_42_mixed_directional_coverage.dispatch_discovery_42(
      context,
      ids,
      left_bands,
      right_bands,
    )
  let assert Ok(previous) =
    discovery_41_joint_directional_deficit.dispatch_discovery_41(
      context,
      ids,
      left_bands,
      right_bands,
    )
  result.previous |> should.equal(previous)
  let joint = previous.previous
  let asymmetry = joint.previous
  let mean = asymmetry.previous
  let signed = mean.previous
  let directional = signed.previous
  let base = directional.previous
  #(base.left_windows, base.right_windows, base.intersection_windows)
  |> should.equal(#(left_count, right_count, intersection))
  base.total_windows |> should.equal(list.length(windows))
  base.combined_windows
  |> should.equal(left_count + right_count - intersection)

  #(directional.left_coverage_numerator, directional.left_coverage_denominator)
  |> should.equal(fraction(intersection, left_count))
  #(
    directional.right_coverage_numerator,
    directional.right_coverage_denominator,
  )
  |> should.equal(fraction(intersection, right_count))
  let jn = joint.joint_coverage_numerator
  let jd = joint.joint_coverage_denominator
  let qn = previous.joint_deficit_numerator
  let qd = previous.joint_deficit_denominator
  #(jn, jd) |> should.equal(fraction(both, total_pairs))
  #(qn, qd) |> should.equal(fraction(neither, total_pairs))
  let n = result.mixed_coverage_numerator
  let d = result.mixed_coverage_denominator
  #(n, d) |> should.equal(fraction(xor, total_pairs))
  { d > 0 && n >= 0 && n <= d } |> should.equal(True)
  d |> should.equal(minimum_denominator(xor, total_pairs, 1))
  { n == 0 }
  |> should.equal({
    left_count > 0
    && right_count > 0
    && intersection == 0
    || intersection == left_count
    && intersection == right_count
  })
  { n == d }
  |> should.equal({ { left_count == 0 } != { right_count == 0 } })
  jn * qd * d + qn * jd * d + n * jd * qd
  |> should.equal(jd * qd * d)
  let mn = mean.mean_numerator
  let md = mean.mean_denominator
  n * md * jd |> should.equal({ 2 * mn * jd - 2 * jn * md } * d)
  #(left_count, right_count, #(n, d))
}

fn wide(power: Int, value: Int) -> Int {
  case power == 0 {
    True -> value
    False -> wide(power - 1, value * 10)
  }
}

pub fn discovery_42_both_empty_test() {
  verify([], [], []) |> should.equal(#(0, 0, #(0, 1)))
}

pub fn discovery_42_left_empty_test() {
  verify([2], [], [band(0, 1000)])
  |> should.equal(#(0, 1, #(1, 1)))
}

pub fn discovery_42_right_empty_test() {
  verify([2], [band(0, 1000)], [])
  |> should.equal(#(1, 0, #(1, 1)))
}

pub fn discovery_42_disjoint_nonempty_test() {
  let assert [gap, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  let #(_, _, joint) =
    verify([2, 2, 2], [band(gap, gap)], [band(2 * gap, 3 * gap)])
  joint |> should.equal(#(0, 1))
}

pub fn discovery_42_equal_nonempty_test() {
  let limit = wide(70, 1)
  verify([4, 2, 5, 1], [band(0 - limit, limit)], [band(0 - limit, limit)])
  |> should.equal(#(10, 10, #(0, 1)))
}

pub fn discovery_42_left_subset_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [3, 3, 3, 3])
  verify([3, 3, 3, 3], [band(2 * gap, 2 * gap)], [band(gap, 2 * gap)])
  |> should.equal(#(3, 7, #(4, 7)))
}

pub fn discovery_42_right_subset_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [3, 3, 3, 3])
  verify([3, 3, 3, 3], [band(gap, 2 * gap)], [band(2 * gap, 2 * gap)])
  |> should.equal(#(7, 3, #(4, 7)))
}

pub fn discovery_42_partial_overlap_test() {
  let assert [gap, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  verify([2, 2, 2], [band(gap, 2 * gap)], [band(2 * gap, 3 * gap)])
  |> should.equal(#(5, 3, #(8, 15)))
}

pub fn discovery_42_asymmetric_overlap_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [4, 4, 4, 4])
  verify([4, 4, 4, 4], [band(gap, 2 * gap)], [band(2 * gap, 3 * gap)])
  |> should.equal(#(7, 5, #(18, 35)))
}

pub fn discovery_42_repeated_ids_duplicate_bands_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [4, 4, 4, 4])
  verify([4, 4, 4, 4], [band(gap, 2 * gap), band(gap, 2 * gap)], [
    band(2 * gap, 3 * gap),
    band(2 * gap, 3 * gap),
  ])
  |> should.equal(#(7, 5, #(18, 35)))
}

pub fn discovery_42_wide_inverted_and_error_priority_test() {
  let limit = wide(70, 1)
  let left = [
    band(0 - limit, -1),
    band(0, 100),
    band(101, 2000),
    band(3, 2),
  ]
  let right = [band(0 - limit, limit), band(limit, limit)]
  let _ = verify([3, 5, 2, 4], left, right)

  let context = bootstrap.new_context(11, 21)
  discovery_42_mixed_directional_coverage.dispatch_discovery_42(
    context,
    [7],
    [],
    [],
  )
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))

  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_42_mixed_directional_coverage.dispatch_discovery_42(
    invalid,
    [7],
    [],
    [],
  )
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_42_mixed_directional_coverage.dispatch_discovery_42(
    invalid,
    [],
    [],
    [],
  )
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_42_matrix_test() {
  let ids = [6, 2, 6, 3, 5, 1, 4, 4, 2, 6, 1, 5]
  let families = [
    [],
    [band(42, 963)],
    [band(500, 3000)],
    [band(0, 20_000)],
    [band(100, 99), band(800, 900)],
  ]
  list.each([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], fn(size) {
    let selected = list.take(ids, size)
    list.each(families, fn(left) {
      let #(_, _, diagonal) = verify(selected, left, left)
      diagonal |> should.equal(#(0, 1))
      list.each(families, fn(right) {
        let #(left_count, right_count, joint) = verify(selected, left, right)
        let #(reverse_left_count, reverse_right_count, reverse_joint) =
          verify(selected, right, left)
        reverse_left_count |> should.equal(right_count)
        reverse_right_count |> should.equal(left_count)
        reverse_joint |> should.equal(joint)
      })
    })
  })
}
