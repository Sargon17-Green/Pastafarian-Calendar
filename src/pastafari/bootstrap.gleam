// Neŭtrala baza infrastrukturo de la unua stadio.
// Ĝi ankoraŭ ne enhavas historian eraron aŭ estontan flikaĵon.

pub type MonsterPhase {
  BootstrapEntry
  BootstrapValidation
  BootstrapDispatch
  BootstrapComplete
}

pub type MonsterStatus {
  New
  Running
  Validated
  Complete
}

pub type MonsterContext {
  MonsterContext(
    calculation_day: Int,
    target_day: Int,
    phase: MonsterPhase,
    sub_phase: Int,
    status: MonsterStatus,
    retry_budget: Int,
    recovery_depth: Int,
    branch_trace: List(String),
    diagnostics: List(String),
    validation_failures: List(String),
  )
}

pub type BootstrapError {
  InvalidRetryBudget
  InvalidRecoveryDepth
}

pub fn new_context(calculation_day: Int, target_day: Int) -> MonsterContext {
  MonsterContext(
    calculation_day: calculation_day,
    target_day: target_day,
    phase: BootstrapEntry,
    sub_phase: 0,
    status: New,
    retry_budget: 0,
    recovery_depth: 0,
    branch_trace: ["BOOTSTRAP_ENTRY"],
    diagnostics: [],
    validation_failures: [],
  )
}

pub fn validate_context(context: MonsterContext) -> Result(MonsterContext, BootstrapError) {
  case context.retry_budget < 0, context.recovery_depth < 0 {
    True, _ -> Error(InvalidRetryBudget)
    _, True -> Error(InvalidRecoveryDepth)
    False, False ->
      Ok(MonsterContext(
        ..context,
        phase: BootstrapValidation,
        status: Validated,
        branch_trace: ["BOOTSTRAP_VALIDATE", ..context.branch_trace],
      ))
  }
}

pub fn dispatch_context(context: MonsterContext) -> Result(MonsterContext, BootstrapError) {
  case validate_context(context) {
    Error(error) -> Error(error)
    Ok(validated) ->
      Ok(MonsterContext(
        ..validated,
        phase: BootstrapComplete,
        sub_phase: 1,
        status: Complete,
        branch_trace: ["BOOTSTRAP_COMPLETE", "BOOTSTRAP_DISPATCH", ..validated.branch_trace],
      ))
  }
}
