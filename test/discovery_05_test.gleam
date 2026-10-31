// Stadio 9 / DISCOVERY 05: aparta test-referenco estas la orakolo.
// Ne uzu produktkodon por kalkuli la atendatan valoron.
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_05_connection
import reference/core

fn observed(calculation_day: Int, target_day: Int) -> Int {
  let context = bootstrap.new_context(calculation_day, target_day)
  let assert Ok(output) = discovery_05_connection.dispatch_discovery_05(context)
  output.connection
}

fn canonical(calculation_day: Int, target_day: Int) -> Int {
  core.work_counts(calculation_day, target_day).connection
}

pub fn discovery_05_foundation_same_day_test() {
  let f = core.foundation_day
  observed(f, f) |> should.equal(2)
  observed(f, f) |> should.equal(canonical(f, f))
}

pub fn discovery_05_foundation_past_test() {
  let f = core.foundation_day
  observed(f, f - 1) |> should.equal(3)
  observed(f, f - 1) |> should.equal(canonical(f, f - 1))
}

pub fn discovery_05_foundation_future_test() {
  let f = core.foundation_day
  observed(f, f + 1) |> should.equal(4)
  observed(f, f + 1) |> should.equal(canonical(f, f + 1))
}

pub fn discovery_05_cross_foundation_test() {
  let f = core.foundation_day
  observed(f - 2, f + 2) |> should.equal(9)
  observed(f - 2, f + 2) |> should.equal(canonical(f - 2, f + 2))
  observed(f + 2, f - 2) |> should.equal(9)
}

pub fn discovery_05_zero_and_negative_test() {
  observed(-1, 0) |> should.equal(canonical(-1, 0))
  observed(0, -1) |> should.equal(canonical(0, -1))
  observed(0, 0) |> should.equal(canonical(0, 0))
}

pub fn discovery_05_wide_magnitudes_test() {
  let early = -123_456_789_012_345_678_901_234_567_890
  let late = 987_654_321_098_765_432_109_876_543_210
  observed(early, late) |> should.equal(canonical(early, late))
  observed(late, early) |> should.equal(canonical(late, early))
  observed(early, early) |> should.equal(canonical(early, early))
}

pub fn discovery_05_symmetry_test() {
  let f = core.foundation_day
  observed(f - 17, f + 19) |> should.equal(observed(f + 19, f - 17))
  observed(-8, 73) |> should.equal(observed(73, -8))
}

pub fn discovery_05_rightward_step_test() {
  let f = core.foundation_day
  observed(f, f + 2) - observed(f, f + 1) |> should.equal(2)
}

pub fn discovery_05_leftward_step_test() {
  let f = core.foundation_day
  observed(f, f - 2) - observed(f, f - 1) |> should.equal(2)
}

pub fn discovery_05_context_isolation_test() {
  let first = bootstrap.new_context(11, 21)
  let first =
    bootstrap.MonsterContext(
      ..first,
      diagnostics: ["UNUA"],
      validation_failures: ["RESTAS"],
    )
  let second = bootstrap.new_context(100, 99)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_05_connection.dispatch_discovery_05(first)
  let assert Ok(b) = discovery_05_connection.dispatch_discovery_05(second)
  a.connection |> should.equal(a.action_count + a.target_count)
  b.connection |> should.equal(b.action_count + b.target_count)
  a.connection |> should.equal(canonical(11, 21))
  b.connection |> should.equal(canonical(100, 99))
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.validation_failures |> should.equal(["RESTAS"])
  b.context.validation_failures |> should.equal([])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_05_invalid_retry_budget_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_05_connection.dispatch_discovery_05(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn discovery_05_invalid_recovery_depth_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_05_connection.dispatch_discovery_05(invalid)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
}

pub fn discovery_05_both_invalid_priority_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_05_connection.dispatch_discovery_05(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
