package pastafari.monster

/**
 * PATCH 15: selezione unica della tessitura annuale, invariabile al variare
 * del giorno. La cicatrice legacy della DISCOVERY 15 resta intatta.
 * I candidati sono una famiglia sintetica materializzata e ordinata,
 * NON l'insieme completo ricavato dalla salsa del calendario canonico.
 */
final case class Patch15MonthWeavingResult(
  historical: LegacyPerDayWeavingResult,
  fixedAnnualWeaving: Vector[Int],
  correctedMonthId: Int,
  correctedDayInMonth: Int
)

object Patch15MonthWeavingWrapper {
  def daywiseWeavingPatch(
    candidates: Vector[Vector[Int]],
    yearRank1: BigInt,
    dayOffset: Int
  ): Patch15MonthWeavingResult = {
    // Obbligatorio: percorrere il vecchio codice della stessa chiamata.
    val historical=LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately(
      candidates,yearRank1,dayOffset)

    // La famiglia e' un Vector materializzato: il rango gia' verificato
    // non puo' superare la sua dimensione Int, non c'e' narrowing indebito.
    val annual=candidates((yearRank1-BigInt(1)).toInt)
    val month=annual(dayOffset)
    val dayInMonth=annual.iterator.take(dayOffset+1).count(_==month)
    Patch15MonthWeavingResult(historical,annual,month,dayInMonth)
  }
}

final case class Patch15MonthWeavingReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  candidates: Vector[Vector[Int]],
  yearRank1: BigInt,
  dayOffset: Int,
  legacyDayRank1: BigInt,
  legacyMonthId: Int,
  fixedAnnualWeaving: Vector[Int],
  correctedMonthId: Int,
  correctedDayInMonth: Int,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch15MonthWeavingHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_15_DAYWISE_WEAVING"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_DAYWISE_WEAVING_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_15_DAYWISE_WEAVING") ||
       ctx.daywiseCandidateWeavings.isEmpty ||
       ctx.daywiseYearRank1.isEmpty ||
       ctx.daywiseOffset.isEmpty ||
       ctx.daywiseInputSnapshot.isEmpty ||
       ctx.legacyDaywiseRank1.isEmpty ||
       ctx.legacyDaywiseMonthId.isEmpty ||
       ctx.patchedAnnualWeaving.nonEmpty ||
       ctx.patchedMonthId.nonEmpty ||
       ctx.patchedDayInMonth.nonEmpty ||
       ctx.patch15Applied)
      throw new IllegalStateException(
        "PATCH 15 richiede una DISCOVERY 15 completa senza output precedente.")

    val weaves=ctx.daywiseCandidateWeavings.get
    val rank=ctx.daywiseYearRank1.get
    val day=ctx.daywiseOffset.get
    // Anche se il mese risultante coincide, gli input devono essere identici
    // a quelli della discovery: protezione contro il cambio post-hoc.
    if(ctx.daywiseInputSnapshot.get!=(weaves,rank,day))
      throw new IllegalStateException(
        "Gli input della tessitura sono mutati dopo la discovery.")

    val result=Patch15MonthWeavingWrapper.daywiseWeavingPatch(weaves,rank,day)
    if(result.historical.candidates!=weaves ||
       result.historical.yearRank1!=rank ||
       result.historical.dayOffset!=day ||
       result.historical.dayRank1!=ctx.legacyDaywiseRank1.get ||
       result.historical.monthId!=ctx.legacyDaywiseMonthId.get)
      throw new IllegalStateException("La cicatrice originale e' stata falsificata.")

    // La pubblicazione e' atomica dopo le convalide.
    ctx.patchedAnnualWeaving=Some(result.fixedAnnualWeaving)
    ctx.patchedMonthId=Some(result.correctedMonthId)
    ctx.patchedDayInMonth=Some(result.correctedDayInMonth)
    ctx.patch15Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch15.month.weaving.calls")
    ctx.status="PATCH_15_READY"
  }
}
