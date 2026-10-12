package pastafari.monster

/**
 * PATCH 13: percorre i veri confini consecutivi degli anni,
 * con intervalli (apertura, chiusura]. Non corregge né cancella
 * la stima legacy a finestre fisse di 5778 giorni.
 *
 * Le durate sono un diagnostico sintetico delimitato e non la
 * generazione canonica dei cancelli dell'anno 5000.
 */
final case class Patch13YearJumpResult(
  historical: LegacyYearJumpResult,
  correctedOffset: BigInt,
  correctedOpenDay: BigInt,
  correctedCloseDay: BigInt
)

object Patch13YearJumpWrapper {
  def yearJumpPatch(
    anchorOpenDay: BigInt,
    yearsBefore: Vector[Int],
    yearsFromAnchor: Vector[Int],
    targetDay: BigInt
  ): Patch13YearJumpResult = {
    // Attraversamento reale del vecchio algoritmo nella medesima chiamata.
    val historical=LegacyYearJumpAdapter.oldJumpGuess(
      anchorOpenDay,yearsBefore,yearsFromAnchor,targetDay)

    if(targetDay>anchorOpenDay) {
      var open=anchorOpenDay
      for(i<-yearsFromAnchor.indices) {
        val close=open+BigInt(yearsFromAnchor(i))
        if(targetDay<=close)
          return Patch13YearJumpResult(historical,BigInt(i),open,close)
        open=close
      }
    } else {
      var close=anchorOpenDay
      for(i<-yearsBefore.indices) {
        val open=close-BigInt(yearsBefore(i))
        if(targetDay>open)
          return Patch13YearJumpResult(historical,-BigInt(i)-1,open,close)
        close=open
      }
    }
    throw new IllegalArgumentException(
      "Il giorno richiesto è fuori dalla finestra sintetica dei cancelli.")
  }
}

final case class Patch13YearJumpReport(
  calculationDay: BigInt, targetDay: BigInt,
  anchorOpenDay: BigInt,
  yearsBefore: Vector[Int], yearsFromAnchor: Vector[Int],
  legacyYearOffset: BigInt, legacyOpenDay: BigInt, legacyCloseDay: BigInt,
  correctedYearOffset: BigInt, correctedOpenDay: BigInt,
  correctedCloseDay: BigInt, patchApplied: Boolean,
  phase: String, status: String, trace: Vector[String]
)

final class Patch13YearJumpHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_13_YEAR_JUMP"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="LEGACY_YEAR_JUMP_READY" ||
       ctx.branchTrace.toVector!=Vector("BOOT","DISCOVERY_13_YEAR_JUMP") ||
       ctx.jumpAnchorOpenDay.isEmpty ||
       ctx.jumpBeforeLengths.isEmpty ||
       ctx.jumpFromAnchorLengths.isEmpty ||
       ctx.legacyJumpOffset.isEmpty ||
       ctx.legacyJumpOpenDay.isEmpty ||
       ctx.legacyJumpCloseDay.isEmpty ||
       ctx.patchedJumpOffset.nonEmpty ||
       ctx.patchedJumpOpenDay.nonEmpty ||
       ctx.patchedJumpCloseDay.nonEmpty || ctx.patch13Applied)
      throw new IllegalStateException(
        "PATCH 13 richiede una DISCOVERY 13 completa nello stesso contesto.")

    val result=Patch13YearJumpWrapper.yearJumpPatch(
      ctx.jumpAnchorOpenDay.get,ctx.jumpBeforeLengths.get,
      ctx.jumpFromAnchorLengths.get,ctx.targetDay)
    if(result.historical.guessedOffset!=ctx.legacyJumpOffset.get ||
       result.historical.guessedOpenDay!=ctx.legacyJumpOpenDay.get ||
       result.historical.guessedCloseDay!=ctx.legacyJumpCloseDay.get)
      throw new IllegalStateException(
        "La traccia della stima legacy è stata alterata.")
    ctx.patchedJumpOffset=Some(result.correctedOffset)
    ctx.patchedJumpOpenDay=Some(result.correctedOpenDay)
    ctx.patchedJumpCloseDay=Some(result.correctedCloseDay)
    ctx.patch13Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch13.year.jump.calls")
    ctx.status="PATCH_13_READY"
  }
}
