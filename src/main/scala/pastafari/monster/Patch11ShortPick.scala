package pastafari.monster

/**
 * PATCH 11: la selezione corta e' uniformemente distribuita
 * tramite rejection sampling. La cicatrice legacy resta una
 * chiamata vera, diagnostica e immutabile.
 *
 * Per evitare un ciclo impossibile su BigInt di 127 bit,
 * il tratto contiguo dei campioni rifiutati viene saltato
 * con aritmetica esatta. Il risultato e' identico al flusso
 * che avanza di +1 o -1 ciclicamente.
 */
final case class Patch11ShortPickResult(
  historical: LegacyBiasedPickResult,
  acceptedSample: BigInt,
  patchedRank: BigInt,
  skippedSamples: BigInt
)

object Patch11ShortPickWrapper {
  private val M=(BigInt(1)<<127)-1

  def shortPickPatch(firstSample: BigInt, directionStep: Int,
                     familySize: BigInt): Patch11ShortPickResult = {
    val historical=LegacyBiasedPickAdapter.biasedLegacyPick(
      firstSample,directionStep,familySize)
    val limit=historical.acceptanceLimit
    var accepted=firstSample
    var skipped=BigInt(0)
    if (firstSample>limit) {
      if (directionStep>0) {
        skipped=M-firstSample+1
        accepted=BigInt(1)
      } else {
        skipped=firstSample-limit
        accepted=limit
      }
    }
    val rank=((accepted-1)%familySize)+1
    Patch11ShortPickResult(historical,accepted,rank,skipped)
  }
}

final case class Patch11ShortPickReport(
  calculationDay: BigInt, targetDay: BigInt,
  firstSample: BigInt, directionStep: Int, familySize: BigInt,
  legacySample: BigInt, legacyRank: BigInt,
  acceptanceLimit: BigInt,
  acceptedSample: BigInt, patchedRank: BigInt,
  skippedSamples: BigInt, patchApplied: Boolean,
  phase: String, status: String, trace: Vector[String]
)

final class Patch11ShortPickHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase = "PATCH_11_SHORT_REJECTION"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status!="LEGACY_BIASED_PICK_READY" ||
        ctx.branchTrace.toVector!=Vector("BOOT","DISCOVERY_11_BIASED_SHORT_PICK") ||
        ctx.selectionSampleInput.isEmpty ||
        ctx.selectionDirectionInput.isEmpty ||
        ctx.selectionFamilySizeInput.isEmpty ||
        ctx.legacyBiasedSampleOutput.isEmpty ||
        ctx.legacyBiasedRankOutput.isEmpty ||
        ctx.legacyAcceptanceLimitOutput.isEmpty ||
        ctx.patchedAcceptedSample.nonEmpty ||
        ctx.patchedShortPickRank.nonEmpty ||
        ctx.patchedSkippedSamples.nonEmpty || ctx.patch11Applied) {
      throw new IllegalStateException(
        "PATCH 11 richiede la discovery completa nello stesso contesto.")
    }
    val corrected=Patch11ShortPickWrapper.shortPickPatch(
      ctx.selectionSampleInput.get,
      ctx.selectionDirectionInput.get,
      ctx.selectionFamilySizeInput.get)
    if (corrected.historical.firstSample!=ctx.legacyBiasedSampleOutput.get ||
        corrected.historical.legacyRank!=ctx.legacyBiasedRankOutput.get ||
        corrected.historical.acceptanceLimit!=ctx.legacyAcceptanceLimitOutput.get) {
      throw new IllegalStateException("Traccia della selezione legacy non conservata.")
    }
    ctx.patchedAcceptedSample=Some(corrected.acceptedSample)
    ctx.patchedShortPickRank=Some(corrected.patchedRank)
    ctx.patchedSkippedSamples=Some(corrected.skippedSamples)
    ctx.patch11Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch11.short.rejection.calls")
    ctx.status="PATCH_11_READY"
  }
}
