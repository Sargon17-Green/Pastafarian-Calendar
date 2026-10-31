// Stadio 13 / DISCOVERY 09: referenco restas nur en la testaro.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_09_visible
import reference/core
import reference/sauce

fn observed(a: Int, b: Int) -> List(Int) {
  discovery_09_visible.visible_drops_for_days(a, b)
}

fn expected(a: Int, b: Int) -> List(Int) {
  let counts = core.work_counts(a, b)
  let stones = core.build_stones()
  let hidden = sauce.build_hidden_drops(counts, stones)
  sauce.build_visible_drops(counts, stones, hidden)
}

pub fn discovery_09_forty_six_drops_test() {
  list.length(observed(11, 21)) |> should.equal(46)
}

pub fn discovery_09_foundation_first_fixture_test() {
  let assert [first, ..] = observed(core.foundation_day, core.foundation_day)
  first |> should.equal(56_644_603_826_892_212_324_764_499_696_091_907_135)
}

pub fn discovery_09_foundation_last_fixture_test() {
  let assert [last, ..] =
    list.reverse(observed(core.foundation_day, core.foundation_day))
  last |> should.equal(141_872_771_689_426_650_819_909_896_585_756_512_282)
}

pub fn discovery_09_foundation_complete_oracle_test() {
  observed(core.foundation_day, core.foundation_day)
  |> should.equal(expected(core.foundation_day, core.foundation_day))
}

pub fn discovery_09_forward_oracle_test() {
  observed(11, 21) |> should.equal(expected(11, 21))
}

pub fn discovery_09_reverse_oracle_test() {
  observed(21, 11) |> should.equal(expected(21, 11))
}

pub fn discovery_09_foundation_crossing_forward_test() {
  let f = core.foundation_day
  observed(f - 1, f + 1) |> should.equal(expected(f - 1, f + 1))
}

pub fn discovery_09_foundation_crossing_reverse_test() {
  let f = core.foundation_day
  observed(f + 1, f - 1) |> should.equal(expected(f + 1, f - 1))
}

pub fn discovery_09_bigint_both_directions_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  observed(huge, -huge) |> should.equal(expected(huge, -huge))
  observed(-huge, huge) |> should.equal(expected(-huge, huge))
}

pub fn discovery_09_modulus_range_test() {
  list.all(observed(11, 21), fn(value) { value >= 1 && value <= core.m })
  |> should.equal(True)
}

pub fn discovery_09_repeatability_test() {
  observed(-100, 100) |> should.equal(observed(-100, 100))
}

pub fn discovery_09_context_isolation_test() {
  let one = bootstrap.new_context(-11, 23)
  let one = bootstrap.MonsterContext(..one, diagnostics: ["UNUA"])
  let two = bootstrap.new_context(400, -900)
  let two = bootstrap.MonsterContext(..two, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_09_visible.dispatch_discovery_09(one)
  let assert Ok(b) = discovery_09_visible.dispatch_discovery_09(two)
  a.visible |> should.equal(expected(-11, 23))
  b.visible |> should.equal(expected(400, -900))
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_09_invalid_retry_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_09_visible.dispatch_discovery_09(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn discovery_09_invalid_recovery_and_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_09_visible.dispatch_discovery_09(recovery)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
  let both =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_09_visible.dispatch_discovery_09(both)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
