package pastafari.monster

/**
 * PATCH 07: conserva l'algoritmo storico di unranking e compensa
 * solo la base zero del suo parametro. L'oracolo resta test-only.
 */
object Patch07PermutationWrapper {
  def permutationPatch(rank1: Int): Vector[Int] = {
    // Esegue davvero la cicatrice con il rango richiesto.
    LegacyPermutationAdapter.oldPermutationUnrank0(rank1)
    // Il vecchio helper legge il rango come indice zero-based;
    // il suo ingresso 720 corrisponde all'indice zero.
    val legacyInput = if (rank1 == 1) 720 else rank1 - 1
    LegacyPermutationAdapter.oldPermutationUnrank0(legacyInput)
  }
}

final case class Patch07PermutationReport(
  calculationDay: BigInt, targetDay: BigInt,
  requestedRank1: Int,
  legacyPermutation: Vector[Int],
  patchedPermutation: Vector[Int],
  patchApplied: Boolean,
  phase: String, status: String, trace: Vector[String]
)

final class Patch07PermutationHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase: String = "PATCH_07_PERMUTATION"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_PERMUTATION_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_07_PERMUTATION") ||
        ctx.permutationRankInput.isEmpty ||
        ctx.legacyPermutationOutput.isEmpty ||
        ctx.patchedPermutationOutput.nonEmpty ||
        ctx.patch07Applied) {
      throw new IllegalStateException(
        "PATCH 07 richiede una DISCOVERY 07 valida in questa invocazione.")
    }
    val rank = ctx.permutationRankInput.get
    val corrected = Patch07PermutationWrapper.permutationPatch(rank)
    ctx.patchedPermutationOutput = Some(corrected)
    ctx.patch07Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch07.permutation.calls")
    ctx.status = "PATCH_07_READY"
  }
}
