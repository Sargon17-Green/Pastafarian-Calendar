// Stadio 44: sendependa rekta indeksa fenestra orakolo por J.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_39_relative_directional_asymmetry
import pastafari/discovery_40_joint_directional_coverage

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
      value_at(values, current)
      + sum_index_range(values, current + 1, end)
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
          collect_indexed_windows(
            gaps,
            start + 1,
            start + 2,
            size,
            reversed,
          )
        False ->
          collect_indexed_windows(
            gaps,
            start,
            end + 1,
            size,
            [sum_index_range(gaps, start, end), ..reversed],
          )
      }
  }
}

fn indexed_windows(gaps: List(Int)) -> List(Int) {
  collect_indexed_windows(gaps, 0, 1, list.length(gaps), [])
}

fn member(bands: List(discovery_27_sum_bands.SumBand), value: Int) -> Bool {
  list.any(bands, fn(item) {
    item.lower <= value && value <= item.upper
  })
}

fn minimum_denominator(numerator: Int, denominator: Int, candidate: Int) -> Int {
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

fn signed_oracle(
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> #(Int, Int) {
  case left_count == 0, right_count == 0 {
    True, True -> #(0, 1)
    True, False -> #(1, 1)
    False, True -> #(-1, 1)
    False, False ->
      fraction(
        intersection * { right_count - left_count },
        left_count * right_count,
      )
  }
}

fn mean_oracle(
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> #(Int, Int) {
  case left_count == 0, right_count == 0 {
    True, True -> #(1, 1)
    True, False -> #(1, 2)
    False, True -> #(1, 2)
    False, False ->
      fraction(
        intersection * { left_count + right_count },
        2 * left_count * right_count,
      )
  }
}

fn asymmetry_oracle(
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> #(Int, Int) {
  case left_count == 0, right_count == 0 {
    True, True -> #(0, 1)
    True, False -> #(2, 1)
    False, True -> #(-2, 1)
    False, False ->
      case intersection == 0 {
        True -> #(0, 1)
        False ->
          fraction(
            2 * { right_count - left_count },
            left_count + right_count,
          )
      }
  }
}

fn joint_oracle(
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> #(Int, Int) {
  case left_count == 0, right_count == 0 {
    True, True -> #(1, 1)
    True, False -> #(0, 1)
    False, True -> #(0, 1)
    False, False ->
      case intersection == 0 {
        True -> #(0, 1)
        False ->
          fraction(
            intersection * intersection,
            left_count * right_count,
          )
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
) -> #(Int, Int, #(Int, Int)) {
  let context = bootstrap.new_context(11, 21)
  let gap_values = gaps(context, ids)
  let windows = indexed_windows(gap_values)
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
  let combined =
    list.length(
      list.filter(windows, fn(value) {
        member(left_bands, value) || member(right_bands, value)
      }),
    )
  let symmetric_difference =
    list.length(
      list.filter(windows, fn(value) {
        member(left_bands, value) != member(right_bands, value)
      }),
    )
  let total = list.length(windows)

  let assert Ok(output) =
    discovery_40_joint_directional_coverage.dispatch_discovery_40(
      context,
      ids,
      left_bands,
      right_bands,
    )
  let asymmetry = output.previous
  let mean = asymmetry.previous
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
    symmetric_difference,
    total,
  ))

  #(base.jaccard_numerator, base.jaccard_denominator)
  |> should.equal(fraction(intersection, combined))
  #(base.dice_numerator, base.dice_denominator)
  |> should.equal(fraction(2 * intersection, left_count + right_count))

  let minimum_count = case left_count <= right_count {
    True -> left_count
    False -> right_count
  }
  let expected_overlap = case minimum_count == 0 && left_count + right_count > 0 {
    True -> #(0, 1)
    False -> fraction(intersection, minimum_count)
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
  let asymmetry_fraction = #(
    asymmetry.asymmetry_numerator,
    asymmetry.asymmetry_denominator,
  )
  asymmetry_fraction
  |> should.equal(asymmetry_oracle(left_count, right_count, intersection))

  let joint = #(
    output.joint_coverage_numerator,
    output.joint_coverage_denominator,
  )
  joint |> should.equal(joint_oracle(left_count, right_count, intersection))
  let #(joint_numerator, joint_denominator) = joint
  let #(left_numerator, left_denominator) = left_coverage
  let #(right_numerator, right_denominator) = right_coverage
  joint_numerator * left_denominator * right_denominator
  |> should.equal(left_numerator * right_numerator * joint_denominator)

  let #(signed_numerator, signed_denominator) = signed_fraction
  let #(mean_numerator, mean_denominator) = mean_fraction
  let #(asymmetry_numerator, asymmetry_denominator) = asymmetry_fraction
  let signed_identity_numerator =
    4
    * mean_numerator
    * mean_numerator
    * signed_denominator
    * signed_denominator
    - signed_numerator
    * signed_numerator
    * mean_denominator
    * mean_denominator
  let signed_identity_denominator =
    4
    * mean_denominator
    * mean_denominator
    * signed_denominator
    * signed_denominator
  joint_numerator * signed_identity_denominator
  |> should.equal(signed_identity_numerator * joint_denominator)

  let asymmetry_identity_numerator =
    mean_numerator
    * mean_numerator
    * {
      4 * asymmetry_denominator * asymmetry_denominator
      - asymmetry_numerator * asymmetry_numerator
    }
  let asymmetry_identity_denominator =
    4
    * mean_denominator
    * mean_denominator
    * asymmetry_denominator
    * asymmetry_denominator
  joint_numerator * asymmetry_identity_denominator
  |> should.equal(asymmetry_identity_numerator * joint_denominator)

  (joint_denominator > 0) |> should.equal(True)
  (joint_numerator >= 0 && joint_numerator <= joint_denominator)
  |> should.equal(True)

  #(left_count, right_count, joint)
}

fn wide(power: Int, value: Int) -> Int {
  case power == 0 {
    True -> value
    False -> wide(power - 1, value * 10)
  }
}

pub fn discovery_40_both_empty_test() {
  verify([], [], []) |> should.equal(#(0, 0, #(1, 1)))

  let context = bootstrap.new_context(11, 21)
  let assert Ok(previous) =
    discovery_39_relative_directional_asymmetry.dispatch_discovery_39(
      context,
      [],
      [],
      [],
    )
  let assert Ok(output) =
    discovery_40_joint_directional_coverage.dispatch_discovery_40(
      context,
      [],
      [],
      [],
    )
  output.previous |> should.equal(previous)
}

pub fn discovery_40_left_empty_test() {
  verify([2], [], [band(0, 1000)])
  |> should.equal(#(0, 1, #(0, 1)))
}

pub fn discovery_40_right_empty_test() {
  verify([2], [band(0, 1000)], [])
  |> should.equal(#(1, 0, #(0, 1)))
}

pub fn discovery_40_disjoint_nonempty_test() {
  let assert [gap, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  let #(_, _, joint) =
    verify([2, 2, 2], [band(gap, gap)], [band(2 * gap, 3 * gap)])
  joint |> should.equal(#(0, 1))
}

pub fn discovery_40_equal_nonempty_test() {
  let limit = wide(70, 1)
  verify(
    [4, 2, 5, 1],
    [band(0 - limit, limit)],
    [band(0 - limit, limit)],
  )
  |> should.equal(#(10, 10, #(1, 1)))
}

pub fn discovery_40_left_subset_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [3, 3, 3, 3])
  verify(
    [3, 3, 3, 3],
    [band(2 * gap, 2 * gap)],
    [band(gap, 2 * gap)],
  )
  |> should.equal(#(3, 7, #(3, 7)))
}

pub fn discovery_40_right_subset_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [3, 3, 3, 3])
  verify(
    [3, 3, 3, 3],
    [band(gap, 2 * gap)],
    [band(2 * gap, 2 * gap)],
  )
  |> should.equal(#(7, 3, #(3, 7)))
}

pub fn discovery_40_partial_overlap_test() {
  let assert [gap, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  verify(
    [2, 2, 2],
    [band(gap, 2 * gap)],
    [band(2 * gap, 3 * gap)],
  )
  |> should.equal(#(5, 3, #(4, 15)))
}

pub fn discovery_40_asymmetric_overlap_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [4, 4, 4, 4])
  verify(
    [4, 4, 4, 4],
    [band(gap, 2 * gap)],
    [band(2 * gap, 3 * gap)],
  )
  |> should.equal(#(7, 5, #(9, 35)))
}

pub fn discovery_40_index_multiplicity_and_duplicate_bands_test() {
  let assert [gap, _, _, _] = gaps(bootstrap.new_context(11, 21), [4, 4, 4, 4])
  verify(
    [4, 4, 4, 4],
    [band(gap, 2 * gap), band(gap, 2 * gap)],
    [band(2 * gap, 3 * gap), band(2 * gap, 3 * gap)],
  )
  |> should.equal(#(7, 5, #(9, 35)))
}

pub fn discovery_40_wide_inverted_and_error_priority_test() {
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
  discovery_40_joint_directional_coverage.dispatch_discovery_40(
    context,
    [7],
    [],
    [],
  )
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))

  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_40_joint_directional_coverage.dispatch_discovery_40(
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
  discovery_40_joint_directional_coverage.dispatch_discovery_40(
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

pub fn discovery_40_matrix_test() {
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
      diagonal |> should.equal(#(1, 1))
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
