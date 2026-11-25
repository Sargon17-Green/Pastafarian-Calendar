// Stadio 41: signita diferenco inter la du rektaj kovroj.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_36_directional_coverage

pub type SignedDirectionalCoverageDifference {
  SignedDirectionalCoverageDifference(
    previous: discovery_36_directional_coverage.DirectionalWindowCoverage,
    signed_difference_numerator: Int,
    signed_difference_denominator: Int,
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
) -> Bool {
  denominator > 0
  && absolute_value(numerator) <= denominator
  && greatest_common_divisor(absolute_value(numerator), denominator) == 1
  && numerator * raw_denominator == raw_numerator * denominator
}

pub fn dispatch_discovery_37(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  SignedDirectionalCoverageDifference,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_36_directional_coverage.dispatch_discovery_36(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) -> {
      let base = previous.previous
      let left_count = base.left_windows
      let right_count = base.right_windows
      let intersection = base.intersection_windows
      let left_ok =
        valid_coverage(
          previous.left_coverage_numerator,
          previous.left_coverage_denominator,
          intersection,
          left_count,
        )
      let right_ok =
        valid_coverage(
          previous.right_coverage_numerator,
          previous.right_coverage_denominator,
          intersection,
          right_count,
        )

      case left_ok && right_ok && left_count >= 0 && right_count >= 0 {
        False -> Error(discovery_19_interval_value.InvalidStream)
        True -> {
          let raw_numerator =
            previous.left_coverage_numerator
            * previous.right_coverage_denominator
            - previous.right_coverage_numerator
            * previous.left_coverage_denominator
          let raw_denominator =
            previous.left_coverage_denominator
            * previous.right_coverage_denominator

          case raw_denominator > 0 {
            False -> Error(discovery_19_interval_value.InvalidStream)
            True -> {
              let #(numerator, denominator) =
                reduced_signed(raw_numerator, raw_denominator)
              let count_formula_ok = case left_count == 0, right_count == 0 {
                True, True -> numerator == 0 && denominator == 1
                True, False -> numerator == 1 && denominator == 1
                False, True -> numerator == -1 && denominator == 1
                False, False ->
                  numerator * left_count * right_count
                  == intersection * { right_count - left_count } * denominator
              }

              case
                valid_signed(
                  numerator,
                  denominator,
                  raw_numerator,
                  raw_denominator,
                )
                && count_formula_ok
              {
                False -> Error(discovery_19_interval_value.InvalidStream)
                True ->
                  Ok(SignedDirectionalCoverageDifference(
                    previous: previous,
                    signed_difference_numerator: numerator,
                    signed_difference_denominator: denominator,
                  ))
              }
            }
          }
        }
      }
    }
  }
}
