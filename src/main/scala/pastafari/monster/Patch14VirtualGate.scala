package pastafari.monster

/**
 * PATCH 14: unrank 1-based di una famiglia virtuale BigInt
 * SENZA materializzare i candidati. La cicatrice storica a 32 bit
 * è percorsa davvero e viene restituita separatamente.
 *
 * Il modello rimane una progressione sintetica di indici di cancello;
 * non crea ancora i cancelli della salsa normativa.
 */
final case class Patch14VirtualGateResult(
  historical: LegacyVirtualGateListResult,
  correctedSelectedGateIndex: BigInt
)

object Patch14VirtualGateWrapper {
  def virtualGatePatch(
    firstGateIndex: BigInt,
    gateStride: BigInt,
    candidateCount: BigInt,
    rank1: BigInt
  ): Patch14VirtualGateResult = {
    val legacy=VirtualLegacyListAdapter.oldVirtualGateAt(
      firstGateIndex,gateStride,candidateCount,rank1)
    // Rank1 è un BigInt esatto, mai convertito a Int.
    val selected=firstGateIndex+(rank1-BigInt(1))*gateStride
    Patch14VirtualGateResult(legacy,selected)
  }
}

final case class Patch14VirtualGateReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  firstGateIndex: BigInt,
  gateStride: BigInt,
  candidateCount: BigInt,
  requestedRank: BigInt,
  legacyNarrowedRank: Int,
  legacySelectedGateIndex: BigInt,
  patchedSelectedGateIndex: BigInt,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch14VirtualGateHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_14_VIRTUAL_GATE_LIST"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_VIRTUAL_GATE_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_14_VIRTUAL_GATE_LIST") ||
       ctx.virtualFirstGateIndex.isEmpty ||
       ctx.virtualGateStride.isEmpty ||
       ctx.virtualCandidateCount.isEmpty ||
       ctx.virtualRequestedRank.isEmpty ||
       ctx.legacyVirtualNarrowedRank.isEmpty ||
       ctx.legacyVirtualSelectedGateIndex.isEmpty ||
       ctx.virtualDiscoveryInputSnapshot.isEmpty ||
       ctx.patchedVirtualSelectedGateIndex.nonEmpty ||
       ctx.patch14Applied)
      throw new IllegalStateException(
        "PATCH 14 richiede la DISCOVERY 14 completa nella stessa invocazione.")

    // Anche per rank=1, la fotografia respinge il cambio di un input
    // che non altererebbe numericamente il candidato scelto.
    if(ctx.virtualDiscoveryInputSnapshot.get!=(
         ctx.virtualFirstGateIndex.get,ctx.virtualGateStride.get,
         ctx.virtualCandidateCount.get,ctx.virtualRequestedRank.get))
      throw new IllegalStateException("Dati modificati dopo la discovery.")

    // Nessuna pubblicazione prima di aver verificato la cicatrice.
    val result=Patch14VirtualGateWrapper.virtualGatePatch(
      ctx.virtualFirstGateIndex.get,
      ctx.virtualGateStride.get,
      ctx.virtualCandidateCount.get,
      ctx.virtualRequestedRank.get)
    if(result.historical.narrowedRank!=ctx.legacyVirtualNarrowedRank.get ||
       result.historical.guessedGateIndex!=ctx.legacyVirtualSelectedGateIndex.get ||
       result.historical.firstGateIndex!=ctx.virtualFirstGateIndex.get ||
       result.historical.gateStride!=ctx.virtualGateStride.get ||
       result.historical.candidateCount!=ctx.virtualCandidateCount.get ||
       result.historical.requestedRank!=ctx.virtualRequestedRank.get)
      throw new IllegalStateException("Risultato legacy contraffatto.")

    ctx.patchedVirtualSelectedGateIndex=Some(result.correctedSelectedGateIndex)
    ctx.patch14Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch14.virtual.gate.calls")
    ctx.status="PATCH_14_READY"
  }
}
