package pastafari.monster

import pastafari.catalog.SourceLanguageCatalog

/**
 * DISCOVERY 18: gli indici canonici dei mesi sono 1..47, mentre
 * Vector Months usa posizioni 0..46. Il vecchio ponte sbaglia
 * usando l'indice canonico come posizione zero-based.
 *
 * La rotazione al modulo 47 evita soltanto un'eccezione per 47:
 * trasforma il mese sabbia nel nome argilla, difetto deliberato.
 * Diagnostico sintetico: l'input contiene indici gia' selezionati.
 */
final case class LegacySourceCatalogMismatchResult(
  canonicalMonthIndices: Vector[Int],
  frozenCatalogVersion: String,
  legacyItalianMonthNames: Vector[String]
)

object LegacySourceCatalogMismatchAdapter {
  def oldSourceCatalogMismatch(
    canonicalMonthIndices: Vector[Int]
  ): LegacySourceCatalogMismatchResult = {
    require(canonicalMonthIndices.length>=3 &&
      canonicalMonthIndices.length<=47,
      "La sequenza annuale deve avere da 3 a 47 mesi.")
    require(canonicalMonthIndices.distinct.length==
      canonicalMonthIndices.length,
      "La selezione canonica dei nomi non contiene duplicati.")
    require(canonicalMonthIndices.forall(x=>x>=1 && x<=47),
      "Indice fuori dal catalogo 1..47.")

    val source=SourceLanguageCatalog.Months
    require(source.length==47 &&
      source.indices.forall(i=>source(i).canonicalIndex==i+1),
      "Il catalogo italiano congelato deve essere in ordine canonico.")

    // ERRORE STORICO: l'ID 1 usa la posizione 1 (melagrana)
    // anziche' 0 (argilla); ID 47 usa la posizione 0.
    val wrong=canonicalMonthIndices.map(i=>source(i % 47).italian)
    LegacySourceCatalogMismatchResult(
      canonicalMonthIndices,SourceLanguageCatalog.Version,wrong)
  }
}

final case class Discovery18SourceCatalogMismatchReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  canonicalMonthIndices: Vector[Int],
  frozenCatalogVersion: String,
  legacyItalianMonthNames: Vector[String],
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery18SourceCatalogMismatchHandler(
  metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.catalogMonthIndices.isEmpty ||
       ctx.catalogInputSnapshot.nonEmpty ||
       ctx.catalogLegacyItalianNames.nonEmpty ||
       ctx.catalogFrozenVersion.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY 18 richiede un Bootstrap nuovo e input completi.")

    val old=LegacySourceCatalogMismatchAdapter.oldSourceCatalogMismatch(
      ctx.catalogMonthIndices.get)
    ctx.catalogInputSnapshot=Some(old.canonicalMonthIndices)
    ctx.catalogLegacyItalianNames=Some(old.legacyItalianMonthNames)
    ctx.catalogFrozenVersion=Some(old.frozenCatalogVersion)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery18.source.catalog.calls")
    ctx.status="LEGACY_SOURCE_CATALOG_MISMATCH_READY"
  }
}
