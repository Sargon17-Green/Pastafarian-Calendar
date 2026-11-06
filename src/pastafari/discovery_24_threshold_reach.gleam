// Stadio 28 / DISCOVERY 24: unua eksplicita prefikso atinganta sojlon.
// Neniu aŭtomata pordegosekvenco, jarlongo aŭ kalendara dato.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_22_gap_prefixes

pub type Reach {
  ReachedAt(prefix_size: Int)
  NotReached
}

pub type ThresholdFinding {
  ThresholdFinding(threshold: Int, reach: Reach)
}

pub fn dispatch_discovery_24(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  thresholds: List(Int),
) -> Result(List(ThresholdFinding), discovery_19_interval_value.Discovery19Error) {
  case
    discovery_22_gap_prefixes.dispatch_discovery_22(context, requested_bowl_ids)
  {
    Error(error) -> Error(error)
    Ok(batch) ->
      Ok(list.map(thresholds, fn(threshold) {
        ThresholdFinding(
          threshold: threshold,
          reach: find_reach(batch.entries, threshold),
        )
      }))
  }
}

fn find_reach(
  entries: List(discovery_22_gap_prefixes.GapPrefix),
  threshold: Int,
) -> Reach {
  case threshold <= 0 {
    True -> ReachedAt(prefix_size: 0)
    False -> first_matching(entries, threshold, 1)
  }
}

fn first_matching(
  entries: List(discovery_22_gap_prefixes.GapPrefix),
  threshold: Int,
  index: Int,
) -> Reach {
  case entries {
    [] -> NotReached
    [entry, ..rest] ->
      case entry.prefix_total >= threshold {
        True -> ReachedAt(prefix_size: index)
        False -> first_matching(rest, threshold, index + 1)
      }
  }
}
