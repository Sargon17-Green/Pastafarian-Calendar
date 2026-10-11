package pastafari.monster

/** DISCOVERY 05: errore storico nella lettura della settima goccia precedente. */
object LegacyPriorAdapter {
  def legacyPrior(hidden: Vector[BigInt], visible: Vector[BigInt], index: Int, lag: Int): BigInt = {
    require(index >= 1 && index <= 47, "Indice della goccia non valido.")
    require(hidden.length == 7, "Servono sette gocce nascoste.")
    require(visible.length == index - 1, "Finestra visibile incompleta o anticipata.")
    require(lag == 1 || lag == 3 || lag == 7, "Ritardo non valido.")
    // Cicatrice intenzionale: lag 7 punta a i-6 anziché a i-7.
    val sourceIndex = index - (if (lag == 7) 6 else lag)
    if (sourceIndex <= 0) hidden(-sourceIndex) else visible(sourceIndex - 1)
  }
}

final case class Discovery05PriorReport(
  calculationDay: BigInt, targetDay: BigInt,
  hiddenDrops: Vector[BigInt], visibleDropsSoFar: Vector[BigInt],
  index: Int, lag: Int, legacyValue: BigInt,
  phase: String, status: String, trace: Vector[String]
)

final class Discovery05PriorHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_05_PRIOR"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.priorHiddenInput.isEmpty || ctx.priorVisibleInput.isEmpty ||
        ctx.priorIndexInput.isEmpty || ctx.priorLagInput.isEmpty ||
        ctx.legacyPriorOutput.nonEmpty) {
      throw new IllegalStateException("DISCOVERY 05 richiede il bootstrap della stessa invocazione.")
    }
    ctx.legacyPriorOutput = Some(LegacyPriorAdapter.legacyPrior(
      ctx.priorHiddenInput.get, ctx.priorVisibleInput.get,
      ctx.priorIndexInput.get, ctx.priorLagInput.get
    ))
    ctx.branchTrace.append(phase)
    metrics.bump("discovery05.prior.calls")
    ctx.status = "LEGACY_PRIOR_READY"
  }
}
