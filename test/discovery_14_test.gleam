// Stadio 18: aparta valida-domajna orakolo; neniam importita en produktadon.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_13_next_bowl
import pastafari/discovery_14_ask_bowl
import reference/core
import reference/sauce

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

fn observed(
  a: Int,
  b: Int,
  id: Int,
  seal: Int,
) -> Result(
  discovery_14_ask_bowl.Discovery14Answer,
  discovery_14_ask_bowl.Discovery14Error,
) {
  discovery_14_ask_bowl.ask_bowl_for_days(a, b, id, seal)
}

fn oracle(
  a: Int,
  b: Int,
  id: Int,
  seal: Int,
) -> discovery_14_ask_bowl.Discovery14Answer {
  let answer = sauce.ask_bowl(sauce.sauce(a, b), id, seal)
  discovery_14_ask_bowl.Discovery14Answer(
    first: answer.first,
    direction_step: answer.direction_step,
  )
}

fn assert_matches(a: Int, b: Int, id: Int, seal: Int) {
  observed(a, b, id, seal) |> should.equal(Ok(oracle(a, b, id, seal)))
}

pub fn discovery_14_first_answer_oracle_test() {
  assert_matches(11, 21, 1, 0)
}

pub fn discovery_14_six_identifiers_oracle_test() {
  let ids = [1, 2, 3, 4, 5, 6]
  let actual = list.map(ids, fn(id) { observed(11, 21, id, 0) })
  let expected = list.map(ids, fn(id) { Ok(oracle(11, 21, id, 0)) })
  actual |> should.equal(expected)
}

pub fn discovery_14_forward_and_reverse_test() {
  assert_matches(11, 21, 1, 0)
  assert_matches(11, 21, 6, 5)
  assert_matches(21, 11, 1, 0)
  assert_matches(21, 11, 6, -5)
}

pub fn discovery_14_same_day_and_foundation_test() {
  let f = core.foundation_day
  assert_matches(0, 0, 1, 0)
  assert_matches(0, 0, 6, 1)
  assert_matches(f, f, 1, 0)
  assert_matches(f, f, 6, -1)
}

pub fn discovery_14_foundation_crossing_test() {
  let f = core.foundation_day
  assert_matches(f - 1, f + 1, 1, 0)
  assert_matches(f - 1, f + 1, 6, 21)
  assert_matches(f + 1, f - 1, 1, -21)
  assert_matches(f + 1, f - 1, 6, 0)
}

pub fn discovery_14_bigint_days_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  assert_matches(huge, -huge, 1, 0)
  assert_matches(huge, -huge, 6, 1)
  assert_matches(-huge, huge, 1, -1)
  assert_matches(-huge, huge, 6, huge)
}

pub fn discovery_14_positive_negative_zero_seals_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  let seals = [0, 1, -1, huge, -huge]
  let actual = list.map(seals, fn(seal) { observed(11, 21, 3, seal) })
  let expected = list.map(seals, fn(seal) { Ok(oracle(11, 21, 3, seal)) })
  actual |> should.equal(expected)
}

pub fn discovery_14_result_bounds_test() {
  let seals = [0, 1, -1, 999, -999]
  let actual = list.map(seals, fn(seal) {
    let assert Ok(answer) = observed(11, 21, 5, seal)
    answer.first >= 1
    && answer.first <= modulus
    && { answer.direction_step == 1 || answer.direction_step == -1 }
  })
  actual |> should.equal([True, True, True, True, True])
}

pub fn discovery_14_direction_parity_test() {
  let seal = -1_000_000_000_000_000_000_000_000_000_000
  let assert Ok(output) = discovery_14_ask_bowl.dispatch_discovery_14(
    bootstrap.new_context(11, 21),
    2,
    seal,
  )
  let first = output.answer.first
  let b6 = sauce.sauce(11, 21).bowls |> list.drop(5) |> list.first
  let assert Ok(last_bowl) = b6
  let seed = first + seal + 194
  let value = seed * seed + 193 * first + 197 * last_bowl
  let remainder = { value - 1 } % modulus
  let saved = case remainder < 0 {
    True -> remainder + modulus + 1
    False -> remainder + 1
  }
  let expected_step = case saved % 2 == 1 {
    True -> 1
    False -> -1
  }
  output.answer.direction_step |> should.equal(expected_step)
  assert_matches(11, 21, 2, seal)
}

pub fn discovery_14_preserves_stage_17_diagnostics_test() {
  let context = bootstrap.new_context(11, 21)
  let assert Ok(previous) =
    discovery_13_next_bowl.dispatch_discovery_13(context, 3)
  let assert Ok(output) =
    discovery_14_ask_bowl.dispatch_discovery_14(context, 3, -50)
  output.context |> should.equal(previous.context)
  output.bowls |> should.equal(previous.bowls)
  output.order_at_drop_46 |> should.equal(previous.order_at_drop_46)
  output.queried_bowl_id |> should.equal(previous.queried_bowl_id)
  output.next_bowl_id |> should.equal(previous.next_bowl_id)
  output.seal |> should.equal(-50)
  output.answer |> should.equal(oracle(11, 21, 3, -50))
}

pub fn discovery_14_interleaved_contexts_test() {
  let base_a = bootstrap.new_context(-11, 23)
  let a = bootstrap.MonsterContext(..base_a, diagnostics: ["UNUA"])
  let base_b = bootstrap.new_context(400, -900)
  let b = bootstrap.MonsterContext(..base_b, diagnostics: ["DUA"])
  let assert Ok(first) = discovery_14_ask_bowl.dispatch_discovery_14(a, 6, -7)
  let assert Ok(second) = discovery_14_ask_bowl.dispatch_discovery_14(b, 1, 19)
  let assert Ok(again) = discovery_14_ask_bowl.dispatch_discovery_14(a, 6, -7)
  first |> should.equal(again)
  first.context.diagnostics |> should.equal(["UNUA"])
  second.context.diagnostics |> should.equal(["DUA"])
  first.context.status |> should.equal(bootstrap.Complete)
  second.context.status |> should.equal(bootstrap.Complete)
  first.seal |> should.equal(-7)
  second.seal |> should.equal(19)
  first.answer |> should.equal(oracle(-11, 23, 6, -7))
  second.answer |> should.equal(oracle(400, -900, 1, 19))
  first.bowls |> should.equal(sauce.sauce(-11, 23).bowls)
  second.bowls |> should.equal(sauce.sauce(400, -900).bowls)
}

pub fn discovery_14_invalid_ids_and_context_priority_test() {
  let invalid_ids = [0, 7, -1]
  let actual = list.map(invalid_ids, fn(id) { observed(11, 21, id, 0) })
  actual
  |> should.equal([
    Error(discovery_14_ask_bowl.InvalidBowlId),
    Error(discovery_14_ask_bowl.InvalidBowlId),
    Error(discovery_14_ask_bowl.InvalidBowlId),
  ])
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_14_ask_bowl.dispatch_discovery_14(retry, 0, 0)
  |> should.equal(
    Error(discovery_14_ask_bowl.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_14_ask_bowl.dispatch_discovery_14(recovery, 7, 0)
  |> should.equal(
    Error(discovery_14_ask_bowl.InvalidContext(bootstrap.InvalidRecoveryDepth)),
  )
  let both =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_14_ask_bowl.dispatch_discovery_14(both, -1, 0)
  |> should.equal(
    Error(discovery_14_ask_bowl.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  discovery_14_ask_bowl.dispatch_discovery_14(base, 0, 0)
  |> should.equal(Error(discovery_14_ask_bowl.InvalidBowlId))
}
