import gleeunit/should
import pastafari/bootstrap

pub fn negative_retry_budget_rejected_test() {
  let context = bootstrap.new_context(17, 19)
  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)

  bootstrap.validate_context(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))

  bootstrap.dispatch_context(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn negative_recovery_depth_rejected_test() {
  let context = bootstrap.new_context(17, 19)
  let invalid = bootstrap.MonsterContext(..context, recovery_depth: -1)

  bootstrap.validate_context(invalid)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))

  bootstrap.dispatch_context(invalid)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
}

pub fn simultaneous_negative_values_have_stable_precedence_test() {
  let context = bootstrap.new_context(17, 19)
  let invalid = bootstrap.MonsterContext(
    ..context,
    retry_budget: -1,
    recovery_depth: -1,
  )

  bootstrap.validate_context(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))

  bootstrap.dispatch_context(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn successful_validation_preserves_nontransition_fields_test() {
  let base = bootstrap.new_context(-15_055_671, 7_777)
  let context = bootstrap.MonsterContext(
    ..base,
    sub_phase: 41,
    retry_budget: 3,
    recovery_depth: 5,
    branch_trace: ["CUSTOM"],
    diagnostics: ["DIAGNOSTIC"],
    validation_failures: ["PRESERVED"],
  )
  let expected = bootstrap.MonsterContext(
    ..context,
    phase: bootstrap.BootstrapValidation,
    status: bootstrap.Validated,
    branch_trace: ["BOOTSTRAP_VALIDATE", "CUSTOM"],
  )

  bootstrap.validate_context(context)
  |> should.equal(Ok(expected))
}

pub fn successful_dispatch_has_exact_transition_trace_test() {
  let base = bootstrap.new_context(-15_055_671, 7_777)
  let context = bootstrap.MonsterContext(
    ..base,
    sub_phase: 41,
    retry_budget: 3,
    recovery_depth: 5,
    branch_trace: ["CUSTOM"],
    diagnostics: ["DIAGNOSTIC"],
    validation_failures: ["PRESERVED"],
  )
  let expected = bootstrap.MonsterContext(
    ..context,
    phase: bootstrap.BootstrapComplete,
    sub_phase: 1,
    status: bootstrap.Complete,
    branch_trace: [
      "BOOTSTRAP_COMPLETE",
      "BOOTSTRAP_DISPATCH",
      "BOOTSTRAP_VALIDATE",
      "CUSTOM",
    ],
  )

  bootstrap.dispatch_context(context)
  |> should.equal(Ok(expected))
}
