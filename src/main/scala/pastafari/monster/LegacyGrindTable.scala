package pastafari.monster

/**
 * DISCOVERY 06: la tabella storica contiene un sentinel alla posizione 0,
 * ma l'accesso continua ad usare l'indice (passo - 1).
 * Risultato: il primo passo usa il sentinel e l'undicesimo il decimo.
 * Non correggere lo slittamento nello stadio di discovery.
 */
final case class LegacyGrindRule(a: Int, b: Int, c: Int, d: Int, stoneKind: Int)

object LegacyGrindTableAdapter {
  val GRIND_TABLE_WITH_SENTINEL: Vector[LegacyGrindRule] = Vector(
    LegacyGrindRule(0, 0, 0, 0, 0), // sentinel apparentemente innocuo
    LegacyGrindRule(3, 5, 7, 11, 0),
    LegacyGrindRule(5, 7, 11, 13, 1),
    LegacyGrindRule(7, 11, 13, 17, 2),
    LegacyGrindRule(11, 13, 17, 19, 3),
    LegacyGrindRule(13, 17, 19, 23, 4),
    LegacyGrindRule(17, 19, 23, 29, 0),
    LegacyGrindRule(19, 23, 29, 31, 1),
    LegacyGrindRule(23, 29, 31, 37, 2),
    LegacyGrindRule(29, 31, 37, 41, 3),
    LegacyGrindRule(31, 37, 41, 43, 4),
    LegacyGrindRule(37, 41, 43, 47, 0)
  )

  def legacyGrindRule(step: Int): LegacyGrindRule = {
    require(step >= 1 && step <= 11, "La macinatura visibile richiede passo 1..11.")
    GRIND_TABLE_WITH_SENTINEL(step - 1) // BUG: sentinel per il primo passo
  }

  def legacyGrind(step: Int, oldValue: BigInt,
                  previous1: BigInt, previous3: BigInt,
                  previous7: BigInt, stones: Vector[BigInt]): BigInt = {
    require(stones.length == 5, "Una riga deve contenere cinque pietre.")
    val rule = legacyGrindRule(step)
    Patch01SaveWrapper.savePatch(
      oldValue * oldValue + rule.a * oldValue + rule.b * previous1 +
        rule.c * previous3 + rule.d * previous7 + stones(rule.stoneKind)
    )
  }
}

final case class Discovery06GrindReport(
  calculationDay: BigInt, targetDay: BigInt,
  step: Int, oldValue: BigInt, previous1: BigInt, previous3: BigInt,
  previous7: BigInt, stones: Vector[BigInt],
  legacyRule: LegacyGrindRule, legacyValue: BigInt,
  phase: String, status: String, trace: Vector[String]
)

final class Discovery06GrindHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "DISCOVERY_06_GRIND"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "BOOTSTRAPPED" ||
        ctx.branchTrace.toVector != Vector("BOOT") ||
        ctx.grindStepInput.isEmpty || ctx.grindValueInput.isEmpty ||
        ctx.grindPrev1Input.isEmpty || ctx.grindPrev3Input.isEmpty ||
        ctx.grindPrev7Input.isEmpty || ctx.grindStonesInput.isEmpty ||
        ctx.legacyGrindRuleOutput.nonEmpty || ctx.legacyGrindOutput.nonEmpty) {
      throw new IllegalStateException("DISCOVERY 06 richiede una nuova invocazione con tutti gli input.")
    }
    val step = ctx.grindStepInput.get
    val stones = ctx.grindStonesInput.get
    val rule = LegacyGrindTableAdapter.legacyGrindRule(step)
    val output = LegacyGrindTableAdapter.legacyGrind(
      step, ctx.grindValueInput.get, ctx.grindPrev1Input.get,
      ctx.grindPrev3Input.get, ctx.grindPrev7Input.get, stones
    )
    ctx.legacyGrindRuleOutput = Some(rule)
    ctx.legacyGrindOutput = Some(output)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery06.grind.calls")
    ctx.status = "LEGACY_GRIND_READY"
  }
}
