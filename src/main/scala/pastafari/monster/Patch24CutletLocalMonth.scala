package pastafari.monster

/** PATCH24: la tessitura annuale si consulta usando dayOffset
  * nell'anno, NON il giorno locale alla cotoletta.
  * Il rapporto include la risposta storica completa.
  * Le strutture annuali sono già selezionate: nessuna salsa.
  */
final case class Patch24CutletLocalMonthResult(
  historical: LegacyCutletLocalMonthResult,
  correctedMonthId: Int,
  correctedDayInMonth: Int
)

object Patch24CutletLocalMonthWrapper {
  def cutletLocalMonthPatch(
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    annualWeaving: Vector[Int],
    yearDayOffset: Int
  ): Patch24CutletLocalMonthResult = {
    val historical=LegacyCutletLocalMonthAdapter.oldCutletLocalMonthLookup(
      gateGaps,cutletPartition,annualWeaving,yearDayOffset)
    val month=annualWeaving(yearDayOffset)
    val ordinal=annualWeaving.iterator.take(yearDayOffset+1)
      .count(_==month)
    Patch24CutletLocalMonthResult(historical,month,ordinal)
  }
}

final case class Patch24CutletLocalMonthReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  gateGaps: Vector[Int],
  cutletPartition: Vector[Int],
  annualWeaving: Vector[Int],
  yearDayOffset: Int,
  cutletId: Int,
  cutletLocalOffset: Int,
  legacyMonthId: Int,
  legacyDayInMonth: Int,
  correctedMonthId: Int,
  correctedDayInMonth: Int,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch24CutletLocalMonthHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_24_CUTLET_LOCAL_MONTH_LOOKUP"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="LEGACY_CUTLET_LOCAL_MONTH_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP") ||
       ctx.crossGateGaps.isEmpty || ctx.crossCutletPartition.isEmpty ||
       ctx.crossAnnualWeaving.isEmpty || ctx.crossYearDayOffset.isEmpty ||
       ctx.crossInputSnapshot.isEmpty ||
       ctx.crossLegacyCutletId.isEmpty ||
       ctx.crossLegacyLocalOffset.isEmpty ||
       ctx.crossLegacyMonthId.isEmpty ||
       ctx.crossLegacyMonthOrdinal.isEmpty ||
       ctx.patch24MonthId.nonEmpty ||
       ctx.patch24DayInMonth.nonEmpty || ctx.patch24Applied)
      throw new IllegalStateException(
        "PATCH24 richiede una DISCOVERY24 integra.")
    val gaps=ctx.crossGateGaps.get
    val parts=ctx.crossCutletPartition.get
    val woven=ctx.crossAnnualWeaving.get
    val day=ctx.crossYearDayOffset.get
    if(ctx.crossInputSnapshot.get!=(gaps,parts,woven,day))
      throw new IllegalStateException("Input cambiati dopo DISCOVERY24.")
    val result=Patch24CutletLocalMonthWrapper.cutletLocalMonthPatch(
      gaps,parts,woven,day)
    if(result.historical.gateGaps!=gaps ||
       result.historical.cutletPartition!=parts ||
       result.historical.annualWeaving!=woven ||
       result.historical.yearDayOffset!=day ||
       result.historical.cutletId!=ctx.crossLegacyCutletId.get ||
       result.historical.cutletLocalOffset!=
         ctx.crossLegacyLocalOffset.get ||
       result.historical.legacyMonthId!=ctx.crossLegacyMonthId.get ||
       result.historical.legacyDayInMonth!=
         ctx.crossLegacyMonthOrdinal.get)
      throw new IllegalStateException("Cicatrice DISCOVERY24 falsificata.")

    ctx.patch24MonthId=Some(result.correctedMonthId)
    ctx.patch24DayInMonth=Some(result.correctedDayInMonth)
    ctx.patch24Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch24.cutlet.month.calls")
    ctx.status="PATCH_24_READY"
  }
}
