// Stadio 39 / DISCOVERY 35: ekzakta reduktita interkovra koeficiento.
// Unu Stage38-voko; neniu reenumerado, rekanonigo aŭ glitkoma aritmetiko.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_34_dice_bands

pub type OverlapWindowSimilarity {
  OverlapWindowSimilarity(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    intersection_windows: Int,
    combined_windows: Int,
    symmetric_difference_windows: Int,
    total_windows: Int,
    jaccard_numerator: Int,
    jaccard_denominator: Int,
    dice_numerator: Int,
    dice_denominator: Int,
    overlap_numerator: Int,
    overlap_denominator: Int,
  )
}

fn greatest_common_divisor(left: Int, right: Int) -> Int {
  case right == 0 {
    True -> left
    False -> greatest_common_divisor(right, left % right)
  }
}

pub fn dispatch_discovery_35(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  OverlapWindowSimilarity,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_34_dice_bands.dispatch_discovery_34(
      context,
      requested_bowl_ids,
      left_bands,
      right_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) -> {
      let left = previous.left_windows
      let right = previous.right_windows
      let intersection = previous.intersection_windows
      let combined = previous.combined_windows
      let xor_count = previous.symmetric_difference_windows
      let total = previous.total_windows
      let j_p = previous.jaccard_numerator
      let j_q = previous.jaccard_denominator
      let d_p = previous.dice_numerator
      let d_q = previous.dice_denominator
      let sum = left + right
      let minimum = case left < right {
        True -> left
        False -> right
      }

      let invalid_counts =
        left < 0
        || right < 0
        || intersection < 0
        || combined < 0
        || xor_count < 0
        || total < 0
        || intersection > minimum
        || left > combined
        || right > combined
        || combined > total
        || combined != left + right - intersection
        || xor_count != combined - intersection
        || xor_count != left + right - 2 * intersection
        || xor_count > combined

      let invalid_j_value = case combined == 0 {
        True -> j_p != 1 || j_q != 1
        False -> j_p * combined != intersection * j_q
      }
      let invalid_d_value = case sum == 0 {
        True -> d_p != 1 || d_q != 1
        False -> d_p * sum != 2 * intersection * d_q
      }
      let invalid_inherited_fractions =
        j_q <= 0
        || j_p < 0
        || j_p > j_q
        || greatest_common_divisor(j_p, j_q) != 1
        || invalid_j_value
        || d_q <= 0
        || d_p < 0
        || d_p > d_q
        || greatest_common_divisor(d_p, d_q) != 1
        || invalid_d_value

      case invalid_counts || invalid_inherited_fractions {
        True -> Error(discovery_19_interval_value.InvalidStream)
        False -> {
          let #(o_p, o_q) = case minimum == 0 {
            True -> case left == 0 && right == 0 {
              True -> #(1, 1)
              False -> #(0, 1)
            }
            False -> {
              let divisor = greatest_common_divisor(intersection, minimum)
              #(intersection / divisor, minimum / divisor)
            }
          }

          let invalid_overlap_value = case minimum == 0 {
            True -> case left == 0 && right == 0 {
              True -> o_p != 1 || o_q != 1
              False -> o_p != 0 || o_q != 1
            }
            False -> o_p * minimum != intersection * o_q
          }
          let invalid_overlap =
            o_q <= 0
            || o_p < 0
            || o_p > o_q
            || greatest_common_divisor(o_p, o_q) != 1
            || invalid_overlap_value
            || o_p * d_q < d_p * o_q
            || d_p * j_q < j_p * d_q

          case invalid_overlap {
            True -> Error(discovery_19_interval_value.InvalidStream)
            False ->
              Ok(OverlapWindowSimilarity(
                canonical_left_bands: previous.canonical_left_bands,
                canonical_combined_bands: previous.canonical_combined_bands,
                canonical_right_bands: previous.canonical_right_bands,
                left_windows: left,
                right_windows: right,
                intersection_windows: intersection,
                combined_windows: combined,
                symmetric_difference_windows: xor_count,
                total_windows: total,
                jaccard_numerator: j_p,
                jaccard_denominator: j_q,
                dice_numerator: d_p,
                dice_denominator: d_q,
                overlap_numerator: o_p,
                overlap_denominator: o_q,
              ))
          }
        }
      }
    }
  }
}
