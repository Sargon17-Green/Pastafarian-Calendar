package pastafari.monster

/**
 * PATCH 05 — la lettura del precedente settimo è i-7.
 * Invoca realmente l'adattatore legacy, ma non lo modifica.
 * I ritardi uno e tre riutilizzano integralmente il vecchio risultato.
 */
object Patch05PriorWrapper {
  def priorPatch(hidden: Vector[BigInt], visible: Vector[BigInt], index: Int, lag: Int): BigInt = {
    val old = LegacyPriorAdapter.legacyPrior(hidden, visible, index, lag)
    if (lag != 7) old
    else {
      val position = index - 7
      if (position <= 0) hidden(-position) else visible(position - 1)
    }
  }
}

final case class Patch05PriorReport(
  calculationDay: BigInt, targetDay: BigInt,
  hiddenDrops: Vector[BigInt], visibleDropsSoFar: Vector[BigInt],
  index: Int, lag: Int, legacyValue: BigInt, patchedValue: BigInt,
  patchApplied: Boolean, phase: String, status: String, trace: Vector[String]
)

final class Patch05PriorHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "PATCH_05_PRIOR"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_PRIOR_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_05_PRIOR") ||
        ctx.priorHiddenInput.isEmpty || ctx.priorVisibleInput.isEmpty ||
        ctx.priorIndexInput.isEmpty || ctx.priorLagInput.isEmpty ||
        ctx.legacyPriorOutput.isEmpty || ctx.patchedPriorOutput.nonEmpty ||
        ctx.patch05Applied) {
      throw new IllegalStateException("PATCH 05 richiede DISCOVERY 05 reale nella stessa invocazione.")
    }
    ctx.patchedPriorOutput = Some(
      Patch05PriorWrapper.priorPatch(
        ctx.priorHiddenInput.get, ctx.priorVisibleInput.get,
        ctx.priorIndexInput.get, ctx.priorLagInput.get
      )
    )
    ctx.patch05Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch05.prior.calls")
    ctx.status = "PATCH_05_READY"
  }
}
