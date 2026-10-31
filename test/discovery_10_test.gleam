// Stadio 14 / DISCOVERY 10: la referenca saŭco estas nur testa orakolo.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_10_initial_bowls
import reference/core
import reference/sauce

fn observed(a: Int, b: Int) -> List(Int) {
  discovery_10_initial_bowls.initial_bowls_for_days(a, b)
}

fn expected(a: Int, b: Int) -> List(Int) {
  sauce.initial_bowls(core.work_counts(a, b))
}

pub fn discovery_10_six_bowls_test() {
  list.length(observed(11, 21)) |> should.equal(6)
}

pub fn discovery_10_foundation_fixture_test() {
  observed(core.foundation_day, core.foundation_day)
  |> should.equal([87_617, 136_163, 289_447, 724_205, 944_789, 1_907_167])
}

pub fn discovery_10_foundation_oracle_test() {
  observed(core.foundation_day, core.foundation_day)
  |> should.equal(expected(core.foundation_day, core.foundation_day))
}

pub fn discovery_10_forward_fixture_and_oracle_test() {
  observed(11, 21)
  |> should.equal([
    14_507_191_460_314_810,
    22_667_488_538_707_602,
    32_641_219_990_828_972,
    44_428_423_395_860_104,
    58_028_962_890_760_230,
    73_443_063_950_500_870,
  ])
  observed(11, 21) |> should.equal(expected(11, 21))
}

pub fn discovery_10_reverse_oracle_test() {
  observed(21, 11) |> should.equal(expected(21, 11))
}

pub fn discovery_10_other_same_day_test() {
  observed(0, 0) |> should.equal(expected(0, 0))
}

pub fn discovery_10_foundation_crossing_test() {
  let f = core.foundation_day
  observed(f - 1, f + 1) |> should.equal(expected(f - 1, f + 1))
  observed(f + 1, f - 1) |> should.equal(expected(f + 1, f - 1))
}

pub fn discovery_10_bigint_both_directions_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  observed(huge, -huge) |> should.equal(expected(huge, -huge))
  observed(-huge, huge) |> should.equal(expected(-huge, huge))
}

pub fn discovery_10_modulus_range_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  list.all(observed(huge, -huge), fn(value) { value >= 1 && value <= core.m })
  |> should.equal(True)
  list.all(observed(-huge, huge), fn(value) { value >= 1 && value <= core.m })
  |> should.equal(True)
}

pub fn discovery_10_repeatability_test() {
  observed(-100, 100) |> should.equal(observed(-100, 100))
}

pub fn discovery_10_context_isolation_test() {
  let one = bootstrap.new_context(-11, 23)
  let one = bootstrap.MonsterContext(..one, diagnostics: ["UNUA"])
  let two = bootstrap.new_context(400, -900)
  let two = bootstrap.MonsterContext(..two, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_10_initial_bowls.dispatch_discovery_10(one)
  let assert Ok(b) = discovery_10_initial_bowls.dispatch_discovery_10(two)
  a.bowls |> should.equal(expected(-11, 23))
  b.bowls |> should.equal(expected(400, -900))
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_10_invalid_context_and_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid_retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_10_initial_bowls.dispatch_discovery_10(invalid_retry)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
  let invalid_recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_10_initial_bowls.dispatch_discovery_10(invalid_recovery)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
  let both =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_10_initial_bowls.dispatch_discovery_10(both)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
