package pastafari.monster

/**
 * DISCOVERY 16: la tessitura annuale è già fissata. Questo vecchio
 * percorso presume ERRONEAMENTE che i giorni di ogni mese siano
 * contigui nella sequenza, sottraendo tutte le durate dei mesi
 * precedenti dal giorno assoluto dell'anno.
 *
 * Famiglia sintetica diagnostica: NON costruisce la salsa, le
 * famiglie normative o le porte reali dell'anno.
 */
final case class LegacyContiguousMonthDayResult(
  annualWeaving: Vector[Int],
  dayOffset: Int,
  monthLengths: Vector[Int],
  selectedMonthId: Int,
  assumedMonthStartOffset: Int,
  guessedDayInMonth: Int
)

object LegacyContiguousMonthDayAdapter {
  def oldContiguousMonthDayGuess(
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): LegacyContiguousMonthDayResult = {
    // Stessa validazione di una tessitura lecita, ma nessuna
    // rielezione giornaliera della tessitura.
    LegacyDaywiseWeavingAdapter.validateCandidates(Vector(annualWeaving))
    require(dayOffset>=0 && dayOffset<annualWeaving.length,
      "Giorno fuori dalla tessitura annuale.")

    val monthCount=annualWeaving.max
    val monthLengths=Vector.tabulate(monthCount)(j=>
      annualWeaving.count(_==j+1))
    val month=annualWeaving(dayOffset)
    val assumedStart=monthLengths.take(month-1).sum

    // DIFETTO STORICO REALE: presuppone blocchi contigui,
    // anche se il mese è aperto e chiuso con giorni intercalati.
    val oldDay=dayOffset-assumedStart+1
    LegacyContiguousMonthDayResult(
      annualWeaving,dayOffset,monthLengths,month,assumedStart,oldDay)
  }
}

final case class Discovery16ContiguousMonthDayReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  dayOffset: Int,
  monthLengths: Vector[Int],
  selectedMonthId: Int,
  assumedMonthStartOffset: Int,
  legacyDayInMonth: Int,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery16ContiguousMonthDayHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.contiguousAnnualWeaving.isEmpty ||
       ctx.contiguousDayOffset.isEmpty ||
       ctx.contiguousInputSnapshot.nonEmpty ||
       ctx.legacyContiguousMonthLengths.nonEmpty ||
       ctx.legacyContiguousSelectedMonthId.nonEmpty ||
       ctx.legacyContiguousAssumedStartOffset.nonEmpty ||
       ctx.legacyContiguousDayInMonth.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY 16 richiede un Bootstrap nuovo e input completi.")

    val result=LegacyContiguousMonthDayAdapter.oldContiguousMonthDayGuess(
      ctx.contiguousAnnualWeaving.get,ctx.contiguousDayOffset.get)
    ctx.contiguousInputSnapshot=Some((result.annualWeaving,result.dayOffset))
    ctx.legacyContiguousMonthLengths=Some(result.monthLengths)
    ctx.legacyContiguousSelectedMonthId=Some(result.selectedMonthId)
    ctx.legacyContiguousAssumedStartOffset=Some(result.assumedMonthStartOffset)
    ctx.legacyContiguousDayInMonth=Some(result.guessedDayInMonth)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery16.contiguous.month.day.calls")
    ctx.status="LEGACY_CONTIGUOUS_MONTH_DAY_READY"
  }
}
