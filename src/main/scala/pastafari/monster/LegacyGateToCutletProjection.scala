package pastafari.monster

/** DISCOVERY26: confonde ID della porta con ID della cotoletta.
  * Una cotoletta puo' comprendere piu' porte. Input pre-selezionati.
  */
final case class LegacyGateToCutletProjectionResult(
  gateGaps: Vector[Int], cutletPartition: Vector[Int],
  dayOffset: Int, gateId: Int, gateStartOffset: Int,
  legacyCutletId: Int, legacyDayInCutlet: Int
)

object LegacyGateToCutletProjectionAdapter {
  def oldGateToCutletProjection(gateGaps:Vector[Int],
      cutletPartition:Vector[Int],dayOffset:Int):
      LegacyGateToCutletProjectionResult = {
    require(cutletPartition.length>=6 && cutletPartition.length<=17,
      "Servono 6..17 cotolette.")
    require(gateGaps.length>=6 && gateGaps.length<=47,
      "Servono 6..47 porte.")
    require(cutletPartition.forall(_>=1) &&
      cutletPartition.sum==gateGaps.length,
      "Partizione delle porte non valida.")
    require(gateGaps.forall(g=>g>=42 && g<=963) &&
      gateGaps.sum>=252 && gateGaps.sum<=5778,
      "Intervalli annuali non validi.")
    require(dayOffset>=0 && dayOffset<gateGaps.sum,
      "Giorno fuori dall'anno.")
    val starts=gateGaps.scanLeft(0)(_+_).init
    val gate=starts.count(_<=dayOffset)
    val start=starts(gate-1)
    // CICATRICE: gateId e' pubblicato erroneamente come cutletId.
    LegacyGateToCutletProjectionResult(
      gateGaps,cutletPartition,dayOffset,gate,start,
      gate,dayOffset-start+1)
  }
}

final case class Discovery26GateToCutletProjectionReport(
  calculationDay: BigInt, targetDay: BigInt,
  gateGaps: Vector[Int], cutletPartition: Vector[Int],
  dayOffset: Int, gateId: Int, gateStartOffset: Int,
  legacyCutletId: Int, legacyDayInCutlet: Int,
  phase: String, status: String, trace: Vector[String]
)

final class Discovery26GateToCutletProjectionHandler(
  metrics:BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_26_GATE_TO_CUTLET_PROJECTION"
  override def handle(ctx:BaseMonsterContext):Unit={
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.gateProjectionGaps.isEmpty ||
       ctx.gateProjectionPartition.isEmpty ||
       ctx.gateProjectionDayOffset.isEmpty ||
       ctx.gateProjectionSnapshot.nonEmpty ||
       ctx.gateProjectionLegacyGateId.nonEmpty ||
       ctx.gateProjectionLegacyGateStart.nonEmpty ||
       ctx.gateProjectionLegacyCutletId.nonEmpty ||
       ctx.gateProjectionLegacyOrdinal.nonEmpty)
      throw new IllegalStateException("DISCOVERY26 richiede bootstrap pulito.")
    val r=LegacyGateToCutletProjectionAdapter.oldGateToCutletProjection(
      ctx.gateProjectionGaps.get,ctx.gateProjectionPartition.get,
      ctx.gateProjectionDayOffset.get)
    ctx.gateProjectionSnapshot=Some((r.gateGaps,r.cutletPartition,r.dayOffset))
    ctx.gateProjectionLegacyGateId=Some(r.gateId)
    ctx.gateProjectionLegacyGateStart=Some(r.gateStartOffset)
    ctx.gateProjectionLegacyCutletId=Some(r.legacyCutletId)
    ctx.gateProjectionLegacyOrdinal=Some(r.legacyDayInCutlet)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery26.gate.cutlet.calls")
    ctx.status="LEGACY_GATE_CUTLET_PROJECTION_READY"
  }
}
