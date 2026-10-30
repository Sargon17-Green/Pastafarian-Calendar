// Stadio 6 / DISCOVERY 03: diagnoza, intence ekskluziva distanco.
// La inkluziva orakolo ekzistas nur en la testa referenco.
// Tiu ĉi nova esplora legacy-modelo ne atestas antaŭan produktan eraron.
import pastafari/bootstrap

pub type Discovery03Output {
  Discovery03Output(
    context: bootstrap.MonsterContext,
    legacy_distance: Int,
  )
}

pub fn old_distance(calculation_day: Int, target_day: Int) -> Int {
  let difference = target_day - calculation_day
  case difference < 0 {
    True -> -difference
    False -> difference
  }
}

pub fn dispatch_discovery_03(
  context: bootstrap.MonsterContext,
) -> Result(Discovery03Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery03Output(
        context: completed,
        legacy_distance: old_distance(
          completed.calculation_day,
          completed.target_day,
        ),
      ))
  }
}
