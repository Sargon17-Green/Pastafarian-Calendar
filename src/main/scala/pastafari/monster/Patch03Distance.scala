package pastafari.monster

/** PATCH 03 conserva realmente il helper storico e aggiunge il giorno iniziale. */
object Patch03DistanceWrapper {
  def distancePatch(calculationDay: BigInt, targetDay: BigInt): BigInt =
    LegacyDistanceAdapter.oldDistance(calculationDay, targetDay) + 1
}

final case class Patch03DistanceReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  legacyDistance: BigInt,
  patchedDistance: BigInt,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch03DistanceHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "PATCH_03_DISTANCE"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_DISTANCE_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_03_DISTANCE") ||
        ctx.legacyDistanceOutput.isEmpty ||
        ctx.patchedDistanceOutput.nonEmpty || ctx.patch03Applied) {
      throw new IllegalStateException(
        "PATCH 03 richiede la vera DISCOVERY 03 della stessa invocazione."
      )
    }
    ctx.patchedDistanceOutput = Some(
      Patch03DistanceWrapper.distancePatch(ctx.calculationDay, ctx.targetDay)
    )
    ctx.patch03Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch03.distance.calls")
    ctx.status = "PATCH_03_READY"
  }
}
