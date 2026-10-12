package pastafari.monster

/**
 * DISCOVERY 14: posizione in un insieme VIRTUALE di indici dei cancelli.
 * La sequenza diagnostica ha rango 1-based e passo signed BigInt.
 * La cicatrice storica restringe il rango a Int, perdendo i bit alti.
 * Non genera cancelli, anni o date canoniche in questa fase.
 */
final case class LegacyVirtualGateListResult(
  firstGateIndex: BigInt,
  gateStride: BigInt,
  candidateCount: BigInt,
  requestedRank: BigInt,
  narrowedRank: Int,
  guessedGateIndex: BigInt
)

object VirtualLegacyListAdapter {
  def oldVirtualGateAt(
    firstGateIndex: BigInt,
    gateStride: BigInt,
    candidateCount: BigInt,
    rank1: BigInt
  ): LegacyVirtualGateListResult = {
    require(gateStride!=0,"Il passo virtuale non può essere zero.")
    require(candidateCount>=1,"La famiglia virtuale non può essere vuota.")
    require(rank1>=1 && rank1<=candidateCount,"Rango fuori intervallo.")
    // DIFETTO INTENZIONALE: BigInt.toInt conserva soltanto 32 bit signed.
    val narrow=rank1.toInt
    val oldIndex=firstGateIndex+(BigInt(narrow)-1)*gateStride
    LegacyVirtualGateListResult(
      firstGateIndex,gateStride,candidateCount,rank1,narrow,oldIndex)
  }
}

final case class Discovery14VirtualGateListReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  firstGateIndex: BigInt,
  gateStride: BigInt,
  candidateCount: BigInt,
  requestedRank: BigInt,
  narrowedRank: Int,
  legacySelectedGateIndex: BigInt,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery14VirtualGateListHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_14_VIRTUAL_GATE_LIST"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.status!="BOOTSTRAPPED" ||
       ctx.phase!=phase ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.virtualFirstGateIndex.isEmpty ||
       ctx.virtualGateStride.isEmpty ||
       ctx.virtualCandidateCount.isEmpty ||
       ctx.virtualRequestedRank.isEmpty ||
       ctx.legacyVirtualNarrowedRank.nonEmpty ||
       ctx.legacyVirtualSelectedGateIndex.nonEmpty ||
       ctx.virtualDiscoveryInputSnapshot.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 14 richiede un Bootstrap integro e input completi.")
    }
    val result=VirtualLegacyListAdapter.oldVirtualGateAt(
      ctx.virtualFirstGateIndex.get,ctx.virtualGateStride.get,
      ctx.virtualCandidateCount.get,ctx.virtualRequestedRank.get)
    ctx.legacyVirtualNarrowedRank=Some(result.narrowedRank)
    ctx.legacyVirtualSelectedGateIndex=Some(result.guessedGateIndex)
    // Una fotografia immutabile dei quattro input al momento della discovery.
    ctx.virtualDiscoveryInputSnapshot=Some((
      result.firstGateIndex,result.gateStride,
      result.candidateCount,result.requestedRank))
    ctx.branchTrace.append(phase)
    metrics.bump("discovery14.virtual.gate.calls")
    ctx.status="LEGACY_VIRTUAL_GATE_READY"
  }
}
