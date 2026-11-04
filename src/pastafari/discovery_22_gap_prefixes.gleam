// Stadio 26 / DISCOVERY 22: prefiksaj sumoj por eksplicitaj petoj.
// Neniu aŭtomata kalendara pordegoserio aŭ jarlongo.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch

pub type GapPrefix {
  GapPrefix(sample: discovery_20_gate_gap.GateGapOutput, prefix_total: Int)
}

pub type GapPrefixBatch {
  GapPrefixBatch(entries: List(GapPrefix), total: Int)
}

pub fn dispatch_discovery_22(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
) -> Result(GapPrefixBatch, discovery_19_interval_value.Discovery19Error) {
  case
    discovery_21_gate_batch.dispatch_discovery_21(context, requested_bowl_ids)
  {
    Error(error) -> Error(error)
    Ok(samples) -> Ok(accumulate(samples, 0, []))
  }
}

fn accumulate(
  samples: List(discovery_20_gate_gap.GateGapOutput),
  running: Int,
  reversed: List(GapPrefix),
) -> GapPrefixBatch {
  case samples {
    [] -> GapPrefixBatch(entries: list.reverse(reversed), total: running)
    [sample, ..rest] -> {
      let next = running + sample.gap
      accumulate(rest, next, [
        GapPrefix(sample: sample, prefix_total: next),
        ..reversed
      ])
    }
  }
}

pub fn prefix_total_for_days(
  calculation_day: Int,
  target_day: Int,
  requested_bowl_ids: List(Int),
) -> Result(Int, discovery_19_interval_value.Discovery19Error) {
  case
    dispatch_discovery_22(
      bootstrap.new_context(calculation_day, target_day),
      requested_bowl_ids,
    )
  {
    Error(error) -> Error(error)
    Ok(result) -> Ok(result.total)
  }
}
