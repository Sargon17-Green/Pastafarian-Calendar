package pastafari.monster

/** DISCOVERY24: difetto di collegamento fra cotolette e mesi.
  * Il ponte storico usa il giorno locale della cotoletta per
  * indicizzare la tessitura dell'intero anno. L'anno e i suoi
  * segmenti sono input già scelti; nessuna salsa generata.
  */
final case class LegacyCutletLocalMonthResult(
  gateGaps: Vector[Int],
  cutletPartition: Vector[Int],
  annualWeaving: Vector[Int],
  yearDayOffset: Int,
  cutletId: Int,
  cutletLocalOffset: Int,
  legacyMonthId: Int,
  legacyDayInMonth: Int
)

object LegacyCutletLocalMonthAdapter {
  def oldCutletLocalMonthLookup(
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    annualWeaving: Vector[Int],
    yearDayOffset: Int
  ): LegacyCutletLocalMonthResult = {
    require(cutletPartition.length>=6 && cutletPartition.length<=17,
      "Servono da sei a diciassette cotolette.")
    require(cutletPartition.forall(_>=1) &&
      cutletPartition.sum==gateGaps.length,
      "Partizione delle porte incoerente.")
    require(gateGaps.forall(g=>g>=42 && g<=963) &&
      gateGaps.sum>=252 && gateGaps.sum<=5778,
      "Durata delle porte non valida.")
    require(annualWeaving.length==gateGaps.sum,
      "La tessitura deve coprire esattamente l'anno.")
    LegacyDaywiseWeavingAdapter.validateCandidates(Vector(annualWeaving))
    require(yearDayOffset>=0 && yearDayOffset<annualWeaving.length,
      "Giorno fuori dall'anno.")

    val starts=cutletPartition.scanLeft(0)(_+_).init
      .map(k=>gateGaps.take(k).sum)
    val cutlet=starts.count(_<=yearDayOffset)
    val local=yearDayOffset-starts(cutlet-1)
    // CICATRICE: local e' un offset NELLA COTOLETTA,
    // NON nella tessitura annuale.
    val month=annualWeaving(local)
    val ordinal=annualWeaving.take(local+1).count(_==month)
    LegacyCutletLocalMonthResult(
      gateGaps,cutletPartition,annualWeaving,yearDayOffset,
      cutlet,local,month,ordinal)
  }
}

final case class Discovery24CutletLocalMonthReport(
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
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery24CutletLocalMonthHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.crossGateGaps.isEmpty || ctx.crossCutletPartition.isEmpty ||
       ctx.crossAnnualWeaving.isEmpty || ctx.crossYearDayOffset.isEmpty ||
       ctx.crossInputSnapshot.nonEmpty ||
       ctx.crossLegacyCutletId.nonEmpty ||
       ctx.crossLegacyLocalOffset.nonEmpty ||
       ctx.crossLegacyMonthId.nonEmpty ||
       ctx.crossLegacyMonthOrdinal.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY24 richiede un bootstrap pulito.")
    val r=LegacyCutletLocalMonthAdapter.oldCutletLocalMonthLookup(
      ctx.crossGateGaps.get,ctx.crossCutletPartition.get,
      ctx.crossAnnualWeaving.get,ctx.crossYearDayOffset.get)
    ctx.crossInputSnapshot=Some((
      r.gateGaps,r.cutletPartition,r.annualWeaving,r.yearDayOffset))
    ctx.crossLegacyCutletId=Some(r.cutletId)
    ctx.crossLegacyLocalOffset=Some(r.cutletLocalOffset)
    ctx.crossLegacyMonthId=Some(r.legacyMonthId)
    ctx.crossLegacyMonthOrdinal=Some(r.legacyDayInMonth)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery24.cutlet.local.month.calls")
    ctx.status="LEGACY_CUTLET_LOCAL_MONTH_READY"
  }
}
