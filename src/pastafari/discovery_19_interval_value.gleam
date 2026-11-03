// Stadio 23 / DISCOVERY 19: unu valoro en fermita entjera intervalo.
// Konservu la jam akceptitan Stage22-selektadon, neniam rekalkulu la saŭcon.
import pastafari/bootstrap
import pastafari/discovery_18_choose_rank

pub type Discovery19Error {
  InvalidContext(bootstrap.BootstrapError)
  InvalidBowlId
  InvalidInterval
  InvalidStream
}

pub type IntervalSelection {
  IntervalSelection(
    lower: Int,
    upper: Int,
    n: Int,
    selection: discovery_18_choose_rank.RankSelection,
    rank: Int,
    value: Int,
  )
}

pub type Discovery19Output {
  Discovery19Output(
    previous: discovery_18_choose_rank.Discovery18Output,
    lower: Int,
    upper: Int,
    n: Int,
    value: Int,
  )
}

fn map_error(
  error: discovery_18_choose_rank.Discovery18Error,
) -> Discovery19Error {
  case error {
    discovery_18_choose_rank.InvalidContext(reason) -> InvalidContext(reason)
    discovery_18_choose_rank.InvalidBowlId -> InvalidBowlId
    discovery_18_choose_rank.InvalidRankRange -> InvalidInterval
    discovery_18_choose_rank.InvalidStream -> InvalidStream
  }
}

fn rank_of(selection: discovery_18_choose_rank.RankSelection) -> Int {
  case selection {
    discovery_18_choose_rank.ShortRank(short) -> short.rank
    discovery_18_choose_rank.WideRank(wide) -> wide.rank
  }
}

pub fn select_interval(
  first: Int,
  step: Int,
  lower: Int,
  upper: Int,
) -> Result(IntervalSelection, Discovery19Error) {
  case lower > upper {
    True -> Error(InvalidInterval)
    False -> {
      let n = upper - lower + 1
      case discovery_18_choose_rank.select_rank(first, step, n) {
        Error(error) -> Error(map_error(error))
        Ok(selection) -> {
          let rank = rank_of(selection)
          Ok(IntervalSelection(
            lower: lower,
            upper: upper,
            n: n,
            selection: selection,
            rank: rank,
            value: lower + rank - 1,
          ))
        }
      }
    }
  }
}

pub fn value_for_days(
  calculation_day: Int,
  target_day: Int,
  queried_bowl_id: Int,
  seal: Int,
  lower: Int,
  upper: Int,
) -> Result(Int, Discovery19Error) {
  case
    dispatch_discovery_19(
      bootstrap.new_context(calculation_day, target_day),
      queried_bowl_id,
      seal,
      lower,
      upper,
    )
  {
    Ok(output) -> Ok(output.value)
    Error(error) -> Error(error)
  }
}

pub fn dispatch_discovery_19(
  context: bootstrap.MonsterContext,
  queried_bowl_id: Int,
  seal: Int,
  lower: Int,
  upper: Int,
) -> Result(Discovery19Output, Discovery19Error) {
  // n=0 petas la kanonan erarprioritaton: kunteksto > bovlo > intervalo.
  let n = case lower > upper {
    True -> 0
    False -> upper - lower + 1
  }
  case
    discovery_18_choose_rank.dispatch_discovery_18(
      context,
      queried_bowl_id,
      seal,
      n,
    )
  {
    Error(error) -> Error(map_error(error))
    Ok(previous) ->
      Ok(Discovery19Output(
        previous: previous,
        lower: lower,
        upper: upper,
        n: n,
        value: lower + previous.rank - 1,
      ))
  }
}
