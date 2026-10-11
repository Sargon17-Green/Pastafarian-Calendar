package pastafari.monster

/**
 * DISCOVERY 02: la formula legacy perde il lato temporale della Fondazione.
 * La cicatrice rimane errata e non viene normalizzata in questo stadio.
 */
object LegacyDayTagAdapter {
  private val FoundationDayOld: BigInt = BigInt(-15055671)
  def oldDayTag(day: BigInt): BigInt = BigInt(2) * (day - FoundationDayOld).abs
}

final case class Discovery02DayTagReport(
  queriedDay: BigInt,
  legacyTag: BigInt,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery02DayTagHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_02_DAY_TAG"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" || ctx.branchTrace.toVector != Vector("BOOT")) {
      throw new IllegalStateException("DISCOVERY 02 richiede il Bootstrap della stessa invocazione.")
    }
    val day = ctx.legacyDayTagInput.getOrElse(
      throw new IllegalStateException("Manca il giorno interrogato.")
    )
    ctx.legacyDayTagOutput = Some(LegacyDayTagAdapter.oldDayTag(day))
    ctx.branchTrace.append(phase)
    metrics.bump("discovery02.daytag.calls")
    ctx.status = "LEGACY_DAY_TAG_READY"
  }
}
