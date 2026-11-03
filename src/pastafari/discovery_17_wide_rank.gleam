// Stadio 21 / DISCOVERY 17: senrifuzbukla larĝa ranga elekto.
// La kanona, intence malrapida orakolo restas nur en test/reference.
import pastafari/bootstrap
import pastafari/discovery_15_answer_at

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery17Error {
  InvalidContext(bootstrap.BootstrapError)
  InvalidBowlId
  InvalidRankRange
  InvalidStream
}

pub type WideSelection {
  WideSelection(
    digit_count: Int,
    space: Int,
    first_wide: Int,
    limit: Int,
    accepted_value: Int,
    rank: Int,
  )
}

pub type Discovery17Output {
  Discovery17Output(
    previous: discovery_15_answer_at.Discovery15Output,
    n: Int,
    digit_count: Int,
    space: Int,
    first_wide: Int,
    limit: Int,
    accepted_value: Int,
    rank: Int,
  )
}

fn regular_mod(value: Int, base: Int) -> Int {
  let remainder = value % base
  case remainder < 0 {
    True -> remainder + base
    False -> remainder
  }
}

// Nur entjera multiplikado: n > modulus garantias almenau du ciferojn.
fn covering_power(n: Int, count: Int, space: Int) -> #(Int, Int) {
  case space >= n {
    True -> #(count, space)
    False -> covering_power(n, count + 1, space * modulus)
  }
}

// La unua respondo estas la malplej signifa cifero.
// Konstruu la tutan valoron unufoje, neniam rekalkulu la saŭcon.
fn assemble_wide(
  first: Int,
  step: Int,
  index: Int,
  count: Int,
  weight: Int,
  acc: Int,
) -> Int {
  case index >= count {
    True -> acc
    False -> {
      let digit = regular_mod(first - 1 + step * index, modulus)
      assemble_wide(
        first,
        step,
        index + 1,
        count,
        weight * modulus,
        acc + digit * weight,
      )
    }
  }
}

pub fn select_wide_rank(
  first: Int,
  step: Int,
  n: Int,
) -> Result(WideSelection, Discovery17Error) {
  // Erara prioritato: n antaŭ fluovalideco, neniam modulo per nulo.
  case n <= modulus {
    True -> Error(InvalidRankRange)
    False ->
      case first < 1 || first > modulus || { step != 1 && step != -1 } {
        True -> Error(InvalidStream)
        False -> {
          let #(digit_count, space) = covering_power(n, 2, modulus * modulus)
          let first_wide = assemble_wide(first, step, 0, digit_count, 1, 1)
          let limit = { space / n } * n
          // Ĉiuj rifuzoj estas unu kontinua fina intervalo.
          let accepted_value = case first_wide <= limit, step {
            True, _ -> first_wide
            False, 1 -> 1
            False, -1 -> limit
            False, _ -> panic as "Jam validigita paŝo"
          }
          let rank = regular_mod(accepted_value - 1, n) + 1
          Ok(WideSelection(
            digit_count: digit_count,
            space: space,
            first_wide: first_wide,
            limit: limit,
            accepted_value: accepted_value,
            rank: rank,
          ))
        }
      }
  }
}

pub fn wide_rank_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
  seal: Int,
  n: Int,
) -> Result(Int, Discovery17Error) {
  case
    dispatch_discovery_17(
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

pub fn dispatch_discovery_17(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
  seal: Int,
  n: Int,
) -> Result(Discovery17Output, Discovery17Error) {
  // Stage19 validigas kuntekston antaŭ bovlo-ID, ekzakte unufoje.
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
        select_wide_rank(
          previous.previous.answer.first,
          previous.previous.answer.direction_step,
          n,
        )
      {
        Error(error) -> Error(error)
        Ok(selection) ->
          Ok(Discovery17Output(
            previous: previous,
            n: n,
            digit_count: selection.digit_count,
            space: selection.space,
            first_wide: selection.first_wide,
            limit: selection.limit,
            accepted_value: selection.accepted_value,
            rank: selection.rank,
          ))
      }
  }
}
