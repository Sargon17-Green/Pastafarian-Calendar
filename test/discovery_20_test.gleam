// Stadio 24 / DISCOVERY 20: 12 apartaj testoj de tipita pordeg-interspaco.
// La referenca saŭco estas vokata nur post sendependa <=8-rifuza antaŭkontrolo.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import reference/core
import reference/sauce

const span = 922

fn output(a: Int, b: Int, bowl_id: Int) {
  discovery_20_gate_gap.dispatch_discovery_20(
    bootstrap.new_context(a, b),
    bowl_id,
  )
}

fn explicit(a: Int, b: Int, bowl_id: Int) {
  discovery_19_interval_value.dispatch_discovery_19(
    bootstrap.new_context(a, b),
    bowl_id,
    core.seal_gate_gap,
    core.gate_gap_min,
    core.gate_gap_max,
  )
}

fn check_pair(a: Int, b: Int, bowl_id: Int) {
  let assert Ok(got) = output(a, b, bowl_id)
  let assert Ok(expected) = explicit(a, b, bowl_id)
  got.previous |> should.equal(expected)
  got.gap |> should.equal(expected.value)
  got.seal |> should.equal(core.seal_gate_gap)
  got.queried_bowl_id |> should.equal(bowl_id)
  got.previous.lower |> should.equal(core.gate_gap_min)
  got.previous.upper |> should.equal(core.gate_gap_max)
  got.previous.n |> should.equal(span)
  got.gap |> should.equal(core.gate_gap_min + got.previous.previous.rank - 1)
  { got.gap >= core.gate_gap_min && got.gap <= core.gate_gap_max }
  |> should.equal(True)
}

// Ĉi tiu paŝa orakol-kontrolo ne uzas la produktan O(1)-rangan formulon.
fn bounded_reference(
  stream: core.AnswerStream,
  index: Int,
) -> Result(Int, Nil) {
  let limit = { core.m / span } * span
  case index > 8 {
    True -> Error(Nil)
    False ->
      case sauce.answer_at(stream, index) <= limit {
        True -> Ok(sauce.choose_rank(stream, span))
        False -> bounded_reference(stream, index + 1)
      }
  }
}

fn check_canonical(a: Int, b: Int, bowl_id: Int) {
  let stream = sauce.ask_bowl(sauce.sauce(a, b), bowl_id, core.seal_gate_gap)
  let assert Ok(got) = output(a, b, bowl_id)
  case bounded_reference(stream, 0) {
    Ok(rank) -> got.gap |> should.equal(core.gate_gap_min + rank - 1)
    Error(_) -> {
      let assert Ok(expected) = explicit(a, b, bowl_id)
      got.previous |> should.equal(expected)
    }
  }
}

pub fn discovery_20_canonical_first_bowl_test() {
  check_pair(11, 21, 1)
  check_canonical(11, 21, 1)
}

pub fn discovery_20_all_six_bowls_test() {
  list.each([1, 2, 3, 4, 5, 6], fn(id) {
    check_pair(11, 21, id)
    check_canonical(11, 21, id)
  })
}

pub fn discovery_20_foundation_boundaries_test() {
  let f = core.foundation_day
  let pairs = [#(f - 1, f), #(f, f), #(f, f + 1), #(f + 1, f)]
  list.each(pairs, fn(pair) {
    let #(a, b) = pair
    check_pair(a, b, 2)
    check_canonical(a, b, 2)
  })
}

pub fn discovery_20_same_day_reverse_and_prior_test() {
  let pairs = [#(0, 0), #(21, 11), #(-12, -19), #(11, 21)]
  list.each(pairs, fn(pair) {
    let #(a, b) = pair
    check_pair(a, b, 3)
  })
}

pub fn discovery_20_unbounded_signed_days_test() {
  let huge = core.m * core.m + core.m
  check_pair(huge, -huge, 1)
  check_pair(-huge, huge, 6)
  check_pair(huge, huge, 5)
}

pub fn discovery_20_previous_chain_preserved_test() {
  let base = bootstrap.new_context(-11, 23)
  let context = bootstrap.MonsterContext(..base, diagnostics: ["STADIO24"])
  let assert Ok(got) = discovery_20_gate_gap.dispatch_discovery_20(context, 6)
  let assert Ok(expected) =
    discovery_19_interval_value.dispatch_discovery_19(
      context,
      6,
      core.seal_gate_gap,
      core.gate_gap_min,
      core.gate_gap_max,
    )
  got.previous |> should.equal(expected)
  got.previous.previous.previous.previous.context.diagnostics
  |> should.equal(["STADIO24"])
}

pub fn discovery_20_output_invariants_test() {
  let assert Ok(got) = output(11, 21, 4)
  got.queried_bowl_id |> should.equal(4)
  got.seal |> should.equal(1)
  got.previous.lower |> should.equal(42)
  got.previous.upper |> should.equal(963)
  got.previous.n |> should.equal(922)
  got.gap |> should.equal(41 + got.previous.previous.rank)
  { got.gap >= 42 && got.gap <= 963 } |> should.equal(True)
}

pub fn discovery_20_convenience_api_equivalence_test() {
  let pairs = [#(11, 21, 1), #(21, 11, 6), #(-3, -3, 2)]
  list.each(pairs, fn(triple) {
    let #(a, b, id) = triple
    let assert Ok(got) = output(a, b, id)
    discovery_20_gate_gap.gap_for_days(a, b, id)
    |> should.equal(Ok(got.gap))
  })
}

pub fn discovery_20_invalid_bowl_ids_test() {
  list.each([0, 7, -1], fn(id) {
    output(11, 21, id)
    |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
    discovery_20_gate_gap.gap_for_days(11, 21, id)
    |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  })
}

pub fn discovery_20_retry_budget_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let bad = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_20_gate_gap.dispatch_discovery_20(bad, 0)
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_20_recovery_depth_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let bad = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_20_gate_gap.dispatch_discovery_20(bad, 7)
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRecoveryDepth,
    )),
  )
}

pub fn discovery_20_interleaved_context_isolation_test() {
  let first = bootstrap.new_context(11, 21)
  let second = bootstrap.new_context(-11, 23)
  let a = bootstrap.MonsterContext(..first, diagnostics: ["A"])
  let b = bootstrap.MonsterContext(..second, diagnostics: ["B"])
  let assert Ok(a1) = discovery_20_gate_gap.dispatch_discovery_20(a, 1)
  let assert Ok(b1) = discovery_20_gate_gap.dispatch_discovery_20(b, 6)
  let assert Ok(a2) = discovery_20_gate_gap.dispatch_discovery_20(a, 1)
  a1 |> should.equal(a2)
  a1.previous.previous.previous.previous.context.diagnostics
  |> should.equal(["A"])
  b1.previous.previous.previous.previous.context.diagnostics
  |> should.equal(["B"])
}
