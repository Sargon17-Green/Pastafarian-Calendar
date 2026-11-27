// Stadio 46 / DISCOVERY 42: miksita direkta kovro.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_41_joint_directional_deficit

pub type MixedDirectionalCoverage {
  MixedDirectionalCoverage(
    previous: discovery_41_joint_directional_deficit.JointDirectionalDeficit,
    mixed_coverage_numerator: Int,
    mixed_coverage_denominator: Int,
  )
}

fn gcd(a: Int, b: Int) -> Int {
  case b == 0 {
    True -> a
    False -> gcd(b, a % b)
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

pub fn dispatch_discovery_42(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  MixedDirectionalCoverage,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_41_joint_directional_deficit.dispatch_discovery_41(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) -> {
      let joint = previous.previous
      let asymmetry = joint.previous
      let mean = asymmetry.previous
      let signed = mean.previous
      let directional = signed.previous
      let base = directional.previous
      let l = base.left_windows
      let r = base.right_windows
      let i = base.intersection_windows
      let t = base.total_windows
      let a = directional.left_coverage_numerator
      let b = directional.left_coverage_denominator
      let c = directional.right_coverage_numerator
      let d = directional.right_coverage_denominator
      let mn = mean.mean_numerator
      let md = mean.mean_denominator
      let jn = joint.joint_coverage_numerator
      let jd = joint.joint_coverage_denominator
      let qn = previous.joint_deficit_numerator
      let qd = previous.joint_deficit_denominator
      let counts_ok =
        i >= 0
        && i <= l
        && i <= r
        && l + r - i <= t
        && base.combined_windows == l + r - i
      let fractions_ok =
        valid_coverage(a, b, l, i)
        && valid_coverage(c, d, r, i)
        && valid_fraction(mn, md)
        && valid_fraction(jn, jd)
        && valid_fraction(qn, qd)
        && mn * 2 * b * d == { a * d + c * b } * md
        && jn * b * d == a * c * jd
        && qn * b * d == { b - a } * { d - c } * qd
      case counts_ok && fractions_ok {
        False -> Error(discovery_19_interval_value.InvalidStream)
        True -> {
          let raw_n = a * { d - c } + { b - a } * c
          let raw_d = b * d
          let divisor = gcd(raw_n, raw_d)
          let n = raw_n / divisor
          let den = raw_d / divisor
          let counts_match = case l == 0, r == 0 {
            True, True -> n == 0 && den == 1
            True, False -> n == 1 && den == 1
            False, True -> n == 1 && den == 1
            False, False -> n * l * r == i * { l + r - 2 * i } * den
          }
          let zero_ok =
            { n == 0 } == { a == 0 && c == 0 || a == b && c == d }
          let one_ok = { n == den } == { { l == 0 } != { r == 0 } }
          let partition_ok =
            jn * qd * den + qn * jd * den + n * jd * qd == jd * qd * den
          let linear_ok =
            n * md * jd == { 2 * mn * jd - 2 * jn * md } * den
          case
            valid_fraction(n, den)
            && counts_match
            && zero_ok
            && one_ok
            && partition_ok
            && linear_ok
          {
            False -> Error(discovery_19_interval_value.InvalidStream)
            True ->
              Ok(MixedDirectionalCoverage(
                previous: previous,
                mixed_coverage_numerator: n,
                mixed_coverage_denominator: den,
              ))
          }
        }
      }
    }
  }
}
