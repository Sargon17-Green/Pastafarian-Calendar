package pastafari.monster

/**
 * PATCH 10: memorizza l'ordine della goccia 46 al momento giusto.
 * La cicatrice della DISCOVERY 10 continua ad essere eseguita e
 * conservata, ma non determina piu la ciotola successiva normativa.
 * Le dodici mescolature successive non alterano questa fotografia.
 */
final case class Patch10Order46Result(
  historical: LegacyOrder46LatchResult,
  latchedOrder46: Vector[Int],
  correctedNextBowl: Int
)

object Patch10Order46Wrapper {
  def order46Patch(drop45: BigInt, drop46: BigInt,
                   queriedBowlId: Int): Patch10Order46Result = {
    // Il vecchio latch viene realmente attraversato.
    val historical = LegacyOrder46LatchAdapter.orderAt46Latch(
      drop45,drop46,queriedBowlId)
    // La PATCH 07 fornisce il vero ordine 1-based della goccia 46.
    val mod = BigInt(720)
    val finalRank = (((drop46-1)%mod+mod)%mod+1).toInt
    val captured = Patch07PermutationWrapper.permutationPatch(finalRank)
    require(captured == historical.order46,
      "La permutazione osservata non coincide con la goccia 46.")
    val position = captured.indexOf(queriedBowlId)
    require(position>=0,"La ciotola richiesta non è nell'ordine 46.")
    Patch10Order46Result(
      historical,captured,captured((position+1)%6))
  }
}

final case class Patch10Order46Report(
  calculationDay: BigInt, targetDay: BigInt,
  drop45: BigInt, drop46: BigInt, queriedBowlId: Int,
  legacyOrder45: Vector[Int],
  observedOrder46: Vector[Int],
  legacyNextBowl: Int,
  latchedOrder46: Vector[Int],
  correctedNextBowl: Int,
  patchApplied: Boolean,
  phase: String, status: String, trace: Vector[String]
)

final class Patch10Order46Handler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase = "PATCH_10_ORDER46_FREEZE"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_ORDER46_LATCH_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_10_ORDER46_LATCH") ||
        ctx.penultimateDropValue.isEmpty || ctx.finalDropValue.isEmpty ||
        ctx.queriedBowlInput.isEmpty || ctx.legacyLatchedOrder45.isEmpty ||
        ctx.observedOrder46.isEmpty || ctx.legacyNextBowlOutput.isEmpty ||
        ctx.patchedLatchedOrder46.nonEmpty ||
        ctx.patchedNextBowlOutput.nonEmpty || ctx.patch10Applied) {
      throw new IllegalStateException(
        "PATCH 10 richiede il latch legacy integro nello stesso contesto.")
    }
    val result=Patch10Order46Wrapper.order46Patch(
      ctx.penultimateDropValue.get,ctx.finalDropValue.get,ctx.queriedBowlInput.get)
    if (result.historical.order45!=ctx.legacyLatchedOrder45.get ||
        result.historical.order46!=ctx.observedOrder46.get ||
        result.historical.legacyNextBowl!=ctx.legacyNextBowlOutput.get) {
      throw new IllegalStateException("Traccia del latch legacy compromessa.")
    }
    ctx.patchedLatchedOrder46=Some(result.latchedOrder46)
    ctx.patchedNextBowlOutput=Some(result.correctedNextBowl)
    ctx.patch10Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch10.order46.freeze.calls")
    ctx.status="PATCH_10_READY"
  }
}
