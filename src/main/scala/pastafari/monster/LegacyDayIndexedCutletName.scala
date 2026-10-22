package pastafari.monster

import pastafari.catalog.SourceLanguageCatalog

/** DISCOVERY21: il vecchio ponte sceglie il nome della cotoletta
  * dal resto del giorno, anziche' dalla cotoletta contenente il giorno.
  * Gli intervalli delle porte e gli indici di nome sono gia' scelti.
  * Non costruisce la salsa normativa o la partizione annuale.
  */
final case class LegacyDayIndexedCutletNameResult(
  gateGaps: Vector[Int],
  cutletPartition: Vector[Int],
  canonicalCutletNameIndices: Vector[Int],
  dayOffset: Int,
  legacyNameSlot: Int,
  legacyCanonicalNameId: Int,
  legacyItalianName: String,
  catalogVersion: String
)

object LegacyDayIndexedCutletNameAdapter {
  def oldDayIndexedCutletName(
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    canonicalCutletNameIndices: Vector[Int],
    dayOffset: Int
  ): LegacyDayIndexedCutletNameResult = {
    require(cutletPartition.size>=6 && cutletPartition.size<=17,
      "La partizione richiede da 6 a 17 cotolette.")
    require(cutletPartition.forall(_>=1) &&
      cutletPartition.sum==gateGaps.size,
      "I gruppi delle porte devono essere positivi e completi.")
    require(gateGaps.forall(g=>g>=42 && g<=963),
      "Intervalli delle porte fuori da 42..963.")
    val yearDays=gateGaps.sum
    require(yearDays>=252 && yearDays<=5778,
      "Anno fuori da 252..5778.")
    require(dayOffset>=0 && dayOffset<yearDays,
      "Il giorno non appartiene all'anno.")
    require(canonicalCutletNameIndices.size==cutletPartition.size &&
      canonicalCutletNameIndices.distinct.size==
        canonicalCutletNameIndices.size &&
      canonicalCutletNameIndices.forall(id=>id>=1 && id<=17),
      "Indici canonici delle cotolette non validi.")
    val slot=dayOffset%cutletPartition.size // CICATRICE INTENZIONALE
    val id=canonicalCutletNameIndices(slot)
    LegacyDayIndexedCutletNameResult(
      gateGaps,cutletPartition,canonicalCutletNameIndices,dayOffset,
      slot,id,SourceLanguageCatalog.cutlet(id).italian,
      SourceLanguageCatalog.Version)
  }
}

final case class Discovery21DayIndexedCutletNameReport(
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
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery21DayIndexedCutletNameHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_21_DAY_INDEXED_CUTLET_NAME"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.cutletNameGateGaps.isEmpty || ctx.cutletNamePartition.isEmpty ||
       ctx.cutletCanonicalNameIndices.isEmpty ||
       ctx.cutletNameDayOffset.isEmpty ||
       ctx.cutletNameInputSnapshot.nonEmpty ||
       ctx.legacyCutletNameSlot.nonEmpty ||
       ctx.legacyCutletNameCanonicalId.nonEmpty ||
       ctx.legacyCutletNameItalian.nonEmpty ||
       ctx.legacyCutletNameCatalogVersion.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY21 richiede bootstrap e input nuovi.")

    val old=LegacyDayIndexedCutletNameAdapter.oldDayIndexedCutletName(
      ctx.cutletNameGateGaps.get,ctx.cutletNamePartition.get,
      ctx.cutletCanonicalNameIndices.get,ctx.cutletNameDayOffset.get)
    ctx.cutletNameInputSnapshot=Some((
      old.gateGaps,old.cutletPartition,
      old.canonicalCutletNameIndices,old.dayOffset))
    ctx.legacyCutletNameSlot=Some(old.legacyNameSlot)
    ctx.legacyCutletNameCanonicalId=Some(old.legacyCanonicalNameId)
    ctx.legacyCutletNameItalian=Some(old.legacyItalianName)
    ctx.legacyCutletNameCatalogVersion=Some(old.catalogVersion)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery21.cutlet.name.calls")
    ctx.status="LEGACY_DAY_INDEXED_CUTLET_NAME_READY"
  }
}
