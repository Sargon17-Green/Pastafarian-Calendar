package pastafari.monster

/**
 * PATCH 01: non elimina né modifica oldRemainder.
 * Il valore legacy zero (un multiplo esatto di M) viene esposto come M;
 * tutti i residui non nulli rimangono esattamente invariati.
 *
 * La sorgente normativa test-only non viene consultata.
 */
object Patch01SaveWrapper {
  private val MOld: BigInt = (BigInt(1) << 127) - 1

  def savePatch(x: BigInt): BigInt = {
    val r = LegacyArithmeticAdapter.oldRemainder(x)
    if (r == 0) MOld else r
  }
}

final case class Patch01SaveReport(
  input: BigInt,
  legacyOutput: BigInt,
  patchedOutput: BigInt,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch01SaveHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "PATCH_01_SAVE"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "LEGACY_REMAINDER_READY" ||
        ctx.legacyRemainderInput.isEmpty ||
        ctx.legacyRemainderOutput.isEmpty) {
      throw new IllegalStateException(
        "PATCH 01 richiede il residuo storico calcolato nella stessa invocazione."
      )
    }
    // Il wrapper esegue davvero oldRemainder, senza sostituirlo con un oracolo.
    ctx.patchedSaveOutput = Some(Patch01SaveWrapper.savePatch(ctx.legacyRemainderInput.get))
    ctx.patch01Applied = true
    ctx.branchTrace.append(phase)
    metrics.bump("patch01.save.calls")
    ctx.status = "PATCH_01_READY"
  }
}
