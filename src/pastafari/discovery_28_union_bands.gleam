// Stadio 32 / DISCOVERY 28: unia nombro de ne-malplenaj sinsekvaj fenestroj
// tra fermitaj entjeraj sumintervaloj; sen datkonverto aŭ kalendara serio.
import gleam/int
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_27_sum_bands

pub type UnionWindowCount {
  UnionWindowCount(
    canonical_bands: List(discovery_27_sum_bands.SumBand),
    qualifying_windows: Int,
  )
}

fn compare_bands(
  left: discovery_27_sum_bands.SumBand,
  right: discovery_27_sum_bands.SumBand,
) {
  case left.lower == right.lower {
    True -> int.compare(left.upper, right.upper)
    False -> int.compare(left.lower, right.lower)
  }
}

fn merge_bands(
  ordered: List(discovery_27_sum_bands.SumBand),
  reversed: List(discovery_27_sum_bands.SumBand),
) -> List(discovery_27_sum_bands.SumBand) {
  case ordered, reversed {
    [], _ -> list.reverse(reversed)
    [next, ..rest], [] -> merge_bands(rest, [next])
    [next, ..rest], [current, ..previous] -> {
      case next.lower <= current.upper + 1 {
        True -> {
          let upper = case next.upper > current.upper {
            True -> next.upper
            False -> current.upper
          }
          merge_bands(rest, [
            discovery_27_sum_bands.SumBand(lower: current.lower, upper: upper),
            ..previous
          ])
        }
        False -> merge_bands(rest, [next, current, ..previous])
      }
    }
  }
}

fn canonicalize(
  bands: List(discovery_27_sum_bands.SumBand),
) -> List(discovery_27_sum_bands.SumBand) {
  bands
  |> list.filter(fn(band) { band.lower <= band.upper })
  |> list.sort(compare_bands)
  |> merge_bands([])
}

fn sum_checked(
  original: List(discovery_27_sum_bands.SumBand),
  remaining: List(discovery_27_sum_bands.SumBand),
  counts: List(discovery_27_sum_bands.SumBandCount),
  total: Int,
) -> Result(UnionWindowCount, discovery_19_interval_value.Discovery19Error) {
  case remaining, counts {
    [], [] ->
      Ok(UnionWindowCount(canonical_bands: original, qualifying_windows: total))
    [band, ..other_bands], [count, ..other_counts] -> {
      case band.lower == count.lower && band.upper == count.upper {
        True ->
          sum_checked(
            original,
            other_bands,
            other_counts,
            total + count.qualifying_windows,
          )
        False -> Error(discovery_19_interval_value.InvalidStream)
      }
    }
    _, _ -> Error(discovery_19_interval_value.InvalidStream)
  }
}

pub fn dispatch_discovery_28(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
) -> Result(UnionWindowCount, discovery_19_interval_value.Discovery19Error) {
  let canonical_bands = canonicalize(bands)
  // Ankaŭ por [] voku Stage31 precize unufoje por konservi erarprioritaton.
  case
    discovery_27_sum_bands.dispatch_discovery_27(
      context,
      requested_bowl_ids,
      canonical_bands,
    )
  {
    Error(error) -> Error(error)
    Ok(counts) -> sum_checked(canonical_bands, canonical_bands, counts, 0)
  }
}
