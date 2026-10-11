package pastafari.monster

/**
 * PATCH 09: il vecchio caveau resta immutato per la diagnostica.
 * Per dodici rimescolamenti di chiusura la nuova istantanea del
 * giro precedente deve sostituire la precedente prima del giro dopo.
 */
final case class Patch09VaultResult(
  historical: LegacyVaultResult,
  rounds: Vector[LegacyVaultRound],
  bowls: Vector[BigInt]
)

object Patch09VaultWrapper {
  def vaultPatch(initial: Vector[BigInt]): Patch09VaultResult = {
    // Il difetto originale viene eseguito davvero, non simulato.
    val historical = LegacyVaultAdapter.vaultOld(initial)
    var snapshot = initial
    val records = Vector.newBuilder[LegacyVaultRound]
    var step = 1
    while (step <= 12) {
      val old = snapshot
      val saved = Patch01SaveWrapper.savePatch(old.sum + 149*step)
      val rank = ((saved-1)%720+1).toInt
      val order = Patch07PermutationWrapper.permutationPatch(rank)
      val next = Array.fill[BigInt](6)(BigInt(0))
      var position = 1
      while (position <= 6) {
        val at = order(position-1)-1
        val previous = order((position+4)%6)-1
        val following = order(position%6)-1
        val x = old(at)+3*old(previous)+5*old(following)+
          saved+step+position*position
        next(at) = Patch01SaveWrapper.savePatch(
          x*x+7*old(previous)*old(following))
        position += 1
      }
      snapshot = next.toVector
      records += LegacyVaultRound(step,saved,rank,order,snapshot)
      step += 1
    }
    Patch09VaultResult(historical,records.result(),snapshot)
  }
}

final case class Patch09VaultReport(
  calculationDay: BigInt, targetDay: BigInt,
  initialBowls: Vector[BigInt],
  legacyRounds: Vector[LegacyVaultRound],
  legacyBowls: Vector[BigInt],
  patchedRounds: Vector[LegacyVaultRound],
  patchedBowls: Vector[BigInt],
  patchApplied: Boolean,
  phase: String, status: String, trace: Vector[String]
)

final class Patch09VaultHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase = "PATCH_09_VAULT_ROLL"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_VAULT_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_09_VAULT") ||
        ctx.postStirInput.isEmpty ||
        ctx.legacyVaultRounds.isEmpty || ctx.legacyVaultOutput.isEmpty ||
        ctx.patchedVaultRounds.nonEmpty || ctx.patchedVaultOutput.nonEmpty ||
        ctx.patch09Applied) {
      throw new IllegalStateException(
        "PATCH 09 richiede una DISCOVERY 09 completa nello stesso contesto.")
    }
    val corrected = Patch09VaultWrapper.vaultPatch(ctx.postStirInput.get)
    if (corrected.historical.rounds != ctx.legacyVaultRounds.get ||
        corrected.historical.bowls != ctx.legacyVaultOutput.get)
      throw new IllegalStateException("Traccia storica non conservata.")
    ctx.patchedVaultRounds = Some(corrected.rounds)
    ctx.patchedVaultOutput = Some(corrected.bowls)
    ctx.patch09Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch09.vault.roll.calls")
    ctx.status = "PATCH_09_READY"
  }
}
