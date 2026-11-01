// Stadio 19 / DISCOVERY 15: unu indeksita valoro de unu jam kreita respondfluo.
// La aparta kanona orakolo restas nur en test/reference.
import pastafari/bootstrap
import pastafari/discovery_14_ask_bowl

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery15Error {
  InvalidBowlId
  InvalidContext(bootstrap.BootstrapError)
}

pub type Discovery15Output {
  Discovery15Output(
    previous: discovery_14_ask_bowl.Discovery14Output,
    index: Int,
    value: Int,
  )
}

// Negativaj kaj multciklaj indeksoj estas validaj.
fn indexed_answer(first: Int, direction_step: Int, k: Int) -> Int {
  let remainder = { first - 1 + direction_step * k } % modulus
  case remainder < 0 {
    True -> remainder + modulus + 1
    False -> remainder + 1
  }
}

pub fn answer_at_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
  seal: Int,
  k: Int,
) -> Result(Int, Discovery15Error) {
  case
    dispatch_discovery_15(
      bootstrap.new_context(calculation_day, target_day),
      queried_bowl_id,
      seal,
      k,
    )
  {
    Ok(output) -> Ok(output.value)
    Error(error) -> Error(error)
  }
}

pub fn dispatch_discovery_15(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
  seal: Int,
  k: Int,
) -> Result(Discovery15Output, Discovery15Error) {
  case
    discovery_14_ask_bowl.dispatch_discovery_14(context, queried_bowl_id, seal)
  {
    Error(discovery_14_ask_bowl.InvalidBowlId) -> Error(InvalidBowlId)
    Error(discovery_14_ask_bowl.InvalidContext(error)) ->
      Error(InvalidContext(error))
    Ok(previous) ->
      Ok(Discovery15Output(
        previous: previous,
        index: k,
        value: indexed_answer(
          previous.answer.first,
          previous.answer.direction_step,
          k,
        ),
      ))
  }
}
