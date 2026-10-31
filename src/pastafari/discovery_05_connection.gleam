// Stadio 9 / DISCOVERY 05: sumo de la du kanonaj tagkalkuloj.
// Nur diagnoza interligo; ne aldonu sesan datokomponanton.
// Uzu la jam korektitan tagmarkon de la propra Gleam-branĉo.
import pastafari/bootstrap
import pastafari/discovery_02_day_tag

pub type Discovery05Output {
  Discovery05Output(
    context: bootstrap.MonsterContext,
    action_count: Int,
    target_count: Int,
    connection: Int,
  )
}

pub fn connection_for_days(calculation_day: Int, target_day: Int) -> Int {
  discovery_02_day_tag.day_tag_patch(calculation_day)
  + discovery_02_day_tag.day_tag_patch(target_day)
}

pub fn dispatch_discovery_05(
  context: bootstrap.MonsterContext,
) -> Result(Discovery05Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) -> {
      let action_count =
        discovery_02_day_tag.day_tag_patch(completed.calculation_day)
      let target_count =
        discovery_02_day_tag.day_tag_patch(completed.target_day)
      Ok(Discovery05Output(
        context: completed,
        action_count: action_count,
        target_count: target_count,
        connection: action_count + target_count,
      ))
    }
  }
}
