// Stadio 43: relativa signita malsimetrio de la du direktaj kovroj.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_38_mean_directional_coverage

pub type RelativeDirectionalCoverageAsymmetry {
  RelativeDirectionalCoverageAsymmetry(
    previous: discovery_38_mean_directional_coverage.MeanDirectionalCoverage,
    asymmetry_numerator: Int,
    asymmetry_denominator: Int,
  )
}

fn absolute_value(value: Int) -> Int {
  case value < 0 {
    True -> -value
    False -> value
  }
}

fn greatest_common_divisor(left: Int, right: Int) -> Int {
  case right == 0 {
    True -> left
    False -> greatest_common_divisor(right, left % right)
  }
}

fn reduced_signed(numerator: Int, denominator: Int) -> #(Int, Int) {
  let divisor = greatest_common_divisor(absolute_value(numerator), denominator)
  #(numerator / divisor, denominator / divisor)
}

fn valid_coverage(
  numerator: Int,
  denominator: Int,
  intersection: Int,
  count: Int,
) -> Bool {
  case count == 0 {
    True -> intersection == 0 && numerator == 1 && denominator == 1
    False ->
      count > 0
      && intersection >= 0
      && intersection <= count
      && denominator > 0
      && numerator >= 0
      && numerator <= denominator
      && greatest_common_divisor(numerator, denominator) == 1
      && numerator * count == intersection * denominator
  }
}

fn valid_signed(
  numerator: Int,
  denominator: Int,
  raw_numerator: Int,
  raw_denominator: Int,
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> Bool {
  let count_formula_ok = case left_count == 0, right_count == 0 {
    True, True -> numerator == 0 && denominator == 1
    True, False -> numerator == 1 && denominator == 1
    False, True -> numerator == -1 && denominator == 1
    False, False ->
      numerator * left_count * right_count
      == intersection * { right_count - left_count } * denominator
  }
  denominator > 0
  && absolute_value(numerator) <= denominator
  && greatest_common_divisor(absolute_value(numerator), denominator) == 1
  && numerator * raw_denominator == raw_numerator * denominator
  && count_formula_ok
}

fn valid_mean(
  numerator: Int,
  denominator: Int,
  raw_numerator: Int,
  raw_denominator: Int,
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> Bool {
  let count_formula_ok = case left_count == 0, right_count == 0 {
    True, True -> numerator == 1 && denominator == 1
    True, False -> numerator == 1 && denominator == 2
    False, True -> numerator == 1 && denominator == 2
    False, False ->
      numerator * 2 * left_count * right_count
      == intersection * { left_count + right_count } * denominator
  }
  denominator > 0
  && numerator >= 0
  && numerator <= denominator
  && greatest_common_divisor(numerator, denominator) == 1
  && numerator * raw_denominator == raw_numerator * denominator
  && count_formula_ok
}

fn asymmetry_matches_counts(
  numerator: Int,
  denominator: Int,
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> Bool {
  case left_count == 0, right_count == 0 {
    True, True -> numerator == 0 && denominator == 1
    True, False -> numerator == 2 && denominator == 1
    False, True -> numerator == -2 && denominator == 1
    False, False ->
      case intersection == 0 {
        True -> numerator == 0 && denominator == 1
        False ->
          numerator * { left_count + right_count }
          == 2 * { right_count - left_count } * denominator
      }
  }
}

fn valid_asymmetry(
  numerator: Int,
  denominator: Int,
  raw_numerator: Int,
  raw_denominator: Int,
) -> Bool {
  denominator > 0
  && absolute_value(numerator) <= 2 * denominator
  && greatest_common_divisor(absolute_value(numerator), denominator) == 1
  && numerator * raw_denominator == raw_numerator * denominator
}

fn reconstructs_coverages(
  mean_numerator: Int,
  mean_denominator: Int,
  asymmetry_numerator: Int,
  asymmetry_denominator: Int,
  left_numerator: Int,
  left_denominator: Int,
  right_numerator: Int,
  right_denominator: Int,
) -> Bool {
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
  let left_ok =
    reconstructed_left_numerator * left_denominator
    == left_numerator * reconstructed_denominator
  let right_ok =
    reconstructed_right_numerator * right_denominator
    == right_numerator * reconstructed_denominator
  left_ok && right_ok
}

pub fn dispatch_discovery_39(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  RelativeDirectionalCoverageAsymmetry,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_38_mean_directional_coverage.dispatch_discovery_38(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) -> {
      let signed = previous.previous
      let directional = signed.previous
      let base = directional.previous
      let left_count = base.left_windows
      let right_count = base.right_windows
      let intersection = base.intersection_windows
      let left_ok =
        valid_coverage(
          directional.left_coverage_numerator,
          directional.left_coverage_denominator,
          intersection,
          left_count,
        )
      let right_ok =
        valid_coverage(
          directional.right_coverage_numerator,
          directional.right_coverage_denominator,
          intersection,
          right_count,
        )
      let signed_raw_numerator =
        directional.left_coverage_numerator
        * directional.right_coverage_denominator
        - directional.right_coverage_numerator
        * directional.left_coverage_denominator
      let signed_raw_denominator =
        directional.left_coverage_denominator
        * directional.right_coverage_denominator
      let signed_ok =
        valid_signed(
          signed.signed_difference_numerator,
          signed.signed_difference_denominator,
          signed_raw_numerator,
          signed_raw_denominator,
          left_count,
          right_count,
          intersection,
        )
      let mean_raw_numerator =
        directional.left_coverage_numerator
        * directional.right_coverage_denominator
        + directional.right_coverage_numerator
        * directional.left_coverage_denominator
      let mean_raw_denominator =
        2
        * directional.left_coverage_denominator
        * directional.right_coverage_denominator
      let mean_ok =
        valid_mean(
          previous.mean_numerator,
          previous.mean_denominator,
          mean_raw_numerator,
          mean_raw_denominator,
          left_count,
          right_count,
          intersection,
        )

      case
        left_count >= 0
        && right_count >= 0
        && left_ok
        && right_ok
        && signed_ok
        && mean_ok
      {
        False -> Error(discovery_19_interval_value.InvalidStream)
        True -> {
          case previous.mean_numerator == 0 {
            True -> {
              let zero_ok =
                signed.signed_difference_numerator == 0
                && reconstructs_coverages(
                  previous.mean_numerator,
                  previous.mean_denominator,
                  0,
                  1,
                  directional.left_coverage_numerator,
                  directional.left_coverage_denominator,
                  directional.right_coverage_numerator,
                  directional.right_coverage_denominator,
                )
              case zero_ok {
                False -> Error(discovery_19_interval_value.InvalidStream)
                True ->
                  Ok(RelativeDirectionalCoverageAsymmetry(
                    previous: previous,
                    asymmetry_numerator: 0,
                    asymmetry_denominator: 1,
                  ))
              }
            }
            False -> {
              let raw_numerator =
                signed.signed_difference_numerator * previous.mean_denominator
              let raw_denominator =
                signed.signed_difference_denominator * previous.mean_numerator

              case raw_denominator > 0 {
                False -> Error(discovery_19_interval_value.InvalidStream)
                True -> {
                  let #(numerator, denominator) =
                    reduced_signed(raw_numerator, raw_denominator)
                  let count_formula_ok =
                    asymmetry_matches_counts(
                      numerator,
                      denominator,
                      left_count,
                      right_count,
                      intersection,
                    )
                  let reconstruction_ok =
                    reconstructs_coverages(
                      previous.mean_numerator,
                      previous.mean_denominator,
                      numerator,
                      denominator,
                      directional.left_coverage_numerator,
                      directional.left_coverage_denominator,
                      directional.right_coverage_numerator,
                      directional.right_coverage_denominator,
                    )

                  case
                    valid_asymmetry(
                      numerator,
                      denominator,
                      raw_numerator,
                      raw_denominator,
                    )
                    && count_formula_ok
                    && reconstruction_ok
                  {
                    False -> Error(discovery_19_interval_value.InvalidStream)
                    True ->
                      Ok(RelativeDirectionalCoverageAsymmetry(
                        previous: previous,
                        asymmetry_numerator: numerator,
                        asymmetry_denominator: denominator,
                      ))
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
