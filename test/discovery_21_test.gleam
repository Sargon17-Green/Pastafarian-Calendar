// Stadio 25 / DISCOVERY 21: dek du testoj de eksplicita orda aro.
// Kanona orakolo nur por sendepende antaŭkalkulitaj <=8 rifuzoj.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import reference/core
import reference/sauce

const span = 922

fn batch(a: Int, b: Int, ids: List(Int)) {
  discovery_21_gate_batch.dispatch_discovery_21(
    bootstrap.new_context(a, b),
    ids,
  )
}

fn bounded_rank(stream: core.AnswerStream, index: Int) -> Result(Int, Nil) {
  let limit = { core.m / span } * span
  case index > 8 {
    True -> Error(Nil)
    False ->
      case sauce.answer_at(stream, index) <= limit {
        True -> Ok(sauce.choose_rank(stream, span))
        False -> bounded_rank(stream, index + 1)
      }
  }
}

fn check_pair(a: Int, b: Int, ids: List(Int)) {
  let context = bootstrap.new_context(a, b)
  let assert Ok(got) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.length(got) |> should.equal(list.length(ids))
  list.each(list.zip(ids, got), fn(pair) {
    let #(id, item) = pair
    let assert Ok(expected) =
      discovery_20_gate_gap.dispatch_discovery_20(context, id)
    item |> should.equal(expected)
    item.queried_bowl_id |> should.equal(id)
    item.seal |> should.equal(1)
    item.gap |> should.equal(item.previous.value)
    item.previous.n |> should.equal(span)
    item.previous.lower |> should.equal(core.gate_gap_min)
    item.previous.upper |> should.equal(core.gate_gap_max)
    { item.gap >= core.gate_gap_min && item.gap <= core.gate_gap_max }
    |> should.equal(True)
  })
}

fn check_oracle(a: Int, b: Int, ids: List(Int)) {
  let assert Ok(got) = batch(a, b, ids)
  list.each(list.zip(ids, got), fn(pair) {
    let #(id, sample) = pair
    let stream = sauce.ask_bowl(sauce.sauce(a, b), id, core.seal_gate_gap)
    case bounded_rank(stream, 0) {
      Ok(rank) -> sample.gap |> should.equal(core.gate_gap_min + rank - 1)
      Error(_) -> {
        let assert Ok(expected) =
          discovery_20_gate_gap.dispatch_discovery_20(
            bootstrap.new_context(a, b),
            id,
          )
        sample |> should.equal(expected)
      }
    }
  })
}

pub fn discovery_21_empty_valid_test() {
  batch(11, 21, []) |> should.equal(Ok([]))
}

pub fn discovery_21_empty_invalid_context_test() {
  let context =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_21_gate_batch.dispatch_discovery_21(context, [])
  |> should.equal(Ok([]))
}

pub fn discovery_21_six_individual_bowls_test() {
  list.each([1, 2, 3, 4, 5, 6], fn(id) {
    check_pair(11, 21, [id])
    check_oracle(11, 21, [id])
  })
}

pub fn discovery_21_forward_order_test() {
  let ids = [1, 2, 3, 4, 5, 6]
  check_pair(11, 21, ids)
  let assert Ok(got) = batch(11, 21, ids)
  list.map(got, fn(sample) { sample.queried_bowl_id })
  |> should.equal(ids)
}

pub fn discovery_21_reverse_order_test() {
  let ids = [6, 5, 4, 3, 2, 1]
  check_pair(11, 21, ids)
  let assert Ok(got) = batch(11, 21, ids)
  list.map(got, fn(sample) { sample.queried_bowl_id })
  |> should.equal(ids)
}

pub fn discovery_21_duplicate_bowl_requests_test() {
  let ids = [3, 3, 3, 1, 3]
  check_pair(11, 21, ids)
  let assert Ok(got) = batch(11, 21, ids)
  let assert Ok(three) =
    discovery_20_gate_gap.dispatch_discovery_20(
      bootstrap.new_context(11, 21),
      3,
    )
  let assert Ok(one) =
    discovery_20_gate_gap.dispatch_discovery_20(
      bootstrap.new_context(11, 21),
      1,
    )
  got |> should.equal([three, three, three, one, three])
}

pub fn discovery_21_same_day_reverse_negative_test() {
  list.each([#(0, 0), #(21, 11), #(-12, -19), #(-11, 23)], fn(pair) {
    let #(a, b) = pair
    check_pair(a, b, [1, 2, 6])
  })
}

pub fn discovery_21_foundation_boundaries_test() {
  let f = core.foundation_day
  list.each([#(f - 1, f), #(f, f), #(f, f + 1), #(f + 1, f)], fn(pair) {
    let #(a, b) = pair
    check_pair(a, b, [2, 4, 5])
  })
}

pub fn discovery_21_huge_signed_days_test() {
  let huge = core.m * core.m + core.m
  check_pair(huge, -huge, [1, 6])
  check_pair(-huge, huge, [6, 1, 6])
}

pub fn discovery_21_invalid_id_positions_test() {
  let bad = Error(discovery_19_interval_value.InvalidBowlId)
  batch(11, 21, [0, 1, 2]) |> should.equal(bad)
  batch(11, 21, [1, 7, 2]) |> should.equal(bad)
  batch(11, 21, [1, 2, -1]) |> should.equal(bad)
}

pub fn discovery_21_invalid_context_priorities_test() {
  let base = bootstrap.new_context(11, 21)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  let depth = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_21_gate_batch.dispatch_discovery_21(retry, [0, 1])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_21_gate_batch.dispatch_discovery_21(depth, [7, 6])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRecoveryDepth,
    )),
  )
  let a = bootstrap.MonsterContext(..base, diagnostics: ["A"])
  let b = bootstrap.MonsterContext(..base, diagnostics: ["B"])
  let assert Ok(one) = discovery_21_gate_batch.dispatch_discovery_21(a, [1])
  let assert Ok(two) = discovery_21_gate_batch.dispatch_discovery_21(b, [1])
  one == two |> should.equal(False)
}

pub fn discovery_21_convenience_and_oracle_test() {
  let ids = [1, 4, 3, 3, 6]
  let assert Ok(got) = batch(11, 21, ids)
  discovery_21_gate_batch.gap_values_for_days(11, 21, ids)
  |> should.equal(Ok(list.map(got, fn(sample) { sample.gap })))
  check_oracle(11, 21, ids)
  check_oracle(21, 11, [2, 5])
}
