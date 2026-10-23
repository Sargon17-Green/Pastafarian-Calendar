package pastafari.monster

/** PATCH22: il giorno nel mese conta le sole occorrenze del mese
  * selezionato nella tessitura annuale già fissata. Preserva
  * integralmente la risposta storica del giorno assoluto+1.
  */
final case class Patch22MonthOrdinalGlobalDayResult(
  historical: LegacyMonthOrdinalGlobalDayResult,
  correctedDayInMonth: Int
)

object Patch22MonthOrdinalGlobalDayWrapper {
  def monthOrdinalPatch(
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): Patch22MonthOrdinalGlobalDayResult = {
    val old=LegacyMonthOrdinalGlobalDayAdapter
      .oldMonthOrdinalGlobalDay(annualWeaving,dayOffset)
    val month=old.selectedMonthId
    val count=annualWeaving.iterator.take(dayOffset+1).count(_==month)
    Patch22MonthOrdinalGlobalDayResult(old,count)
  }
}

final case class Patch22MonthOrdinalGlobalDayReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  dayOffset: Int,
  selectedMonthId: Int,
  legacyDayInMonth: Int,
  correctedDayInMonth: Int,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch22MonthOrdinalGlobalDayHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_22_MONTH_ORDINAL_GLOBAL_DAY"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="LEGACY_MONTH_ORDINAL_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY") ||
       ctx.monthOrdinalWeaving.isEmpty ||
       ctx.monthOrdinalDayOffset.isEmpty ||
       ctx.monthOrdinalSnapshot.isEmpty ||
       ctx.legacyMonthOrdinalMonthId.isEmpty ||
       ctx.legacyDayInMonth.isEmpty ||
       ctx.patchedDayInMonth.nonEmpty || ctx.patch22Applied)
      throw new IllegalStateException(
        "PATCH22 richiede DISCOVERY22 integra.")
    val w=ctx.monthOrdinalWeaving.get
    val day=ctx.monthOrdinalDayOffset.get
    if(ctx.monthOrdinalSnapshot.get!=(w,day))
      throw new IllegalStateException("Snapshot modificata dopo DISCOVERY22.")
    val result=Patch22MonthOrdinalGlobalDayWrapper
      .monthOrdinalPatch(w,day)
    if(result.historical.annualWeaving!=w ||
       result.historical.dayOffset!=day ||
       result.historical.selectedMonthId!=
         ctx.legacyMonthOrdinalMonthId.get ||
       result.historical.legacyDayInMonth!=ctx.legacyDayInMonth.get)
      throw new IllegalStateException("Cicatrice DISCOVERY22 manomessa.")
    ctx.patchedDayInMonth=Some(result.correctedDayInMonth)
    ctx.patch22Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch22.month.ordinal.calls")
    ctx.status="PATCH_22_READY"
  }
}
