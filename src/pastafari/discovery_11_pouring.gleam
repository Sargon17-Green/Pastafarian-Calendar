// Stadio 15 / DISCOVERY 11: sinkronaj transiroj de ses bovloj per 46 gutoj.
// Ĉi tiu produktada efektivigo ne importas la testan referencan saŭcon.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_06_stones
import pastafari/discovery_07_bowls
import pastafari/discovery_09_visible
import pastafari/discovery_10_initial_bowls

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery11Output {
  Discovery11Output(
    context: bootstrap.MonsterContext,
    bowls: List(Int),
    order_at_drop_46: List(Int),
  )
}

fn save(value: Int) -> Int {
  let rem = { value - 1 } % modulus
  case rem < 0 {
    True -> rem + modulus + 1
    False -> rem + 1
  }
}

fn value_at(items: List(Int), index: Int) -> Int {
  case items {
    [] -> panic as "Mankas bovla valoro"
    [first, ..rest] ->
      case index == 1 {
        True -> first
        False -> value_at(rest, index - 1)
      }
  }
}

fn position_of(order: List(Int), wanted: Int, position: Int) -> Int {
  case order {
    [] -> panic as "Mankas bovla identigilo"
    [first, ..rest] ->
      case first == wanted {
        True -> position
        False -> position_of(rest, wanted, position + 1)
      }
  }
}

fn stone_field(stone: discovery_06_stones.Stone, position: Int) -> Int {
  case position {
    1 -> stone.wheat
    2 -> stone.barley
    3 -> stone.salt
    4 -> stone.bitter
    5 -> stone.red
    6 -> stone.wheat
    _ -> panic as "Nevalida pozicio"
  }
}

fn pour_at(position: Int, pours: #(Int, Int, Int)) -> Int {
  let #(first, second, third) = pours
  case position {
    1 -> first
    2 -> second
    3 -> third
    _ -> 0
  }
}

fn next_values(
  identifiers: List(Int),
  old: List(Int),
  order: List(Int),
  drop: Int,
  stone: discovery_06_stones.Stone,
  index: Int,
  pours: #(Int, Int, Int),
  reversed: List(Int),
) -> List(Int) {
  case identifiers {
    [] -> list.reverse(reversed)
    [identifier, ..remaining] -> {
      let position = position_of(order, identifier, 1)
      let prev_position = case position == 1 {
        True -> 6
        False -> position - 1
      }
      let next_position = case position == 6 {
        True -> 1
        False -> position + 1
      }
      let previous = value_at(old, value_at(order, prev_position))
      let following = value_at(old, value_at(order, next_position))
      let seed =
        value_at(old, identifier)
        + 2
        * previous
        + 3
        * following
        + pour_at(position, pours)
        + drop
        + stone_field(stone, position)
      let updated =
        save(seed * seed + 5 * previous * following + index * position)
      next_values(remaining, old, order, drop, stone, index, pours, [
        updated,
        ..reversed
      ])
    }
  }
}

fn pour_with_order(
  old: List(Int),
  drop: Int,
  stone: discovery_06_stones.Stone,
  index: Int,
  order: List(Int),
) -> List(Int) {
  let first_id = value_at(order, 1)
  let second_id = value_at(order, 2)
  let third_id = value_at(order, 3)
  let first =
    save(drop * drop + stone.wheat * value_at(old, first_id) + 3 * index)
  let second =
    save(drop * drop + stone.barley * value_at(old, second_id) + 5 * index)
  let third =
    save(drop * drop + stone.salt * value_at(old, third_id) + 7 * index)
  next_values(
    [1, 2, 3, 4, 5, 6],
    old,
    order,
    drop,
    stone,
    index,
    #(first, second, third),
    [],
  )
}

pub fn pour_single_drop(
  old: List(Int),
  drop: Int,
  stone: discovery_06_stones.Stone,
  index: Int,
) -> List(Int) {
  let order = discovery_07_bowls.bowl_order_from_drop(drop)
  pour_with_order(old, drop, stone, index, order)
}

fn run_drops(
  index: Int,
  drops: List(Int),
  stones: List(discovery_06_stones.Stone),
  bowls: List(Int),
  last_order: List(Int),
) -> #(List(Int), List(Int)) {
  case drops, stones {
    [], [] -> #(bowls, last_order)
    [drop, ..remaining_drops], [stone, ..remaining_stones] -> {
      let order = discovery_07_bowls.bowl_order_from_drop(drop)
      let next = pour_with_order(bowls, drop, stone, index, order)
      run_drops(
        index + 1,
        remaining_drops,
        remaining_stones,
        next,
        order,
      )
    }
    _, _ -> panic as "Malsama nombro de gutoj kaj ŝtonoj"
  }
}

pub fn pour_visible_drops_for_days(
  calculation_day: Int,
  target_day: Int,
) -> #(List(Int), List(Int)) {
  let initial =
    discovery_10_initial_bowls.initial_bowls_for_days(
      calculation_day,
      target_day,
    )
  let drops =
    discovery_09_visible.visible_drops_for_days(calculation_day, target_day)
  let stones = discovery_06_stones.build_stones()
  run_drops(1, drops, stones, initial, [])
}

pub fn dispatch_discovery_11(
  context: bootstrap.MonsterContext,
) -> Result(Discovery11Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) -> {
      let #(bowls, order) =
        pour_visible_drops_for_days(completed.calculation_day, completed.target_day)
      Ok(Discovery11Output(
        context: completed,
        bowls: bowls,
        order_at_drop_46: order,
      ))
    }
  }
}
