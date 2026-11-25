// Stadio 40: direkta kovrado sen reenumerado de fenestroj.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_35_overlap_bands

pub type DirectionalWindowCoverage {
  DirectionalWindowCoverage(
    previous: discovery_35_overlap_bands.OverlapWindowSimilarity,
    left_coverage_numerator: Int,
    left_coverage_denominator: Int,
    right_coverage_numerator: Int,
    right_coverage_denominator: Int,
  )
}

fn gcd(a: Int, b: Int) -> Int {
  case b == 0 {
    True -> a
    False -> gcd(b, a % b)
  }
}

fn reduced(i: Int, n: Int) -> #(Int, Int) {
  case n == 0 {
    True -> #(1, 1)
    False -> {
      let d = gcd(i, n)
      #(i / d, n / d)
    }
  }
}

fn valid(p: Int, q: Int, numerator: Int, denominator: Int) -> Bool {
  let value_ok = case denominator == 0 {
    True -> p == 1 && q == 1
    False -> p * denominator == numerator * q
  }
  q > 0 && p >= 0 && p <= q && gcd(p, q) == 1 && value_ok
}

pub fn dispatch_discovery_36(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  DirectionalWindowCoverage,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_35_overlap_bands.dispatch_discovery_35(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) ->
      // The inherited pipeline may skip per-bowl validation for an empty ID list.
      case bootstrap.validate_context(context) {
        Error(error) -> Error(discovery_19_interval_value.InvalidContext(error))
        Ok(_) -> {
          let l = previous.left_windows
          let r = previous.right_windows
          let i = previous.intersection_windows
          let u = previous.combined_windows
          let x = previous.symmetric_difference_windows
          let t = previous.total_windows
          let k = list.length(requested_bowl_ids)
          let m = case l <= r {
            True -> l
            False -> r
          }
          let jp = previous.jaccard_numerator
          let jq = previous.jaccard_denominator
          let dp = previous.dice_numerator
          let dq = previous.dice_denominator
          let op = previous.overlap_numerator
          let oq = previous.overlap_denominator
          let counts_ok =
            l >= 0
            && r >= 0
            && i >= 0
            && x >= 0
            && u >= 0
            && t >= 0
            && i <= m
            && l <= u
            && r <= u
            && u <= t
            && u == l + r - i
            && x == u - i
            && t == k * { k + 1 } / 2
          let overlap_ok = case m == 0 && l + r > 0 {
            True -> op == 0 && oq == 1
            False -> valid(op, oq, i, m)
          }
          case
            counts_ok
            && valid(jp, jq, i, u)
            && valid(dp, dq, 2 * i, l + r)
            && overlap_ok
          {
            False -> Error(discovery_19_interval_value.InvalidStream)
            True -> {
              let #(lp, lq) = reduced(i, l)
              let #(rp, rq) = reduced(i, r)
              let #(low_p, low_q, high_p, high_q) = case lp * rq <= rp * lq {
                True -> #(lp, lq, rp, rq)
                False -> #(rp, rq, lp, lq)
              }
              let relations = case l > 0 && r > 0 {
                True ->
                  high_p * oq == op * high_q
                  && low_p * dq <= dp * low_q
                  && dp * high_q <= high_p * dq
                  && jp * low_q <= low_p * jq
                False -> True
              }
              let left_subset = { lp == lq } == { i == l }
              let right_subset = { rp == rq } == { i == r }
              case
                valid(lp, lq, i, l)
                && valid(rp, rq, i, r)
                && left_subset
                && right_subset
                && relations
              {
                False -> Error(discovery_19_interval_value.InvalidStream)
                True ->
                  Ok(DirectionalWindowCoverage(
                    previous: previous,
                    left_coverage_numerator: lp,
                    left_coverage_denominator: lq,
                    right_coverage_numerator: rp,
                    right_coverage_denominator: rq,
                  ))
              }
            }
          }
        }
      }
  }
}
