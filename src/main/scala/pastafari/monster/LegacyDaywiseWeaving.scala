package pastafari.monster

/**
 * DISCOVERY 15: una lista SINTETICA di tessiture mensili, già ordinata
 * lessicograficamente, viene erroneamente scelta di nuovo per ogni giorno.
 * Il rango iniziale dovrebbe identificare un'unica tessitura per l'anno;
 * la cicatrice lo fa invece avanzare di dayOffset prima di leggere il mese.
 *
 * Questa famiglia diagnostica non genera salsa o tessiture canoniche:
 * convalida soltanto candidati completi forniti dal chiamante.
 */
final case class LegacyPerDayWeavingResult(
  candidates: Vector[Vector[Int]],
  yearRank1: BigInt,
  dayOffset: Int,
  dayRank1: BigInt,
  monthId: Int
)

object LegacyDaywiseWeavingAdapter {
  def validateCandidates(candidates: Vector[Vector[Int]]): Unit = {
    require(candidates.nonEmpty,"La famiglia sintetica non può essere vuota.")
    val length=candidates.head.length
    require(length>=252 && length<=5778,
      "Il numero sintetico di giorni deve essere tra 252 e 5778.")
    val monthCount=candidates.head.maxOption.getOrElse(0)
    require(monthCount>=3 && monthCount<=47,
      "Sono necessari da tre a quarantasette mesi.")
    val expectedCounts=Vector.tabulate(monthCount)(j=>
      candidates.head.count(_==j+1))
    require(expectedCounts.forall(x=>x>=4 && x<=123),
      "Ogni mese deve durare da 4 a 123 giorni.")
    require(expectedCounts.sum==length,
      "Il numero di giorni non coincide con le durate dei mesi.")

    var previous=Vector.empty[Int]
    for((weaving,index)<-candidates.zipWithIndex) {
      require(weaving.length==length && weaving.forall(x=>x>=1 && x<=monthCount),
        "Tessitura non valida per lunghezza o ID.")
      require(Vector.tabulate(monthCount)(j=>
        weaving.count(_==j+1))==expectedCounts,
        "Le durate dei mesi non coincidono.")

      // Inizio e fine dei mesi devono seguire entrambi l'ordine 1..m.
      val consumed=Array.fill(monthCount)(0)
      var opened=0
      var closed=0
      weaving.foreach { month =>
        val idx=month-1
        if(consumed(idx)==0) {
          require(month==opened+1,"Un mese è stato aperto fuori ordine.")
          opened=month
        }
        consumed(idx)+=1
        if(consumed(idx)==expectedCounts(idx)) {
          require(month==closed+1,"Un mese è stato chiuso fuori ordine.")
          closed=month
        }
      }
      require(opened==monthCount && closed==monthCount,
        "I mesi non sono stati aperti e chiusi integralmente.")

      if(index>0) {
        var position=0
        while(position<length && previous(position)==weaving(position))
          position+=1
        require(position<length && previous(position)<weaving(position),
          "I candidati devono essere distinti e in ordine lessicografico.")
      }
      previous=weaving
    }
  }

  def legacyChooseEachDaySeparately(
    candidates: Vector[Vector[Int]],
    yearRank1: BigInt,
    dayOffset: Int
  ): LegacyPerDayWeavingResult = {
    validateCandidates(candidates)
    require(yearRank1>=1 && yearRank1<=BigInt(candidates.size),
      "Rango annuale fuori dalla famiglia.")
    require(dayOffset>=0 && dayOffset<candidates.head.size,
      "Giorno fuori dal dominio della tessitura.")

    // ERRORE VOLUTO: il rango riparte dal giorno, non dalla struttura
    // annuale immutabile; selezione distinta a ogni chiamata.
    val dayRank=BigInt(1)+((yearRank1-BigInt(1)+BigInt(dayOffset)) %
      BigInt(candidates.size))
    val oldMonth=candidates(dayRank.toInt-1)(dayOffset)
    LegacyPerDayWeavingResult(candidates,yearRank1,dayOffset,dayRank,oldMonth)
  }
}

final case class Discovery15DaywiseWeavingReport(
  calculationDay: BigInt, targetDay: BigInt,
  candidates: Vector[Vector[Int]], yearRank1: BigInt, dayOffset: Int,
  legacyDayRank1: BigInt, legacyMonthId: Int,
  phase: String, status: String, trace: Vector[String]
)

final class Discovery15DaywiseWeavingHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_15_DAYWISE_WEAVING"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.daywiseCandidateWeavings.isEmpty ||
       ctx.daywiseYearRank1.isEmpty ||
       ctx.daywiseOffset.isEmpty ||
       ctx.daywiseInputSnapshot.nonEmpty ||
       ctx.legacyDaywiseRank1.nonEmpty ||
       ctx.legacyDaywiseMonthId.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY 15 richiede un Bootstrap nuovo e tutti gli input.")

    // Tutta la validazione precede la pubblicazione nel contesto.
    val result=LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately(
      ctx.daywiseCandidateWeavings.get,ctx.daywiseYearRank1.get,
      ctx.daywiseOffset.get)
    ctx.daywiseInputSnapshot=Some((
      result.candidates,result.yearRank1,result.dayOffset))
    ctx.legacyDaywiseRank1=Some(result.dayRank1)
    ctx.legacyDaywiseMonthId=Some(result.monthId)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery15.daywise.weaving.calls")
    ctx.status="LEGACY_DAYWISE_WEAVING_READY"
  }
}
