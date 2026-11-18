// Stadio 31 / DISCOVERY 27: nombro de pozitivaj sinsekvaj fenestroj
// kun sumo en fermita intervalo, sen kreado de kalendara sinsekvo.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_26_window_count

pub type SumBand {
  SumBand(lower: Int, upper: Int)
}

pub type SumBandCount {
  SumBandCount(lower: Int, upper: Int, qualifying_windows: Int)
}

pub fn dispatch_discovery_27(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  bands: List(SumBand),
) -> Result(List(SumBandCount), discovery_19_interval_value.Discovery19Error) {
  let thresholds =
    list.fold(bands, [], fn(acc, band) { [band.upper + 1, band.lower, ..acc] })
    |> list.reverse

  case
    discovery_26_window_count.dispatch_discovery_26(
      context,
      requested_bowl_ids,
      thresholds,
    )
  {
    Error(error) -> Error(error)
    Ok(counts) -> Ok(assemble_counts(bands, counts, []))
  }
}

fn assemble_counts(
  bands: List(SumBand),
  counts: List(discovery_26_window_count.ThresholdWindowCount),
  reversed: List(SumBandCount),
) -> List(SumBandCount) {
  case bands {
    [] -> list.reverse(reversed)
    [band, ..rest] -> {
      // Stage30 liveras unu kalkulon por ĉiu petita sojlo, laŭ ordo.
      let assert [at_lower, past_upper, ..remaining] = counts
      let qualifying = case band.lower > band.upper {
        True -> 0
        False -> at_lower.qualifying_windows - past_upper.qualifying_windows
      }
      assemble_counts(rest, remaining, [
        SumBandCount(
          lower: band.lower,
          upper: band.upper,
          qualifying_windows: qualifying,
        ),
        ..reversed
      ])
    }
  }
}
