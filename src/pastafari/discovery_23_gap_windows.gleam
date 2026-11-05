// Stadio 27 / DISCOVERY 23: duonmalfermitaj sumfenestroj de eksplicitaj petoj.
// Neniu jarlongo aŭ aŭtomata kanona pordegoserio.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_22_gap_prefixes

pub type WindowTotal {
  WindowTotal(start: Int, end: Int, total: Int)
}

pub type Discovery23Error {
  Upstream(discovery_19_interval_value.Discovery19Error)
  InvalidWindow(start: Int, end: Int, size: Int)
}

pub fn dispatch_discovery_23(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  windows: List(#(Int, Int)),
) -> Result(List(WindowTotal), Discovery23Error) {
  case
    discovery_22_gap_prefixes.dispatch_discovery_22(
      context,
      requested_bowl_ids,
    )
  {
    Error(error) -> Error(Upstream(error))
    Ok(batch) -> {
      let values = list.map(batch.entries, fn(entry) { entry.prefix_total })
      let size = list.length(values)
      collect_windows(windows, values, size, [])
    }
  }
}

fn collect_windows(
  windows: List(#(Int, Int)),
  prefixes: List(Int),
  size: Int,
  reversed: List(WindowTotal),
) -> Result(List(WindowTotal), Discovery23Error) {
  case windows {
    [] -> Ok(list.reverse(reversed))
    [#(start, end), ..rest] ->
      case start < 0 || end < start || end > size {
        True -> Error(InvalidWindow(start: start, end: end, size: size))
        False -> {
          let total = prefix_at(prefixes, end) - prefix_at(prefixes, start)
          collect_windows(rest, prefixes, size, [
            WindowTotal(start: start, end: end, total: total),
            ..reversed
          ])
        }
      }
  }
}

fn prefix_at(prefixes: List(Int), index: Int) -> Int {
  case index == 0 {
    True -> 0
    False -> {
      // Indekso ĉiam troviĝas en 1..size post la valida fenestrokontrolo.
      let assert Ok(value) = list.at(prefixes, index - 1)
      value
    }
  }
}
