// Stadio 33 / DISCOVERY 29: fenestroj ekster la unio de fermitaj sumintervaloj.
// Nur eksplicitaj bovlo-petoj; ne kronologia serio aŭ plena datkonverto.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands
import pastafari/discovery_28_union_bands

pub type ComplementWindowCount {
  ComplementWindowCount(
    canonical_bands: List(discovery_27_sum_bands.SumBand),
    inside_windows: Int,
    outside_windows: Int,
    total_windows: Int,
  )
}

pub fn dispatch_discovery_29(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
) -> Result(ComplementWindowCount, discovery_19_interval_value.Discovery19Error) {
  // Stage32 faras la validigon unufoje eĉ se bands aŭ ids estas malplenaj.
  case
    discovery_28_union_bands.dispatch_discovery_28(
      context,
      requested_bowl_ids,
      bands,
    )
  {
    Error(error) -> Error(error)
    Ok(union) -> {
      let k = list.length(requested_bowl_ids)
      let total = k * { k + 1 } / 2
      let inside = union.qualifying_windows
      case inside < 0 || inside > total {
        True -> Error(discovery_19_interval_value.InvalidStream)
        False ->
          Ok(ComplementWindowCount(
            canonical_bands: union.canonical_bands,
            inside_windows: inside,
            outside_windows: total - inside,
            total_windows: total,
          ))
      }
    }
  }
}
