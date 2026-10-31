// Stadio 17 / DISCOVERY 13: la orakolo vivas nur en test/reference.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_11_pouring
import pastafari/discovery_12_post_stir
import pastafari/discovery_13_next_bowl
import reference/core
import reference/sauce

fn observed(a: Int, b: Int, id: Int) -> Result(Int, discovery_13_next_bowl.Discovery13Error) {
  discovery_13_next_bowl.next_bowl_for_days(a, b, id)
}

fn oracle(a: Int, b: Int, id: Int) -> Int {
  sauce.next_bowl_in_drop_46_order(sauce.sauce(a, b), id)
}

fn assert_all_identifiers(a: Int, b: Int) {
  let identifiers = [1, 2, 3, 4, 5, 6]
  let actual = list.map(identifiers, fn(id) { observed(a, b, id) })
  let expected = list.map(identifiers, fn(id) { Ok(oracle(a, b, id)) })
  actual |> should.equal(expected)
}

pub fn discovery_13_six_cyclic_successors_test() {
  assert_all_identifiers(11, 21)
}

pub fn discovery_13_successors_form_permutation_test() {
  let ids = [1, 2, 3, 4, 5, 6]
  let successors = list.map(ids, fn(id) {
    let assert Ok(next) = observed(11, 21, id)
    next
  })
  list.length(successors) |> should.equal(6)
  list.all(ids, fn(id) { list.contains(successors, id) })
  |> should.equal(True)
}

pub fn discovery_13_preserves_original_order_test() {
  let context = bootstrap.new_context(11, 21)
  let assert Ok(output) =
    discovery_13_next_bowl.dispatch_discovery_13(context, 3)
  let #(old_bowls, original_order) =
    discovery_11_pouring.pour_visible_drops_for_days(11, 21)
  let #(final_bowls, order_after_stir) =
    discovery_12_post_stir.post_stir_for_days(11, 21)
  output.order_at_drop_46 |> should.equal(original_order)
  output.order_at_drop_46 |> should.equal(order_after_stir)
  output.bowls |> should.equal(final_bowls)
  output.bowls |> should.equal(sauce.sauce(11, 21).bowls)
  list.length(old_bowls) |> should.equal(6)
}

pub fn discovery_13_foundation_same_day_oracle_test() {
  let f = core.foundation_day
  assert_all_identifiers(f, f)
}

pub fn discovery_13_forward_oracle_test() {
  assert_all_identifiers(11, 21)
}

pub fn discovery_13_reverse_oracle_test() {
  assert_all_identifiers(21, 11)
}

pub fn discovery_13_other_same_day_oracle_test() {
  assert_all_identifiers(0, 0)
}

pub fn discovery_13_foundation_crossing_test() {
  let f = core.foundation_day
  observed(f - 1, f + 1, 1) |> should.equal(Ok(oracle(f - 1, f + 1, 1)))
  observed(f - 1, f + 1, 6) |> should.equal(Ok(oracle(f - 1, f + 1, 6)))
  observed(f + 1, f - 1, 1) |> should.equal(Ok(oracle(f + 1, f - 1, 1)))
  observed(f + 1, f - 1, 6) |> should.equal(Ok(oracle(f + 1, f - 1, 6)))
}

pub fn discovery_13_bigint_both_directions_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  observed(huge, -huge, 1) |> should.equal(Ok(oracle(huge, -huge, 1)))
  observed(huge, -huge, 6) |> should.equal(Ok(oracle(huge, -huge, 6)))
  observed(-huge, huge, 1) |> should.equal(Ok(oracle(-huge, huge, 1)))
  observed(-huge, huge, 6) |> should.equal(Ok(oracle(-huge, huge, 6)))
}

pub fn discovery_13_invalid_and_valid_bowl_ids_test() {
  let bad = [0, 7, -1]
  let actual = list.map(bad, fn(id) { observed(11, 21, id) })
  actual |> should.equal([
    Error(discovery_13_next_bowl.InvalidBowlId),
    Error(discovery_13_next_bowl.InvalidBowlId),
    Error(discovery_13_next_bowl.InvalidBowlId),
  ])
  observed(11, 21, 1) |> should.equal(Ok(oracle(11, 21, 1)))
  observed(11, 21, 6) |> should.equal(Ok(oracle(11, 21, 6)))
}

pub fn discovery_13_interleaved_contexts_test() {
  let first = bootstrap.new_context(-11, 23)
  let first = bootstrap.MonsterContext(..first, diagnostics: ["UNUA"])
  let second = bootstrap.new_context(400, -900)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_13_next_bowl.dispatch_discovery_13(first, 6)
  let assert Ok(b) = discovery_13_next_bowl.dispatch_discovery_13(second, 1)
  let assert Ok(a_again) = discovery_13_next_bowl.dispatch_discovery_13(first, 6)
  a |> should.equal(a_again)
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
  a.queried_bowl_id |> should.equal(6)
  b.queried_bowl_id |> should.equal(1)
  a.next_bowl_id |> should.equal(oracle(-11, 23, 6))
  b.next_bowl_id |> should.equal(oracle(400, -900, 1))
  a.order_at_drop_46 |> should.equal(sauce.sauce(-11, 23).order_at_drop_46)
  b.order_at_drop_46 |> should.equal(sauce.sauce(400, -900).order_at_drop_46)
  a.bowls |> should.equal(sauce.sauce(-11, 23).bowls)
  b.bowls |> should.equal(sauce.sauce(400, -900).bowls)
}

pub fn discovery_13_retry_recovery_error_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_13_next_bowl.dispatch_discovery_13(retry, 0)
  |> should.equal(
    Error(discovery_13_next_bowl.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_13_next_bowl.dispatch_discovery_13(recovery, 7)
  |> should.equal(
    Error(discovery_13_next_bowl.InvalidContext(bootstrap.InvalidRecoveryDepth)),
  )
  let both = bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_13_next_bowl.dispatch_discovery_13(both, -1)
  |> should.equal(
    Error(discovery_13_next_bowl.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  discovery_13_next_bowl.dispatch_discovery_13(base, 0)
  |> should.equal(Error(discovery_13_next_bowl.InvalidBowlId))
}
