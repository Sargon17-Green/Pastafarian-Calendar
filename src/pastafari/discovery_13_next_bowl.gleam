// Stadio 17 / DISCOVERY 13: la sekva identigilo en la konservita 46-a ordo.
// La produktada serĉo estas sendependa de la testa referenca saŭco.
import gleam/list
import pastafari/bootstrap
import pastafari/discovery_12_post_stir

pub type Discovery13Error {
  InvalidBowlId
  InvalidContext(bootstrap.BootstrapError)
}

pub type Discovery13Output {
  Discovery13Output(
    context: bootstrap.MonsterContext,
    bowls: List(Int),
    order_at_drop_46: List(Int),
    queried_bowl_id: Int,
    next_bowl_id: Int,
  )
}

fn valid_id(id: Int) -> Bool {
  id >= 1 && id <= 6
}

// Promenu tra la historia ringo. La unua elemento estas la posteulo
// de la lasta; ĉi tiu serĉo ne rekalkulas la permutan rangon.
fn successor(order: List(Int), wanted: Int) -> Int {
  case order {
    [] -> panic as "Mankas la ordo de la 46-a guto"
    [first, ..rest] -> walk_ring(rest, first, first, wanted)
  }
}

fn walk_ring(
  remaining: List(Int),
  first: Int,
  previous: Int,
  wanted: Int,
) -> Int {
  case remaining {
    [] ->
      case previous == wanted {
        True -> first
        False -> panic as "Mankas la demandita bovlo en la ordo"
      }
    [current, ..rest] ->
      case previous == wanted {
        True -> current
        False -> walk_ring(rest, first, current, wanted)
      }
  }
}

pub fn next_bowl_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
) -> Result(Int, Discovery13Error) {
  case valid_id(queried_bowl_id) {
    False -> Error(InvalidBowlId)
    True -> {
      let #(_, order_at_drop_46) =
        discovery_12_post_stir.post_stir_for_days(
          calculation_day,
          target_day,
        )
      Ok(successor(order_at_drop_46, queried_bowl_id))
    }
  }
}

pub fn dispatch_discovery_13(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
) -> Result(Discovery13Output, Discovery13Error) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(InvalidContext(error))
    Ok(completed) ->
      case valid_id(queried_bowl_id) {
        False -> Error(InvalidBowlId)
        True -> {
          let #(bowls, order_at_drop_46) =
            discovery_12_post_stir.post_stir_for_days(
              completed.calculation_day,
              completed.target_day,
            )
          Ok(Discovery13Output(
            context: completed,
            bowls: bowls,
            order_at_drop_46: order_at_drop_46,
            queried_bowl_id: queried_bowl_id,
            next_bowl_id: successor(order_at_drop_46, queried_bowl_id),
          ))
        }
      }
  }
}
