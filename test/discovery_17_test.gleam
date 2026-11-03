// Stadio 21: ekzakte 12 testoj. La malrapida orakolo restas en test/reference.
// Neniam vokas rifuzbuklan orakolon kiam sendepende kalkulita distanco > 8.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_15_answer_at
import pastafari/discovery_17_wide_rank
import reference/core
import reference/sauce

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

fn actual(a: Int, b: Int, id: Int, seal: Int, n: Int) {
  discovery_17_wide_rank.wide_rank_for_days(a, b, id, seal, n)
}

fn select(first: Int, step: Int, n: Int) {
  discovery_17_wide_rank.select_wide_rank(first, step, n)
}

fn invariants(first: Int, step: Int, n: Int) -> Bool {
  case select(first, step, n) {
    Error(_) -> False
    Ok(value) ->
      value.digit_count >= 2
      && value.space >= n
      && value.first_wide >= 1
      && value.first_wide <= value.space
      && value.limit >= n
      && value.limit <= value.space
      && value.accepted_value >= 1
      && value.accepted_value <= value.limit
      && value.rank >= 1
      && value.rank <= n
      && value.rank == { value.accepted_value - 1 } % n + 1
  }
}

// Nur du-cifera kazo. Konstruas W el APARTA orakola fluo,
// ne el la produktada unua larĝa valoro; maksimumo 8 rifuzoj.
fn assert_bounded_oracle(a: Int, b: Int, id: Int, seal: Int, n: Int) {
  let stream = sauce.ask_bowl(sauce.sauce(a, b), id, seal)
  let space = modulus * modulus
  let first_wide =
    1
    + { sauce.answer_at(stream, 0) - 1 }
    + { sauce.answer_at(stream, 1) - 1 }
    * modulus
  let limit = { space / n } * n
  let distance = case first_wide <= limit, stream.direction_step {
    True, _ -> 0
    False, 1 -> space - first_wide + 1
    False, -1 -> first_wide - limit
    False, _ -> panic as "Nevalida kanona fluo"
  }
  case distance <= 8 {
    True ->
      actual(a, b, id, seal, n)
      |> should.equal(Ok(sauce.choose_rank_wide(stream, n)))
    False -> {
      let assert Ok(output) =
        discovery_17_wide_rank.dispatch_discovery_17(
          bootstrap.new_context(a, b),
          id,
          seal,
          n,
        )
      output.rank >= 1 && output.rank <= n |> should.equal(True)
      output.first_wide |> should.equal(first_wide)
    }
  }
}

pub fn discovery_17_basic_wide_oracle_test() {
  let n = modulus + 1
  assert_bounded_oracle(11, 21, 1, 0, n)
  let assert Ok(result) =
    discovery_17_wide_rank.dispatch_discovery_17(
      bootstrap.new_context(11, 21),
      1,
      0,
      n,
    )
  result.previous.index |> should.equal(0)
  result.previous.value |> should.equal(result.previous.previous.answer.first)
  invariants(
    result.previous.previous.answer.first,
    result.previous.previous.answer.direction_step,
    n,
  )
  |> should.equal(True)
}

pub fn discovery_17_six_bowls_oracle_test() {
  let n = modulus + 1
  list.each([1, 2, 3, 4, 5, 6], fn(id) {
    assert_bounded_oracle(11, 21, id, 17, n)
  })
}

pub fn discovery_17_directions_same_day_test() {
  let n = modulus + 3
  assert_bounded_oracle(11, 21, 2, 0, n)
  assert_bounded_oracle(21, 11, 3, -7, n)
  assert_bounded_oracle(0, 0, 4, 7, n)
  assert_bounded_oracle(-20, -20, 6, 9, n)
}

pub fn discovery_17_foundation_boundaries_test() {
  let f = core.foundation_day
  let n = modulus + 1
  assert_bounded_oracle(f - 1, f, 3, 0, n)
  assert_bounded_oracle(f, f + 1, 3, -1, n)
  assert_bounded_oracle(f + 1, f - 1, 2, 30, n)
  assert_bounded_oracle(f - 1, f + 1, 2, -30, n)
}

pub fn discovery_17_seal_boundaries_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  let n = modulus + 1
  list.each([0, 1, -1, huge, -huge], fn(seal) {
    assert_bounded_oracle(11, 21, 3, seal, n)
  })
  let assert Ok(output) =
    discovery_17_wide_rank.dispatch_discovery_17(
      bootstrap.new_context(11, 21),
      3,
      -huge,
      n,
    )
  output.previous.previous.seal |> should.equal(-huge)
}

pub fn discovery_17_huge_days_determinism_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  let n = modulus * modulus + 1
  let values = [
    actual(huge, -huge, 1, huge, n),
    actual(-huge, huge, 6, -huge, n),
    actual(huge, huge, 3, -huge, n),
  ]
  values
  |> should.equal([
    actual(huge, -huge, 1, huge, n),
    actual(-huge, huge, 6, -huge, n),
    actual(huge, huge, 3, -huge, n),
  ])
  list.each(values, fn(value) {
    case value {
      Ok(rank) -> rank >= 1 && rank <= n |> should.equal(True)
      Error(_) -> False |> should.equal(True)
    }
  })
}

pub fn discovery_17_synthetic_first_values_test() {
  let n = modulus + 1
  let cases = [
    #(1, 1),
    #(1, -1),
    #(modulus - 1, 1),
    #(modulus - 1, -1),
    #(modulus, 1),
    #(modulus, -1),
  ]
  list.each(cases, fn(entry) {
    let #(first, step) = entry
    let stream = core.AnswerStream(first: first, direction_step: step)
    let expected = sauce.choose_rank_wide(stream, n)
    let assert Ok(found) = select(first, step, n)
    found.rank |> should.equal(expected)
    invariants(first, step, n) |> should.equal(True)
  })
}

pub fn discovery_17_power_limits_test() {
  let square = modulus * modulus
  let cube = square * modulus
  let assert Ok(at_square) = select(1, 1, square)
  at_square.digit_count |> should.equal(2)
  at_square.space |> should.equal(square)
  at_square.limit |> should.equal(square)
  let assert Ok(after_square) = select(1, 1, square + 1)
  after_square.digit_count |> should.equal(3)
  after_square.space |> should.equal(cube)
  let assert Ok(at_cube) = select(modulus, -1, cube)
  at_cube.digit_count |> should.equal(3)
  at_cube.space |> should.equal(cube)
  at_cube.limit |> should.equal(cube)
  invariants(modulus, -1, cube) |> should.equal(True)
}

pub fn discovery_17_digit_order_and_power_transitions_test() {
  let square = modulus * modulus
  let fourth = square * square
  let cases = [#(1, 1), #(1, -1), #(modulus, 1), #(modulus, -1)]
  list.each(cases, fn(entry) {
    let #(first, step) = entry
    let stream = core.AnswerStream(first: first, direction_step: step)
    let assert Ok(found) = select(first, step, square)
    let low = sauce.answer_at(stream, 0) - 1
    let high = sauce.answer_at(stream, 1) - 1
    found.first_wide |> should.equal(1 + low + high * modulus)
    found.rank |> should.equal(sauce.choose_rank_wide(stream, square))
    let assert Ok(after) = select(first, step, square + 1)
    after.digit_count |> should.equal(3)
    let assert Ok(at_fourth) = select(first, step, fourth)
    at_fourth.digit_count |> should.equal(4)
    let assert Ok(after_fourth) = select(first, step, fourth + 1)
    after_fourth.digit_count |> should.equal(5)
    invariants(first, step, fourth + 1) |> should.equal(True)
  })
}

pub fn discovery_17_long_rejection_without_oracle_test() {
  let square = modulus * modulus
  let n = { square / 2 } + 1
  let assert Ok(forward) = select(modulus - 1, 1, n)
  let assert Ok(backward) = select(1, -1, n)
  forward.limit |> should.equal(n)
  backward.limit |> should.equal(n)
  forward.first_wide > n |> should.equal(True)
  backward.first_wide > n |> should.equal(True)
  forward.accepted_value |> should.equal(1)
  backward.accepted_value |> should.equal(n)
  forward.rank |> should.equal(1)
  backward.rank |> should.equal(n)
  invariants(modulus - 1, 1, n) |> should.equal(True)
  invariants(1, -1, n) |> should.equal(True)
}

pub fn discovery_17_preserves_stage19_and_context_test() {
  let n = modulus + 1
  let base_a = bootstrap.new_context(-11, 23)
  let a = bootstrap.MonsterContext(..base_a, diagnostics: ["UNUA"])
  let base_b = bootstrap.new_context(400, -900)
  let b = bootstrap.MonsterContext(..base_b, diagnostics: ["DUA"])
  let assert Ok(first) =
    discovery_17_wide_rank.dispatch_discovery_17(a, 6, -7, n)
  let assert Ok(second) =
    discovery_17_wide_rank.dispatch_discovery_17(b, 1, 19, n)
  let assert Ok(again) =
    discovery_17_wide_rank.dispatch_discovery_17(a, 6, -7, n)
  first |> should.equal(again)
  first.previous.index |> should.equal(0)
  second.previous.index |> should.equal(0)
  first.previous.previous.context.diagnostics |> should.equal(["UNUA"])
  second.previous.previous.context.diagnostics |> should.equal(["DUA"])
  first.previous.previous.seal |> should.equal(-7)
  second.previous.previous.seal |> should.equal(19)
  let assert Ok(old) = discovery_15_answer_at.dispatch_discovery_15(a, 6, -7, 0)
  first.previous |> should.equal(old)
  invariants(
    first.previous.previous.answer.first,
    first.previous.previous.answer.direction_step,
    n,
  )
  |> should.equal(True)
}

pub fn discovery_17_invalid_inputs_and_priority_test() {
  let n = modulus + 1
  let invalid = [0, -1, modulus, modulus - 1]
  list.map(invalid, fn(rank) { actual(11, 21, 1, 0, rank) })
  |> should.equal([
    Error(discovery_17_wide_rank.InvalidRankRange),
    Error(discovery_17_wide_rank.InvalidRankRange),
    Error(discovery_17_wide_rank.InvalidRankRange),
    Error(discovery_17_wide_rank.InvalidRankRange),
  ])
  select(0, 0, 0)
  |> should.equal(Error(discovery_17_wide_rank.InvalidRankRange))
  select(0, 1, n)
  |> should.equal(Error(discovery_17_wide_rank.InvalidStream))
  select(modulus + 1, 1, n)
  |> should.equal(Error(discovery_17_wide_rank.InvalidStream))
  select(1, 0, n)
  |> should.equal(Error(discovery_17_wide_rank.InvalidStream))
  select(1, 2, n)
  |> should.equal(Error(discovery_17_wide_rank.InvalidStream))
  list.map([0, 7, -1], fn(id) { actual(11, 21, id, 0, 0) })
  |> should.equal([
    Error(discovery_17_wide_rank.InvalidBowlId),
    Error(discovery_17_wide_rank.InvalidBowlId),
    Error(discovery_17_wide_rank.InvalidBowlId),
  ])
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_17_wide_rank.dispatch_discovery_17(retry, 0, 0, 0)
  |> should.equal(
    Error(discovery_17_wide_rank.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_17_wide_rank.dispatch_discovery_17(recovery, 7, 0, -1)
  |> should.equal(
    Error(discovery_17_wide_rank.InvalidContext(bootstrap.InvalidRecoveryDepth)),
  )
}
