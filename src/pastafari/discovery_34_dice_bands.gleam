// Stadio 38 / DISCOVERY 34: ekzakta Sorensen-Dice-simileco.
// Precize unu Stage37-voko. Neniu dua fenestra enumerado, glitkomo aŭ rekanonigo.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_33_jaccard_bands

pub type DiceWindowSimilarity {
  DiceWindowSimilarity(
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
  )
}

fn greatest_common_divisor(left: Int, right: Int) -> Int {
  case right == 0 {
    True -> left
    False -> greatest_common_divisor(right, left % right)
  }
}

pub fn dispatch_discovery_34(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  DiceWindowSimilarity,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_33_jaccard_bands.dispatch_discovery_33(
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
      let j_numerator = previous.similarity_numerator
      let j_denominator = previous.similarity_denominator
      let invalid_counts =
        left < 0
        || right < 0
        || intersection < 0
        || combined < 0
        || xor_count < 0
        || total < 0
        || intersection > left
        || intersection > right
        || left > combined
        || right > combined
        || combined > total
        || combined != left + right - intersection
        || xor_count != combined - intersection
        || xor_count != left + right - 2 * intersection
        || xor_count > combined

      let invalid_jaccard_value = case combined == 0 {
        True -> j_numerator != 1 || j_denominator != 1
        False -> j_numerator * combined != intersection * j_denominator
      }
      let invalid_jaccard =
        j_denominator <= 0
        || j_numerator < 0
        || j_numerator > j_denominator
        || greatest_common_divisor(j_numerator, j_denominator) != 1
        || invalid_jaccard_value

      case invalid_counts || invalid_jaccard {
        True -> Error(discovery_19_interval_value.InvalidStream)
        False -> {
          let sum = left + right
          let #(numerator, denominator) = case sum == 0 {
            True -> #(1, 1)
            False -> {
              let divisor = greatest_common_divisor(2 * intersection, sum)
              #(2 * intersection / divisor, sum / divisor)
            }
          }
          let invalid_dice =
            denominator <= 0
            || numerator < 0
            || numerator > denominator
            || greatest_common_divisor(numerator, denominator) != 1
            || case sum == 0 {
              True -> numerator != 1 || denominator != 1
              False -> numerator * sum != 2 * intersection * denominator
            }

          case invalid_dice {
            True -> Error(discovery_19_interval_value.InvalidStream)
            False ->
              Ok(DiceWindowSimilarity(
                canonical_left_bands: previous.canonical_left_bands,
                canonical_combined_bands: previous.canonical_combined_bands,
                canonical_right_bands: previous.canonical_right_bands,
                left_windows: left,
                right_windows: right,
                intersection_windows: intersection,
                combined_windows: combined,
                symmetric_difference_windows: xor_count,
                total_windows: total,
                jaccard_numerator: j_numerator,
                jaccard_denominator: j_denominator,
                dice_numerator: numerator,
                dice_denominator: denominator,
              ))
          }
        }
      }
    }
  }
}
