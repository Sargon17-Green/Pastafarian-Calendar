package pastafari.monster

import pastafari.catalog.SourceLanguageCatalog

/** PATCH21: il nome della cotoletta deriva dal segmento contenente
  * il giorno, non dal giorno modulo numero delle cotolette.
  * Conserva l'intero output storico DISCOVERY21.
  * Non genera la salsa annuale o i nomi canonici.
  */
final case class Patch21DayIndexedCutletNameResult(
  historical: LegacyDayIndexedCutletNameResult,
  correctedCanonicalNameId: Int,
  correctedItalianName: String
)

object Patch21DayIndexedCutletNameWrapper {
  def cutletNamePatch(
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    canonicalCutletNameIndices: Vector[Int],
    dayOffset: Int
  ): Patch21DayIndexedCutletNameResult = {
    val old=LegacyDayIndexedCutletNameAdapter.oldDayIndexedCutletName(
      gateGaps,cutletPartition,canonicalCutletNameIndices,dayOffset)
    // Ogni inizio della cotoletta e' inclusivo, prima porta
    // di chiusura della successiva esclusiva.
    var crossedGates=0
    var start=0
    var chosen = -1
    var i=0
    while(i<cutletPartition.size) {
      crossedGates+=cutletPartition(i)
      val end=gateGaps.take(crossedGates).sum
      if(dayOffset>=start && dayOffset<end) chosen=i
      start=end
      i+=1
    }
    if(chosen<0)
      throw new IllegalStateException("Nessuna cotoletta per il giorno.")
    val id=canonicalCutletNameIndices(chosen)
    Patch21DayIndexedCutletNameResult(
      old,id,SourceLanguageCatalog.cutlet(id).italian)
  }
}

final case class Patch21DayIndexedCutletNameReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  gateGaps: Vector[Int],
  cutletPartition: Vector[Int],
  canonicalCutletNameIndices: Vector[Int],
  dayOffset: Int,
  legacyNameSlot: Int,
  legacyCanonicalNameId: Int,
  legacyItalianName: String,
  catalogVersion: String,
  correctedCanonicalNameId: Int,
  correctedItalianName: String,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch21DayIndexedCutletNameHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_21_DAY_INDEXED_CUTLET_NAME"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_DAY_INDEXED_CUTLET_NAME_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_21_DAY_INDEXED_CUTLET_NAME") ||
       ctx.cutletNameGateGaps.isEmpty ||
       ctx.cutletNamePartition.isEmpty ||
       ctx.cutletCanonicalNameIndices.isEmpty ||
       ctx.cutletNameDayOffset.isEmpty ||
       ctx.cutletNameInputSnapshot.isEmpty ||
       ctx.legacyCutletNameSlot.isEmpty ||
       ctx.legacyCutletNameCanonicalId.isEmpty ||
       ctx.legacyCutletNameItalian.isEmpty ||
       ctx.legacyCutletNameCatalogVersion.isEmpty ||
       ctx.patchedCutletNameId.nonEmpty ||
       ctx.patchedCutletNameItalian.nonEmpty || ctx.patch21Applied)
      throw new IllegalStateException(
        "PATCH21 richiede DISCOVERY21 integra nella stessa richiesta.")
    val g=ctx.cutletNameGateGaps.get
    val p=ctx.cutletNamePartition.get
    val ids=ctx.cutletCanonicalNameIndices.get
    val d=ctx.cutletNameDayOffset.get
    if(ctx.cutletNameInputSnapshot.get!=(g,p,ids,d))
      throw new IllegalStateException("Input mutato dopo DISCOVERY21.")
    val result=Patch21DayIndexedCutletNameWrapper.cutletNamePatch(
      g,p,ids,d)
    if(result.historical.gateGaps!=g ||
       result.historical.cutletPartition!=p ||
       result.historical.canonicalCutletNameIndices!=ids ||
       result.historical.dayOffset!=d ||
       result.historical.legacyNameSlot!=ctx.legacyCutletNameSlot.get ||
       result.historical.legacyCanonicalNameId!=
         ctx.legacyCutletNameCanonicalId.get ||
       result.historical.legacyItalianName!=ctx.legacyCutletNameItalian.get ||
       result.historical.catalogVersion!=ctx.legacyCutletNameCatalogVersion.get)
      throw new IllegalStateException("Cicatrice DISCOVERY21 falsificata.")
    ctx.patchedCutletNameId=Some(result.correctedCanonicalNameId)
    ctx.patchedCutletNameItalian=Some(result.correctedItalianName)
    ctx.patch21Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch21.cutlet.name.calls")
    ctx.status="PATCH_21_READY"
  }
}
