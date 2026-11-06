// Stadio 29 / DISCOVERY 25: plej mallonga eksplicita kontigua sojlofenestro.
// Strikte pozitivaj Stage25-interspacoj ebligas O(k) glitfenestron po sojlo.
// Neniu aŭtomata pordegoserio, jaro, aŭ kalendara datkonverto.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_22_gap_prefixes

pub type WindowReach {
  WindowFound(start: Int, end: Int, total: Int)
  NoWindow
}

pub type ThresholdWindow {
  ThresholdWindow(threshold: Int, reach: WindowReach)
}

pub fn dispatch_discovery_25(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  thresholds: List(Int),
) -> Result(List(ThresholdWindow), discovery_19_interval_value.Discovery19Error) {
  case
    discovery_22_gap_prefixes.dispatch_discovery_22(context, requested_bowl_ids)
  {
    Error(error) -> Error(error)
    Ok(batch) -> {
      let gaps = list.map(batch.entries, fn(entry) { entry.sample.gap })
      Ok(
        list.map(thresholds, fn(threshold) {
          ThresholdWindow(
            threshold: threshold,
            reach: find_shortest(gaps, threshold),
          )
        }),
      )
    }
  }
}

fn find_shortest(gaps: List(Int), threshold: Int) -> WindowReach {
  case threshold <= 0 {
    True -> WindowFound(start: 0, end: 0, total: 0)
    False -> scan_right(gaps, gaps, threshold, 0, 0, 0, NoWindow)
  }
}

fn scan_right(
  left_remaining: List(Int),
  right_remaining: List(Int),
  threshold: Int,
  left: Int,
  right: Int,
  total: Int,
  best: WindowReach,
) -> WindowReach {
  case right_remaining {
    [] -> best
    [gap, ..rest] -> {
      let next_right = right + 1
      let #(next_left_remaining, next_left, next_total, next_best) =
        shrink_left(
          left_remaining,
          threshold,
          left,
          next_right,
          total + gap,
          best,
        )
      scan_right(
        next_left_remaining,
        rest,
        threshold,
        next_left,
        next_right,
        next_total,
        next_best,
      )
    }
  }
}

fn shrink_left(
  left_remaining: List(Int),
  threshold: Int,
  left: Int,
  right: Int,
  total: Int,
  best: WindowReach,
) -> #(List(Int), Int, Int, WindowReach) {
  case total >= threshold, left_remaining {
    True, [gap, ..rest] -> {
      let next_best = choose_best(best, left, right, total)
      shrink_left(rest, threshold, left + 1, right, total - gap, next_best)
    }
    _, _ -> #(left_remaining, left, total, best)
  }
}

fn choose_best(
  best: WindowReach,
  start: Int,
  end: Int,
  total: Int,
) -> WindowReach {
  case best {
    NoWindow -> WindowFound(start: start, end: end, total: total)
    WindowFound(start: previous_start, end: previous_end, total: _) ->
      case
        end - start < previous_end - previous_start
        || {
          end - start == previous_end - previous_start && start < previous_start
        }
      {
        True -> WindowFound(start: start, end: end, total: total)
        False -> best
      }
  }
}
