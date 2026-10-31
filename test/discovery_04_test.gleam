// Stadio 8 / DISCOVERY 04: komparu kontraŭ la aparta kanona referenco.
// Neniu artefarita EXPECTED_RED; malsukcesoj devas esti efektive reproduktitaj.
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_04_direction
import reference/core

fn direction(calculation_day: Int, target_day: Int) -> Int {
  let context = bootstrap.new_context(calculation_day, target_day)
  let assert Ok(output) = discovery_04_direction.dispatch_discovery_04(context)
  output.direction
}

fn canonical(calculation_day: Int, target_day: Int) -> Int {
  core.work_counts(calculation_day, target_day).direction
}

pub fn discovery_04_past_boundary_test() {
  let f = core.foundation_day
  direction(f, f - 1) |> should.equal(1)
  direction(f, f - 1) |> should.equal(canonical(f, f - 1))
}

pub fn discovery_04_same_day_boundary_test() {
  let f = core.foundation_day
  direction(f, f) |> should.equal(2)
  direction(f, f) |> should.equal(canonical(f, f))
}

pub fn discovery_04_future_boundary_test() {
  let f = core.foundation_day
  direction(f, f + 1) |> should.equal(3)
  direction(f, f + 1) |> should.equal(canonical(f, f + 1))
}

pub fn discovery_04_cross_foundation_test() {
  let f = core.foundation_day
  direction(f - 2, f + 2) |> should.equal(canonical(f - 2, f + 2))
  direction(f + 2, f - 2) |> should.equal(canonical(f + 2, f - 2))
  direction(f - 2, f + 2) |> should.equal(3)
  direction(f + 2, f - 2) |> should.equal(1)
}

pub fn discovery_04_zero_and_negative_test() {
  direction(-1, 0) |> should.equal(3)
  direction(0, -1) |> should.equal(1)
  direction(0, 0) |> should.equal(2)
  direction(-1, 0) |> should.equal(canonical(-1, 0))
  direction(0, -1) |> should.equal(canonical(0, -1))
}

pub fn discovery_04_wide_magnitudes_test() {
  let earlier = -123_456_789_012_345_678_901_234_567_890
  let later = 987_654_321_098_765_432_109_876_543_210
  direction(earlier, later) |> should.equal(canonical(earlier, later))
  direction(later, earlier) |> should.equal(canonical(later, earlier))
  direction(earlier, earlier) |> should.equal(2)
  direction(later, later) |> should.equal(2)
}

pub fn discovery_04_translation_invariance_test() {
  let shift = 999_999_999_999_999_999_999_999
  direction(-7, 8) |> should.equal(direction(-7 + shift, 8 + shift))
  direction(8, -7) |> should.equal(direction(8 + shift, -7 + shift))
  direction(4, 4) |> should.equal(direction(4 + shift, 4 + shift))
}

pub fn discovery_04_reversal_test() {
  let f = core.foundation_day
  direction(f - 4, f + 8) + direction(f + 8, f - 4)
  |> should.equal(4)
  direction(f, f) |> should.equal(2)
}

pub fn discovery_04_independent_contexts_test() {
  let first = bootstrap.new_context(11, 21)
  let first =
    bootstrap.MonsterContext(
      ..first,
      diagnostics: ["UNUA"],
      validation_failures: ["RESTAS"],
    )
  let second = bootstrap.new_context(100, 99)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(first_out) = discovery_04_direction.dispatch_discovery_04(first)
  let assert Ok(second_out) = discovery_04_direction.dispatch_discovery_04(second)
  first_out.direction |> should.equal(3)
  second_out.direction |> should.equal(1)
  first_out.context.diagnostics |> should.equal(["UNUA"])
  second_out.context.diagnostics |> should.equal(["DUA"])
  first_out.context.validation_failures |> should.equal(["RESTAS"])
  second_out.context.validation_failures |> should.equal([])
  first_out.context.status |> should.equal(bootstrap.Complete)
  second_out.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_04_invalid_retry_budget_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_04_direction.dispatch_discovery_04(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn discovery_04_invalid_recovery_depth_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_04_direction.dispatch_discovery_04(invalid)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
}

pub fn discovery_04_invalid_error_precedence_test() {
  let base = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let invalid = bootstrap.MonsterContext(
    ..base,
    retry_budget: -1,
    recovery_depth: -1,
  )
  discovery_04_direction.dispatch_discovery_04(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
