// Stadio 15 / DISCOVERY 11: plena referenca saŭco nur en testoj.
import gleam/int
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_06_stones
import pastafari/discovery_11_pouring
import reference/core
import reference/sauce

fn observed(a: Int, b: Int) -> #(List(Int), List(Int)) {
  discovery_11_pouring.pour_visible_drops_for_days(a, b)
}

fn expected(a: Int, b: Int) -> #(List(Int), List(Int)) {
  let counts = core.work_counts(a, b)
  let stones = core.build_stones()
  let hidden = sauce.build_hidden_drops(counts, stones)
  let visible = sauce.build_visible_drops(counts, stones, hidden)
  let initial = sauce.initial_bowls(counts)
  sauce.apply_visible_drops_to_bowls(initial, visible, stones)
}

pub fn discovery_11_six_bowls_test() {
  let #(bowls, _) = observed(11, 21)
  list.length(bowls) |> should.equal(6)
}

pub fn discovery_11_final_order_permutation_test() {
  let #(_, order) = observed(11, 21)
  list.sort(order, fn(a, b) { int.compare(a, b) })
  |> should.equal([1, 2, 3, 4, 5, 6])
}

pub fn discovery_11_foundation_oracle_test() {
  let f = core.foundation_day
  observed(f, f) |> should.equal(expected(f, f))
}

pub fn discovery_11_forward_oracle_test() {
  observed(11, 21) |> should.equal(expected(11, 21))
}

pub fn discovery_11_reverse_oracle_test() {
  observed(21, 11) |> should.equal(expected(21, 11))
}

pub fn discovery_11_other_same_day_oracle_test() {
  observed(0, 0) |> should.equal(expected(0, 0))
}

pub fn discovery_11_foundation_crossing_test() {
  let f = core.foundation_day
  observed(f - 1, f + 1) |> should.equal(expected(f - 1, f + 1))
  observed(f + 1, f - 1) |> should.equal(expected(f + 1, f - 1))
}

pub fn discovery_11_bigint_both_directions_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  observed(huge, -huge) |> should.equal(expected(huge, -huge))
  observed(-huge, huge) |> should.equal(expected(-huge, huge))
}

pub fn discovery_11_modulus_bounds_test() {
  let #(bowls, _) = observed(-100, 100)
  list.all(bowls, fn(value) { value >= 1 && value <= core.m })
  |> should.equal(True)
}

pub fn discovery_11_single_drop_synchronous_sentinel_test() {
  let stone =
    discovery_06_stones.Stone(
      wheat: 1,
      barley: 2,
      salt: 3,
      bitter: 4,
      red: 5,
    )
  discovery_11_pouring.pour_single_drop([1, 2, 3, 4, 5, 6], 1, stone, 1)
  |> should.equal([737, 693, 1643, 979, 1494, 472])
  observed(-100, 100) |> should.equal(observed(-100, 100))
}

pub fn discovery_11_context_isolation_test() {
  let one = bootstrap.new_context(-11, 23)
  let one = bootstrap.MonsterContext(..one, diagnostics: ["UNUA"])
  let two = bootstrap.new_context(400, -900)
  let two = bootstrap.MonsterContext(..two, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_11_pouring.dispatch_discovery_11(one)
  let assert Ok(b) = discovery_11_pouring.dispatch_discovery_11(two)
  #(a.bowls, a.order_at_drop_46) |> should.equal(expected(-11, 23))
  #(b.bowls, b.order_at_drop_46) |> should.equal(expected(400, -900))
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_11_invalid_context_and_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_11_pouring.dispatch_discovery_11(retry)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_11_pouring.dispatch_discovery_11(recovery)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
  let both =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_11_pouring.dispatch_discovery_11(both)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
