package pastafari.monster

/**
 * Cicatrice storica DISCOVERY 01.
 * È intenzionalmente il residuo euclideo nell'intervallo [0,M-1], non SAVE.
 * Non aggiungere la correzione dello zero prima dello stadio PATCH 01.
 */
object LegacyArithmeticAdapter {
  private val MOld: BigInt = (BigInt(1) << 127) - 1

  def oldRemainder(x: BigInt): BigInt = {
    val r = x % MOld
    if (r.signum < 0) r + MOld else r
  }
}

final case class Discovery01Report(
  input: BigInt,
  legacyOutput: BigInt,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery01RemainderHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_01_REMAINDER"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED") {
      throw new IllegalStateException("DISCOVERY 01 richiede il Bootstrap della stessa invocazione.")
    }
    val input = ctx.legacyRemainderInput.getOrElse(
      throw new IllegalStateException("Manca l'operando del residuo legacy.")
    )
    ctx.legacyRemainderOutput = Some(LegacyArithmeticAdapter.oldRemainder(input))
    ctx.branchTrace.append(phase)
    metrics.bump("discovery01.remainder.calls")
    ctx.status = "LEGACY_REMAINDER_READY"
  }
}
