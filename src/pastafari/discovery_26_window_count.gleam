// Stadio 30 / DISCOVERY 26: kalkulu ĉiujn ne-malplenajn atingantajn fenestrojn.
// Strikte pozitivaj eksplicitaj Stage25-interspacoj ebligas du montrilojn.
// Neniu jarkalkulo, aŭtomata kalendara serio aŭ kompleta datkonverto.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_22_gap_prefixes

pub type ThresholdWindowCount {
  ThresholdWindowCount(threshold: Int, qualifying_windows: Int)
}

pub fn dispatch_discovery_26(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  thresholds: List(Int),
) -> Result(
  List(ThresholdWindowCount),
  discovery_19_interval_value.Discovery19Error,
) {
  case
    discovery_22_gap_prefixes.dispatch_discovery_22(context, requested_bowl_ids)
  {
    Error(error) -> Error(error)
    Ok(batch) -> {
      let gaps = list.map(batch.entries, fn(entry) { entry.sample.gap })
      let size = list.length(gaps)
      Ok(
        list.map(thresholds, fn(threshold) {
          ThresholdWindowCount(
            threshold: threshold,
            qualifying_windows: count_for_threshold(
              gaps,
              size,
              batch.total,
              threshold,
            ),
          )
        }),
      )
    }
  }
}

fn count_for_threshold(
  gaps: List(Int),
  size: Int,
  grand_total: Int,
  threshold: Int,
) -> Int {
  case threshold <= 0 {
    True -> size * { size + 1 } / 2
    False ->
      case threshold > grand_total {
        True -> 0
        False -> scan_starts(gaps, gaps, threshold, size, 0, 0)
      }
  }
}

fn scan_starts(
  left_remaining: List(Int),
  right_remaining: List(Int),
  threshold: Int,
  right_unconsumed: Int,
  total: Int,
  count: Int,
) -> Int {
  case left_remaining {
    [] -> count
    [left_gap, ..rest] -> {
      let #(next_right, unconsumed, next_total) =
        extend_right(right_remaining, threshold, right_unconsumed, total)
      case next_total >= threshold {
        False -> count
        True ->
          scan_starts(
            rest,
            next_right,
            threshold,
            unconsumed,
            next_total - left_gap,
            count + unconsumed + 1,
          )
      }
    }
  }
}

fn extend_right(
  remaining: List(Int),
  threshold: Int,
  unconsumed: Int,
  total: Int,
) -> #(List(Int), Int, Int) {
  case total >= threshold, remaining {
    True, _ -> #(remaining, unconsumed, total)
    False, [] -> #(remaining, unconsumed, total)
    False, [gap, ..rest] ->
      extend_right(rest, threshold, unconsumed - 1, total + gap)
  }
}
