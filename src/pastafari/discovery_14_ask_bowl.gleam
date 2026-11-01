// Stadio 18 / DISCOVERY 14: la unua respondo kaj direkto por unu bovlo.
// Reuzas la Stage17-diagnozon; la aparta referenca orakolo restas nur en testoj.
import pastafari/bootstrap
import pastafari/discovery_13_next_bowl

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery14Answer {
  Discovery14Answer(first: Int, direction_step: Int)
}

pub type Discovery14Error {
  InvalidBowlId
  InvalidContext(bootstrap.BootstrapError)
}

pub type Discovery14Output {
  Discovery14Output(
    context: bootstrap.MonsterContext,
    bowls: List(Int),
    order_at_drop_46: List(Int),
    queried_bowl_id: Int,
    next_bowl_id: Int,
    seal: Int,
    answer: Discovery14Answer,
  )
}

fn save(value: Int) -> Int {
  let remainder = { value - 1 } % modulus
  case remainder < 0 {
    True -> remainder + modulus + 1
    False -> remainder + 1
  }
}

// La ses valoroj restas en ordo de bovlaj IDoj, ne en guta ordo.
fn bowl_at(bowls: List(Int), id: Int) -> Int {
  case bowls {
    [] -> panic as "Mankas bovla valoro"
    [first, ..rest] ->
      case id == 1 {
        True -> first
        False -> bowl_at(rest, id - 1)
      }
  }
}

fn compute_answer(
  bowls: List(Int),
  id: Int,
  next_id: Int,
  seal: Int,
) -> Discovery14Answer {
  let seed = bowl_at(bowls, id) + seal + 181
  let first = save(seed * seed + 179 * bowl_at(bowls, next_id) + seal)
  let direction_seed = first + seal + 194
  let direction_number =
    save(
      direction_seed * direction_seed + 193 * first + 197 * bowl_at(bowls, 6),
    )
  let direction_step = case direction_number % 2 == 1 {
    True -> 1
    False -> -1
  }
  Discovery14Answer(first: first, direction_step: direction_step)
}

pub fn ask_bowl_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
  seal: Int,
) -> Result(Discovery14Answer, Discovery14Error) {
  case
    dispatch_discovery_14(
      bootstrap.new_context(calculation_day, target_day),
      queried_bowl_id,
      seal,
    )
  {
    Ok(output) -> Ok(output.answer)
    Error(error) -> Error(error)
  }
}

pub fn dispatch_discovery_14(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
  seal: Int,
) -> Result(Discovery14Output, Discovery14Error) {
  case discovery_13_next_bowl.dispatch_discovery_13(context, queried_bowl_id) {
    Error(discovery_13_next_bowl.InvalidBowlId) -> Error(InvalidBowlId)
    Error(discovery_13_next_bowl.InvalidContext(error)) ->
      Error(InvalidContext(error))
    Ok(previous) ->
      Ok(Discovery14Output(
        context: previous.context,
        bowls: previous.bowls,
        order_at_drop_46: previous.order_at_drop_46,
        queried_bowl_id: previous.queried_bowl_id,
        next_bowl_id: previous.next_bowl_id,
        seal: seal,
        answer: compute_answer(
          previous.bowls,
          previous.queried_bowl_id,
          previous.next_bowl_id,
          seal,
        ),
      ))
  }
}
