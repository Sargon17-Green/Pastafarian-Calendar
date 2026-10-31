// Stadio 13 / DISCOVERY 09: 46 videblaj gutoj el propra inversa akumulilo.
// La testa referenco ne estas importata en produktkodo.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_02_day_tag
import pastafari/discovery_03_distance
import pastafari/discovery_04_direction
import pastafari/discovery_06_stones
import pastafari/discovery_08_hidden

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery09Output {
  Discovery09Output(context: bootstrap.MonsterContext, visible: List(Int))
}

pub type Work {
  Work(action: Int, target: Int, distance: Int, connection: Int, direction: Int)
}

fn save(value: Int) -> Int {
  let rem = { value - 1 } % modulus
  case rem < 0 {
    True -> rem + modulus + 1
    False -> rem + 1
  }
}

fn select_at(items: List(Int), position: Int) -> Int {
  case items {
    [] -> panic as "Mankas atendita guto"
    [head, ..tail] ->
      case position == 1 {
        True -> head
        False -> select_at(tail, position - 1)
      }
  }
}

fn earlier(reversed: List(Int), hidden: List(Int), index: Int, back: Int) -> Int {
  case index > back {
    True -> select_at(reversed, back)
    False -> select_at(hidden, back - index + 1)
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

fn grind(
  coefficients: List(#(Int, Int, Int, Int, Int)),
  value: Int,
  p1: Int,
  p3: Int,
  p7: Int,
  stone: discovery_06_stones.Stone,
) -> Int {
  case coefficients {
    [] -> value
    [coefficient, ..rest] -> {
      let #(a, b, c, d, kind) = coefficient
      let next =
        save(
          value * value + a * value + b * p1 + c * p3 + d * p7
          + stone_field(stone, kind),
        )
      grind(rest, next, p1, p3, p7, stone)
    }
  }
}

fn eleven_grinds() -> List(#(Int, Int, Int, Int, Int)) {
  [
    #(3, 5, 7, 11, 1),
    #(5, 7, 11, 13, 2),
    #(7, 11, 13, 17, 3),
    #(11, 13, 17, 19, 4),
    #(13, 17, 19, 23, 5),
    #(17, 19, 23, 29, 1),
    #(19, 23, 29, 31, 2),
    #(23, 29, 31, 37, 3),
    #(29, 31, 37, 41, 4),
    #(31, 37, 41, 43, 5),
    #(37, 41, 43, 47, 1),
  ]
}

fn build_visible(
  index: Int,
  stones: List(discovery_06_stones.Stone),
  hidden: List(Int),
  work: Work,
  reversed: List(Int),
) -> List(Int) {
  case stones {
    [] -> list.reverse(reversed)
    [stone, ..rest] -> {
      let p1 = earlier(reversed, hidden, index, 1)
      let p3 = earlier(reversed, hidden, index, 3)
      let p7 = earlier(reversed, hidden, index, 7)
      let seed =
        save(
          stone.wheat * work.action + stone.barley * work.target
          + stone.salt * work.distance + stone.bitter * work.connection
          + stone.red * work.direction + p1 + 3 * p3 + 5 * p7 + index,
        )
      let value = grind(eleven_grinds(), seed, p1, p3, p7, stone)
      build_visible(index + 1, rest, hidden, work, [value, ..reversed])
    }
  }
}

pub fn visible_drops_for_days(
  calculation_day: Int,
  target_day: Int,
) -> List(Int) {
  let action = discovery_02_day_tag.day_tag_patch(calculation_day)
  let target = discovery_02_day_tag.day_tag_patch(target_day)
  let distance =
    discovery_03_distance.old_distance(calculation_day, target_day) + 1
  let direction =
    discovery_04_direction.direction_for_days(calculation_day, target_day)
  let work = Work(
    action: action,
    target: target,
    distance: distance,
    connection: action + target,
    direction: direction,
  )
  let hidden =
    discovery_08_hidden.hidden_drops_for_days(calculation_day, target_day)
  build_visible(1, discovery_06_stones.build_stones(), hidden, work, [])
}

pub fn dispatch_discovery_09(
  context: bootstrap.MonsterContext,
) -> Result(Discovery09Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery09Output(
        context: completed,
        visible: visible_drops_for_days(
          completed.calculation_day,
          completed.target_day,
        ),
      ))
  }
}
