package pastafari.monster

/**
 * PATCH 04 — tutte le cinque pietre della nuova riga leggono
 * esclusivamente la riga precedente immutabile.
 *
 * Il materiale iniziale viene dal vero risultato di DISCOVERY 04,
 * non da una riscrittura del vecchio adattatore. Le righe legacy
 * successive rimangono disponibili per la diagnosi e non vengono
 * utilizzate come nuove basi per la ricorrenza corretta.
 */
object Patch04StonesWrapper {
  private val FirstRow = Vector[BigInt](17, 29, 43, 71, 101)

  def stonesPatch(legacyRows: Vector[Vector[BigInt]]): Vector[Vector[BigInt]] = {
    require(legacyRows.length == 46 && legacyRows.forall(_.length == 5),
      "Sono necessarie 46 righe legacy di cinque pietre.")
    require(legacyRows.head == FirstRow,
      "La riga iniziale deve essere quella canonica.")

    val out = Vector.newBuilder[Vector[BigInt]]
    var previous: Vector[BigInt] = legacyRows.head
    out += previous

    var rowNumber = 2
    while (rowNumber <= 46) {
      // Letture da previous, senza aggiornamenti in-place.
      val wheat = Patch01SaveWrapper.savePatch(
        previous(0) * previous(0) + 3 * previous(1) + rowNumber
      )
      val barley = Patch01SaveWrapper.savePatch(
        previous(1) * previous(1) + 5 * previous(2) + previous(0)
      )
      val salt = Patch01SaveWrapper.savePatch(
        previous(2) * previous(2) + 7 * previous(3) + previous(1)
      )
      val bitter = Patch01SaveWrapper.savePatch(
        previous(3) * previous(3) + 11 * previous(4) + previous(2)
      )
      val red = Patch01SaveWrapper.savePatch(
        previous(4) * previous(4) + 13 * previous(0) + previous(3)
      )
      val next = Vector(wheat, barley, salt, bitter, red)
      out += next
      previous = next
      rowNumber += 1
    }
    out.result()
  }
}

final case class Patch04StonesReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  legacyStoneRows: Vector[Vector[BigInt]],
  patchedStoneRows: Vector[Vector[BigInt]],
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch04StonesHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "PATCH_04_STONES"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_STONES_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_04_STONES") ||
        ctx.legacyStoneRowsOutput.isEmpty ||
        ctx.patchedStoneRowsOutput.nonEmpty || ctx.patch04Applied) {
      throw new IllegalStateException(
        "PATCH 04 richiede la vera DISCOVERY 04 nella stessa invocazione."
      )
    }
    ctx.patchedStoneRowsOutput = Some(
      Patch04StonesWrapper.stonesPatch(ctx.legacyStoneRowsOutput.get)
    )
    ctx.patch04Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch04.stones.calls")
    ctx.status = "PATCH_04_READY"
  }
}
