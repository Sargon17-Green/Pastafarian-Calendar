// Stadio 22 / DISCOVERY 18: unuigita, senrifuzbukla ranga elekto.
// Ne importu la apartan kanonan orakolon el test/reference.
import pastafari/bootstrap
import pastafari/discovery_15_answer_at
import pastafari/discovery_16_short_rank
import pastafari/discovery_17_wide_rank

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery18Error {
  InvalidContext(bootstrap.BootstrapError)
  InvalidBowlId
  InvalidRankRange
  InvalidStream
}

pub type RankSelection {
  ShortRank(selection: discovery_16_short_rank.ShortSelection)
  WideRank(selection: discovery_17_wide_rank.WideSelection)
}

pub type Discovery18Output {
  Discovery18Output(
    previous: discovery_15_answer_at.Discovery15Output,
    n: Int,
    selection: RankSelection,
    rank: Int,
  )
}

fn selection_rank(selection: RankSelection) -> Int {
  case selection {
    ShortRank(short) -> short.rank
    WideRank(wide) -> wide.rank
  }
}

// La unua kontrolo estas n > 0. Ĉiu subelektilo ricevas sian propran domajnon.
pub fn select_rank(
  first: Int,
  step: Int,
  n: Int,
) -> Result(RankSelection, Discovery18Error) {
  case n <= 0 {
    True -> Error(InvalidRankRange)
    False ->
      case n <= modulus {
        True ->
          case discovery_16_short_rank.select_short_rank(first, step, n) {
            Ok(short) -> Ok(ShortRank(selection: short))
            Error(discovery_16_short_rank.InvalidRankRange) ->
              Error(InvalidRankRange)
            Error(discovery_16_short_rank.InvalidStream) -> Error(InvalidStream)
            Error(discovery_16_short_rank.InvalidBowlId) -> Error(InvalidBowlId)
            Error(discovery_16_short_rank.InvalidContext(error)) ->
              Error(InvalidContext(error))
          }
        False ->
          case discovery_17_wide_rank.select_wide_rank(first, step, n) {
            Ok(wide) -> Ok(WideRank(selection: wide))
            Error(discovery_17_wide_rank.InvalidRankRange) ->
              Error(InvalidRankRange)
            Error(discovery_17_wide_rank.InvalidStream) -> Error(InvalidStream)
            Error(discovery_17_wide_rank.InvalidBowlId) -> Error(InvalidBowlId)
            Error(discovery_17_wide_rank.InvalidContext(error)) ->
              Error(InvalidContext(error))
          }
      }
  }
}

pub fn choose_rank_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
  seal: Int,
  n: Int,
) -> Result(Int, Discovery18Error) {
  case
    dispatch_discovery_18(
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

pub fn dispatch_discovery_18(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
  seal: Int,
  n: Int,
) -> Result(Discovery18Output, Discovery18Error) {
  // Ekzakte unu Stage19-dissendo, sen duobla produktado de saŭco.
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
        select_rank(
          previous.previous.answer.first,
          previous.previous.answer.direction_step,
          n,
        )
      {
        Error(error) -> Error(error)
        Ok(selection) ->
          Ok(Discovery18Output(
            previous: previous,
            n: n,
            selection: selection,
            rank: selection_rank(selection),
          ))
      }
  }
}
