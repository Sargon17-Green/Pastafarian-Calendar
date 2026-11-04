// Stadio 25 / DISCOVERY 21: eksplicita ordkonserva aro de pordeg-interspacaj petoj.
// Tio ne estas kronologia pordegoserio aŭ jara kalkulo.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap

pub fn dispatch_discovery_21(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
) -> Result(
  List(discovery_20_gate_gap.GateGapOutput),
  discovery_19_interval_value.Discovery19Error,
) {
  collect(context, requested_bowl_ids, [])
}

fn collect(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  reversed: List(discovery_20_gate_gap.GateGapOutput),
) -> Result(
  List(discovery_20_gate_gap.GateGapOutput),
  discovery_19_interval_value.Discovery19Error,
) {
  case requested_bowl_ids {
    [] -> Ok(list.reverse(reversed))
    [bowl_id, ..rest] ->
      case discovery_20_gate_gap.dispatch_discovery_20(context, bowl_id) {
        Error(error) -> Error(error)
        Ok(sample) -> collect(context, rest, [sample, ..reversed])
      }
  }
}

pub fn gap_values_for_days(
  calculation_day: Int,
  target_day: Int,
  requested_bowl_ids: List(Int),
) -> Result(List(Int), discovery_19_interval_value.Discovery19Error) {
  case
    dispatch_discovery_21(
      bootstrap.new_context(calculation_day, target_day),
      requested_bowl_ids,
    )
  {
    Error(error) -> Error(error)
    Ok(samples) -> Ok(list.map(samples, fn(sample) { sample.gap }))
  }
}
