package pastafari.monster

/**
 * DISCOVERY 13: il vecchio motore salta un numero stimato di anni
 * assumendo un'ampiezza costante di 5778 giorni. La norma percorre
 * invece i veri anni consecutivi e i rispettivi cancelli.
 *
 * La piccola finestra di anni sintetici è un diagnostico isolato:
 * nessun calcolo di anno 5000 canonico viene modificato qui.
 */
final case class LegacyYearJumpResult(
  anchorOpenDay: BigInt,
  yearsBefore: Vector[Int],
  yearsFromAnchor: Vector[Int],
  targetDay: BigInt,
  guessedOffset: BigInt,
  guessedOpenDay: BigInt,
  guessedCloseDay: BigInt
)

object LegacyYearJumpAdapter {
  private val ApproximateYearDays=BigInt(5778)

  def oldJumpGuess(
    anchorOpenDay: BigInt,
    yearsBefore: Vector[Int],
    yearsFromAnchor: Vector[Int],
    targetDay: BigInt
  ): LegacyYearJumpResult = {
    require(yearsBefore.nonEmpty && yearsFromAnchor.nonEmpty,
      "Servono durate note prima e dopo l'anno 5000.")
    require((yearsBefore++yearsFromAnchor).forall(x=>x>=252 && x<=5778),
      "Ogni anno sintetico deve durare fra 252 e 5778 giorni.")

    // BUG: tratta tutti gli anni come massimi, non percorre i cancelli.
    val relative=targetDay-anchorOpenDay-BigInt(1)
    val q=relative/ApproximateYearDays
    val r=relative%ApproximateYearDays
    val estimate=if(relative<0 && r!=0)q-1 else q
    val guessedOpen=anchorOpenDay+estimate*ApproximateYearDays
    LegacyYearJumpResult(
      anchorOpenDay,yearsBefore,yearsFromAnchor,targetDay,estimate,
      guessedOpen,guessedOpen+ApproximateYearDays)
  }
}

final case class Discovery13YearJumpReport(
  calculationDay: BigInt, targetDay: BigInt,
  anchorOpenDay: BigInt,
  yearsBefore: Vector[Int], yearsFromAnchor: Vector[Int],
  legacyYearOffset: BigInt,
  legacyOpenDay: BigInt,
  legacyCloseDay: BigInt,
  phase: String, status: String, trace: Vector[String]
)

final class Discovery13YearJumpHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_13_YEAR_JUMP"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if (ctx.status!="BOOTSTRAPPED" ||
        ctx.branchTrace.toVector!=Vector("BOOT") ||
        ctx.jumpAnchorOpenDay.isEmpty ||
        ctx.jumpBeforeLengths.isEmpty ||
        ctx.jumpFromAnchorLengths.isEmpty ||
        ctx.legacyJumpOffset.nonEmpty ||
        ctx.legacyJumpOpenDay.nonEmpty ||
        ctx.legacyJumpCloseDay.nonEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 13 richiede un Bootstrap fresco.")
    }
    val r=LegacyYearJumpAdapter.oldJumpGuess(
      ctx.jumpAnchorOpenDay.get,ctx.jumpBeforeLengths.get,
      ctx.jumpFromAnchorLengths.get,ctx.targetDay)
    ctx.legacyJumpOffset=Some(r.guessedOffset)
    ctx.legacyJumpOpenDay=Some(r.guessedOpenDay)
    ctx.legacyJumpCloseDay=Some(r.guessedCloseDay)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery13.year.jump.calls")
    ctx.status="LEGACY_YEAR_JUMP_READY"
  }
}
