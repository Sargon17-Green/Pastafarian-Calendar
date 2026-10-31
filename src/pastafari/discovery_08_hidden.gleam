// Stadio 12 / DISCOVERY 08: sep kaŝitaj gutoj el la propraj laboraj kalkuloj.
// Produktkodo ne importas la testan referencon nek fremdan branĉon.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_02_day_tag
import pastafari/discovery_03_distance
import pastafari/discovery_04_direction
import pastafari/discovery_06_stones

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery08Output {
  Discovery08Output(context: bootstrap.MonsterContext, hidden: List(Int))
}

fn save(value: Int) -> Int {
  let remainder = { value - 1 } % modulus
  case remainder < 0 {
    True -> remainder + modulus + 1
    False -> remainder + 1
  }
}

fn stone_field(stone: discovery_06_stones.Stone, kind: Int) -> Int {
  case kind {
    1 -> stone.wheat
    2 -> stone.barley
    3 -> stone.salt
    4 -> stone.bitter
    5 -> stone.red
    _ -> panic as "Nevalida ŝtona speco"
  }
}

fn grind_seven(
  step: Int,
  value: Int,
  stone: discovery_06_stones.Stone,
) -> Int {
  case step > 7 {
    True -> value
    False -> {
      let kind = case step {
        6 -> 1
        7 -> 2
        _ -> step
      }
      let next = save(value * value + 3 * value + stone_field(stone, kind) + step)
      grind_seven(step + 1, next, stone)
    }
  }
}

fn build_from_pairs(
  coefficients: List(#(Int, Int, Int, Int)),
  stones: List(discovery_06_stones.Stone),
  action: Int,
  target: Int,
  distance: Int,
  connection: Int,
  direction: Int,
  reverse_acc: List(Int),
) -> List(Int) {
  case coefficients {
    [] -> list.reverse(reverse_acc)
    [coefficient, ..remaining_coefficients] -> {
      let #(a, b, c, d) = coefficient
      let assert [stone, ..remaining_stones] = stones
      let seed = save(
        action + a * target + b * distance + c * connection + d * direction
        + stone.wheat + stone.barley + stone.salt + stone.bitter + stone.red,
      )
      let value = grind_seven(1, seed, stone)
      build_from_pairs(
        remaining_coefficients,
        remaining_stones,
        action,
        target,
        distance,
        connection,
        direction,
        [value, ..reverse_acc],
      )
    }
  }
}

pub fn hidden_drops_for_days(calculation_day: Int, target_day: Int) -> List(Int) {
  let action = discovery_02_day_tag.day_tag_patch(calculation_day)
  let target = discovery_02_day_tag.day_tag_patch(target_day)
  let distance = discovery_03_distance.old_distance(calculation_day, target_day) + 1
  let connection = action + target
  let direction = discovery_04_direction.direction_for_days(calculation_day, target_day)
  build_from_pairs(
    [
      #(3, 4, 6, 8),
      #(5, 7, 10, 12),
      #(7, 10, 14, 16),
      #(9, 13, 18, 20),
      #(11, 16, 22, 24),
      #(13, 19, 26, 28),
      #(15, 22, 30, 32),
    ],
    discovery_06_stones.build_stones(),
    action,
    target,
    distance,
    connection,
    direction,
    [],
  )
}

pub fn dispatch_discovery_08(
  context: bootstrap.MonsterContext,
) -> Result(Discovery08Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery08Output(
        context: completed,
        hidden: hidden_drops_for_days(completed.calculation_day, completed.target_day),
      ))
  }
}
