// Stadio 16 / DISCOVERY 12: dek du sinkronaj postaj miksadoj.
// La ordo ĉe guto 46 estas aparte konservata; neniu testa orakolo en produktkodo.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_07_bowls
import pastafari/discovery_11_pouring

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery12Output {
  Discovery12Output(
    context: bootstrap.MonsterContext,
    bowls: List(Int),
    order_at_drop_46: List(Int),
  )
}

fn save(value: Int) -> Int {
  let remainder = { value - 1 } % modulus
  case remainder < 0 {
    True -> remainder + modulus + 1
    False -> remainder + 1
  }
}

fn value_at(values: List(Int), index: Int) -> Int {
  case values {
    [] -> panic as "Mankas bovla valoro"
    [first, ..rest] ->
      case index == 1 {
        True -> first
        False -> value_at(rest, index - 1)
      }
  }
}

fn find_position(order: List(Int), wanted: Int, index: Int) -> Int {
  case order {
    [] -> panic as "Mankas bovla identigilo"
    [first, ..rest] ->
      case first == wanted {
        True -> index
        False -> find_position(rest, wanted, index + 1)
      }
  }
}

fn stir_by_identifier(
  identifiers: List(Int),
  old: List(Int),
  order: List(Int),
  q: Int,
  stir: Int,
  reversed: List(Int),
) -> List(Int) {
  case identifiers {
    [] -> list.reverse(reversed)
    [identifier, ..remaining] -> {
      let position = find_position(order, identifier, 1)
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
      let s =
        value_at(old, identifier)
        + 3
        * previous
        + 5
        * following
        + q
        + stir
        + position
        * position
      let updated = save(s * s + 7 * previous * following)
      stir_by_identifier(remaining, old, order, q, stir, [updated, ..reversed])
    }
  }
}

// Publika unupaŝa sondo: kontrolu sinkronecon per konata ses-bovla sentinelo.
pub fn post_stir_once(old: List(Int), stir: Int) -> List(Int) {
  let sum = list.fold(old, 0, fn(acc, value) { acc + value })
  let q = save(sum + 149 * stir)
  let order = discovery_07_bowls.bowl_order_from_drop(q)
  stir_by_identifier([1, 2, 3, 4, 5, 6], old, order, q, stir, [])
}

fn apply_twelve(stir: Int, current: List(Int)) -> List(Int) {
  case stir > 12 {
    True -> current
    False -> apply_twelve(stir + 1, post_stir_once(current, stir))
  }
}

pub fn post_stir_for_days(
  calculation_day: Int,
  target_day: Int,
) -> #(List(Int), List(Int)) {
  let #(after_drops, order_at_drop_46) =
    discovery_11_pouring.pour_visible_drops_for_days(
      calculation_day,
      target_day,
    )
  #(apply_twelve(1, after_drops), order_at_drop_46)
}

pub fn dispatch_discovery_12(
  context: bootstrap.MonsterContext,
) -> Result(Discovery12Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) -> {
      let #(bowls, order_at_drop_46) =
        post_stir_for_days(completed.calculation_day, completed.target_day)
      Ok(Discovery12Output(
        context: completed,
        bowls: bowls,
        order_at_drop_46: order_at_drop_46,
      ))
    }
  }
}
