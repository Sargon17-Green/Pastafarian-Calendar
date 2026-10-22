package pastafari.monster

/** DISCOVERY22: tessitura dell'anno già scelta; il vecchio ponte
  * attribuisce il numero assoluto del giorno come giorno nel mese.
  * Il numero normativo è il conteggio delle occorrenze precedenti
  * del mese, inclusa l'occorrenza corrente; qui resta NON corretto.
  */
final case class LegacyMonthOrdinalGlobalDayResult(
  annualWeaving: Vector[Int],
  dayOffset: Int,
  selectedMonthId: Int,
  legacyDayInMonth: Int
)

object LegacyMonthOrdinalGlobalDayAdapter {
  def oldMonthOrdinalGlobalDay(
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): LegacyMonthOrdinalGlobalDayResult = {
    LegacyDaywiseWeavingAdapter.validateCandidates(
      Vector(annualWeaving))
    require(dayOffset>=0 && dayOffset<annualWeaving.size,
      "Giorno fuori dalla tessitura.")
    // CICATRICE: il giorno della struttura annuale e' scambiato
    // con il giorno d'occorrenza del mese selezionato.
    LegacyMonthOrdinalGlobalDayResult(
      annualWeaving,dayOffset,annualWeaving(dayOffset),dayOffset+1)
  }
}

final case class Discovery22MonthOrdinalGlobalDayReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  dayOffset: Int,
  selectedMonthId: Int,
  legacyDayInMonth: Int,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery22MonthOrdinalGlobalDayHandler(
  metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.monthOrdinalWeaving.isEmpty ||
       ctx.monthOrdinalDayOffset.isEmpty ||
       ctx.monthOrdinalSnapshot.nonEmpty ||
       ctx.legacyMonthOrdinalMonthId.nonEmpty ||
       ctx.legacyDayInMonth.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY22 richiede un bootstrap nuovo e input integri.")
    val result=LegacyMonthOrdinalGlobalDayAdapter
      .oldMonthOrdinalGlobalDay(
        ctx.monthOrdinalWeaving.get,ctx.monthOrdinalDayOffset.get)
    ctx.monthOrdinalSnapshot=Some((
      result.annualWeaving,result.dayOffset))
    ctx.legacyMonthOrdinalMonthId=Some(result.selectedMonthId)
    ctx.legacyDayInMonth=Some(result.legacyDayInMonth)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery22.month.ordinal.calls")
    ctx.status="LEGACY_MONTH_ORDINAL_READY"
  }
}
