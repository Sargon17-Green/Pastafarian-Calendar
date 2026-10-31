// Stadio 16 / DISCOVERY 12: sendependa orakolo nur en la testa tavolo.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_11_pouring
import pastafari/discovery_12_post_stir
import reference/core
import reference/sauce

fn observed(a: Int, b: Int) -> #(List(Int), List(Int)) {
  discovery_12_post_stir.post_stir_for_days(a, b)
}

fn expected(a: Int, b: Int) -> #(List(Int), List(Int)) {
  let counts = core.work_counts(a, b)
  let stones = core.build_stones()
  let hidden = sauce.build_hidden_drops(counts, stones)
  let visible = sauce.build_visible_drops(counts, stones, hidden)
  let initial = sauce.initial_bowls(counts)
  let #(after_drops, order_at_drop_46) =
    sauce.apply_visible_drops_to_bowls(initial, visible, stones)
  #(sauce.post_stir_12(after_drops), order_at_drop_46)
}

pub fn discovery_12_six_final_bowls_test() {
  let #(bowls, _) = observed(11, 21)
  list.length(bowls) |> should.equal(6)
}

pub fn discovery_12_preserves_drop_46_order_test() {
  let #(_, order) = observed(11, 21)
  let #(_, stage15_order) =
    discovery_11_pouring.pour_visible_drops_for_days(11, 21)
  order |> should.equal(stage15_order)
  order |> should.equal(element_order(expected(11, 21)))
}

fn element_order(result: #(List(Int), List(Int))) -> List(Int) {
  let #(_, order) = result
  order
}

pub fn discovery_12_foundation_oracle_test() {
  let f = core.foundation_day
  observed(f, f) |> should.equal(expected(f, f))
}

pub fn discovery_12_forward_oracle_test() {
  observed(11, 21) |> should.equal(expected(11, 21))
}

pub fn discovery_12_reverse_oracle_test() {
  observed(21, 11) |> should.equal(expected(21, 11))
}

pub fn discovery_12_other_same_day_test() {
  observed(0, 0) |> should.equal(expected(0, 0))
}

pub fn discovery_12_foundation_crossing_test() {
  let f = core.foundation_day
  observed(f - 1, f + 1) |> should.equal(expected(f - 1, f + 1))
  observed(f + 1, f - 1) |> should.equal(expected(f + 1, f - 1))
}

pub fn discovery_12_bigint_both_directions_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  observed(huge, -huge) |> should.equal(expected(huge, -huge))
  observed(-huge, huge) |> should.equal(expected(-huge, huge))
}

pub fn discovery_12_modulus_range_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  let #(first, _) = observed(huge, -huge)
  let #(second, _) = observed(-huge, huge)
  list.all(first, fn(value) { value >= 1 && value <= core.m })
  |> should.equal(True)
  list.all(second, fn(value) { value >= 1 && value <= core.m })
  |> should.equal(True)
}

pub fn discovery_12_synchronous_sentinel_and_determinism_test() {
  discovery_12_post_stir.post_stir_once([1, 2, 3, 4, 5, 6], 1)
  |> should.equal([43_348, 43_821, 49_771, 36_114, 57_684, 55_801])
  observed(-100, 100) |> should.equal(observed(-100, 100))
}

pub fn discovery_12_interleaved_contexts_test() {
  let first = bootstrap.new_context(-11, 23)
  let first = bootstrap.MonsterContext(..first, diagnostics: ["UNUA"])
  let second = bootstrap.new_context(400, -900)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_12_post_stir.dispatch_discovery_12(first)
  let assert Ok(b) = discovery_12_post_stir.dispatch_discovery_12(second)
  let assert Ok(again) = discovery_12_post_stir.dispatch_discovery_12(first)
  #(a.bowls, a.order_at_drop_46) |> should.equal(expected(-11, 23))
  #(b.bowls, b.order_at_drop_46) |> should.equal(expected(400, -900))
  a |> should.equal(again)
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_12_retry_recovery_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_12_post_stir.dispatch_discovery_12(retry)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_12_post_stir.dispatch_discovery_12(recovery)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
  let both =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_12_post_stir.dispatch_discovery_12(both)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
