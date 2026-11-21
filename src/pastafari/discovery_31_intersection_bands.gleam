// Stadio 35 / DISCOVERY 31: fenestroj samtempe en A kaj B.
// Produktkodo komponas Stage32 kaj Stage34; neniu fenestra enumerado.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_28_union_bands
import pastafari/discovery_30_difference_bands

pub type IntersectionWindowCount {
  IntersectionWindowCount(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    combined_windows: Int,
    difference_windows: Int,
    intersection_windows: Int,
    total_windows: Int,
  )
}

pub fn dispatch_discovery_31(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(IntersectionWindowCount, discovery_19_interval_value.Discovery19Error) {
  case
    discovery_28_union_bands.dispatch_discovery_28(
      context,
      requested_bowl_ids,
      left_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(left) ->
      case
        discovery_30_difference_bands.dispatch_discovery_30(
          context,
          requested_bowl_ids,
          left_bands,
          right_bands,
        )
      {
        Error(error) -> Error(error)
        Ok(difference) -> {
          let k = list.length(requested_bowl_ids)
          let total = k * { k + 1 } / 2
          let a = left.qualifying_windows
          let b = difference.excluded_windows
          let union = difference.combined_windows
          let excluded = difference.difference_windows
          let intersection = a - excluded
          case
            excluded < 0
            || excluded > a
            || a > union
            || union > total
            || b < 0
            || b > union
            || intersection < 0
            || intersection > b
            || intersection != a + b - union
          {
            True -> Error(discovery_19_interval_value.InvalidStream)
            False ->
              Ok(IntersectionWindowCount(
                canonical_left_bands: left.canonical_bands,
                canonical_combined_bands: difference.canonical_combined_bands,
                canonical_right_bands: difference.canonical_excluded_bands,
                left_windows: a,
                right_windows: b,
                combined_windows: union,
                difference_windows: excluded,
                intersection_windows: intersection,
                total_windows: total,
              ))
          }
        }
      }
  }
}
