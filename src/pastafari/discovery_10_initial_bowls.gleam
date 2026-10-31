// Stadio 14 / DISCOVERY 10: ses komencaj bovloj, ordigitaj laŭ identigilo.
// Produktkodo uzas nur proprajn antaŭajn kalkulojn, neniam test/reference.
import pastafari/bootstrap
import pastafari/discovery_02_day_tag
import pastafari/discovery_03_distance
import pastafari/discovery_04_direction

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery10Output {
  Discovery10Output(context: bootstrap.MonsterContext, bowls: List(Int))
}

fn save(value: Int) -> Int {
  let remainder = { value - 1 } % modulus
  case remainder < 0 {
    True -> remainder + modulus + 1
    False -> remainder + 1
  }
}

fn create_bowls(
  primes: List(#(Int, Int)),
  action: Int,
  target: Int,
  distance: Int,
  connection: Int,
  direction: Int,
) -> List(Int) {
  case primes {
    [] -> []
    [entry, ..rest] -> {
      let #(identifier, prime) = entry
      let seed =
        action
        + identifier
        * target
        + distance
        + connection
        + direction
        + prime
        * prime
      let value = save(seed * seed + identifier)
      [
        value,
        ..create_bowls(rest, action, target, distance, connection, direction)
      ]
    }
  }
}

pub fn initial_bowls_for_days(
  calculation_day: Int,
  target_day: Int,
) -> List(Int) {
  let action = discovery_02_day_tag.day_tag_patch(calculation_day)
  let target = discovery_02_day_tag.day_tag_patch(target_day)
  let distance =
    discovery_03_distance.old_distance(calculation_day, target_day) + 1
  let connection = action + target
  let direction =
    discovery_04_direction.direction_for_days(calculation_day, target_day)
  create_bowls(
    [#(1, 17), #(2, 19), #(3, 23), #(4, 29), #(5, 31), #(6, 37)],
    action,
    target,
    distance,
    connection,
    direction,
  )
}

pub fn dispatch_discovery_10(
  context: bootstrap.MonsterContext,
) -> Result(Discovery10Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery10Output(
        context: completed,
        bowls: initial_bowls_for_days(
          completed.calculation_day,
          completed.target_day,
        ),
      ))
  }
}
