package pastafari.monster

/**
 * DISCOVERY 11: la selezione corta legacy riduce subito la prima
 * risposta modulo N. Manca l'accettazione limitata a
 * floor(M/N)*N e il proseguimento nel flusso fino al campione ammesso.
 * Nessuna PATCH 11: preservare questo difetto come cicatrice.
 */
final case class LegacyBiasedPickResult(
  firstSample: BigInt,
  legacyRank: BigInt,
  acceptanceLimit: BigInt
)

object LegacyBiasedPickAdapter {
  private val M=(BigInt(1)<<127)-1

  def biasedLegacyPick(firstSample: BigInt, directionStep: Int,
                       familySize: BigInt): LegacyBiasedPickResult = {
    require(firstSample>=1 && firstSample<=M,
      "La prima risposta deve appartenere a [1,M].")
    require(directionStep==1 || directionStep == -1,
      "La direzione del flusso deve essere +1 o -1.")
    require(familySize>=1 && familySize<=M,
      "La famiglia corta deve appartenere a [1,M].")
    val limit=(M/familySize)*familySize
    // BUG: il campione e' usato anche se firstSample > limit.
    val rank=((firstSample-1)%familySize)+1
    LegacyBiasedPickResult(firstSample,rank,limit)
  }
}

final case class Discovery11BiasedPickReport(
  calculationDay: BigInt, targetDay: BigInt,
  firstSample: BigInt, directionStep: Int, familySize: BigInt,
  legacySample: BigInt, legacyRank: BigInt, acceptanceLimit: BigInt,
  phase: String, status: String, trace: Vector[String]
)

final class Discovery11BiasedPickHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase = "DISCOVERY_11_BIASED_SHORT_PICK"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status!="BOOTSTRAPPED" ||
        ctx.branchTrace.toVector!=Vector("BOOT") ||
        ctx.selectionSampleInput.isEmpty ||
        ctx.selectionDirectionInput.isEmpty ||
        ctx.selectionFamilySizeInput.isEmpty ||
        ctx.legacyBiasedSampleOutput.nonEmpty ||
        ctx.legacyBiasedRankOutput.nonEmpty ||
        ctx.legacyAcceptanceLimitOutput.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 11 richiede un Bootstrap fresco senza risultato.")
    }
    val result=LegacyBiasedPickAdapter.biasedLegacyPick(
      ctx.selectionSampleInput.get,ctx.selectionDirectionInput.get,
      ctx.selectionFamilySizeInput.get)
    ctx.legacyBiasedSampleOutput=Some(result.firstSample)
    ctx.legacyBiasedRankOutput=Some(result.legacyRank)
    ctx.legacyAcceptanceLimitOutput=Some(result.acceptanceLimit)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery11.biased.short.calls")
    ctx.status="LEGACY_BIASED_PICK_READY"
  }
}
