// Stadio 43: rekta fenestra orakolo por relativa signita malsimetrio.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_38_mean_directional_coverage
import pastafari/discovery_39_relative_directional_asymmetry

fn band(a: Int, b: Int) -> discovery_27_sum_bands.SumBand {
  discovery_27_sum_bands.SumBand(lower: a, upper: b)
}

fn prefix_sums(gs: List(Int), n: Int) -> List(Int) {
  case gs {
    [] -> []
    [g, ..rest] -> [n + g, ..prefix_sums(rest, n + g)]
  }
}

fn window_sums(gs: List(Int)) -> List(Int) {
  case gs {
    [] -> []
    [_, ..rest] -> list.append(prefix_sums(gs, 0), window_sums(rest))
  }
}

fn member(bs: List(discovery_27_sum_bands.SumBand), value: Int) -> Bool {
  list.any(bs, fn(b) { b.lower <= value && value <= b.upper })
}

fn minimum_q(numerator: Int, denominator: Int, q: Int) -> Int {
  case numerator * q % denominator == 0 {
    True -> q
    False -> minimum_q(numerator, denominator, q + 1)
  }
}

fn fraction(numerator: Int, denominator: Int) -> #(Int, Int) {
  case denominator == 0 {
    True -> #(1, 1)
    False -> {
      let q = minimum_q(numerator, denominator, 1)
      #(numerator * q / denominator, q)
    }
  }
}

fn signed_oracle(left: Int, right: Int, intersection: Int) -> #(Int, Int) {
  case left == 0, right == 0 {
    True, True -> #(0, 1)
    True, False -> #(1, 1)
    False, True -> #(-1, 1)
    False, False -> fraction(intersection * { right - left }, left * right)
  }
}

fn mean_oracle(left: Int, right: Int, intersection: Int) -> #(Int, Int) {
  case left == 0, right == 0 {
    True, True -> #(1, 1)
    True, False -> #(1, 2)
    False, True -> #(1, 2)
    False, False -> fraction(intersection * { left + right }, 2 * left * right)
  }
}

fn asymmetry_oracle(left: Int, right: Int, intersection: Int) -> #(Int, Int) {
  case left == 0, right == 0 {
    True, True -> #(0, 1)
    True, False -> #(2, 1)
    False, True -> #(-2, 1)
    False, False ->
      case intersection == 0 {
        True -> #(0, 1)
        False -> fraction(2 * { right - left }, left + right)
      }
  }
}

fn gaps(context: bootstrap.MonsterContext, ids: List(Int)) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.map(samples, fn(sample) { sample.gap })
}

fn verify(
  ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> #(#(Int, Int), #(Int, Int), #(Int, Int)) {
  let context = bootstrap.new_context(11, 21)
  let windows = window_sums(gaps(context, ids))
  let left_count =
    list.length(list.filter(windows, fn(w) { member(left_bands, w) }))
  let right_count =
    list.length(list.filter(windows, fn(w) { member(right_bands, w) }))
  let intersection =
    list.length(
      list.filter(windows, fn(w) {
        member(left_bands, w) && member(right_bands, w)
      }),
    )
  let combined =
    list.length(
      list.filter(windows, fn(w) {
        member(left_bands, w) || member(right_bands, w)
      }),
    )
  let xor_count =
    list.length(
      list.filter(windows, fn(w) {
        member(left_bands, w) != member(right_bands, w)
      }),
    )
  let total = list.length(windows)

  let assert Ok(out) =
    discovery_39_relative_directional_asymmetry.dispatch_discovery_39(
      context,
      ids,
      left_bands,
      right_bands,
    )
  let assert Ok(reference) =
    discovery_38_mean_directional_coverage.dispatch_discovery_38(
      context,
      ids,
      left_bands,
      right_bands,
    )
  out.previous |> should.equal(reference)

  let mean = out.previous
  let signed = mean.previous
  let directional = signed.previous
  let base = directional.previous
  #(
    base.left_windows,
    base.right_windows,
    base.intersection_windows,
    base.combined_windows,
    base.symmetric_difference_windows,
    base.total_windows,
  )
  |> should.equal(#(
    left_count,
    right_count,
    intersection,
    combined,
    xor_count,
    total,
  ))
  #(base.jaccard_numerator, base.jaccard_denominator)
  |> should.equal(fraction(intersection, combined))
  #(base.dice_numerator, base.dice_denominator)
  |> should.equal(fraction(2 * intersection, left_count + right_count))

  let minimum = case left_count <= right_count {
    True -> left_count
    False -> right_count
  }
  let expected_overlap = case minimum == 0 && left_count + right_count > 0 {
    True -> #(0, 1)
    False -> fraction(intersection, minimum)
  }
  #(base.overlap_numerator, base.overlap_denominator)
  |> should.equal(expected_overlap)

  let left_coverage = #(
    directional.left_coverage_numerator,
    directional.left_coverage_denominator,
  )
  let right_coverage = #(
    directional.right_coverage_numerator,
    directional.right_coverage_denominator,
  )
  left_coverage |> should.equal(fraction(intersection, left_count))
  right_coverage |> should.equal(fraction(intersection, right_count))

  let signed_fraction = #(
    signed.signed_difference_numerator,
    signed.signed_difference_denominator,
  )
  signed_fraction
  |> should.equal(signed_oracle(left_count, right_count, intersection))
  let mean_fraction = #(mean.mean_numerator, mean.mean_denominator)
  mean_fraction
  |> should.equal(mean_oracle(left_count, right_count, intersection))
  let asymmetry = #(out.asymmetry_numerator, out.asymmetry_denominator)
  asymmetry
  |> should.equal(asymmetry_oracle(left_count, right_count, intersection))

  let #(mean_numerator, mean_denominator) = mean_fraction
  let #(asymmetry_numerator, asymmetry_denominator) = asymmetry
  let #(left_numerator, left_denominator) = left_coverage
  let #(right_numerator, right_denominator) = right_coverage
  let reconstructed_left_numerator =
    mean_numerator
    * 2
    * asymmetry_denominator
    + mean_numerator
    * asymmetry_numerator
  let reconstructed_right_numerator =
    mean_numerator
    * 2
    * asymmetry_denominator
    - mean_numerator
    * asymmetry_numerator
  let reconstructed_denominator = 2 * mean_denominator * asymmetry_denominator
  let left_reconstruction_ok =
    reconstructed_left_numerator * left_denominator
    == left_numerator * reconstructed_denominator
  left_reconstruction_ok |> should.equal(True)
  let right_reconstruction_ok =
    reconstructed_right_numerator * right_denominator
    == right_numerator * reconstructed_denominator
  right_reconstruction_ok |> should.equal(True)

  let asymmetry_denominator_positive = asymmetry_denominator > 0
  asymmetry_denominator_positive |> should.equal(True)
  let asymmetry_in_range =
    asymmetry_numerator >= 0 - 2 * asymmetry_denominator
    && asymmetry_numerator <= 2 * asymmetry_denominator
  asymmetry_in_range |> should.equal(True)
  #(asymmetry, mean_fraction, signed_fraction)
}

fn wide(n: Int, value: Int) -> Int {
  case n == 0 {
    True -> value
    False -> wide(n - 1, value * 10)
  }
}

pub fn discovery_39_both_empty_test() {
  verify([], [], [])
  |> should.equal(#(#(0, 1), #(1, 1), #(0, 1)))
}

pub fn discovery_39_left_empty_test() {
  verify([2], [], [band(0, 1000)])
  |> should.equal(#(#(2, 1), #(1, 2), #(1, 1)))
}

pub fn discovery_39_right_empty_test() {
  verify([2], [band(0, 1000)], [])
  |> should.equal(#(#(-2, 1), #(1, 2), #(-1, 1)))
}

pub fn discovery_39_disjoint_nonempty_test() {
  let assert [g, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  verify([2, 2, 2], [band(g, g)], [band(2 * g, 3 * g)])
  |> should.equal(#(#(0, 1), #(0, 1), #(0, 1)))
}

pub fn discovery_39_equal_cardinality_overlap_test() {
  let assert [g, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  verify([2, 2, 2], [band(g, 2 * g)], [band(g, g), band(2 * g, 2 * g)])
  |> should.equal(#(#(0, 1), #(1, 1), #(0, 1)))
}

pub fn discovery_39_left_subset_test() {
  let assert [g, _, _, _] = gaps(bootstrap.new_context(11, 21), [3, 3, 3, 3])
  verify([3, 3, 3, 3], [band(2 * g, 2 * g)], [band(g, 2 * g)])
  |> should.equal(#(#(4, 5), #(5, 7), #(4, 7)))
}

pub fn discovery_39_right_subset_test() {
  let assert [g, _, _, _] = gaps(bootstrap.new_context(11, 21), [3, 3, 3, 3])
  verify([3, 3, 3, 3], [band(g, 2 * g)], [band(2 * g, 2 * g)])
  |> should.equal(#(#(-4, 5), #(5, 7), #(-4, 7)))
}

pub fn discovery_39_partial_overlap_negative_test() {
  let assert [g, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  verify([2, 2, 2], [band(g, 2 * g)], [band(2 * g, 3 * g)])
  |> should.equal(#(#(-1, 2), #(8, 15), #(-4, 15)))
}

pub fn discovery_39_partial_overlap_positive_test() {
  let assert [g, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  verify([2, 2, 2], [band(2 * g, 3 * g)], [band(g, 2 * g)])
  |> should.equal(#(#(1, 2), #(8, 15), #(4, 15)))
}

pub fn discovery_39_index_multiplicity_and_duplicate_bands_test() {
  let assert [g, _, _, _] = gaps(bootstrap.new_context(11, 21), [4, 4, 4, 4])
  verify([4, 4, 4, 4], [band(g, 2 * g), band(g, 2 * g)], [
    band(2 * g, 3 * g),
    band(2 * g, 3 * g),
  ])
  |> should.equal(#(#(-1, 3), #(18, 35), #(-6, 35)))
}

pub fn discovery_39_wide_inverted_and_error_priority_test() {
  let w = wide(70, 1)
  let left = [band(-w, -1), band(0, 100), band(101, 2000), band(3, 2)]
  let right = [band(-w, w), band(w, w)]
  let _ = verify([3, 5, 2, 4], left, right)

  let context = bootstrap.new_context(11, 21)
  discovery_39_relative_directional_asymmetry.dispatch_discovery_39(
    context,
    [7],
    [],
    [],
  )
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))

  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_39_relative_directional_asymmetry.dispatch_discovery_39(
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
  discovery_39_relative_directional_asymmetry.dispatch_discovery_39(
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

pub fn discovery_39_matrix_test() {
  let ids = [6, 2, 6, 3, 5, 1, 4, 4, 2, 6, 1, 5]
  let families = [
    [],
    [band(42, 963)],
    [band(500, 3000)],
    [band(0, 20_000)],
    [band(100, 99), band(800, 900)],
  ]
  list.each([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], fn(k) {
    let selected = list.take(ids, k)
    list.each(families, fn(a) {
      list.each(families, fn(b) {
        let #(asymmetry, mean, signed) = verify(selected, a, b)
        let #(reverse_asymmetry, reverse_mean, reverse_signed) =
          verify(selected, b, a)
        reverse_mean |> should.equal(mean)
        let #(asymmetry_numerator, asymmetry_denominator) = asymmetry
        reverse_asymmetry
        |> should.equal(#(0 - asymmetry_numerator, asymmetry_denominator))
        let #(signed_numerator, signed_denominator) = signed
        reverse_signed
        |> should.equal(#(0 - signed_numerator, signed_denominator))
        verify(selected, a, a)
        |> should.equal(#(#(0, 1), #(1, 1), #(0, 1)))
      })
    })
  })
}
