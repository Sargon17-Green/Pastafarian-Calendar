package pastafari.monster

/**
 * DISCOVERY 09: le dodici mescolature finali usano per errore
 * sempre il caveau d'ingresso, non il risultato del giro precedente.
 * Il rango, SAVE e le sei equazioni di un singolo giro sono normativi.
 * Non correggere il difetto in questa discovery.
 */
final case class LegacyVaultRound(
  step: Int, savedSum: BigInt, orderRank: Int,
  order: Vector[Int], bowls: Vector[BigInt]
)

final case class LegacyVaultResult(
  rounds: Vector[LegacyVaultRound], bowls: Vector[BigInt]
)

object LegacyVaultAdapter {
  def vaultOld(initial: Vector[BigInt]): LegacyVaultResult = {
    require(initial.length == 6, "Il caveau richiede esattamente sei ciotole.")
    val vaultOld = initial  // BUG: il vecchio caveau non viene mai aggiornato.
    var published = initial
    val records = Vector.newBuilder[LegacyVaultRound]
    var stir = 1
    while (stir <= 12) {
      val old = vaultOld  // BUG: dovrebbe usare published dopo il primo giro.
      val saved = Patch01SaveWrapper.savePatch(old.sum + 149*stir)
      val orderRank = ((saved-1)%720+1).toInt
      val order = Patch07PermutationWrapper.permutationPatch(orderRank)
      val next = Array.fill[BigInt](6)(BigInt(0))
      var position = 1
      while (position <= 6) {
        val bowl = order(position-1)-1
        val previous = order((position+4)%6)-1
        val following = order(position%6)-1
        val x = old(bowl) + 3*old(previous) + 5*old(following) +
          saved + stir + position*position
        next(bowl) = Patch01SaveWrapper.savePatch(
          x*x + 7*old(previous)*old(following))
        position += 1
      }
      published = next.toVector
      records += LegacyVaultRound(stir,saved,orderRank,order,published)
      stir += 1
    }
    LegacyVaultResult(records.result(),published)
  }
}

final case class Discovery09VaultReport(
  calculationDay: BigInt, targetDay: BigInt,
  initialBowls: Vector[BigInt],
  legacyRounds: Vector[LegacyVaultRound],
  legacyBowls: Vector[BigInt],
  phase: String, status: String, trace: Vector[String]
)

final class Discovery09VaultHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase = "DISCOVERY_09_VAULT"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.postStirInput.isEmpty ||
        ctx.legacyVaultRounds.nonEmpty || ctx.legacyVaultOutput.nonEmpty) {
      throw new IllegalStateException(
        "La DISCOVERY 09 richiede un Bootstrap fresco senza risultati.")
    }
    val old = LegacyVaultAdapter.vaultOld(ctx.postStirInput.get)
    ctx.legacyVaultRounds = Some(old.rounds)
    ctx.legacyVaultOutput = Some(old.bowls)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery09.vault.calls")
    ctx.status = "LEGACY_VAULT_READY"
  }
}
