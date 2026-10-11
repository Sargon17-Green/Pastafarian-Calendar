package pastafari.monster

/**
 * PATCH 02: conserva oldDayTag e la sua numerazione simmetrica.
 * Non riscrive il legacy adapter e non importa l'oracolo test-only.
 */
object Patch02DayTagWrapper {
  private val FoundationDay: BigInt = BigInt(-15055671)

  def dayTagPatch(day: BigInt): BigInt = {
    val legacy = LegacyDayTagAdapter.oldDayTag(day)
    if (day >= FoundationDay) legacy + 1 else legacy
  }
}

final case class Patch02DayTagReport(
  queriedDay: BigInt,
  legacyTag: BigInt,
  patchedTag: BigInt,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch02DayTagHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "PATCH_02_DAY_TAG"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_DAY_TAG_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_02_DAY_TAG") ||
        ctx.legacyDayTagInput.isEmpty ||
        ctx.legacyDayTagOutput.isEmpty) {
      throw new IllegalStateException(
        "PATCH 02 richiede il percorso DISCOVERY 02 della stessa invocazione."
      )
    }
    ctx.patchedDayTagOutput = Some(Patch02DayTagWrapper.dayTagPatch(ctx.legacyDayTagInput.get))
    ctx.patch02Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch02.daytag.calls")
    ctx.status = "PATCH_02_READY"
  }
}
