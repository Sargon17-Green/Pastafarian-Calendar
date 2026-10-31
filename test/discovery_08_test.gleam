// Stadio 12 / DISCOVERY 08: sendependa orakolo en test/reference/sauce.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_08_hidden
import reference/core
import reference/sauce

fn observed(a: Int, b: Int) -> List(Int) {
  discovery_08_hidden.hidden_drops_for_days(a, b)
}

fn expected(a: Int, b: Int) -> List(Int) {
  sauce.build_hidden_drops(core.work_counts(a, b), core.build_stones())
}

pub fn discovery_08_seven_drops_test() {
  list.length(observed(11, 21)) |> should.equal(7)
}

pub fn discovery_08_foundation_first_fixture_test() {
  let assert [first, ..] = observed(core.foundation_day, core.foundation_day)
  first |> should.equal(119_390_830_530_032_782_664_128_530_203_002_080_344)
}

pub fn discovery_08_foundation_last_fixture_test() {
  let assert [last, ..] =
    list.reverse(observed(core.foundation_day, core.foundation_day))
  last |> should.equal(6_164_285_870_955_721_082_771_365_327_359_496_898)
}

pub fn discovery_08_all_seven_foundation_oracle_test() {
  observed(core.foundation_day, core.foundation_day)
  |> should.equal(expected(core.foundation_day, core.foundation_day))
}

pub fn discovery_08_nontrivial_oracle_test() {
  observed(11, 21) |> should.equal(expected(11, 21))
}

pub fn discovery_08_reverse_direction_oracle_test() {
  observed(21, 11) |> should.equal(expected(21, 11))
  observed(21, 11) == observed(11, 21) |> should.equal(False)
}

pub fn discovery_08_foundation_crossing_oracle_test() {
  let f = core.foundation_day
  observed(f - 1, f + 1) |> should.equal(expected(f - 1, f + 1))
  observed(f + 1, f - 1) |> should.equal(expected(f + 1, f - 1))
}

pub fn discovery_08_bigint_oracle_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  observed(huge, -huge) |> should.equal(expected(huge, -huge))
  observed(-huge, huge) |> should.equal(expected(-huge, huge))
}

pub fn discovery_08_modulus_bounds_test() {
  list.all(observed(11, 21), fn(value) { value >= 1 && value <= core.m })
  |> should.equal(True)
}

pub fn discovery_08_repeatability_test() {
  observed(-100, 100) |> should.equal(observed(-100, 100))
}

pub fn discovery_08_isolated_contexts_test() {
  let first = bootstrap.new_context(-11, 23)
  let first = bootstrap.MonsterContext(..first, diagnostics: ["UNUA"])
  let second = bootstrap.new_context(400, -900)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_08_hidden.dispatch_discovery_08(first)
  let assert Ok(b) = discovery_08_hidden.dispatch_discovery_08(second)
  a.hidden |> should.equal(expected(-11, 23))
  b.hidden |> should.equal(expected(400, -900))
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_08_invalid_retry_budget_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_08_hidden.dispatch_discovery_08(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn discovery_08_invalid_recovery_depth_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_08_hidden.dispatch_discovery_08(invalid)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
}

pub fn discovery_08_invalid_both_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_08_hidden.dispatch_discovery_08(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
