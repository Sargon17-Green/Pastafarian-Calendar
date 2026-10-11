package pastafari.monster

/**
 * DISCOVERY 03: errore di distanza a estremi esclusi.
 * Il numero di intervalli fra due giorni è scambiato per il numero
 * inclusivo dei giorni di lavoro. Non correggere qui l'errore di +1.
 */
object LegacyDistanceAdapter {
  def oldDistance(calculationDay: BigInt, targetDay: BigInt): BigInt =
    (targetDay - calculationDay).abs
}

final case class Discovery03DistanceReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  legacyDistance: BigInt,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery03DistanceHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_03_DISTANCE"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.legacyDistanceOutput.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 03 richiede un Bootstrap nuovo nella stessa invocazione."
      )
    }
    ctx.legacyDistanceOutput = Some(
      LegacyDistanceAdapter.oldDistance(ctx.calculationDay, ctx.targetDay)
    )
    ctx.branchTrace.append(phase)
    metrics.bump("discovery03.distance.calls")
    ctx.status = "LEGACY_DISTANCE_READY"
  }
}
