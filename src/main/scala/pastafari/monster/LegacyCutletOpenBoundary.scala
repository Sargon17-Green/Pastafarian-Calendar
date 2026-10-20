package pastafari.monster

/** DISCOVERY20: mappatura sintetica dei giorni sulle cotolette
  * delimitate da porte. Il vecchio algoritmo non cambia
  * cotoletta al suo primo giorno, ma solo al giorno successivo.
  * Non seleziona la salsa né la partizione annuale normativa.
  */
final case class LegacyCutletOpenBoundaryResult(
  gateGaps: Vector[Int],
  cutletPartition: Vector[Int],
  dayOffset: Int,
  cutletStartOffsets: Vector[Int],
  legacyCutletId: Int,
  legacyDayInCutlet: Int
)

object LegacyCutletOpenBoundaryAdapter {
  def oldCutletOpenBoundary(
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    dayOffset: Int
  ): LegacyCutletOpenBoundaryResult = {
    require(cutletPartition.length>=6 && cutletPartition.length<=17,
      "Sono necessarie da sei a diciassette cotolette.")
    require(cutletPartition.forall(_>=1),
      "Ogni cotoletta contiene almeno un intervallo di porte.")
    require(cutletPartition.sum==gateGaps.length,
      "La partizione deve coprire esattamente le porte.")
    require(gateGaps.forall(g=>g>=42 && g<=963),
      "Ogni intervallo delle porte vale fra 42 e 963 giorni.")
    val yearLength=gateGaps.sum
    require(yearLength>=252 && yearLength<=5778,
      "La durata annuale deve essere da 252 a 5778 giorni.")
    require(dayOffset>=0 && dayOffset<yearLength,
      "Il giorno e' fuori dall'anno.")
    val starts=cutletPartition.scanLeft(0)(_+_).init
      .map(k=>gateGaps.take(k).sum)
    // CICATRICE: > invece di >=, esattamente sul nuovo inizio.
    val oldId=1+starts.tail.count(start=>dayOffset>start)
    LegacyCutletOpenBoundaryResult(
      gateGaps,cutletPartition,dayOffset,starts,
      oldId,dayOffset-starts(oldId-1)+1)
  }
}

final case class Discovery20CutletOpenBoundaryReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  gateGaps: Vector[Int],
  cutletPartition: Vector[Int],
  dayOffset: Int,
  cutletStartOffsets: Vector[Int],
  legacyCutletId: Int,
  legacyDayInCutlet: Int,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery20CutletOpenBoundaryHandler(
  metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_20_CUTLET_OPEN_BOUNDARY"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.cutletGateGaps.isEmpty || ctx.cutletGatePartition.isEmpty ||
       ctx.cutletDayOffset.isEmpty ||
       ctx.cutletBoundarySnapshot.nonEmpty ||
       ctx.legacyCutletStartOffsets.nonEmpty ||
       ctx.legacyCutletId.nonEmpty ||
       ctx.legacyDayInCutlet.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY20 richiede bootstrap nuovo e input integri.")
    val result=LegacyCutletOpenBoundaryAdapter.oldCutletOpenBoundary(
      ctx.cutletGateGaps.get,ctx.cutletGatePartition.get,
      ctx.cutletDayOffset.get)
    ctx.cutletBoundarySnapshot=Some((
      result.gateGaps,result.cutletPartition,result.dayOffset))
    ctx.legacyCutletStartOffsets=Some(result.cutletStartOffsets)
    ctx.legacyCutletId=Some(result.legacyCutletId)
    ctx.legacyDayInCutlet=Some(result.legacyDayInCutlet)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery20.cutlet.boundary.calls")
    ctx.status="LEGACY_CUTLET_BOUNDARY_READY"
  }
}
