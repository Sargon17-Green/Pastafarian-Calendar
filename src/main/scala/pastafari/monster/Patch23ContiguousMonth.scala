package pastafari.monster

/** PATCH23: elimina l'assunzione che ogni mese sia un blocco
  * contiguo. Conserva il risultato dell'adapter storico
  * DISCOVERY23 con mese e durate non modificate.
  *
  * L'anno e' già selezionato, la salsa annuale resta fuori fase.
  */
final case class Patch23ContiguousMonthResult(
  historical: LegacyContiguousMonthResult,
  correctedDayInMonth: Int
)

object Patch23ContiguousMonthWrapper {
  def contiguousMonthPatch(
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): Patch23ContiguousMonthResult = {
    val old=LegacyContiguousMonthAdapter.oldContiguousDayInMonth(
      annualWeaving,dayOffset)
    val month=old.selectedMonthId
    // Il giorno nel mese è il numero di occorrenze di tale ID
    // nel prefisso incluso il giorno stesso, non una sottrazione
    // della somma delle durate dei mesi precedenti.
    val ordinal=annualWeaving.view.take(dayOffset+1)
      .count(_==month)
    Patch23ContiguousMonthResult(old,ordinal)
  }
}

final case class Patch23ContiguousMonthReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  dayOffset: Int,
  monthLengths: Vector[Int],
  selectedMonthId: Int,
  legacyDayInMonth: Int,
  correctedDayInMonth: Int,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch23ContiguousMonthHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_23_CONTIGUOUS_MONTH_ASSUMPTION"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="LEGACY_CONTIGUOUS_MONTH_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION") ||
       ctx.monthBlockWeaving.isEmpty || ctx.monthBlockDayOffset.isEmpty ||
       ctx.monthBlockSnapshot.isEmpty ||
       ctx.legacyMonthBlockLengths.isEmpty ||
       ctx.legacyMonthBlockMonthId.isEmpty ||
       ctx.legacyMonthBlockOrdinal.isEmpty ||
       ctx.patch23CorrectedDayInMonth.nonEmpty || ctx.patch23Applied)
      throw new IllegalStateException(
        "PATCH23 richiede una DISCOVERY23 integra.")
    val w=ctx.monthBlockWeaving.get
    val day=ctx.monthBlockDayOffset.get
    if(ctx.monthBlockSnapshot.get!=(w,day))
      throw new IllegalStateException(
        "Input modificato dopo DISCOVERY23.")

    val result=Patch23ContiguousMonthWrapper.contiguousMonthPatch(w,day)
    if(result.historical.annualWeaving!=w ||
       result.historical.dayOffset!=day ||
       result.historical.monthLengths!=ctx.legacyMonthBlockLengths.get ||
       result.historical.selectedMonthId!=ctx.legacyMonthBlockMonthId.get ||
       result.historical.legacyDayInMonth!=ctx.legacyMonthBlockOrdinal.get)
      throw new IllegalStateException(
        "Cicatrice DISCOVERY23 non corrispondente.")

    ctx.patch23CorrectedDayInMonth=Some(result.correctedDayInMonth)
    ctx.patch23Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch23.contiguous.month.calls")
    ctx.status="PATCH_23_READY"
  }
}
