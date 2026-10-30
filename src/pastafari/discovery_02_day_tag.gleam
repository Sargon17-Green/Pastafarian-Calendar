// Stadio 5 / PATCH 02: konservu la historian tagmarkon por diagnozo.
// La korekto aldonas 1 ekde la fonda tago, konservante antaŭajn tagojn.
import pastafari/bootstrap

pub const old_foundation_day = -15_055_671

pub type Discovery02Output {
  Discovery02Output(
    context: bootstrap.MonsterContext,
    legacy_day_tag: Int,
    patched_day_tag: Int,
  )
}

pub fn old_day_tag(day: Int) -> Int {
  let displacement = day - old_foundation_day
  case displacement < 0 {
    True -> -2 * displacement
    False -> 2 * displacement
  }
}

pub fn day_tag_patch(day: Int) -> Int {
  let legacy = old_day_tag(day)
  case day < old_foundation_day {
    True -> legacy
    False -> legacy + 1
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
        patched_day_tag: day_tag_patch(day),
      ))
  }
}
