package pastafari.monster

/** DISCOVERY25: l'adapter storico congela il mese e il numero del
  * giorno al PRIMO giorno del varco. Poi riusa erroneamente la
  * coppia in tutte le giornate del varco.
  * Ingresso: intervalli e tessitura annuale già selezionati.
  */
final case class LegacyGateStartMonthCacheResult(
  gateGaps: Vector[Int],
  annualWeaving: Vector[Int],
  dayOffset: Int,
  gateId: Int,
  gateStartDayOffset: Int,
  legacyMonthId: Int,
  legacyDayInMonth: Int
)

object LegacyGateStartMonthCacheAdapter {
  def oldGateStartMonthCache(
    gateGaps: Vector[Int],
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): LegacyGateStartMonthCacheResult = {
    require(gateGaps.length>=6 && gateGaps.length<=47,
      "Numero di varchi fuori dal dominio diagnostico 6..47.")
    require(gateGaps.forall(g=>g>=42 && g<=963) &&
      gateGaps.sum>=252 && gateGaps.sum<=5778,
      "Intervalli dei varchi non validi.")
    require(annualWeaving.length==gateGaps.sum,
      "La tessitura non coincide con l'anno dei varchi.")
    LegacyDaywiseWeavingAdapter.validateCandidates(
      Vector(annualWeaving))
    require(dayOffset>=0 && dayOffset<annualWeaving.length,
      "Giorno fuori dall'anno.")
    var start=0
    var selectedStart= -1
    var selectedGate=0
    for((size,index)<-gateGaps.zipWithIndex) {
      if(dayOffset>=start && dayOffset<start+size) {
        selectedStart=start
        selectedGate=index+1
      }
      start+=size
    }
    if(selectedGate==0)
      throw new IllegalStateException("Varchi non coprono il giorno.")
    // CICATRICE: cache basata sull'inizio del varco.
    val month=annualWeaving(selectedStart)
    val ordinal=annualWeaving.iterator.take(selectedStart+1)
      .count(_==month)
    LegacyGateStartMonthCacheResult(
      gateGaps,annualWeaving,dayOffset,
      selectedGate,selectedStart,month,ordinal)
  }
}

final case class Discovery25GateStartMonthCacheReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  gateGaps: Vector[Int],
  annualWeaving: Vector[Int],
  dayOffset: Int,
  gateId: Int,
  gateStartDayOffset: Int,
  legacyMonthId: Int,
  legacyDayInMonth: Int,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery25GateStartMonthCacheHandler(
  metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_25_GATE_START_MONTH_CACHE"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.gateCacheGaps.isEmpty ||
       ctx.gateCacheAnnualWeaving.isEmpty ||
       ctx.gateCacheDayOffset.isEmpty ||
       ctx.gateCacheInputSnapshot.nonEmpty ||
       ctx.legacyGateCacheGateId.nonEmpty ||
       ctx.legacyGateCacheStart.nonEmpty ||
       ctx.legacyGateCacheMonthId.nonEmpty ||
       ctx.legacyGateCacheOrdinal.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY25 richiede bootstrap e input nuovi.")
    val r=LegacyGateStartMonthCacheAdapter.oldGateStartMonthCache(
      ctx.gateCacheGaps.get,ctx.gateCacheAnnualWeaving.get,
      ctx.gateCacheDayOffset.get)
    ctx.gateCacheInputSnapshot=Some((
      r.gateGaps,r.annualWeaving,r.dayOffset))
    ctx.legacyGateCacheGateId=Some(r.gateId)
    ctx.legacyGateCacheStart=Some(r.gateStartDayOffset)
    ctx.legacyGateCacheMonthId=Some(r.legacyMonthId)
    ctx.legacyGateCacheOrdinal=Some(r.legacyDayInMonth)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery25.gate.cache.calls")
    ctx.status="LEGACY_GATE_START_CACHE_READY"
  }
}
