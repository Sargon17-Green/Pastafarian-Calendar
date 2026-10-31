// Stadio 11 / DISCOVERY 07: sendependa kanona orakolo en test/reference.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_07_bowls
import reference/core

fn dispatch(drop_value: Int) -> discovery_07_bowls.Discovery07Output {
  let assert Ok(output) =
    discovery_07_bowls.dispatch_discovery_07(
      bootstrap.new_context(11, 21),
      drop_value,
    )
  output
}

fn observed(drop_value: Int) -> List(Int) {
  dispatch(drop_value).order
}

fn ranks_up_to_720(current: Int, reverse_acc: List(Int)) -> List(Int) {
  case current > 720 {
    True -> list.reverse(reverse_acc)
    False -> ranks_up_to_720(current + 1, [current, ..reverse_acc])
  }
}

fn unique_orders(orders: List(List(Int)), seen: List(List(Int))) -> Bool {
  case orders {
    [] -> True
    [order, ..rest] ->
      case list.contains(seen, order) {
        True -> False
        False -> unique_orders(rest, [order, ..seen])
      }
  }
}

pub fn discovery_07_first_rank_test() {
  observed(1) |> should.equal([1, 2, 3, 4, 5, 6])
  observed(1) |> should.equal(core.bowl_order_from_drop(1))
  dispatch(1).rank1 |> should.equal(1)
}

pub fn discovery_07_second_rank_test() {
  observed(2) |> should.equal([1, 2, 3, 4, 6, 5])
  observed(2) |> should.equal(core.bowl_order_from_drop(2))
  dispatch(2).rank1 |> should.equal(2)
}

pub fn discovery_07_final_rank_test() {
  observed(720) |> should.equal([6, 5, 4, 3, 2, 1])
  observed(720) |> should.equal(core.bowl_order_from_drop(720))
  dispatch(720).rank1 |> should.equal(720)
}

pub fn discovery_07_zero_and_negative_test() {
  observed(0) |> should.equal([6, 5, 4, 3, 2, 1])
  observed(-1) |> should.equal([6, 5, 4, 3, 1, 2])
  observed(-719) |> should.equal([1, 2, 3, 4, 5, 6])
  observed(-1) |> should.equal(core.bowl_order_from_drop(-1))
  dispatch(0).rank1 |> should.equal(720)
}

pub fn discovery_07_periodicity_test() {
  observed(1) |> should.equal(observed(721))
  observed(1) |> should.equal(observed(-719))
  observed(2) |> should.equal(observed(1442))
  observed(720) |> should.equal(observed(0))
}

pub fn discovery_07_bigint_test() {
  let huge = 1_180_591_620_717_411_303_424
  observed(huge) |> should.equal([3, 4, 5, 2, 6, 1])
  observed(huge) |> should.equal(core.bowl_order_from_drop(huge))
  observed(-huge) |> should.equal(core.bowl_order_from_drop(-huge))
}

pub fn discovery_07_all_720_reference_test() {
  let ranks = ranks_up_to_720(1, [])
  let actual = list.map(ranks, observed)
  let expected = list.map(ranks, core.bowl_order_from_drop)
  actual |> should.equal(expected)
}

pub fn discovery_07_all_720_unique_permutations_test() {
  let ranks = ranks_up_to_720(1, [])
  let orders = list.map(ranks, observed)
  list.length(orders) |> should.equal(720)
  unique_orders(orders, []) |> should.equal(True)
  list.all(orders, fn(order) {
    list.length(order) == 6
    && list.all([1, 2, 3, 4, 5, 6], fn(bowl) {
      list.contains(order, bowl)
    })
  })
  |> should.equal(True)
}

pub fn discovery_07_isolated_contexts_test() {
  let first = bootstrap.new_context(-11, 23)
  let first = bootstrap.MonsterContext(..first, diagnostics: ["UNUA"])
  let second = bootstrap.new_context(400, -900)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_07_bowls.dispatch_discovery_07(first, 1)
  let assert Ok(b) = discovery_07_bowls.dispatch_discovery_07(second, 720)
  a.order |> should.equal([1, 2, 3, 4, 5, 6])
  b.order |> should.equal([6, 5, 4, 3, 2, 1])
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.calculation_day |> should.equal(-11)
  b.context.target_day |> should.equal(-900)
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_07_invalid_retry_budget_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_07_bowls.dispatch_discovery_07(invalid, 1)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn discovery_07_invalid_recovery_depth_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_07_bowls.dispatch_discovery_07(invalid, 1)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
}

pub fn discovery_07_both_invalid_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_07_bowls.dispatch_discovery_07(invalid, 1)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
