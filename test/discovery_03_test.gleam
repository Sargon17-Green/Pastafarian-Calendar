// Stadio 6 / DISCOVERY 03: tri atendataj normigaj malsukcesoj.
// La kanona inkluziva distanco estas prenata nur el test/reference/core.gleam.
// La historia ekskluziva distanco estas intence diagnoza, ne flikita.
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_03_distance
import reference/core

fn legacy(calculation_day: Int, target_day: Int) -> Int {
  let context = bootstrap.new_context(calculation_day, target_day)
  let assert Ok(output) = discovery_03_distance.dispatch_discovery_03(context)
  output.legacy_distance
}

fn canonical(calculation_day: Int, target_day: Int) -> Int {
  core.work_counts(calculation_day, target_day).distance
}

pub fn discovery_03_same_day_expected_red_test() {
  let f = core.foundation_day
  legacy(f, f) |> should.equal(canonical(f, f))
}

pub fn discovery_03_forward_expected_red_test() {
  let f = core.foundation_day
  legacy(f, f + 1) |> should.equal(canonical(f, f + 1))
}

pub fn discovery_03_reverse_expected_red_test() {
  let f = core.foundation_day
  legacy(f + 1, f) |> should.equal(canonical(f + 1, f))
}

pub fn discovery_03_symmetry_large_integers_test() {
  let earlier = -123_456_789_012_345_678_901_234_567_890
  let later = 987_654_321_098_765_432_109_876_543_210
  legacy(earlier, later) |> should.equal(legacy(later, earlier))
}

pub fn discovery_03_nonnegative_and_zero_guards_test() {
  let earlier = -123_456_789_012_345_678_901_234_567_890
  let later = 987_654_321_098_765_432_109_876_543_210
  { legacy(earlier, later) >= 0 } |> should.equal(True)
  { legacy(later, earlier) >= 0 } |> should.equal(True)
  legacy(earlier, earlier) |> should.equal(0)
  legacy(later, later) |> should.equal(0)
}

pub fn discovery_03_independent_contexts_test() {
  let first = bootstrap.new_context(11, 21)
  let first =
    bootstrap.MonsterContext(
      ..first,
      diagnostics: ["UNUA"],
      validation_failures: ["RESTAS"],
    )
  let second = bootstrap.new_context(100, 99)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(first_out) = discovery_03_distance.dispatch_discovery_03(first)
  let assert Ok(second_out) =
    discovery_03_distance.dispatch_discovery_03(second)

  first_out.legacy_distance |> should.equal(10)
  second_out.legacy_distance |> should.equal(1)
  first_out.context.diagnostics |> should.equal(["UNUA"])
  second_out.context.diagnostics |> should.equal(["DUA"])
  first_out.context.validation_failures |> should.equal(["RESTAS"])
  second_out.context.validation_failures |> should.equal([])
}

pub fn discovery_03_invalid_retry_budget_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_03_distance.dispatch_discovery_03(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn discovery_03_invalid_recovery_depth_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_03_distance.dispatch_discovery_03(invalid)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
}
