package pastafari.monster

/**
 * DISCOVERY 08 — errore storico di aliasing delle sei ciotole.
 * I getti sono calcolati dall'ingresso intatto; durante la
 * mescolatura old e next condividono invece lo stesso Array.
 * La PATCH 08 non deve essere introdotta durante la discovery.
 */
final case class LegacyBowlAliasResult(
  order: Vector[Int], pours: Vector[BigInt], bowls: Vector[BigInt]
)

object LegacyBowlAliasAdapter {
  private val stoneAtPosition = Vector(0,1,2,3,4,0)

  def bowlAlias(initial: Vector[BigInt], drop: BigInt,
                stones: Vector[BigInt], step: Int,
                rank1: Int): LegacyBowlAliasResult = {
    require(initial.length == 6, "Servono sei ciotole.")
    require(stones.length == 5, "Servono cinque pietre.")
    require(step >= 1 && step <= 46, "Indice di goccia non valido.")
    require(rank1 >= 1 && rank1 <= 720, "Rango di permutazione non valido.")
    // La scelta del rango è già normativa grazie alla PATCH 07.
    val order = Patch07PermutationWrapper.permutationPatch(rank1)
    val register = initial.toArray
    val old = register
    val next = register // BUG: non è una copia dell'istantanea!
    val pours = Array.fill[BigInt](6)(BigInt(0))
    pours(0) = Patch01SaveWrapper.savePatch(
      drop*drop + stones(0)*old(order(0)-1) + 3*step)
    pours(1) = Patch01SaveWrapper.savePatch(
      drop*drop + stones(1)*old(order(1)-1) + 5*step)
    pours(2) = Patch01SaveWrapper.savePatch(
      drop*drop + stones(2)*old(order(2)-1) + 7*step)

    var position = 1
    while (position <= 6) {
      val bowl = order(position-1)-1
      val previous = order((position+4)%6)-1
      val following = order(position%6)-1
      val kind = stoneAtPosition(position-1)
      val sum = old(bowl) + 2*old(previous) + 3*old(following) +
        pours(position-1) + drop + stones(kind)
      next(bowl) = Patch01SaveWrapper.savePatch(
        sum*sum + 5*old(previous)*old(following) + step*position)
      position += 1
    }
    LegacyBowlAliasResult(order,pours.toVector,next.toVector)
  }
}

final case class Discovery08BowlAliasReport(
  calculationDay: BigInt, targetDay: BigInt,
  initialBowls: Vector[BigInt], drop: BigInt,
  stones: Vector[BigInt], step: Int, orderRank1: Int,
  bowlOrder: Vector[Int], pours: Vector[BigInt],
  legacyBowls: Vector[BigInt],
  phase: String, status: String, trace: Vector[String]
)

final class Discovery08BowlAliasHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_08_BOWL_ALIAS"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.bowlInput.isEmpty || ctx.bowlDropInput.isEmpty ||
        ctx.bowlStonesInput.isEmpty || ctx.bowlStepInput.isEmpty ||
        ctx.bowlRankInput.isEmpty || ctx.legacyBowlOrderOutput.nonEmpty ||
        ctx.legacyBowlPoursOutput.nonEmpty || ctx.legacyBowlOutput.nonEmpty) {
      throw new IllegalStateException("DISCOVERY 08 richiede un Bootstrap nuovo.")
    }
    val r = LegacyBowlAliasAdapter.bowlAlias(
      ctx.bowlInput.get,ctx.bowlDropInput.get,ctx.bowlStonesInput.get,
      ctx.bowlStepInput.get,ctx.bowlRankInput.get)
    ctx.legacyBowlOrderOutput = Some(r.order)
    ctx.legacyBowlPoursOutput = Some(r.pours)
    ctx.legacyBowlOutput = Some(r.bowls)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery08.bowl.alias.calls")
    ctx.status = "LEGACY_BOWL_ALIAS_READY"
  }
}
