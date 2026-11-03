// Stadio 24 / DISCOVERY 20: unu kanona pordeg-interspaca specimeno.
// La bovlo restas eksplicita; ĉi tiu stadio ne konstruas pordegoserion.
import pastafari/bootstrap
import pastafari/discovery_19_interval_value

pub const gap_min = 42
pub const gap_max = 963
pub const gap_seal = 1

pub type GateGapOutput {
  GateGapOutput(
    previous: discovery_19_interval_value.Discovery19Output,
    queried_bowl_id: Int,
    seal: Int,
    gap: Int,
  )
}

pub fn dispatch_discovery_20(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
) -> Result(GateGapOutput, discovery_19_interval_value.Discovery19Error) {
  case
    discovery_19_interval_value.dispatch_discovery_19(
      context,
      queried_bowl_id,
      gap_seal,
      gap_min,
      gap_max,
    )
  {
    Error(error) -> Error(error)
    Ok(previous) ->
      Ok(GateGapOutput(
        previous: previous,
        queried_bowl_id: queried_bowl_id,
        seal: gap_seal,
        gap: previous.value,
      ))
  }
}

pub fn gap_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
) -> Result(Int, discovery_19_interval_value.Discovery19Error) {
  case
    dispatch_discovery_20(
      bootstrap.new_context(calculation_day, target_day),
      queried_bowl_id,
    )
  {
    Error(error) -> Error(error)
    Ok(output) -> Ok(output.gap)
  }
}
