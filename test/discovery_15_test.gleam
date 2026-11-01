// Stadio 19: aparta orakolo nur en la testdosierujo.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_14_ask_bowl
import pastafari/discovery_15_answer_at
import reference/core
import reference/sauce

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

fn observed(
  a: Int,
  b: Int,
  id: Int,
  seal: Int,
  k: Int,
) -> Result(Int, discovery_15_answer_at.Discovery15Error) {
  discovery_15_answer_at.answer_at_for_days(a, b, id, seal, k)
}

fn oracle(a: Int, b: Int, id: Int, seal: Int, k: Int) -> Int {
  let stream = sauce.ask_bowl(sauce.sauce(a, b), id, seal)
  sauce.answer_at(stream, k)
}

fn assert_matches(a: Int, b: Int, id: Int, seal: Int, k: Int) {
  observed(a, b, id, seal, k) |> should.equal(Ok(oracle(a, b, id, seal, k)))
}

pub fn discovery_15_zero_index_matches_first_test() {
  let assert Ok(previous) =
    discovery_14_ask_bowl.ask_bowl_for_days(11, 21, 1, 0)
  observed(11, 21, 1, 0, 0) |> should.equal(Ok(previous.first))
  assert_matches(11, 21, 1, 0, 0)
}

pub fn discovery_15_positive_negative_one_oracle_test() {
  assert_matches(11, 21, 2, 0, 1)
  assert_matches(11, 21, 2, 0, -1)
  assert_matches(11, 21, 5, -2, 1)
  assert_matches(11, 21, 5, -2, -1)
}

pub fn discovery_15_all_six_bowl_ids_test() {
  let ids = [1, 2, 3, 4, 5, 6]
  let actual = list.map(ids, fn(id) { observed(11, 21, id, 7, 19) })
  let expected = list.map(ids, fn(id) { Ok(oracle(11, 21, id, 7, 19)) })
  actual |> should.equal(expected)
}

pub fn discovery_15_reverse_and_same_day_test() {
  assert_matches(11, 21, 1, 0, 29)
  assert_matches(21, 11, 1, 0, 29)
  assert_matches(0, 0, 1, 0, -29)
  assert_matches(-20, -20, 6, 9, 1)
}

pub fn discovery_15_foundation_crossing_test() {
  let f = core.foundation_day
  assert_matches(f - 1, f, 3, 0, 2)
  assert_matches(f, f + 1, 3, -1, -2)
  assert_matches(f + 1, f - 1, 2, 30, 3)
  assert_matches(f - 1, f + 1, 2, -30, -3)
}

pub fn discovery_15_zero_negative_and_positive_seals_test() {
  let seals = [0, 1, -1, 999, -999]
  let actual = list.map(seals, fn(seal) { observed(11, 21, 3, seal, 17) })
  let expected = list.map(seals, fn(seal) { Ok(oracle(11, 21, 3, seal, 17)) })
  actual |> should.equal(expected)
}

pub fn discovery_15_bigint_days_and_seals_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  assert_matches(huge, -huge, 1, huge, 3)
  assert_matches(-huge, huge, 6, -huge, -3)
  assert_matches(huge, huge, 3, -huge, huge)
}

pub fn discovery_15_modulus_periodicity_test() {
  let indices = [0, modulus, -modulus, 2 * modulus, -2 * modulus]
  let actual = list.map(indices, fn(k) { observed(11, 21, 4, 0, k) })
  let expected = list.map(indices, fn(k) { Ok(oracle(11, 21, 4, 0, k)) })
  actual |> should.equal(expected)
  let assert Ok(at_zero) = observed(11, 21, 4, 0, 0)
  list.map(actual, fn(result) { result == Ok(at_zero) })
  |> should.equal([True, True, True, True, True])
}

pub fn discovery_15_index_boundary_test() {
  let indices = [modulus - 1, modulus, modulus + 1, -modulus - 1]
  let actual = list.map(indices, fn(k) { observed(11, 21, 6, -1, k) })
  let expected = list.map(indices, fn(k) { Ok(oracle(11, 21, 6, -1, k)) })
  actual |> should.equal(expected)
}

pub fn discovery_15_interleaved_context_isolation_test() {
  let base_a = bootstrap.new_context(-11, 23)
  let a = bootstrap.MonsterContext(..base_a, diagnostics: ["UNUA"])
  let base_b = bootstrap.new_context(400, -900)
  let b = bootstrap.MonsterContext(..base_b, diagnostics: ["DUA"])
  let assert Ok(first) =
    discovery_15_answer_at.dispatch_discovery_15(a, 6, -7, -19)
  let assert Ok(second) =
    discovery_15_answer_at.dispatch_discovery_15(b, 1, 19, 1000)
  let assert Ok(again) =
    discovery_15_answer_at.dispatch_discovery_15(a, 6, -7, -19)
  first |> should.equal(again)
  first.previous.context.diagnostics |> should.equal(["UNUA"])
  second.previous.context.diagnostics |> should.equal(["DUA"])
  first.previous.context.status |> should.equal(bootstrap.Complete)
  second.previous.context.status |> should.equal(bootstrap.Complete)
  first.previous.seal |> should.equal(-7)
  second.previous.seal |> should.equal(19)
  first.index |> should.equal(-19)
  second.index |> should.equal(1000)
  first.value |> should.equal(oracle(-11, 23, 6, -7, -19))
  second.value |> should.equal(oracle(400, -900, 1, 19, 1000))
}

pub fn discovery_15_bounds_and_one_step_invariant_test() {
  let ks = [-modulus - 1, -1, 0, 1, modulus + 1]
  let checks =
    list.map(ks, fn(k) {
      let assert Ok(output) =
        discovery_15_answer_at.dispatch_discovery_15(
          bootstrap.new_context(11, 21),
          5,
          -100,
          k,
        )
      let assert Ok(next) = observed(11, 21, 5, -100, k + 1)
      let shifted =
        { output.value - 1 + output.previous.answer.direction_step } % modulus
      let expected_next = case shifted < 0 {
        True -> shifted + modulus + 1
        False -> shifted + 1
      }
      output.value >= 1 && output.value <= modulus && next == expected_next
    })
  checks |> should.equal([True, True, True, True, True])
}

pub fn discovery_15_invalid_id_and_context_priority_test() {
  let ids = [0, 7, -1]
  let actual = list.map(ids, fn(id) { observed(11, 21, id, 0, -modulus) })
  actual
  |> should.equal([
    Error(discovery_15_answer_at.InvalidBowlId),
    Error(discovery_15_answer_at.InvalidBowlId),
    Error(discovery_15_answer_at.InvalidBowlId),
  ])
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_15_answer_at.dispatch_discovery_15(retry, 0, 0, modulus)
  |> should.equal(
    Error(discovery_15_answer_at.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_15_answer_at.dispatch_discovery_15(recovery, 7, 0, -modulus)
  |> should.equal(
    Error(discovery_15_answer_at.InvalidContext(bootstrap.InvalidRecoveryDepth)),
  )
  let both =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_15_answer_at.dispatch_discovery_15(both, -1, 0, 0)
  |> should.equal(
    Error(discovery_15_answer_at.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
}
