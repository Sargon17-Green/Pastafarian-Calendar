// Stadio 22: precize 12 testfunkcioj, kun aparta limigita orakolo.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_15_answer_at
import pastafari/discovery_16_short_rank
import pastafari/discovery_17_wide_rank
import pastafari/discovery_18_choose_rank
import reference/core
import reference/sauce

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

fn actual(a: Int, b: Int, id: Int, seal: Int, n: Int) {
  discovery_18_choose_rank.choose_rank_for_days(a, b, id, seal, n)
}

fn select(first: Int, step: Int, n: Int) {
  discovery_18_choose_rank.select_rank(first, step, n)
}

fn power_cover(n: Int, k: Int, space: Int) -> #(Int, Int) {
  case space >= n {
    True -> #(k, space)
    False -> power_cover(n, k + 1, space * modulus)
  }
}

fn oracle_digits(
  stream: core.AnswerStream,
  j: Int,
  k: Int,
  weight: Int,
  acc: Int,
) -> Int {
  case j >= k {
    True -> acc
    False ->
      oracle_digits(
        stream,
        j + 1,
        k,
        weight * modulus,
        acc + { sauce.answer_at(stream, j) - 1 } * weight,
      )
  }
}

// Senbloka prekontrolo de la nombro de necesaj laŭvortaj rifuzoj.
// Ne alvoku la malrapidan orakolon se la nombro superas 8.
fn bounded_oracle(a: Int, b: Int, id: Int, seal: Int, n: Int) {
  let stream = sauce.ask_bowl(sauce.sauce(a, b), id, seal)
  let #(space, first_candidate) = case n <= modulus {
    True -> #(modulus, sauce.answer_at(stream, 0))
    False -> {
      let #(k, space) = power_cover(n, 2, modulus * modulus)
      #(space, oracle_digits(stream, 0, k, 1, 1))
    }
  }
  let limit = { space / n } * n
  let rejected = case first_candidate <= limit, stream.direction_step {
    True, _ -> 0
    False, 1 -> space - first_candidate + 1
    False, -1 -> first_candidate - limit
    False, _ -> panic as "Nevalida kanona fluo"
  }
  case rejected <= 8 {
    True ->
      actual(a, b, id, seal, n)
      |> should.equal(Ok(sauce.choose_rank(stream, n)))
    False -> {
      let assert Ok(rank) = actual(a, b, id, seal, n)
      { rank >= 1 && rank <= n } |> should.equal(True)
    }
  }
}

fn assert_subselection(first: Int, step: Int, n: Int) {
  case select(first, step, n) {
    Ok(discovery_18_choose_rank.ShortRank(selection)) -> {
      let assert Ok(short) =
        discovery_16_short_rank.select_short_rank(first, step, n)
      selection |> should.equal(short)
      { selection.rank >= 1 && selection.rank <= n } |> should.equal(True)
    }
    Ok(discovery_18_choose_rank.WideRank(selection)) -> {
      let assert Ok(wide) =
        discovery_17_wide_rank.select_wide_rank(first, step, n)
      selection |> should.equal(wide)
      { selection.rank >= 1 && selection.rank <= n } |> should.equal(True)
    }
    Error(_) -> False |> should.equal(True)
  }
}

pub fn discovery_18_basic_short_oracle_test() {
  bounded_oracle(11, 21, 1, 0, 7)
  let assert Ok(selection) = select(1, 1, 7)
  case selection {
    discovery_18_choose_rank.ShortRank(short) -> short.rank |> should.equal(1)
    _ -> False |> should.equal(True)
  }
}

pub fn discovery_18_basic_wide_oracle_test() {
  let n = modulus + 1
  bounded_oracle(11, 21, 1, 0, n)
  let assert Ok(selection) = select(1, -1, n)
  case selection {
    discovery_18_choose_rank.WideRank(wide) -> wide.rank |> should.equal(1)
    _ -> False |> should.equal(True)
  }
}

pub fn discovery_18_modulus_transition_test() {
  let first = modulus - 1
  let n = [modulus - 1, modulus, modulus + 1, modulus + 2]
  list.each(n, fn(size) { assert_subselection(first, 1, size) })
  let assert Ok(before) = select(first, 1, modulus)
  let assert Ok(after) = select(first, 1, modulus + 1)
  case before, after {
    discovery_18_choose_rank.ShortRank(_), discovery_18_choose_rank.WideRank(_)
    -> True |> should.equal(True)
    _, _ -> False |> should.equal(True)
  }
}

pub fn discovery_18_six_bowl_ids_both_modes_test() {
  list.each([1, 2, 3, 4, 5, 6], fn(id) {
    bounded_oracle(11, 21, id, 19, 3)
    bounded_oracle(11, 21, id, 19, modulus + 1)
  })
}

pub fn discovery_18_direction_and_foundation_test() {
  let f = core.foundation_day
  list.each([#(f - 1, f), #(f, f + 1), #(f + 1, f - 1), #(20, 20)], fn(pair) {
    let #(a, b) = pair
    bounded_oracle(a, b, 3, 0, 7)
    bounded_oracle(a, b, 3, 0, modulus + 1)
  })
}

pub fn discovery_18_seals_and_previous_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  list.each([0, 1, -1, huge, -huge], fn(seal) {
    bounded_oracle(11, 21, 3, seal, 7)
    bounded_oracle(11, 21, 3, seal, modulus + 1)
  })
  let assert Ok(output) =
    discovery_18_choose_rank.dispatch_discovery_18(
      bootstrap.new_context(11, 21),
      3,
      -huge,
      modulus + 1,
    )
  output.previous.previous.seal |> should.equal(-huge)
  output.previous.index |> should.equal(0)
}

pub fn discovery_18_huge_signed_days_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  let n = modulus * modulus + 1
  let a = actual(huge, -huge, 6, huge, n)
  let b = actual(-huge, huge, 1, -huge, 7)
  a |> should.equal(actual(huge, -huge, 6, huge, n))
  b |> should.equal(actual(-huge, huge, 1, -huge, 7))
  case a {
    Ok(rank) -> { rank >= 1 && rank <= n } |> should.equal(True)
    Error(_) -> False |> should.equal(True)
  }
  case b {
    Ok(rank) -> { rank >= 1 && rank <= 7 } |> should.equal(True)
    Error(_) -> False |> should.equal(True)
  }
}

pub fn discovery_18_synthetic_short_test() {
  let cases = [#(1, 1), #(1, -1), #(modulus - 1, 1), #(modulus, -1)]
  list.each(cases, fn(entry) {
    let #(first, step) = entry
    list.each([1, 3, modulus], fn(n) {
      assert_subselection(first, step, n)
      let stream = core.AnswerStream(first: first, direction_step: step)
      let assert Ok(selection) = select(first, step, n)
      case selection {
        discovery_18_choose_rank.ShortRank(short) ->
          short.rank |> should.equal(sauce.choose_rank(stream, n))
        _ -> False |> should.equal(True)
      }
    })
  })
}

pub fn discovery_18_synthetic_wide_powers_test() {
  let square = modulus * modulus
  let cases = [#(1, 1), #(1, -1), #(modulus - 1, 1), #(modulus, -1)]
  list.each(cases, fn(entry) {
    let #(first, step) = entry
    list.each([modulus + 1, square, square + 1], fn(n) {
      assert_subselection(first, step, n)
      let assert Ok(choice) = select(first, step, n)
      case choice {
        discovery_18_choose_rank.WideRank(wide) -> {
          let #(k, s) = power_cover(n, 2, square)
          wide.digit_count |> should.equal(k)
          wide.space |> should.equal(s)
          wide.limit |> should.equal({ s / n } * n)
        }
        _ -> False |> should.equal(True)
      }
    })
  })
}

pub fn discovery_18_long_rejections_without_oracle_test() {
  let half_short = { modulus / 2 } + 1
  let half_wide = { modulus * modulus / 2 } + 1
  let assert Ok(forward_short) = select(modulus, 1, half_short)
  let assert Ok(reverse_short) = select(modulus, -1, half_short)
  let assert Ok(forward_wide) = select(modulus - 1, 1, half_wide)
  let assert Ok(reverse_wide) = select(1, -1, half_wide)
  case forward_short, reverse_short {
    discovery_18_choose_rank.ShortRank(forward),
    discovery_18_choose_rank.ShortRank(reverse)
    -> {
      forward.accepted_value |> should.equal(1)
      reverse.accepted_value |> should.equal(half_short)
    }
    _, _ -> False |> should.equal(True)
  }
  case forward_wide, reverse_wide {
    discovery_18_choose_rank.WideRank(forward),
    discovery_18_choose_rank.WideRank(reverse)
    -> {
      forward.accepted_value |> should.equal(1)
      reverse.accepted_value |> should.equal(half_wide)
    }
    _, _ -> False |> should.equal(True)
  }
}

pub fn discovery_18_stage19_and_context_isolation_test() {
  let n = modulus + 1
  let base_a = bootstrap.new_context(-11, 23)
  let a = bootstrap.MonsterContext(..base_a, diagnostics: ["UNUA"])
  let base_b = bootstrap.new_context(400, -900)
  let b = bootstrap.MonsterContext(..base_b, diagnostics: ["DUA"])
  let assert Ok(first) =
    discovery_18_choose_rank.dispatch_discovery_18(a, 6, -7, n)
  let assert Ok(second) =
    discovery_18_choose_rank.dispatch_discovery_18(b, 1, 19, 7)
  let assert Ok(again) =
    discovery_18_choose_rank.dispatch_discovery_18(a, 6, -7, n)
  first |> should.equal(again)
  let assert Ok(old) = discovery_15_answer_at.dispatch_discovery_15(a, 6, -7, 0)
  first.previous |> should.equal(old)
  first.previous.index |> should.equal(0)
  second.previous.index |> should.equal(0)
  first.previous.previous.context.diagnostics |> should.equal(["UNUA"])
  second.previous.previous.context.diagnostics |> should.equal(["DUA"])
  assert_subselection(
    first.previous.previous.answer.first,
    first.previous.previous.answer.direction_step,
    n,
  )
}

pub fn discovery_18_invalid_inputs_and_priority_test() {
  list.each([0, -1], fn(n) {
    select(0, 0, n)
    |> should.equal(Error(discovery_18_choose_rank.InvalidRankRange))
  })
  let n = modulus + 1
  list.each([0, modulus + 1], fn(first) {
    select(first, 1, n)
    |> should.equal(Error(discovery_18_choose_rank.InvalidStream))
  })
  list.each([0, 2], fn(step) {
    select(1, step, 3)
    |> should.equal(Error(discovery_18_choose_rank.InvalidStream))
  })
  list.each([0, 7, -1], fn(id) {
    actual(11, 21, id, 0, 0)
    |> should.equal(Error(discovery_18_choose_rank.InvalidBowlId))
  })
  actual(11, 21, 1, 0, 0)
  |> should.equal(Error(discovery_18_choose_rank.InvalidRankRange))
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_18_choose_rank.dispatch_discovery_18(retry, 0, 0, 0)
  |> should.equal(
    Error(discovery_18_choose_rank.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_18_choose_rank.dispatch_discovery_18(recovery, 7, 0, -1)
  |> should.equal(
    Error(discovery_18_choose_rank.InvalidContext(
      bootstrap.InvalidRecoveryDepth,
    ))
  )
}
