package pastafari.monster

/**
 * PATCH 12: il limite annuale normativo è inclusivo a 5778 giorni.
 * La cicatrice DISCOVERY 12 conserva il tetto 5777 e viene eseguita
 * davvero prima di pubblicare il giudizio corretto nello stesso contesto.
 */
final case class Patch12YearCeilingResult(
  historical: LegacyYearCeilingResult,
  normativeMaximum: Int,
  correctedAccepted: Boolean
)

object Patch12YearCeilingWrapper {
  def yearMaxPatch(gaps: Vector[Int]): Patch12YearCeilingResult = {
    val historical=LegacyYearCeilingAdapter.legacyYearMax(gaps)
    val canonicalMaximum=5778
    val accepted=gaps.length>=6 &&
      historical.yearLength>=252 &&
      historical.yearLength<=canonicalMaximum
    Patch12YearCeilingResult(historical,canonicalMaximum,accepted)
  }
}

final case class Patch12YearCeilingReport(
  calculationDay: BigInt,targetDay: BigInt,
  gateGaps: Vector[Int],yearLength: BigInt,
  legacyAccepted: Boolean,legacyMaximum: Int,
  patchedAccepted: Boolean,patchedMaximum: Int,
  patchApplied: Boolean,
  phase: String,status: String,trace: Vector[String]
)

final class Patch12YearCeilingHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_12_YEAR_CEILING"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status!="LEGACY_YEAR_CEILING_READY" ||
        ctx.branchTrace.toVector !=
          Vector("BOOT","DISCOVERY_12_YEAR_CEILING") ||
        ctx.legacyYearGapsInput.isEmpty ||
        ctx.legacyYearLengthOutput.isEmpty ||
        ctx.legacyYearAcceptedOutput.isEmpty ||
        ctx.legacyYearMaxOutput.isEmpty ||
        ctx.patchedYearAcceptedOutput.nonEmpty ||
        ctx.patchedYearMaxOutput.nonEmpty ||
        ctx.patch12Applied) {
      throw new IllegalStateException(
        "PATCH 12 richiede una discovery completa e non alterata.")
    }
    val result=Patch12YearCeilingWrapper.yearMaxPatch(
      ctx.legacyYearGapsInput.get)
    if (result.historical.yearLength!=ctx.legacyYearLengthOutput.get ||
        result.historical.oldMaximum!=ctx.legacyYearMaxOutput.get ||
        result.historical.accepted!=ctx.legacyYearAcceptedOutput.get) {
      throw new IllegalStateException("Il tetto legacy è stato modificato.")
    }
    ctx.patchedYearAcceptedOutput=Some(result.correctedAccepted)
    ctx.patchedYearMaxOutput=Some(result.normativeMaximum)
    ctx.patch12Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch12.year.ceiling.calls")
    ctx.status="PATCH_12_READY"
  }
}
