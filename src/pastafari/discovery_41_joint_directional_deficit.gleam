// Stadio 45 / DISCOVERY 41: komuna direkta manko.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_40_joint_directional_coverage

pub type JointDirectionalDeficit {
  JointDirectionalDeficit(
    previous: discovery_40_joint_directional_coverage.JointDirectionalCoverage,
    joint_deficit_numerator: Int,
    joint_deficit_denominator: Int,
  )
}

fn gcd(a: Int, b: Int) -> Int {
  case b == 0 {
    True -> a
    False -> gcd(b, a % b)
  }
}

fn absolute(a: Int) -> Int {
  case a < 0 {
    True -> 0 - a
    False -> a
  }
}

fn valid_fraction(n: Int, d: Int) -> Bool {
  d > 0 && n >= 0 && n <= d && gcd(n, d) == 1
}

fn valid_coverage(n: Int, d: Int, count: Int, intersection: Int) -> Bool {
  valid_fraction(n, d)
  && case count == 0 {
    True -> intersection == 0 && n == 1 && d == 1
    False -> n * count == intersection * d
  }
}

pub fn dispatch_discovery_41(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  JointDirectionalDeficit,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_40_joint_directional_coverage.dispatch_discovery_40(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) -> {
      let asymmetry = previous.previous
      let mean = asymmetry.previous
      let signed = mean.previous
      let directional = signed.previous
      let base = directional.previous
      let l = base.left_windows
      let r = base.right_windows
      let i = base.intersection_windows
      let ln = directional.left_coverage_numerator
      let ld = directional.left_coverage_denominator
      let rn = directional.right_coverage_numerator
      let rd = directional.right_coverage_denominator
      let mn = mean.mean_numerator
      let md = mean.mean_denominator
      let sn = signed.signed_difference_numerator
      let sd = signed.signed_difference_denominator
      let jn = previous.joint_coverage_numerator
      let jd = previous.joint_coverage_denominator
      let counts_ok =
        i >= 0 && i <= l && i <= r
        && l <= base.total_windows && r <= base.total_windows
        && l + r - i <= base.total_windows
        && base.combined_windows == l + r - i
      let fractions_ok =
        valid_coverage(ln, ld, l, i)
        && valid_coverage(rn, rd, r, i)
        && valid_fraction(mn, md)
        && sd > 0
        && absolute(sn) <= sd
        && gcd(absolute(sn), sd) == 1
        && valid_fraction(jn, jd)
        && jn * ld * rd == ln * rn * jd
        && mn * 2 * ld * rd == { ln * rd + rn * ld } * md
        && sn * ld * rd == { ln * rd - rn * ld } * sd
      case counts_ok && fractions_ok {
        False -> Error(discovery_19_interval_value.InvalidStream)
        True -> {
          let raw_n = { ld - ln } * { rd - rn }
          let raw_d = ld * rd
          let divisor = gcd(raw_n, raw_d)
          let n = raw_n / divisor
          let d = raw_d / divisor
          let counts_match = case l == 0 || r == 0 {
            True -> n == 0 && d == 1
            False -> n * l * r == { l - i } * { r - i } * d
          }
          let zero_ok = { n == 0 } == { i == l || i == r }
          let one_ok = { n == d } == { l > 0 && r > 0 && i == 0 }
          let bounds_ok = n * ld <= { ld - ln } * d
            && n * rd <= { rd - rn } * d
          let linear_ok =
            n * md * jd == { md * jd - 2 * mn * jd + jn * md } * d
          let square_n =
            4 * { md - mn } * { md - mn } * sd * sd
            - sn * sn * md * md
          let square_d = 4 * md * md * sd * sd
          case
            valid_fraction(n, d)
            && counts_match
            && zero_ok
            && one_ok
            && bounds_ok
            && linear_ok
            && n * square_d == square_n * d
          {
            False -> Error(discovery_19_interval_value.InvalidStream)
            True ->
              Ok(JointDirectionalDeficit(
                previous: previous,
                joint_deficit_numerator: n,
                joint_deficit_denominator: d,
              ))
          }
        }
      }
    }
  }
}
