package pastafari.monster

import pastafari.catalog.SourceLanguageCatalog

/**
 * PATCH 18: l'indice canonico 1..47 accede allo stesso mese
 * nel catalogo italiano congelato, senza rotazione o riordino.
 *
 * L'errore storico 1-based/0-based rimane eseguito e visibile
 * nello stesso report. Gli indici sono gia' scelti dal chiamante:
 * non si pretende di implementare la salsa annuale completa.
 */
final case class Patch18SourceCatalogResult(
  historical: LegacySourceCatalogMismatchResult,
  correctedItalianMonthNames: Vector[String]
)

object Patch18SourceCatalogWrapper {
  def sourceCatalogIndexPatch(
    canonicalMonthIndices: Vector[Int]
  ): Patch18SourceCatalogResult = {
    val historical=
      LegacySourceCatalogMismatchAdapter.oldSourceCatalogMismatch(
        canonicalMonthIndices)

    // Il lookup pubblicato dal catalogo prende ID canonici 1-based,
    // non le posizioni zero-based del vecchio Vector.
    val corrected=canonicalMonthIndices.map(i=>
      SourceLanguageCatalog.month(i).italian)
    Patch18SourceCatalogResult(historical,corrected)
  }
}

final case class Patch18SourceCatalogReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  canonicalMonthIndices: Vector[Int],
  frozenCatalogVersion: String,
  legacyItalianMonthNames: Vector[String],
  correctedItalianMonthNames: Vector[String],
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch18SourceCatalogHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_18_SOURCE_CATALOG_INDEX"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_SOURCE_CATALOG_MISMATCH_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_18_SOURCE_CATALOG_MISMATCH") ||
       ctx.catalogMonthIndices.isEmpty ||
       ctx.catalogInputSnapshot.isEmpty ||
       ctx.catalogLegacyItalianNames.isEmpty ||
       ctx.catalogFrozenVersion.isEmpty ||
       ctx.patchedCatalogItalianNames.nonEmpty ||
       ctx.patch18Applied)
      throw new IllegalStateException(
        "PATCH 18 richiede una DISCOVERY 18 integra nella stessa richiesta.")

    val indices=ctx.catalogMonthIndices.get
    if(ctx.catalogInputSnapshot.get!=indices)
      throw new IllegalStateException(
        "Gli indici canonici sono cambiati dopo DISCOVERY 18.")

    val result=Patch18SourceCatalogWrapper.sourceCatalogIndexPatch(indices)
    if(result.historical.canonicalMonthIndices!=indices ||
       result.historical.frozenCatalogVersion!=ctx.catalogFrozenVersion.get ||
       result.historical.legacyItalianMonthNames!=
         ctx.catalogLegacyItalianNames.get)
      throw new IllegalStateException(
        "La cicatrice 1-based/0-based del catalogo e' stata falsificata.")
    if(ctx.catalogFrozenVersion.get!=SourceLanguageCatalog.Version ||
       result.correctedItalianMonthNames.length!=indices.length ||
       result.correctedItalianMonthNames.distinct.length!=indices.length)
      throw new IllegalStateException("Il catalogo sorgente non e' integro.")

    // Nessuno stato patch e' pubblicato prima delle verifiche.
    ctx.patchedCatalogItalianNames=Some(result.correctedItalianMonthNames)
    ctx.patch18Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch18.source.catalog.calls")
    ctx.status="PATCH_18_READY"
  }
}
