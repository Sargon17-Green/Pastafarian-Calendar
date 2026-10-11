package pastafari.monster

/**
 * PATCH 08: mantiene il vero helper della DISCOVERY 08 e
 * calcola le sei nuove ciotole da una istantanea immutata.
 * Ordine e SAVE rimangono quelli già corretti in precedenza.
 */
object Patch08BowlWrapper {
  private val stoneKinds = Vector(0,1,2,3,4,0)

  def bowlPatch(initial: Vector[BigInt], drop: BigInt,
                stones: Vector[BigInt], step: Int,
                rank1: Int): Vector[BigInt] = {
    val legacy = LegacyBowlAliasAdapter.bowlAlias(initial,drop,stones,step,rank1)
    val old = initial // Vector immutabile; non condivide il registro mutato.
    val order = legacy.order
    val pours = legacy.pours // Calcolati prima dell'alias nel helper legacy.
    val next = Array.fill[BigInt](6)(BigInt(0))
    var position = 1
    while (position <= 6) {
      val current = order(position-1)-1
      val previous = order((position+4)%6)-1
      val following = order(position%6)-1
      val sum = old(current) + 2*old(previous) + 3*old(following) +
        pours(position-1) + drop + stones(stoneKinds(position-1))
      next(current) = Patch01SaveWrapper.savePatch(
        sum*sum + 5*old(previous)*old(following) + step*position)
      position += 1
    }
    next.toVector
  }
}

final case class Patch08BowlReport(
  calculationDay: BigInt, targetDay: BigInt,
  initialBowls: Vector[BigInt], drop: BigInt,
  stones: Vector[BigInt], step: Int, orderRank1: Int,
  bowlOrder: Vector[Int], pours: Vector[BigInt],
  legacyBowls: Vector[BigInt], patchedBowls: Vector[BigInt],
  patchApplied: Boolean,
  phase: String, status: String, trace: Vector[String]
)

final class Patch08BowlHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase = "PATCH_08_BOWL_FREEZE"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_BOWL_ALIAS_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_08_BOWL_ALIAS") ||
        ctx.bowlInput.isEmpty || ctx.bowlDropInput.isEmpty ||
        ctx.bowlStonesInput.isEmpty || ctx.bowlStepInput.isEmpty ||
        ctx.bowlRankInput.isEmpty || ctx.legacyBowlOrderOutput.isEmpty ||
        ctx.legacyBowlPoursOutput.isEmpty || ctx.legacyBowlOutput.isEmpty ||
        ctx.patchedBowlOutput.nonEmpty || ctx.patch08Applied) {
      throw new IllegalStateException("PATCH 08 richiede una DISCOVERY 08 completa.")
    }
    val corrected = Patch08BowlWrapper.bowlPatch(
      ctx.bowlInput.get,ctx.bowlDropInput.get,ctx.bowlStonesInput.get,
      ctx.bowlStepInput.get,ctx.bowlRankInput.get)
    ctx.patchedBowlOutput = Some(corrected)
    ctx.patch08Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch08.bowl.freeze.calls")
    ctx.status = "PATCH_08_READY"
  }
}
