// Stadio 4 / DISCOVERY 02: intence historia tagmarka eraro.
// Neniu korekto de PATCH 02 estas efektivigita ĉi tie.
import pastafari/bootstrap

pub const old_foundation_day = -15_055_671

pub type Discovery02Output {
  Discovery02Output(
    context: bootstrap.MonsterContext,
    legacy_day_tag: Int,
  )
}

pub fn old_day_tag(day: Int) -> Int {
  let displacement = day - old_foundation_day
  case displacement < 0 {
    True -> -2 * displacement
    False -> 2 * displacement
  }
}

pub fn dispatch_discovery_02(
  context: bootstrap.MonsterContext,
  day: Int,
) -> Result(Discovery02Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery02Output(
        context: completed,
        legacy_day_tag: old_day_tag(day),
      ))
  }
}
