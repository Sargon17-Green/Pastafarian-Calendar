package pastafari.monster

/**
 * PATCH 16: il giorno del mese conta le occorrenze dell'ID mensile
 * nel prefisso della tessitura annuale, anche con mesi intercalati.
 * La cicatrice "mesi contigui" viene realmente invocata e conservata.
 *
 * I vettori annuali sono candidati sintetici già scelti: la salsa e la
 * selezione normativa della tessitura restano fuori da questa fase.
 */
final case class Patch16ContiguousMonthDayResult(
  historical: LegacyContiguousMonthDayResult,
  correctedMonthId: Int,
  correctedDayInMonth: Int
)

object Patch16ContiguousMonthDayWrapper {
  def contiguousMonthDayPatch(
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): Patch16ContiguousMonthDayResult = {
    val old=LegacyContiguousMonthDayAdapter.oldContiguousMonthDayGuess(
      annualWeaving,dayOffset)
    // Prima di pubblicare, usa la vera sequenza selezionata per l'anno.
    val month=annualWeaving(dayOffset)
    val position=annualWeaving.iterator.take(dayOffset+1).count(_==month)
    Patch16ContiguousMonthDayResult(old,month,position)
  }
}

final case class Patch16ContiguousMonthDayReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  dayOffset: Int,
  monthLengths: Vector[Int],
  legacySelectedMonthId: Int,
  legacyAssumedMonthStartOffset: Int,
  legacyDayInMonth: Int,
  correctedMonthId: Int,
  correctedDayInMonth: Int,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch16ContiguousMonthDayHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_16_CONTIGUOUS_MONTH_DAY"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_CONTIGUOUS_MONTH_DAY_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_16_CONTIGUOUS_MONTH_DAY") ||
       ctx.contiguousAnnualWeaving.isEmpty ||
       ctx.contiguousDayOffset.isEmpty ||
       ctx.contiguousInputSnapshot.isEmpty ||
       ctx.legacyContiguousMonthLengths.isEmpty ||
       ctx.legacyContiguousSelectedMonthId.isEmpty ||
       ctx.legacyContiguousAssumedStartOffset.isEmpty ||
       ctx.legacyContiguousDayInMonth.isEmpty ||
       ctx.patchedContiguousMonthId.nonEmpty ||
       ctx.patchedContiguousDayInMonth.nonEmpty ||
       ctx.patch16Applied)
      throw new IllegalStateException(
        "PATCH 16 richiede una DISCOVERY 16 integra nella stessa chiamata.")

    val weave=ctx.contiguousAnnualWeaving.get
    val day=ctx.contiguousDayOffset.get
    if(ctx.contiguousInputSnapshot.get!=(weave,day))
      throw new IllegalStateException(
        "Gli input annuali sono mutati dopo la discovery.")

    // Eseguire davvero il legacy; rifiutare ogni manipolazione prima
    // di scrivere un qualsiasi output patch nel contesto.
    val result=Patch16ContiguousMonthDayWrapper.contiguousMonthDayPatch(
      weave,day)
    if(result.historical.annualWeaving!=weave ||
       result.historical.dayOffset!=day ||
       result.historical.monthLengths!=ctx.legacyContiguousMonthLengths.get ||
       result.historical.selectedMonthId!=ctx.legacyContiguousSelectedMonthId.get ||
       result.historical.assumedMonthStartOffset!=
         ctx.legacyContiguousAssumedStartOffset.get ||
       result.historical.guessedDayInMonth!=ctx.legacyContiguousDayInMonth.get)
      throw new IllegalStateException("La cicatrice storica e' stata falsificata.")

    ctx.patchedContiguousMonthId=Some(result.correctedMonthId)
    ctx.patchedContiguousDayInMonth=Some(result.correctedDayInMonth)
    ctx.patch16Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch16.contiguous.month.day.calls")
    ctx.status="PATCH_16_READY"
  }
}
