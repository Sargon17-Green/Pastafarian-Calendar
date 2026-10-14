package pastafari.monster

import pastafari.catalog.SourceLanguageCatalog

/**
 * DISCOVERY 19: una tessitura annuale gia' selezionata assegna ogni
 * giorno a un ID mensile (1..n), ma il vecchio ponte seleziona il
 * nome usando dayOffset % n anziche' weaving(dayOffset)-1.
 *
 * I nomi sono indici canonici gia' scelti e tradotti correttamente
 * da PATCH18. Nessuna salsa, selezione di porte o anno completo.
 */
final case class LegacyDayIndexedMonthNameResult(
  annualWeaving: Vector[Int],
  canonicalMonthNameIndices: Vector[Int],
  dayOffset: Int,
  selectedMonthId: Int,
  legacyNameSlot: Int,
  frozenCatalogVersion: String,
  legacyItalianMonthName: String
)

object LegacyDayIndexedMonthNameAdapter {
  def oldDayIndexedMonthName(
    annualWeaving: Vector[Int],
    canonicalMonthNameIndices: Vector[Int],
    dayOffset: Int
  ): LegacyDayIndexedMonthNameResult = {
    LegacyDaywiseWeavingAdapter.validateCandidates(Vector(annualWeaving))
    val n=annualWeaving.max
    require(canonicalMonthNameIndices.size==n,
      "Un ID di nome canonico per ogni mese.")
    // PATCH18 mantiene la semantica 1-based del catalogo, ma questa
    // discovery NON invoca la vecchia rotazione di DISCOVERY18.
    val monthNames=Patch18SourceCatalogWrapper.sourceCatalogIndexPatch(
      canonicalMonthNameIndices).correctedItalianMonthNames
    require(dayOffset>=0 && dayOffset<annualWeaving.size,
      "Indice giornaliero fuori dalla tessitura.")
    val slot=dayOffset%n // CICATRICE: conta i giorni, non gli ID dei mesi
    LegacyDayIndexedMonthNameResult(
      annualWeaving,canonicalMonthNameIndices,dayOffset,
      annualWeaving(dayOffset),slot,SourceLanguageCatalog.Version,
      monthNames(slot))
  }
}

final case class Discovery19DayIndexedMonthNameReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  canonicalMonthNameIndices: Vector[Int],
  dayOffset: Int,
  selectedMonthId: Int,
  legacyNameSlot: Int,
  frozenCatalogVersion: String,
  legacyItalianMonthName: String,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery19DayIndexedMonthNameHandler(
  metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_19_DAY_INDEXED_MONTH_NAME"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.dayNameWeaving.isEmpty ||
       ctx.dayNameCanonicalIndices.isEmpty ||
       ctx.dayNameOffset.isEmpty ||
       ctx.dayNameSnapshot.nonEmpty ||
       ctx.dayNameLegacyMonthId.nonEmpty ||
       ctx.dayNameLegacySlot.nonEmpty ||
       ctx.dayNameLegacyItalian.nonEmpty ||
       ctx.dayNameFrozenVersion.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY19 richiede bootstrap nuovo e input integri.")
    val result=LegacyDayIndexedMonthNameAdapter.oldDayIndexedMonthName(
      ctx.dayNameWeaving.get,ctx.dayNameCanonicalIndices.get,
      ctx.dayNameOffset.get)
    // Nessuna mutazione viene pubblicata prima della validazione.
    ctx.dayNameSnapshot=Some((
      result.annualWeaving,result.canonicalMonthNameIndices,
      result.dayOffset))
    ctx.dayNameLegacyMonthId=Some(result.selectedMonthId)
    ctx.dayNameLegacySlot=Some(result.legacyNameSlot)
    ctx.dayNameLegacyItalian=Some(result.legacyItalianMonthName)
    ctx.dayNameFrozenVersion=Some(result.frozenCatalogVersion)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery19.day.name.calls")
    ctx.status="LEGACY_DAY_INDEXED_MONTH_NAME_READY"
  }
}
