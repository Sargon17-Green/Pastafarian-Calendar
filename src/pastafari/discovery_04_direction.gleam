// Stadio 8 / DISCOVERY 04: direkto inter la kalkula kaj cela tagoj.
// Sendependa produkta klasifiko; la kanona orakolo restas nur en test/reference.
// Neniu historia produkt-eraro aŭ intence ruĝa atesto estas supozata.
import pastafari/bootstrap

pub type Discovery04Output {
  Discovery04Output(context: bootstrap.MonsterContext, direction: Int)
}

pub fn direction_for_days(calculation_day: Int, target_day: Int) -> Int {
  let difference = target_day - calculation_day
  case difference {
    0 -> 2
    _ ->
      case difference < 0 {
        True -> 1
        False -> 3
      }
  }
}

pub fn dispatch_discovery_04(
  context: bootstrap.MonsterContext,
) -> Result(Discovery04Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery04Output(
        context: completed,
        direction: direction_for_days(
          completed.calculation_day,
          completed.target_day,
        ),
      ))
  }
}
