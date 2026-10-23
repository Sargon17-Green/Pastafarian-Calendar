package pastafari.monster

/** DISCOVERY23: l'errore storico suppone che i mesi occupino
  * blocchi contigui, anche quando la tessitura annuale è intrecciata.
  *
  * Gli ID dei mesi della tessitura sono già selezionati.
  * Non produce alcuna salsa annuale, né altera l'ordine dei mesi.
  */
final case class LegacyContiguousMonthResult(
  annualWeaving: Vector[Int],
  dayOffset: Int,
  monthLengths: Vector[Int],
  selectedMonthId: Int,
  legacyDayInMonth: Int
)

object LegacyContiguousMonthAdapter {
  def oldContiguousDayInMonth(
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): LegacyContiguousMonthResult = {
    LegacyDaywiseWeavingAdapter.validateCandidates(Vector(annualWeaving))
    require(dayOffset>=0 && dayOffset<annualWeaving.size,
      "Giorno fuori dalla tessitura selezionata.")
    val monthCount=annualWeaving.max
    val lengths=Vector.tabulate(monthCount)(j=>
      annualWeaving.count(_==j+1))
    val selectedMonth=annualWeaving(dayOffset)
    // CICATRICE INTENZIONALE: i mesi sarebbero blocchi consecutivi.
    val presumedStart=lengths.take(selectedMonth-1).sum
    LegacyContiguousMonthResult(
      annualWeaving,dayOffset,lengths,selectedMonth,
      dayOffset-presumedStart+1)
  }
}

final case class Discovery23ContiguousMonthReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  dayOffset: Int,
  monthLengths: Vector[Int],
  selectedMonthId: Int,
  legacyDayInMonth: Int,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery23ContiguousMonthHandler(
  metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.monthBlockWeaving.isEmpty || ctx.monthBlockDayOffset.isEmpty ||
       ctx.monthBlockSnapshot.nonEmpty ||
       ctx.legacyMonthBlockLengths.nonEmpty ||
       ctx.legacyMonthBlockMonthId.nonEmpty ||
       ctx.legacyMonthBlockOrdinal.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY23 richiede bootstrap nuovo e input non alterati.")
    val old=LegacyContiguousMonthAdapter.oldContiguousDayInMonth(
      ctx.monthBlockWeaving.get,ctx.monthBlockDayOffset.get)
    ctx.monthBlockSnapshot=Some((old.annualWeaving,old.dayOffset))
    ctx.legacyMonthBlockLengths=Some(old.monthLengths)
    ctx.legacyMonthBlockMonthId=Some(old.selectedMonthId)
    ctx.legacyMonthBlockOrdinal=Some(old.legacyDayInMonth)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery23.contiguous.month.calls")
    ctx.status="LEGACY_CONTIGUOUS_MONTH_READY"
  }
}
