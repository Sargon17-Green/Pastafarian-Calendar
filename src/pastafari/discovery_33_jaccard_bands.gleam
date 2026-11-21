// Stadio 37 / DISCOVERY 33: ekzakta reduktita Jaccard-simileco de fenestraroj.
// Unu Stage32-voko; neniu nova fenestra enumerado aŭ glitkoma aritmetiko.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_32_symmetric_difference_bands

pub type JaccardWindowSimilarity {
  JaccardWindowSimilarity(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    intersection_windows: Int,
    combined_windows: Int,
    symmetric_difference_windows: Int,
    total_windows: Int,
    similarity_numerator: Int,
    similarity_denominator: Int,
  )
}

fn greatest_common_divisor(left: Int, right: Int) -> Int {
  case right == 0 {
    True -> left
    False -> greatest_common_divisor(right, left % right)
  }
}

pub fn dispatch_discovery_33(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  JaccardWindowSimilarity,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_32_symmetric_difference_bands.dispatch_discovery_32(
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
      let symmetric_difference = previous.symmetric_difference_windows
      let total = previous.total_windows
      let invalid_counts =
        intersection < 0
        || left < 0
        || right < 0
        || combined < 0
        || total < 0
        || intersection > left
        || intersection > right
        || left > combined
        || right > combined
        || combined > total
        || combined != left + right - intersection
        || symmetric_difference != left + right - 2 * intersection
        || symmetric_difference != combined - intersection
        || symmetric_difference < 0
        || symmetric_difference > combined

      case invalid_counts {
        True -> Error(discovery_19_interval_value.InvalidStream)
        False -> {
          let #(numerator, denominator) = case combined == 0 {
            True -> #(1, 1)
            False -> {
              let divisor = greatest_common_divisor(intersection, combined)
              #(
                intersection / divisor,
                combined / divisor,
              )
            }
          }

          let invalid_fraction =
            denominator <= 0
            || numerator < 0
            || numerator > denominator
            || greatest_common_divisor(numerator, denominator) != 1
            || numerator * combined != intersection * denominator

          case invalid_fraction {
            True -> Error(discovery_19_interval_value.InvalidStream)
            False ->
              Ok(JaccardWindowSimilarity(
                canonical_left_bands: previous.canonical_left_bands,
                canonical_combined_bands: previous.canonical_combined_bands,
                canonical_right_bands: previous.canonical_right_bands,
                left_windows: left,
                right_windows: right,
                intersection_windows: intersection,
                combined_windows: combined,
                symmetric_difference_windows: symmetric_difference,
                total_windows: total,
                similarity_numerator: numerator,
                similarity_denominator: denominator,
              ))
          }
        }
      }
    }
  }
}
