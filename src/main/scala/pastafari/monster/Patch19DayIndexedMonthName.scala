package pastafari.monster

import pastafari.catalog.SourceLanguageCatalog

/** PATCH19: il nome appartiene al mese selezionato dalla tessitura,
  * non all'offset del giorno. La vecchia diagnosi viene eseguita e
  * restituita inalterata; nessuna tessitura annuale è inventata.
  */
final case class Patch19DayIndexedMonthNameResult(
  historical: LegacyDayIndexedMonthNameResult,
  correctedMonthId: Int,
  correctedItalianMonthName: String
)

object Patch19DayIndexedMonthNameWrapper {
  def dayIndexedNamePatch(
    annualWeaving: Vector[Int],
    canonicalMonthNameIndices: Vector[Int],
    dayOffset: Int
  ): Patch19DayIndexedMonthNameResult = {
    val historical=LegacyDayIndexedMonthNameAdapter.oldDayIndexedMonthName(
      annualWeaving,canonicalMonthNameIndices,dayOffset)
    val monthId=annualWeaving(dayOffset)
    // Gli ID dei mesi nella tessitura sono 1-based; gli indici
    // dei nomi sono già stati scelti senza rimpiazzo dalla PATCH17.
    val canonicalNameId=canonicalMonthNameIndices(monthId-1)
    val corrected=SourceLanguageCatalog.month(canonicalNameId).italian
    Patch19DayIndexedMonthNameResult(historical,monthId,corrected)
  }
}

final case class Patch19DayIndexedMonthNameReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  annualWeaving: Vector[Int],
  canonicalMonthNameIndices: Vector[Int],
  dayOffset: Int,
  selectedMonthId: Int,
  legacyNameSlot: Int,
  frozenCatalogVersion: String,
  legacyItalianMonthName: String,
  correctedItalianMonthName: String,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch19DayIndexedMonthNameHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_19_DAY_INDEXED_MONTH_NAME"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_DAY_INDEXED_MONTH_NAME_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_19_DAY_INDEXED_MONTH_NAME") ||
       ctx.dayNameWeaving.isEmpty ||
       ctx.dayNameCanonicalIndices.isEmpty ||
       ctx.dayNameOffset.isEmpty ||
       ctx.dayNameSnapshot.isEmpty ||
       ctx.dayNameLegacyMonthId.isEmpty ||
       ctx.dayNameLegacySlot.isEmpty ||
       ctx.dayNameLegacyItalian.isEmpty ||
       ctx.dayNameFrozenVersion.isEmpty ||
       ctx.dayNamePatchedItalian.nonEmpty || ctx.patch19Applied)
      throw new IllegalStateException(
        "PATCH19 richiede una DISCOVERY19 integra e non già corretta.")

    val w=ctx.dayNameWeaving.get
    val ids=ctx.dayNameCanonicalIndices.get
    val day=ctx.dayNameOffset.get
    if(ctx.dayNameSnapshot.get!=(w,ids,day) ||
       ctx.dayNameFrozenVersion.get!=SourceLanguageCatalog.Version)
      throw new IllegalStateException(
        "Snapshot o versione congelata di DISCOVERY19 alterata.")

    val result=Patch19DayIndexedMonthNameWrapper.dayIndexedNamePatch(
      w,ids,day)
    if(result.historical.selectedMonthId!=ctx.dayNameLegacyMonthId.get ||
       result.historical.legacyNameSlot!=ctx.dayNameLegacySlot.get ||
       result.historical.legacyItalianMonthName!=ctx.dayNameLegacyItalian.get ||
       result.historical.frozenCatalogVersion!=ctx.dayNameFrozenVersion.get ||
       result.historical.annualWeaving!=w ||
       result.historical.canonicalMonthNameIndices!=ids ||
       result.historical.dayOffset!=day ||
       result.correctedMonthId!=w(day))
      throw new IllegalStateException(
        "Il rapporto storico è stato falsificato prima della PATCH19.")

    // Pubblicazione atomica, dopo verifica completa della cicatrice.
    ctx.dayNamePatchedItalian=Some(result.correctedItalianMonthName)
    ctx.patch19Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch19.day.name.calls")
    ctx.status="PATCH_19_READY"
  }
}
