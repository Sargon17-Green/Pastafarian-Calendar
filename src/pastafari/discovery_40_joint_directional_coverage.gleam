// Stadio 44 / DISCOVERY 40: komuna multiplikita direkta kovro.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_39_relative_directional_asymmetry

pub type JointDirectionalCoverage {
  JointDirectionalCoverage(
    previous: discovery_39_relative_directional_asymmetry.RelativeDirectionalCoverageAsymmetry,
    joint_coverage_numerator: Int,
    joint_coverage_denominator: Int,
  )
}

fn absolute_value(value: Int) -> Int {
  case value < 0 {
    True -> 0 - value
    False -> value
  }
}

fn greatest_common_divisor(left: Int, right: Int) -> Int {
  case right == 0 {
    True -> left
    False -> greatest_common_divisor(right, left % right)
  }
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

fn asymmetry_matches_signed_mean(
  asymmetry_numerator: Int,
  asymmetry_denominator: Int,
  signed_numerator: Int,
  signed_denominator: Int,
  mean_numerator: Int,
  mean_denominator: Int,
) -> Bool {
  case mean_numerator == 0 {
    True ->
      asymmetry_numerator == 0
      && asymmetry_denominator == 1
      && signed_numerator == 0
    False ->
      asymmetry_numerator * signed_denominator * mean_numerator
      == signed_numerator * mean_denominator * asymmetry_denominator
  }
}

fn valid_asymmetry(numerator: Int, denominator: Int) -> Bool {
  denominator > 0
  && absolute_value(numerator) <= 2 * denominator
  && greatest_common_divisor(absolute_value(numerator), denominator) == 1
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

fn valid_joint(
  numerator: Int,
  denominator: Int,
  raw_numerator: Int,
  raw_denominator: Int,
) -> Bool {
  denominator > 0
  && numerator >= 0
  && numerator <= denominator
  && greatest_common_divisor(numerator, denominator) == 1
  && numerator * raw_denominator == raw_numerator * denominator
}

fn joint_matches_counts(
  numerator: Int,
  denominator: Int,
  left_count: Int,
  right_count: Int,
  intersection: Int,
) -> Bool {
  case left_count == 0, right_count == 0 {
    True, True -> numerator == 1 && denominator == 1
    True, False -> numerator == 0 && denominator == 1
    False, True -> numerator == 0 && denominator == 1
    False, False ->
      case intersection == 0 {
        True -> numerator == 0 && denominator == 1
        False ->
          numerator * left_count * right_count
          == intersection * intersection * denominator
      }
  }
}

pub fn dispatch_discovery_40(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  JointDirectionalCoverage,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_39_relative_directional_asymmetry.dispatch_discovery_39(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) -> {
      let mean = previous.previous
      let signed = mean.previous
      let directional = signed.previous
      let base = directional.previous
      let left_count = base.left_windows
      let right_count = base.right_windows
      let intersection = base.intersection_windows
      let minimum_count = case left_count <= right_count {
        True -> left_count
        False -> right_count
      }
      let counts_ok =
        base.total_windows >= 0
        && left_count >= 0
        && right_count >= 0
        && intersection >= 0
        && intersection <= minimum_count
        && left_count <= base.total_windows
        && right_count <= base.total_windows
        && base.combined_windows == left_count + right_count - intersection
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
          mean.mean_numerator,
          mean.mean_denominator,
          mean_raw_numerator,
          mean_raw_denominator,
          left_count,
          right_count,
          intersection,
        )
      let asymmetry_ok =
        valid_asymmetry(
          previous.asymmetry_numerator,
          previous.asymmetry_denominator,
        )
        && asymmetry_matches_counts(
          previous.asymmetry_numerator,
          previous.asymmetry_denominator,
          left_count,
          right_count,
          intersection,
        )
        && asymmetry_matches_signed_mean(
          previous.asymmetry_numerator,
          previous.asymmetry_denominator,
          signed.signed_difference_numerator,
          signed.signed_difference_denominator,
          mean.mean_numerator,
          mean.mean_denominator,
        )
      let reconstruction_ok =
        reconstructs_coverages(
          mean.mean_numerator,
          mean.mean_denominator,
          previous.asymmetry_numerator,
          previous.asymmetry_denominator,
          directional.left_coverage_numerator,
          directional.left_coverage_denominator,
          directional.right_coverage_numerator,
          directional.right_coverage_denominator,
        )

      case
        counts_ok
        && left_ok
        && right_ok
        && signed_ok
        && mean_ok
        && asymmetry_ok
        && reconstruction_ok
      {
        False -> Error(discovery_19_interval_value.InvalidStream)
        True -> {
          let raw_numerator =
            directional.left_coverage_numerator
            * directional.right_coverage_numerator
          let raw_denominator =
            directional.left_coverage_denominator
            * directional.right_coverage_denominator

          case raw_denominator > 0 {
            False -> Error(discovery_19_interval_value.InvalidStream)
            True -> {
              let divisor =
                greatest_common_divisor(raw_numerator, raw_denominator)
              let numerator = raw_numerator / divisor
              let denominator = raw_denominator / divisor
              let fraction_ok =
                valid_joint(
                  numerator,
                  denominator,
                  raw_numerator,
                  raw_denominator,
                )
              let cardinality_ok =
                joint_matches_counts(
                  numerator,
                  denominator,
                  left_count,
                  right_count,
                  intersection,
                )
              let signed_identity_numerator =
                4
                * mean.mean_numerator
                * mean.mean_numerator
                * signed.signed_difference_denominator
                * signed.signed_difference_denominator
                - signed.signed_difference_numerator
                * signed.signed_difference_numerator
                * mean.mean_denominator
                * mean.mean_denominator
              let signed_identity_denominator =
                4
                * mean.mean_denominator
                * mean.mean_denominator
                * signed.signed_difference_denominator
                * signed.signed_difference_denominator
              let signed_identity_ok =
                numerator * signed_identity_denominator
                == signed_identity_numerator * denominator
              let asymmetry_identity_numerator =
                mean.mean_numerator
                * mean.mean_numerator
                * {
                  4
                  * previous.asymmetry_denominator
                  * previous.asymmetry_denominator
                  - previous.asymmetry_numerator
                  * previous.asymmetry_numerator
                }
              let asymmetry_identity_denominator =
                4
                * mean.mean_denominator
                * mean.mean_denominator
                * previous.asymmetry_denominator
                * previous.asymmetry_denominator
              let asymmetry_identity_ok =
                numerator * asymmetry_identity_denominator
                == asymmetry_identity_numerator * denominator

              case
                fraction_ok
                && cardinality_ok
                && signed_identity_ok
                && asymmetry_identity_ok
              {
                False -> Error(discovery_19_interval_value.InvalidStream)
                True ->
                  Ok(JointDirectionalCoverage(
                    previous: previous,
                    joint_coverage_numerator: numerator,
                    joint_coverage_denominator: denominator,
                  ))
              }
            }
          }
        }
      }
    }
  }
}
