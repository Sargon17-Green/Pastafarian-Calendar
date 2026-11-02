// Stadio 20 / DISCOVERY 16: mallonga ranga elekto el unu jam konata fluo.
// La produktada elekto estas senbukla; la kanona orakolo restas nur en testoj.
import pastafari/bootstrap
import pastafari/discovery_15_answer_at

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery16Error {
  InvalidContext(bootstrap.BootstrapError)
  InvalidBowlId
  InvalidRankRange
  InvalidStream
}

pub type ShortSelection {
  ShortSelection(limit: Int, accepted_value: Int, rank: Int)
}

pub type Discovery16Output {
  Discovery16Output(
    previous: discovery_15_answer_at.Discovery15Output,
    n: Int,
    limit: Int,
    accepted_value: Int,
    rank: Int,
  )
}

// Ĉiuj modulaj operacioj okazas nur post la pozitiva n-validigo.
pub fn select_short_rank(
  first: Int,
  step: Int,
  n: Int,
) -> Result(ShortSelection, Discovery16Error) {
  case n < 1 || n > modulus {
    True -> Error(InvalidRankRange)
    False ->
      case first < 1 || first > modulus || { step != 1 && step != -1 } {
        True -> Error(InvalidStream)
        False -> {
          let limit = { modulus / n } * n
          let accepted_value = case first <= limit, step {
            True, _ -> first
            False, 1 -> 1
            False, -1 -> limit
            False, _ -> panic as "Jam validigita paŝo"
          }
          let rank = { accepted_value - 1 } % n + 1
          Ok(ShortSelection(
            limit: limit,
            accepted_value: accepted_value,
            rank: rank,
          ))
        }
      }
  }
}

pub fn short_rank_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
  seal: Int,
  n: Int,
) -> Result(Int, Discovery16Error) {
  case
    dispatch_discovery_16(
      bootstrap.new_context(calculation_day, target_day),
      queried_bowl_id,
      seal,
      n,
    )
  {
    Ok(output) -> Ok(output.rank)
    Error(error) -> Error(error)
  }
}

pub fn dispatch_discovery_16(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
  seal: Int,
  n: Int,
) -> Result(Discovery16Output, Discovery16Error) {
  // La delegita Stage19-dispatĉo kontrolas kuntekston antaŭ bovlo-ID.
  // Ĝuste unu voko: nek ripetu la 46 gutojn nek la 12 postmiksadojn.
  case
    discovery_15_answer_at.dispatch_discovery_15(
      context,
      queried_bowl_id,
      seal,
      0,
    )
  {
    Error(discovery_15_answer_at.InvalidContext(error)) ->
      Error(InvalidContext(error))
    Error(discovery_15_answer_at.InvalidBowlId) -> Error(InvalidBowlId)
    Ok(previous) ->
      case
        select_short_rank(
          previous.previous.answer.first,
          previous.previous.answer.direction_step,
          n,
        )
      {
        Error(error) -> Error(error)
        Ok(selection) ->
          Ok(Discovery16Output(
            previous: previous,
            n: n,
            limit: selection.limit,
            accepted_value: selection.accepted_value,
            rank: selection.rank,
          ))
      }
  }
}
