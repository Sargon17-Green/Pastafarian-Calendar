// Stadio 47 / DISCOVERY 43: kondiĉa konkorda kovro.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_42_mixed_directional_coverage

pub type ConcordantScore {
  NoConcordantPairs
  Fraction(numerator: Int, denominator: Int)
}

pub type ConditionalConcordantCoverage {
  ConditionalConcordantCoverage(
    previous: discovery_42_mixed_directional_coverage.MixedDirectionalCoverage,
    score: ConcordantScore,
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

pub fn dispatch_discovery_43(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  ConditionalConcordantCoverage,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_42_mixed_directional_coverage.dispatch_discovery_42(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) -> {
      let deficit = previous.previous
      let joint = deficit.previous
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
      let jn = joint.joint_coverage_numerator
      let jd = joint.joint_coverage_denominator
      let qn = deficit.joint_deficit_numerator
      let qd = deficit.joint_deficit_denominator
      let xn = previous.mixed_coverage_numerator
      let xd = previous.mixed_coverage_denominator
      let counts_ok =
        i >= 0
        && i <= l
        && i <= r
        && l + r - i <= t
        && base.combined_windows == l + r - i
      let fractions_ok =
        valid_coverage(a, b, l, i)
        && valid_coverage(c, d, r, i)
        && valid_fraction(jn, jd)
        && valid_fraction(qn, qd)
        && valid_fraction(xn, xd)
        && jn * b * d == a * c * jd
        && qn * b * d == { b - a } * { d - c } * qd
        && jn * qd * xd + qn * jd * xd + xn * jd * qd == jd * qd * xd
      case counts_ok && fractions_ok {
        False -> Error(discovery_19_interval_value.InvalidStream)
        True -> {
          let raw_n = jn * qd
          let raw_d = raw_n + qn * jd
          let exactly_one_empty = { l == 0 } != { r == 0 }
          case raw_d == 0 {
            True ->
              case exactly_one_empty && xn == xd {
                True ->
                  Ok(ConditionalConcordantCoverage(
                    previous: previous,
                    score: NoConcordantPairs,
                  ))
                False -> Error(discovery_19_interval_value.InvalidStream)
              }
            False -> {
              let divisor = gcd(raw_n, raw_d)
              let n = raw_n / divisor
              let den = raw_d / divisor
              let counts_match = case l == 0, r == 0 {
                True, True -> n == 1 && den == 1
                False, False ->
                  n * { i * i + { l - i } * { r - i } } == i * i * den
                _, _ -> False
              }
              case valid_fraction(n, den) && counts_match {
                False -> Error(discovery_19_interval_value.InvalidStream)
                True ->
                  Ok(ConditionalConcordantCoverage(
                    previous: previous,
                    score: Fraction(numerator: n, denominator: den),
                  ))
              }
            }
          }
        }
      }
    }
  }
}
