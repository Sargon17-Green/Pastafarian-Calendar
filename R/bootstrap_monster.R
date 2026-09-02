new_monster_context <- function(calculationDay, targetDay) {
  list(
    calculationDay = calculationDay,
    targetDay = targetDay,
    phase = 'BOOTSTRAP',
    subPhase = 0L,
    mode = 'AUTHORITATIVE_BOOTSTRAP',
    status = 'NEW',
    retryBudget = 0L,
    recoveryDepth = 0L,
    currentHandler = 'BootstrapDispatcher',
    previousHandler = NA_character_,
    branchTrace = character(),
    semantic = list(),
    pendingSemantic = NULL,
    rollbackSemantic = NULL,
    metrics = list(),
    logs = character(),
    diagnostics = character(),
    warnings = character(),
    lastError = NULL,
    wrappedErrors = list(),
    validationFailures = character()
  )
}

bootstrap_metrics_bump <- function(ctx, key) {
  old <- ctx$metrics[[key]]
  if (is.null(old)) old <- 0L
  ctx$metrics[[key]] <- old + 1L
  ctx
}

bootstrap_validate_integer_day <- function(day) {
  if (is.character(day)) {
    if (length(day) != 1L || !grepl('^[+-]?[0-9]+$', day)) stop('El dia textual no és un enter decimal vàlid.')
    return(TRUE)
  }
  if (length(day) != 1L || typeof(day) != "integer" || is.na(day)) stop('El dia numèric no és un enter exacte de R; useu una cadena decimal.')
  TRUE
}

bootstrap_dispatch <- function(ctx) {
  ctx$branchTrace <- c(ctx$branchTrace, 'VALIDATE_INPUT')
  bootstrap_validate_integer_day(ctx$calculationDay)
  bootstrap_validate_integer_day(ctx$targetDay)
  ctx$status <- 'BOOTSTRAP_READY'
  ctx <- bootstrap_metrics_bump(ctx, 'bootstrap.validated')
  ctx
}

calendarDateSpaghetti <- function(calculationDay, targetDay) {
  ctx <- new_monster_context(calculationDay, targetDay)
  ctx <- bootstrap_dispatch(ctx)
  stop('Stage 1 només crea l\'esquelet de producció; la ruta semàntica històrica encara no existeix.')
}
