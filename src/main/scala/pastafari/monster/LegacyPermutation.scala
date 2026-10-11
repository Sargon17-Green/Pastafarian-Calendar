package pastafari.monster

import scala.collection.mutable

/**
 * DISCOVERY 07 — errore storico della base del rango.
 * La famiglia normativa ha rango 1..720; questo helper usa
 * invece il rango come indice 0-based. Il rango 720 si riavvolge
 * a zero in modo storico, non normativo.
 *
 * La cicatrice non deve essere riparata in questo stadio.
 */
object LegacyPermutationAdapter {
  private val Size = 6
  private val Total = 720

  def oldPermutationUnrank0(rank1: Int): Vector[Int] = {
    require(rank1 >= 1 && rank1 <= Total,
      "Il rango della permutazione deve appartenere a 1..720.")

    // BUG intenzionale: manca la sottrazione di 1 dal rango d'ingresso.
    var rank0 = rank1 % Total
    val remaining = mutable.ArrayBuffer(1, 2, 3, 4, 5, 6)
    val permutation = Vector.newBuilder[Int]
    var slots = Size
    var block = 120 // 5!
    while (slots >= 1) {
      val q = if (slots == 1) 0 else rank0 / block
      if (q < 0 || q >= remaining.length)
        throw new IllegalStateException("Indice legacy fuori intervallo.")
      permutation += remaining.remove(q)
      if (slots > 1) {
        rank0 = rank0 % block
        block = if (slots == 2) 1 else block / (slots - 1)
      }
      slots -= 1
    }
    permutation.result()
  }
}

final case class Discovery07PermutationReport(
  calculationDay: BigInt, targetDay: BigInt,
  requestedRank1: Int, legacyPermutation: Vector[Int],
  phase: String, status: String, trace: Vector[String]
)

final class Discovery07PermutationHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_07_PERMUTATION"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.permutationRankInput.isEmpty ||
        ctx.legacyPermutationOutput.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 07 richiede un Bootstrap nuovo senza risultato preesistente.")
    }
    val permutation =
      LegacyPermutationAdapter.oldPermutationUnrank0(ctx.permutationRankInput.get)
    ctx.legacyPermutationOutput = Some(permutation)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery07.permutation.calls")
    ctx.status = "LEGACY_PERMUTATION_READY"
  }
}
