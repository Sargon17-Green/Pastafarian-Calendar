// Stadio 34 / DISCOVERY 30: fenestroj en A sed ne en B.
// Uzu Stage32 dufoje; neniu plena datkonverto aŭ nova kanonigilo.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_28_union_bands

pub type DifferenceWindowCount {
  DifferenceWindowCount(
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_excluded_bands: List(discovery_27_sum_bands.SumBand),
    combined_windows: Int,
    excluded_windows: Int,
    difference_windows: Int,
    total_windows: Int,
  )
}

pub fn dispatch_discovery_30(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  included_bands: List(discovery_27_sum_bands.SumBand),
  excluded_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(DifferenceWindowCount, discovery_19_interval_value.Discovery19Error) {
  case
    discovery_28_union_bands.dispatch_discovery_28(
      context,
      requested_bowl_ids,
      list.append(included_bands, excluded_bands),
    )
  {
    Error(error) -> Error(error)
    Ok(combined) ->
      case
        discovery_28_union_bands.dispatch_discovery_28(
          context,
          requested_bowl_ids,
          excluded_bands,
        )
      {
        Error(error) -> Error(error)
        Ok(excluded) -> {
          let k = list.length(requested_bowl_ids)
          let total = k * { k + 1 } / 2
          let both_count = combined.qualifying_windows
          let excluded_count = excluded.qualifying_windows
          case
            excluded_count < 0
            || both_count < excluded_count
            || both_count > total
          {
            True -> Error(discovery_19_interval_value.InvalidStream)
            False ->
              Ok(DifferenceWindowCount(
                canonical_combined_bands: combined.canonical_bands,
                canonical_excluded_bands: excluded.canonical_bands,
                combined_windows: both_count,
                excluded_windows: excluded_count,
                difference_windows: both_count - excluded_count,
                total_windows: total,
              ))
          }
        }
      }
  }
}
