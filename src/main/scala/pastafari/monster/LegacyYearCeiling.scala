package pastafari.monster

/**
 * DISCOVERY 12: il limite superiore storico per la lunghezza
 * dell'anno era 5777 giorni, anziché i 5778 canonici.
 * I cancelli sono rappresentati da divari consecutivi, ciascuno
 * fra 42 e 963 giorni, con almeno sei intervalli nell'anno valido.
 * Non introdurre PATCH 12 in questa discovery.
 */
final case class LegacyYearCeilingResult(
  gateGaps: Vector[Int],
  yearLength: BigInt,
  oldMaximum: Int,
  accepted: Boolean
)

object LegacyYearCeilingAdapter {
  private val LEGACY_YEAR_MAX: Int = 5777

  def legacyYearMax(gaps: Vector[Int]): LegacyYearCeilingResult = {
    require(gaps.nonEmpty,"È necessario almeno un divario di cancello.")
    require(gaps.forall(x=>x>=42 && x<=963),
      "Ciascun divario deve essere compreso fra 42 e 963 giorni.")
    val length=gaps.foldLeft(BigInt(0))((acc,g)=>acc+BigInt(g))
    val accepted=gaps.length>=6 && length>=252 && length<=LEGACY_YEAR_MAX
    LegacyYearCeilingResult(gaps,length,LEGACY_YEAR_MAX,accepted)
  }
}

final case class Discovery12YearCeilingReport(
  calculationDay: BigInt,targetDay: BigInt,
  gateGaps: Vector[Int],yearLength: BigInt,
  legacyAccepted: Boolean,oldMaximum: Int,
  phase: String,status: String,trace: Vector[String]
)

final class Discovery12YearCeilingHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_12_YEAR_CEILING"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status!="BOOTSTRAPPED" ||
        ctx.branchTrace.toVector!=Vector("BOOT") ||
        ctx.legacyYearGapsInput.isEmpty ||
        ctx.legacyYearLengthOutput.nonEmpty ||
        ctx.legacyYearAcceptedOutput.nonEmpty ||
        ctx.legacyYearMaxOutput.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 12 richiede un Bootstrap nuovo e divari non elaborati.")
    }
    val result=LegacyYearCeilingAdapter.legacyYearMax(
      ctx.legacyYearGapsInput.get)
    ctx.legacyYearLengthOutput=Some(result.yearLength)
    ctx.legacyYearAcceptedOutput=Some(result.accepted)
    ctx.legacyYearMaxOutput=Some(result.oldMaximum)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery12.year.ceiling.calls")
    ctx.status="LEGACY_YEAR_CEILING_READY"
  }
}
