// Stadio 20: apartaj orakoloj restas ekskluzive sub test/reference.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_15_answer_at
import pastafari/discovery_16_short_rank
import reference/core
import reference/sauce

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

fn actual(a: Int, b: Int, id: Int, seal: Int, n: Int) {
  discovery_16_short_rank.short_rank_for_days(a, b, id, seal, n)
}

// n <= 11 garantias maksimume 10 sinsekvajn rifuzojn por paŝo +/-1.
fn short_oracle(a: Int, b: Int, id: Int, seal: Int, n: Int) -> Int {
  let stream = sauce.ask_bowl(sauce.sauce(a, b), id, seal)
  sauce.choose_rank_short(stream, n)
}

fn assert_oracle(a: Int, b: Int, id: Int, seal: Int, n: Int) {
  actual(a, b, id, seal, n) |> should.equal(Ok(short_oracle(a, b, id, seal, n)))
}

fn select(first: Int, step: Int, n: Int) {
  discovery_16_short_rank.select_short_rank(first, step, n)
}

pub fn discovery_16_basic_short_oracle_test() {
  assert_oracle(11, 21, 1, 0, 7)
  let assert Ok(result) =
    discovery_16_short_rank.dispatch_discovery_16(
      bootstrap.new_context(11, 21), 1, 0, 7,
    )
  result.previous.index |> should.equal(0)
  result.previous.value |> should.equal(result.previous.previous.answer.first)
}

pub fn discovery_16_six_bowl_ids_oracle_test() {
  let ids = [1, 2, 3, 4, 5, 6]
  let observed = list.map(ids, fn(id) { actual(11, 21, id, 17, 2) })
  let expected = list.map(ids, fn(id) { Ok(short_oracle(11, 21, id, 17, 2)) })
  observed |> should.equal(expected)
}

pub fn discovery_16_directions_and_same_day_oracle_test() {
  assert_oracle(11, 21, 2, 0, 1)
  assert_oracle(21, 11, 3, -7, 3)
  assert_oracle(0, 0, 4, 7, 5)
  assert_oracle(-20, -20, 6, 9, 5)
}

pub fn discovery_16_foundation_boundaries_oracle_test() {
  let f = core.foundation_day
  assert_oracle(f - 1, f, 3, 0, 11)
  assert_oracle(f, f + 1, 3, -1, 11)
  assert_oracle(f + 1, f - 1, 2, 30, 11)
  assert_oracle(f - 1, f + 1, 2, -30, 11)
}

pub fn discovery_16_big_seals_oracle_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  let seals = [0, 1, -1, huge, -huge]
  let observed = list.map(seals, fn(seal) { actual(11, 21, 3, seal, 7) })
  let expected = list.map(seals, fn(seal) { Ok(short_oracle(11, 21, 3, seal, 7)) })
  observed |> should.equal(expected)
  let assert Ok(output) =
    discovery_16_short_rank.dispatch_discovery_16(
      bootstrap.new_context(11, 21), 3, -huge, 7,
    )
  output.previous.previous.seal |> should.equal(-huge)
}

pub fn discovery_16_big_days_determinism_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  let choices = [
    actual(huge, -huge, 1, huge, 97),
    actual(-huge, huge, 6, -huge, 97),
    actual(huge, huge, 3, -huge, 97),
  ]
  choices |> should.equal([
    actual(huge, -huge, 1, huge, 97),
    actual(-huge, huge, 6, -huge, 97),
    actual(huge, huge, 3, -huge, 97),
  ])
  let checks = list.map(choices, fn(result) {
    case result {
      Ok(rank) -> rank >= 1 && rank <= 97
      Error(_) -> False
    }
  })
  checks |> should.equal([True, True, True])
}

pub fn discovery_16_one_and_full_modulus_test() {
  let assert Ok(one) = select(modulus, -1, 1)
  one.limit |> should.equal(modulus)
  one.rank |> should.equal(1)
  let assert Ok(full) = select(modulus - 123, 1, modulus)
  full.limit |> should.equal(modulus)
  full.accepted_value |> should.equal(modulus - 123)
  full.rank |> should.equal(modulus - 123)
  actual(11, 21, 1, 0, 1) |> should.equal(Ok(1))
}

pub fn discovery_16_near_modulus_rejection_test() {
  let n = modulus - 1
  let assert Ok(at_limit) = select(n, 1, n)
  at_limit.accepted_value |> should.equal(n)
  at_limit.rank |> should.equal(n)
  let assert Ok(wrapped) = select(modulus, 1, n)
  wrapped.accepted_value |> should.equal(1)
  wrapped.rank |> should.equal(1)
  let assert Ok(backward) = select(modulus, -1, n)
  backward.accepted_value |> should.equal(n)
  backward.rank |> should.equal(n)
}

pub fn discovery_16_half_modulus_long_rejection_test() {
  let n = { modulus / 2 } + 1
  let assert Ok(forward) = select(modulus, 1, n)
  let assert Ok(backward) = select(modulus, -1, n)
  forward.limit |> should.equal(n)
  backward.limit |> should.equal(n)
  forward.accepted_value |> should.equal(1)
  backward.accepted_value |> should.equal(n)
  forward.rank |> should.equal(1)
  backward.rank |> should.equal(n)
}

pub fn discovery_16_synthetic_invariants_test() {
  let cases = [
    #(1, 1, 3),
    #(modulus, 1, 3),
    #(modulus, -1, 3),
    #(modulus - 3, -1, 5),
    #(modulus / 3, 1, modulus),
  ]
  let checks = list.map(cases, fn(entry) {
    let #(first, step, n) = entry
    let assert Ok(found) = select(first, step, n)
    let limit_by_division = { modulus / n } * n
    found.limit == limit_by_division
    && found.accepted_value >= 1
    && found.accepted_value <= limit_by_division
    && found.rank >= 1
    && found.rank <= n
    && found.rank == { found.accepted_value - 1 } % n + 1
  })
  checks |> should.equal([True, True, True, True, True])
}

pub fn discovery_16_interleaved_contexts_unchanged_test() {
  let base_a = bootstrap.new_context(-11, 23)
  let a = bootstrap.MonsterContext(..base_a, diagnostics: ["UNUA"])
  let base_b = bootstrap.new_context(400, -900)
  let b = bootstrap.MonsterContext(..base_b, diagnostics: ["DUA"])
  let assert Ok(first) = discovery_16_short_rank.dispatch_discovery_16(a, 6, -7, 7)
  let assert Ok(second) = discovery_16_short_rank.dispatch_discovery_16(b, 1, 19, 3)
  let assert Ok(again) = discovery_16_short_rank.dispatch_discovery_16(a, 6, -7, 7)
  first |> should.equal(again)
  first.previous.index |> should.equal(0)
  second.previous.index |> should.equal(0)
  first.previous.previous.context.diagnostics |> should.equal(["UNUA"])
  second.previous.previous.context.diagnostics |> should.equal(["DUA"])
  first.previous.previous.seal |> should.equal(-7)
  second.previous.previous.seal |> should.equal(19)
  let assert Ok(old) = discovery_15_answer_at.dispatch_discovery_15(a, 6, -7, 0)
  first.previous |> should.equal(old)
}

pub fn discovery_16_invalid_inputs_and_priority_test() {
  let n = modulus + 1
  let ranks = [0, -1, n]
  let observed = list.map(ranks, fn(rank) { actual(11, 21, 1, 0, rank) })
  observed |> should.equal([
    Error(discovery_16_short_rank.InvalidRankRange),
    Error(discovery_16_short_rank.InvalidRankRange),
    Error(discovery_16_short_rank.InvalidRankRange),
  ])
  select(0, 1, 2) |> should.equal(Error(discovery_16_short_rank.InvalidStream))
  select(modulus + 1, 1, 2)
  |> should.equal(Error(discovery_16_short_rank.InvalidStream))
  select(1, 0, 2) |> should.equal(Error(discovery_16_short_rank.InvalidStream))
  select(1, 2, 2) |> should.equal(Error(discovery_16_short_rank.InvalidStream))
  select(0, 0, 0)
  |> should.equal(Error(discovery_16_short_rank.InvalidRankRange))
  let ids = [0, 7, -1]
  list.map(ids, fn(id) { actual(11, 21, id, 0, 0) })
  |> should.equal([
    Error(discovery_16_short_rank.InvalidBowlId),
    Error(discovery_16_short_rank.InvalidBowlId),
    Error(discovery_16_short_rank.InvalidBowlId),
  ])
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_16_short_rank.dispatch_discovery_16(retry, 0, 0, 0)
  |> should.equal(Error(discovery_16_short_rank.InvalidContext(bootstrap.InvalidRetryBudget)))
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_16_short_rank.dispatch_discovery_16(recovery, 7, 0, -1)
  |> should.equal(Error(discovery_16_short_rank.InvalidContext(bootstrap.InvalidRecoveryDepth)))
}
