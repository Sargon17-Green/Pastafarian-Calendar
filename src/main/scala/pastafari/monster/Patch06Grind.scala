package pastafari.monster

/**
 * PATCH 06: il sentinel storico sopravvive e il helper legacy viene davvero eseguito.
 * L'unica correzione di indice è da (step - 1) a step per la regola attiva.
 * Il riferimento normativo resta esclusivamente nei test e non entra nel prodotto.
 */
object Patch06GrindWrapper {
  def rulePatch(step: Int): LegacyGrindRule = {
    // Esegue il lookup storico anche quando la sua risposta non è utilizzabile.
    LegacyGrindTableAdapter.legacyGrindRule(step)
    LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL(step)
  }

  def grindPatch(step: Int, oldValue: BigInt, previous1: BigInt,
                 previous3: BigInt, previous7: BigInt,
                 stones: Vector[BigInt]): BigInt = {
    // Attraversa il vero calcolo legacy: non lo ricostruisce a posteriori.
    LegacyGrindTableAdapter.legacyGrind(
      step, oldValue, previous1, previous3, previous7, stones
    )
    val rule = rulePatch(step)
    Patch01SaveWrapper.savePatch(
      oldValue * oldValue + rule.a * oldValue +
        rule.b * previous1 + rule.c * previous3 +
        rule.d * previous7 + stones(rule.stoneKind)
    )
  }
}

final case class Patch06GrindReport(
  calculationDay: BigInt, targetDay: BigInt,
  step: Int, oldValue: BigInt, previous1: BigInt,
  previous3: BigInt, previous7: BigInt, stones: Vector[BigInt],
  legacyRule: LegacyGrindRule, legacyValue: BigInt,
  patchedRule: LegacyGrindRule, patchedValue: BigInt,
  patchApplied: Boolean,
  phase: String, status: String, trace: Vector[String]
)

final class Patch06GrindHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "PATCH_06_GRIND"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_GRIND_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_06_GRIND") ||
        ctx.grindStepInput.isEmpty || ctx.grindValueInput.isEmpty ||
        ctx.grindPrev1Input.isEmpty || ctx.grindPrev3Input.isEmpty ||
        ctx.grindPrev7Input.isEmpty || ctx.grindStonesInput.isEmpty ||
        ctx.legacyGrindRuleOutput.isEmpty || ctx.legacyGrindOutput.isEmpty ||
        ctx.patchedGrindOutput.nonEmpty || ctx.patchedGrindRuleOutput.nonEmpty ||
        ctx.patch06Applied) {
      throw new IllegalStateException("PATCH 06 richiede la DISCOVERY 06 in questa invocazione.")
    }
    val step = ctx.grindStepInput.get
    val rule = Patch06GrindWrapper.rulePatch(step)
    val value = Patch06GrindWrapper.grindPatch(
      step, ctx.grindValueInput.get, ctx.grindPrev1Input.get,
      ctx.grindPrev3Input.get, ctx.grindPrev7Input.get, ctx.grindStonesInput.get
    )
    ctx.patchedGrindRuleOutput = Some(rule)
    ctx.patchedGrindOutput = Some(value)
    ctx.patch06Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch06.grind.calls")
    ctx.status = "PATCH_06_READY"
  }
}
