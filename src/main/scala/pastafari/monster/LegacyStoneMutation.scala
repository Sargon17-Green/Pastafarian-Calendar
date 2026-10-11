package pastafari.monster

/**
 * DISCOVERY 04 — cicatrice di mutazione sequenziale delle pietre.
 *
 * La ricorrenza corretta leggerebbe tutti e cinque i risultati
 * dalla riga precedente. Questo adattatore invece sovrascrive
 * un registro prima di calcolare il prossimo e riutilizza
 * i valori già mutati nella medesima riga.
 *
 * Non copiare la riga precedente e non applicare una patch qui.
 */
object LegacyStoneMutationAdapter {
  def mutateStonesWrong(): Vector[Vector[BigInt]] = {
    val registers = Array[BigInt](17, 29, 43, 71, 101)
    val out = Vector.newBuilder[Vector[BigInt]]
    out += registers.toVector

    var rowNumber = 2
    while (rowNumber <= 46) {
      registers(0) = Patch01SaveWrapper.savePatch(
        registers(0) * registers(0) + 3 * registers(1) + rowNumber
      )
      registers(1) = Patch01SaveWrapper.savePatch(
        registers(1) * registers(1) + 5 * registers(2) + registers(0)
      )
      registers(2) = Patch01SaveWrapper.savePatch(
        registers(2) * registers(2) + 7 * registers(3) + registers(1)
      )
      registers(3) = Patch01SaveWrapper.savePatch(
        registers(3) * registers(3) + 11 * registers(4) + registers(2)
      )
      registers(4) = Patch01SaveWrapper.savePatch(
        registers(4) * registers(4) + 13 * registers(0) + registers(3)
      )
      // Congelamento del risultato: non esporre l'array mutabile.
      out += registers.toVector
      rowNumber += 1
    }
    out.result()
  }
}

final case class Discovery04StonesReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  legacyStoneRows: Vector[Vector[BigInt]],
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery04StonesHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_04_STONES"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.legacyStoneRowsOutput.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 04 richiede un Bootstrap nuovo della stessa invocazione."
      )
    }
    ctx.legacyStoneRowsOutput = Some(LegacyStoneMutationAdapter.mutateStonesWrong())
    ctx.branchTrace.append(phase)
    metrics.bump("discovery04.stones.calls")
    ctx.status = "LEGACY_STONES_READY"
  }
}
