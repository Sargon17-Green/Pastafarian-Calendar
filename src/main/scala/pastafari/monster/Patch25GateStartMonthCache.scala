package pastafari.monster

/** PATCH25: sostituisce la cache del primo giorno del varco con
  * la coppia (mese, giorno nel mese) del giorno target nell'anno.
  * La cicatrice del vecchio calcolo resta parte del rapporto.
  * Riceve una tessitura annuale già selezionata: niente salsa.
  */
final case class Patch25GateStartMonthCacheResult(
  historical: LegacyGateStartMonthCacheResult,
  correctedMonthId: Int,
  correctedDayInMonth: Int
)

object Patch25GateStartMonthCacheWrapper {
  def gateCacheMonthPatch(
    gateGaps: Vector[Int],
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): Patch25GateStartMonthCacheResult = {
    val historical=LegacyGateStartMonthCacheAdapter.oldGateStartMonthCache(
      gateGaps,annualWeaving,dayOffset)
    val month=annualWeaving(dayOffset)
    val ordinal=annualWeaving.iterator.take(dayOffset+1).count(_==month)
    Patch25GateStartMonthCacheResult(historical,month,ordinal)
  }
}

final case class Patch25GateStartMonthCacheReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  gateGaps: Vector[Int],
  annualWeaving: Vector[Int],
  dayOffset: Int,
  gateId: Int,
  gateStartDayOffset: Int,
  legacyMonthId: Int,
  legacyDayInMonth: Int,
  correctedMonthId: Int,
  correctedDayInMonth: Int,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch25GateStartMonthCacheHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_25_GATE_START_MONTH_CACHE"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_GATE_START_CACHE_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_25_GATE_START_MONTH_CACHE") ||
       ctx.gateCacheGaps.isEmpty || ctx.gateCacheAnnualWeaving.isEmpty ||
       ctx.gateCacheDayOffset.isEmpty || ctx.gateCacheInputSnapshot.isEmpty ||
       ctx.legacyGateCacheGateId.isEmpty ||
       ctx.legacyGateCacheStart.isEmpty ||
       ctx.legacyGateCacheMonthId.isEmpty ||
       ctx.legacyGateCacheOrdinal.isEmpty ||
       ctx.patch25CurrentMonthId.nonEmpty ||
       ctx.patch25CurrentDayInMonth.nonEmpty || ctx.patch25Applied)
      throw new IllegalStateException("PATCH25 richiede DISCOVERY25 integra.")
    val gaps=ctx.gateCacheGaps.get
    val weave=ctx.gateCacheAnnualWeaving.get
    val day=ctx.gateCacheDayOffset.get
    if(ctx.gateCacheInputSnapshot.get!=(gaps,weave,day))
      throw new IllegalStateException("Input modificati dopo DISCOVERY25.")
    val corrected=Patch25GateStartMonthCacheWrapper.gateCacheMonthPatch(
      gaps,weave,day)
    if(corrected.historical.gateGaps!=gaps ||
       corrected.historical.annualWeaving!=weave ||
       corrected.historical.dayOffset!=day ||
       corrected.historical.gateId!=ctx.legacyGateCacheGateId.get ||
       corrected.historical.gateStartDayOffset!=
         ctx.legacyGateCacheStart.get ||
       corrected.historical.legacyMonthId!=ctx.legacyGateCacheMonthId.get ||
       corrected.historical.legacyDayInMonth!=ctx.legacyGateCacheOrdinal.get)
      throw new IllegalStateException("Cicatrice DISCOVERY25 falsificata.")
    ctx.patch25CurrentMonthId=Some(corrected.correctedMonthId)
    ctx.patch25CurrentDayInMonth=Some(corrected.correctedDayInMonth)
    ctx.patch25Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch25.gate.cache.calls")
    ctx.status="PATCH_25_READY"
  }
}
