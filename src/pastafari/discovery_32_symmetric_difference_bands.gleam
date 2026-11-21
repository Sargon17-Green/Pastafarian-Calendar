// Stadio 36 / DISCOVERY 32: simetria diferenco de sumfenestroj.
// Unu Stage35-voko; neniu dua kanonigo aŭ fenestra enumerado.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_31_intersection_bands

pub type SymmetricDifferenceWindowCount {
  SymmetricDifferenceWindowCount(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    intersection_windows: Int,
    combined_windows: Int,
    symmetric_difference_windows: Int,
    total_windows: Int,
  )
}

pub fn dispatch_discovery_32(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(
  SymmetricDifferenceWindowCount,
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_31_intersection_bands.dispatch_discovery_31(
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
      let total = previous.total_windows
      let symmetric_difference = left + right - 2 * intersection
      case
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
        || symmetric_difference < 0
        || symmetric_difference > combined
      {
        True -> Error(discovery_19_interval_value.InvalidStream)
        False ->
          Ok(SymmetricDifferenceWindowCount(
            canonical_left_bands: previous.canonical_left_bands,
            canonical_combined_bands: previous.canonical_combined_bands,
            canonical_right_bands: previous.canonical_right_bands,
            left_windows: left,
            right_windows: right,
            intersection_windows: intersection,
            combined_windows: combined,
            symmetric_difference_windows: symmetric_difference,
            total_windows: total,
          ))
      }
    }
  }
}
