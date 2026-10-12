package pastafari.monster

/**
 * DISCOVERY 10: il registro della goccia 46 viene salvato in ritardo.
 * Il latch conserva per errore la permutazione precedente (goccia 45).
 * La selezione della permutazione usa gia la PATCH 07 e non
 * dipende dalle dodici mescolature finali del caveau.
 */
final case class LegacyOrder46LatchResult(
  order45: Vector[Int],
  order46: Vector[Int],
  legacyNextBowl: Int
)

object LegacyOrder46LatchAdapter {
  private def rankFromDrop(value: BigInt): Int = {
    val mod = BigInt(720)
    (((value - 1) % mod + mod) % mod + 1).toInt
  }

  def orderAt46Latch(drop45: BigInt, drop46: BigInt,
                     queriedBowlId: Int): LegacyOrder46LatchResult = {
    require(queriedBowlId>=1 && queriedBowlId<=6,
      "L'identificatore della ciotola deve stare fra uno e sei.")
    val order45 = Patch07PermutationWrapper.permutationPatch(rankFromDrop(drop45))
    val order46 = Patch07PermutationWrapper.permutationPatch(rankFromDrop(drop46))
    val captured = order45 // BUG: il latch mantiene l'ordine della goccia 45.
    val position = captured.indexOf(queriedBowlId)
    val next = captured((position+1)%6)
    LegacyOrder46LatchResult(order45,order46,next)
  }
}

final case class Discovery10Order46LatchReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  drop45: BigInt, drop46: BigInt,
  queriedBowlId: Int,
  legacyOrder45: Vector[Int],
  observedOrder46: Vector[Int],
  legacyNextBowl: Int,
  phase: String, status: String, trace: Vector[String]
)

final class Discovery10Order46LatchHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase = "DISCOVERY_10_ORDER46_LATCH"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.penultimateDropValue.isEmpty ||
        ctx.finalDropValue.isEmpty || ctx.queriedBowlInput.isEmpty ||
        ctx.legacyLatchedOrder45.nonEmpty ||
        ctx.observedOrder46.nonEmpty || ctx.legacyNextBowlOutput.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 10 richiede un Bootstrap nuovo e nessun latch precedente.")
    }
    val result = LegacyOrder46LatchAdapter.orderAt46Latch(
      ctx.penultimateDropValue.get,ctx.finalDropValue.get,
      ctx.queriedBowlInput.get)
    ctx.legacyLatchedOrder45 = Some(result.order45)
    ctx.observedOrder46 = Some(result.order46)
    ctx.legacyNextBowlOutput = Some(result.legacyNextBowl)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery10.order46.latch.calls")
    ctx.status = "LEGACY_ORDER46_LATCH_READY"
  }
}
