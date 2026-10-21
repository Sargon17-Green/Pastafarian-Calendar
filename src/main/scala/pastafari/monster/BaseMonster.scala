package pastafari.monster

import scala.collection.mutable

final case class BaseMonsterContext(
  calculationDay: BigInt,
  targetDay: BigInt,
  var phase: String = "BOOT",
  var subPhase: Int = 0,
  var mode: String = "BASE",
  var status: String = "NEW",
  branchTrace: mutable.ArrayBuffer[String] = mutable.ArrayBuffer.empty[String],
  diagnostics: mutable.ArrayBuffer[String] = mutable.ArrayBuffer.empty[String],
  var legacyRemainderInput: Option[BigInt] = None,
  var legacyRemainderOutput: Option[BigInt] = None,
  var patchedSaveOutput: Option[BigInt] = None,
  var patch01Applied: Boolean = false,
  var legacyDayTagInput: Option[BigInt] = None,
  var legacyDayTagOutput: Option[BigInt] = None,
  var patchedDayTagOutput: Option[BigInt] = None,
  var patch02Applied: Boolean = false,
  var legacyDistanceOutput: Option[BigInt] = None,
  var patchedDistanceOutput: Option[BigInt] = None,
  var patch03Applied: Boolean = false,
  var legacyStoneRowsOutput: Option[Vector[Vector[BigInt]]] = None,
  var patchedStoneRowsOutput: Option[Vector[Vector[BigInt]]] = None,
  var patch04Applied: Boolean = false,
  var priorHiddenInput: Option[Vector[BigInt]] = None,
  var priorVisibleInput: Option[Vector[BigInt]] = None,
  var priorIndexInput: Option[Int] = None,
  var priorLagInput: Option[Int] = None,
  var legacyPriorOutput: Option[BigInt] = None,
  var patchedPriorOutput: Option[BigInt] = None,
  var patch05Applied: Boolean = false,
  var grindStepInput: Option[Int] = None,
  var grindValueInput: Option[BigInt] = None,
  var grindPrev1Input: Option[BigInt] = None,
  var grindPrev3Input: Option[BigInt] = None,
  var grindPrev7Input: Option[BigInt] = None,
  var grindStonesInput: Option[Vector[BigInt]] = None,
  var legacyGrindRuleOutput: Option[LegacyGrindRule] = None,
  var legacyGrindOutput: Option[BigInt] = None,
  var patchedGrindRuleOutput: Option[LegacyGrindRule] = None,
  var patchedGrindOutput: Option[BigInt] = None,
  var patch06Applied: Boolean = false,
  var permutationRankInput: Option[Int] = None,
  var legacyPermutationOutput: Option[Vector[Int]] = None,
  var patchedPermutationOutput: Option[Vector[Int]] = None,
  var patch07Applied: Boolean = false,
  var bowlStepInput: Option[Int] = None,
  var bowlRankInput: Option[Int] = None,
  var bowlInput: Option[Vector[BigInt]] = None,
  var bowlDropInput: Option[BigInt] = None,
  var bowlStonesInput: Option[Vector[BigInt]] = None,
  var legacyBowlOrderOutput: Option[Vector[Int]] = None,
  var legacyBowlPoursOutput: Option[Vector[BigInt]] = None,
  var legacyBowlOutput: Option[Vector[BigInt]] = None,
  var patchedBowlOutput: Option[Vector[BigInt]] = None,
  var patch08Applied: Boolean = false,
  var postStirInput: Option[Vector[BigInt]] = None,
  var legacyVaultRounds: Option[Vector[LegacyVaultRound]] = None,
  var legacyVaultOutput: Option[Vector[BigInt]] = None,
  var patchedVaultRounds: Option[Vector[LegacyVaultRound]] = None,
  var patchedVaultOutput: Option[Vector[BigInt]] = None,
  var patch09Applied: Boolean = false,
  var penultimateDropValue: Option[BigInt] = None,
  var finalDropValue: Option[BigInt] = None,
  var queriedBowlInput: Option[Int] = None,
  var legacyLatchedOrder45: Option[Vector[Int]] = None,
  var observedOrder46: Option[Vector[Int]] = None,
  var legacyNextBowlOutput: Option[Int] = None,
  var patchedLatchedOrder46: Option[Vector[Int]] = None,
  var patchedNextBowlOutput: Option[Int] = None,
  var patch10Applied: Boolean = false,
  var selectionSampleInput: Option[BigInt] = None,
  var selectionDirectionInput: Option[Int] = None,
  var selectionFamilySizeInput: Option[BigInt] = None,
  var legacyBiasedSampleOutput: Option[BigInt] = None,
  var legacyBiasedRankOutput: Option[BigInt] = None,
  var legacyAcceptanceLimitOutput: Option[BigInt] = None,
  var patchedAcceptedSample: Option[BigInt] = None,
  var patchedShortPickRank: Option[BigInt] = None,
  var patchedSkippedSamples: Option[BigInt] = None,
  var patch11Applied: Boolean = false,
  var legacyYearGapsInput: Option[Vector[Int]] = None,
  var legacyYearLengthOutput: Option[BigInt] = None,
  var legacyYearAcceptedOutput: Option[Boolean] = None,
  var legacyYearMaxOutput: Option[Int] = None,
  var patchedYearAcceptedOutput: Option[Boolean] = None,
  var patchedYearMaxOutput: Option[Int] = None,
  var patch12Applied: Boolean = false,
  var jumpAnchorOpenDay: Option[BigInt] = None,
  var jumpBeforeLengths: Option[Vector[Int]] = None,
  var jumpFromAnchorLengths: Option[Vector[Int]] = None,
  var legacyJumpOffset: Option[BigInt] = None,
  var legacyJumpOpenDay: Option[BigInt] = None,
  var legacyJumpCloseDay: Option[BigInt] = None,
  var patchedJumpOffset: Option[BigInt] = None,
  var patchedJumpOpenDay: Option[BigInt] = None,
  var patchedJumpCloseDay: Option[BigInt] = None,
  var patch13Applied: Boolean = false,
  var virtualFirstGateIndex: Option[BigInt] = None,
  var virtualGateStride: Option[BigInt] = None,
  var virtualCandidateCount: Option[BigInt] = None,
  var virtualRequestedRank: Option[BigInt] = None,
  var legacyVirtualNarrowedRank: Option[Int] = None,
  var legacyVirtualSelectedGateIndex: Option[BigInt] = None,
  var virtualDiscoveryInputSnapshot: Option[(BigInt,BigInt,BigInt,BigInt)] = None,
  var patchedVirtualSelectedGateIndex: Option[BigInt] = None,
  var patch14Applied: Boolean = false,
  var daywiseCandidateWeavings: Option[Vector[Vector[Int]]] = None,
  var daywiseYearRank1: Option[BigInt] = None,
  var daywiseOffset: Option[Int] = None,
  var daywiseInputSnapshot: Option[(Vector[Vector[Int]],BigInt,Int)] = None,
  var legacyDaywiseRank1: Option[BigInt] = None,
  var legacyDaywiseMonthId: Option[Int] = None,
  var patchedAnnualWeaving: Option[Vector[Int]] = None,
  var patchedMonthId: Option[Int] = None,
  var patchedDayInMonth: Option[Int] = None,
  var patch15Applied: Boolean = false,
  var contiguousAnnualWeaving: Option[Vector[Int]] = None,
  var contiguousDayOffset: Option[Int] = None,
  var contiguousInputSnapshot: Option[(Vector[Int],Int)] = None,
  var legacyContiguousMonthLengths: Option[Vector[Int]] = None,
  var legacyContiguousSelectedMonthId: Option[Int] = None,
  var legacyContiguousAssumedStartOffset: Option[Int] = None,
  var legacyContiguousDayInMonth: Option[Int] = None,
  var patchedContiguousMonthId: Option[Int] = None,
  var patchedContiguousDayInMonth: Option[Int] = None,
  var patch16Applied: Boolean = false,
  var monthNameCount: Option[Int] = None,
  var monthNameRank1: Option[BigInt] = None,
  var monthNameInputSnapshot: Option[(Int,BigInt)] = None,
  var legacyMonthNameIndices: Option[Vector[Int]] = None,
  var legacyMonthNameDistinctChoices: Option[BigInt] = None,
  var legacyMonthNameReplacementSpace: Option[BigInt] = None,
  var patchedDistinctMonthNameIndices: Option[Vector[Int]] = None,
  var patch17Applied: Boolean = false,
  var catalogMonthIndices: Option[Vector[Int]] = None,
  var catalogInputSnapshot: Option[Vector[Int]] = None,
  var catalogLegacyItalianNames: Option[Vector[String]] = None,
  var catalogFrozenVersion: Option[String] = None,
  var patchedCatalogItalianNames: Option[Vector[String]] = None,
  var patch18Applied: Boolean = false,
  var dayNameWeaving: Option[Vector[Int]] = None,
  var dayNameCanonicalIndices: Option[Vector[Int]] = None,
  var dayNameOffset: Option[Int] = None,
  var dayNameSnapshot: Option[(Vector[Int],Vector[Int],Int)] = None,
  var dayNameLegacyMonthId: Option[Int] = None,
  var dayNameLegacySlot: Option[Int] = None,
  var dayNameLegacyItalian: Option[String] = None,
  var dayNameFrozenVersion: Option[String] = None,
  var dayNamePatchedItalian: Option[String] = None,
  var patch19Applied: Boolean = false,
  var cutletGateGaps: Option[Vector[Int]] = None,
  var cutletGatePartition: Option[Vector[Int]] = None,
  var cutletDayOffset: Option[Int] = None,
  var cutletBoundarySnapshot: Option[(Vector[Int],Vector[Int],Int)] = None,
  var legacyCutletStartOffsets: Option[Vector[Int]] = None,
  var legacyCutletId: Option[Int] = None,
  var legacyDayInCutlet: Option[Int] = None,
  var patchedCutletId: Option[Int] = None,
  var patchedDayInCutlet: Option[Int] = None,
  var patch20Applied: Boolean = false
)

final class BaseMetricsShell {
  private val counters = mutable.Map.empty[String, BigInt]

  def bump(name: String): Unit = {
    counters.update(name, counters.getOrElse(name, BigInt(0)) + 1)
  }

  def snapshot: Map[String, BigInt] = counters.toMap
}

final class BaseValidationManager {
  def requireFreshContext(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "NEW") {
      throw new IllegalStateException("Il contesto di base non è nuovo.")
    }
    if (ctx.branchTrace.nonEmpty) {
      throw new IllegalStateException("La traccia di un contesto nuovo deve essere vuota.")
    }
  }


  /** Ricalcolo separato: né wrapper corretto né oracolo test-only. */
  /** Verifica indipendente della cicatrice di troncamento signed 32 bit. */
  /**
   * PATCH 14: prova della scelta BigInt senza richiamare il wrapper corretto.
   * Un ranking 1-based valido deve soddisfare:
   * selected-first == stride*(rank-1).
   */
  /** Prova indipendente dell'errore storico: giorno per giorno, mai PATCH15. */
  /** Verifica autonoma della tessitura annuale fissa e del giorno mensile. */
  /**
   * Ricostruzione autonoma della cicatrice dei mesi contigui.
   * L'oracolo del prefisso tessuto NON è usato in produzione:
   * lo scopo è certificare proprio il difetto di DISCOVERY 16.
   */
  /**
   * PATCH 16: prova indipendente della selezione di un mese già fisso
   * e del numero di apparizioni fino al giorno richiesto.
   * Non chiama il wrapper corretto o l'oracolo dei test.
   */
  /** DISCOVERY17: certifica senza correggerla la base 47 CON rimpiazzo. */
  /**
   * PATCH 17: verifica indipendente senza chiamare il wrapper
   * corretto o l'oracolo test-only. Ricalcola la selezione
   * storica e ricostruisce il rango dalle posizioni eliminate.
   */
  /**
   * DISCOVERY18: ricostruisce autonomamente il bug 1-based/0-based.
   * Non applica il lookup corretto del catalogo ai risultati.
   */
  /**
   * PATCH18: valida con una scansione indipendente la cicatrice
   * dell'indice ruotato e la mappatura esatta dell'ID canonico.
   * Non richiama mai Patch18SourceCatalogWrapper.
   */
  /**
   * DISCOVERY19: ricostruisce la lettura storica del nome con
   * l'offset del giorno, senza richiamare l'adapter o un oracolo test.
   */
  def requireDiscovery19Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="DISCOVERY_19_DAY_INDEXED_MONTH_NAME" ||
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
       ctx.dayNameFrozenVersion.isEmpty)
      throw new IllegalStateException("DISCOVERY19 non completa.")

    val w=ctx.dayNameWeaving.get
    val ids=ctx.dayNameCanonicalIndices.get
    val day=ctx.dayNameOffset.get
    if(ctx.dayNameSnapshot.get!=(w,ids,day))
      throw new IllegalStateException("Snapshot DISCOVERY19 alterata.")
    LegacyDaywiseWeavingAdapter.validateCandidates(Vector(w))
    if(day<0 || day>=w.size || ids.size!=w.max ||
       ids.distinct.size!=ids.size ||
       ids.exists(i=>i<1 || i>47))
      throw new IllegalStateException("Input DISCOVERY19 non valido.")
    val source=pastafari.catalog.SourceLanguageCatalog.Months
    if(source.size!=47 ||
       source.indices.exists(i=>source(i).canonicalIndex!=i+1) ||
       ctx.dayNameFrozenVersion.get!=
         pastafari.catalog.SourceLanguageCatalog.Version)
      throw new IllegalStateException("Catalogo congelato alterato.")
    val wrongSlot=day%ids.size
    val wrongId=ids(wrongSlot)
    val wrongName=source.find(_.canonicalIndex==wrongId)
      .getOrElse(throw new IllegalStateException("ID assente.")).italian
    if(ctx.dayNameLegacyMonthId.get!=w(day) ||
       ctx.dayNameLegacySlot.get!=wrongSlot ||
       ctx.dayNameLegacyItalian.get!=wrongName)
      throw new IllegalStateException("Cicatrice DISCOVERY19 falsificata.")
  }


  /**
   * PATCH19: verifica indipendente della mappatura nome/mese.
   * Non richiama né l'adapter storico né il wrapper della patch.
   */

  /** DISCOVERY20: conferma indipendente del confine storico ">".
    * La regola normativa ">=" resta riservata ai soli test.
    */

  /**
   * PATCH20: valica autonomamente le soglie cumulative inclusive.
   * Non chiama il wrapper, l'adapter storico o l'oracolo dei test.
   */
  def requirePatch20Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_20_CUTLET_OPEN_BOUNDARY" ||
       ctx.status!="PATCH_20_READY" || !ctx.patch20Applied ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_20_CUTLET_OPEN_BOUNDARY",
         "PATCH_20_CUTLET_OPEN_BOUNDARY") ||
       ctx.cutletGateGaps.isEmpty || ctx.cutletGatePartition.isEmpty ||
       ctx.cutletDayOffset.isEmpty || ctx.cutletBoundarySnapshot.isEmpty ||
       ctx.legacyCutletStartOffsets.isEmpty || ctx.legacyCutletId.isEmpty ||
       ctx.legacyDayInCutlet.isEmpty || ctx.patchedCutletId.isEmpty ||
       ctx.patchedDayInCutlet.isEmpty)
      throw new IllegalStateException("PATCH20 non completa.")

    val gaps=ctx.cutletGateGaps.get
    val parts=ctx.cutletGatePartition.get
    val day=ctx.cutletDayOffset.get
    if(ctx.cutletBoundarySnapshot.get!=(gaps,parts,day) ||
       parts.length<6 || parts.length>17 || parts.exists(_<1) ||
       parts.sum!=gaps.length || gaps.exists(g=>g<42 || g>963) ||
       gaps.sum<252 || gaps.sum>5778 || day<0 || day>=gaps.sum)
      throw new IllegalStateException("Input o snapshot PATCH20 invalida.")

    // Ricostruzione dalla durata di ogni segmento, indipendente
    // dai valori di inizio del wrapper.
    var gate=0
    var start=0
    var correctId=0
    var correctDay=0
    val starts=scala.collection.mutable.ArrayBuffer.empty[Int]
    for((intervals,index)<-parts.zipWithIndex) {
      starts+=start
      var duration=0
      var k=0
      while(k<intervals) {
        duration+=gaps(gate)
        gate+=1
        k+=1
      }
      if(day>=start && day<start+duration) {
        correctId=index+1
        correctDay=day-start+1
      }
      start+=duration
    }
    if(gate!=gaps.length || start!=gaps.sum || correctId==0)
      throw new IllegalStateException("Partizione PATCH20 non valida.")

    val legacy=1+starts.drop(1).count(_<day)
    val oldDay=day-starts(legacy-1)+1
    if(ctx.legacyCutletStartOffsets.get!=starts.toVector ||
       ctx.legacyCutletId.get!=legacy ||
       ctx.legacyDayInCutlet.get!=oldDay ||
       ctx.patchedCutletId.get!=correctId ||
       ctx.patchedDayInCutlet.get!=correctDay)
      throw new IllegalStateException("Risultato PATCH20 manomesso.")
  }

  def requireDiscovery20Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="DISCOVERY_20_CUTLET_OPEN_BOUNDARY" ||
       ctx.status!="LEGACY_CUTLET_BOUNDARY_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_20_CUTLET_OPEN_BOUNDARY") ||
       ctx.cutletGateGaps.isEmpty || ctx.cutletGatePartition.isEmpty ||
       ctx.cutletDayOffset.isEmpty || ctx.cutletBoundarySnapshot.isEmpty ||
       ctx.legacyCutletStartOffsets.isEmpty ||
       ctx.legacyCutletId.isEmpty || ctx.legacyDayInCutlet.isEmpty)
      throw new IllegalStateException("DISCOVERY20 non completa.")
    val gaps=ctx.cutletGateGaps.get
    val parts=ctx.cutletGatePartition.get
    val day=ctx.cutletDayOffset.get
    if(ctx.cutletBoundarySnapshot.get!=(gaps,parts,day))
      throw new IllegalStateException("Snapshot DISCOVERY20 alterata.")
    if(parts.length<6 || parts.length>17 || parts.exists(_<1) ||
       parts.sum!=gaps.length || gaps.exists(g=>g<42 || g>963) ||
       gaps.sum<252 || gaps.sum>5778 || day<0 || day>=gaps.sum)
      throw new IllegalStateException("Input DISCOVERY20 non valido.")
    val starts=parts.scanLeft(0)(_+_).init
      .map(k=>gaps.take(k).sum)
    // Ricalcolo indipendente: si chiude la cotoletta soltanto
    // quando il giorno supera strettamente il nuovo inizio.
    var oldId=1
    var i=1
    while(i<starts.length) {
      if(day>starts(i)) oldId+=1
      i+=1
    }
    val oldDay=day-starts(oldId-1)+1
    if(ctx.legacyCutletStartOffsets.get!=starts ||
       ctx.legacyCutletId.get!=oldId ||
       ctx.legacyDayInCutlet.get!=oldDay)
      throw new IllegalStateException("Cicatrice DISCOVERY20 alterata.")
  }

  def requirePatch19Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_19_DAY_INDEXED_MONTH_NAME" ||
       ctx.status!="PATCH_19_READY" || !ctx.patch19Applied ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_19_DAY_INDEXED_MONTH_NAME",
         "PATCH_19_DAY_INDEXED_MONTH_NAME") ||
       ctx.dayNameWeaving.isEmpty || ctx.dayNameCanonicalIndices.isEmpty ||
       ctx.dayNameOffset.isEmpty || ctx.dayNameSnapshot.isEmpty ||
       ctx.dayNameLegacyMonthId.isEmpty || ctx.dayNameLegacySlot.isEmpty ||
       ctx.dayNameLegacyItalian.isEmpty || ctx.dayNameFrozenVersion.isEmpty ||
       ctx.dayNamePatchedItalian.isEmpty)
      throw new IllegalStateException("PATCH19 non completa.")

    val w=ctx.dayNameWeaving.get
    val ids=ctx.dayNameCanonicalIndices.get
    val day=ctx.dayNameOffset.get
    if(ctx.dayNameSnapshot.get!=(w,ids,day))
      throw new IllegalStateException("Snapshot PATCH19 alterata.")
    LegacyDaywiseWeavingAdapter.validateCandidates(Vector(w))
    if(day<0 || day>=w.size || ids.size!=w.max ||
       ids.distinct.length!=ids.length ||
       ids.exists(i=>i<1 || i>47))
      throw new IllegalStateException("Input PATCH19 non valido.")

    val catalog=pastafari.catalog.SourceLanguageCatalog.Months
    if(catalog.length!=47 ||
       catalog.indices.exists(i=>catalog(i).canonicalIndex!=i+1) ||
       ctx.dayNameFrozenVersion.get!=
         pastafari.catalog.SourceLanguageCatalog.Version)
      throw new IllegalStateException("Catalogo PATCH19 alterato.")

    val trueMonth=w(day)
    val wrongSlot=day%ids.length
    val oldId=ids(wrongSlot)
    val correctedId=ids(trueMonth-1)
    val historical=catalog.find(_.canonicalIndex==oldId)
      .getOrElse(throw new IllegalStateException("ID storico assente.")).italian
    val corrected=catalog.find(_.canonicalIndex==correctedId)
      .getOrElse(throw new IllegalStateException("ID corretto assente.")).italian
    if(ctx.dayNameLegacyMonthId.get!=trueMonth ||
       ctx.dayNameLegacySlot.get!=wrongSlot ||
       ctx.dayNameLegacyItalian.get!=historical ||
       ctx.dayNamePatchedItalian.get!=corrected)
      throw new IllegalStateException("Nome PATCH19 non coerente.")
  }

  def requirePatch18Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_18_SOURCE_CATALOG_INDEX" ||
       ctx.status!="PATCH_18_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_18_SOURCE_CATALOG_MISMATCH",
         "PATCH_18_SOURCE_CATALOG_INDEX") ||
       ctx.catalogMonthIndices.isEmpty ||
       ctx.catalogInputSnapshot.isEmpty ||
       ctx.catalogLegacyItalianNames.isEmpty ||
       ctx.catalogFrozenVersion.isEmpty ||
       ctx.patchedCatalogItalianNames.isEmpty ||
       !ctx.patch18Applied)
      throw new IllegalStateException("PATCH 18 non completa.")

    val indices=ctx.catalogMonthIndices.get
    if(ctx.catalogInputSnapshot.get!=indices ||
       indices.size<3 || indices.size>47 ||
       indices.distinct.size!=indices.size ||
       indices.exists(i=>i<1 || i>47))
      throw new IllegalStateException("Input o snapshot catalogo falsificati.")

    val source=pastafari.catalog.SourceLanguageCatalog.Months
    if(source.size!=47 ||
       source.indices.exists(i=>source(i).canonicalIndex!=i+1) ||
       source.map(_.italian).distinct.size!=47 ||
       ctx.catalogFrozenVersion.get!=
         pastafari.catalog.SourceLanguageCatalog.Version)
      throw new IllegalStateException("Catalogo congelato non integro.")

    val oldNames=ctx.catalogLegacyItalianNames.get
    val correctNames=ctx.patchedCatalogItalianNames.get
    if(oldNames.size!=indices.size || correctNames.size!=indices.size)
      throw new IllegalStateException("Numero di nomi falsificato.")

    var pos=0
    while(pos<indices.size){
      val id=indices(pos)
      // Ricostruzione OLD: ID usato come posizione zero-based.
      val previous=source(id%47)
      // Ricostruzione PATCH: ID canonico tradotto alla posizione id-1.
      val expected=source(id-1)
      if(oldNames(pos)!=previous.italian ||
         correctNames(pos)!=expected.italian ||
         expected.canonicalIndex!=id)
        throw new IllegalStateException(
          "Mappatura del mese storico o corretto falsificata.")
      pos+=1
    }
    if(correctNames.distinct.size!=indices.size)
      throw new IllegalStateException("Nomi corretti duplicati.")
  }

  def requireDiscovery18Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="DISCOVERY_18_SOURCE_CATALOG_MISMATCH" ||
       ctx.status!="LEGACY_SOURCE_CATALOG_MISMATCH_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_18_SOURCE_CATALOG_MISMATCH") ||
       ctx.catalogMonthIndices.isEmpty ||
       ctx.catalogInputSnapshot.isEmpty ||
       ctx.catalogLegacyItalianNames.isEmpty ||
       ctx.catalogFrozenVersion.isEmpty)
      throw new IllegalStateException("DISCOVERY 18 non completa.")

    val requested=ctx.catalogMonthIndices.get
    if(ctx.catalogInputSnapshot.get!=requested ||
       requested.size<3 || requested.size>47 ||
       requested.distinct.size!=requested.size ||
       requested.exists(i=>i<1 || i>47))
      throw new IllegalStateException("Indici o snapshot alterati.")

    val source=pastafari.catalog.SourceLanguageCatalog.Months
    if(source.size!=47 ||
       source.indices.exists(i=>source(i).canonicalIndex!=i+1) ||
       ctx.catalogFrozenVersion.get!=
         pastafari.catalog.SourceLanguageCatalog.Version)
      throw new IllegalStateException("Identita' del catalogo alterata.")

    val names=ctx.catalogLegacyItalianNames.get
    if(names.length!=requested.length)
      throw new IllegalStateException("Numero nomi falsificato.")

    var idx=0
    while(idx<requested.length){
      val wrongPosition=requested(idx)%47
      if(names(idx)!=source(wrongPosition).italian)
        throw new IllegalStateException(
          "Mappatura storica del catalogo falsificata.")
      idx+=1
    }

    val historical=LegacySourceCatalogMismatchAdapter.oldSourceCatalogMismatch(
      requested)
    if(historical.legacyItalianMonthNames!=names ||
       historical.frozenCatalogVersion!=ctx.catalogFrozenVersion.get)
      throw new IllegalStateException("La cicatrice non e' riproducibile.")
  }

  def requirePatch17Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_17_DISTINCT_MONTH_NAME" ||
       ctx.status!="PATCH_17_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_17_DUPLICATED_MONTH_NAME",
         "PATCH_17_DISTINCT_MONTH_NAME") ||
       ctx.monthNameCount.isEmpty || ctx.monthNameRank1.isEmpty ||
       ctx.monthNameInputSnapshot.isEmpty ||
       ctx.legacyMonthNameIndices.isEmpty ||
       ctx.legacyMonthNameDistinctChoices.isEmpty ||
       ctx.legacyMonthNameReplacementSpace.isEmpty ||
       ctx.patchedDistinctMonthNameIndices.isEmpty ||
       !ctx.patch17Applied)
      throw new IllegalStateException("PATCH 17 non completa.")

    val count=ctx.monthNameCount.get
    val rank=ctx.monthNameRank1.get
    if(count<3 || count>47 || ctx.monthNameInputSnapshot.get!=(count,rank))
      throw new IllegalStateException("Snapshot dei nomi falsificata.")

    var domain=BigInt(1)
    var index=0
    while(index<count){domain*=BigInt(47-index);index+=1}
    if(rank<1 || rank>domain ||
       ctx.legacyMonthNameDistinctChoices.get!=domain ||
       ctx.legacyMonthNameReplacementSpace.get!=BigInt(47).pow(count))
      throw new IllegalStateException("Cardinalita' e rango falsificati.")

    // Reimposta la scelta storica usando la rappresentazione base47.
    val legacy=ctx.legacyMonthNameIndices.get
    if(legacy.length!=count || legacy.exists(x=>x<1 || x>47))
      throw new IllegalStateException("Nomi legacy fuori catalogo.")
    var base47=BigInt(0)
    legacy.foreach(name=>base47=base47*47+BigInt(name-1))
    if(base47+1!=rank)
      throw new IllegalStateException("Scelta legacy alterata.")

    // Ricostruisce il numero ordinale (rank-1) dell'intera
    // sequenza distinta, senza l'unrank della PATCH17.
    val names=ctx.patchedDistinctMonthNameIndices.get
    if(names.length!=count || names.distinct.length!=count ||
       names.exists(x=>x<1 || x>47))
      throw new IllegalStateException("Nomi ripetuti o invalidi.")

    val available=scala.collection.mutable.ArrayBuffer.from(1 to 47)
    var reconstructed=BigInt(0)
    index=0
    while(index<count){
      val chosen=names(index)
      val digit=available.indexOf(chosen)
      if(digit<0)throw new IllegalStateException(
        "Nome già usato non più disponibile.")

      var suffixChoices=BigInt(1)
      var t=0
      while(t<count-index-1){
        suffixChoices*=BigInt(available.size-1-t)
        t+=1
      }
      reconstructed+=BigInt(digit)*suffixChoices
      available.remove(digit)
      index+=1
    }
    if(reconstructed+1!=rank)
      throw new IllegalStateException(
        "Il rango dei nomi senza rimpiazzo è falsificato.")
  }

  def requireDiscovery17Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="DISCOVERY_17_DUPLICATED_MONTH_NAME" ||
       ctx.status!="LEGACY_DUPLICATED_MONTH_NAMES_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_17_DUPLICATED_MONTH_NAME") ||
       ctx.monthNameCount.isEmpty ||
       ctx.monthNameRank1.isEmpty ||
       ctx.monthNameInputSnapshot.isEmpty ||
       ctx.legacyMonthNameIndices.isEmpty ||
       ctx.legacyMonthNameDistinctChoices.isEmpty ||
       ctx.legacyMonthNameReplacementSpace.isEmpty)
      throw new IllegalStateException("DISCOVERY 17 non completa.")

    val count=ctx.monthNameCount.get
    val rank=ctx.monthNameRank1.get
    if(ctx.monthNameInputSnapshot.get!=(count,rank) ||
       count<3 || count>47)
      throw new IllegalStateException("Input dei nomi alterati.")

    var distinct=BigInt(1)
    var index=0
    while(index<count){
      distinct*=BigInt(47-index)
      index+=1
    }
    if(rank<1 || rank>distinct)
      throw new IllegalStateException("Rango fuori dal dominio distinto.")
    val replacement=BigInt(47).pow(count)
    if(ctx.legacyMonthNameDistinctChoices.get!=distinct ||
       ctx.legacyMonthNameReplacementSpace.get!=replacement)
      throw new IllegalStateException("Spazio dei nomi falsificato.")

    val names=ctx.legacyMonthNameIndices.get
    if(names.length!=count || names.exists(x=>x<1 || x>47))
      throw new IllegalStateException("Indici del catalogo invalidi.")

    // Ricostruisce il valore base47 in ordine lessicografico,
    // senza richiamare la funzione che ha scelto i nomi.
    var reconstructed=BigInt(0)
    index=0
    while(index<count){
      reconstructed=reconstructed*BigInt(47)+BigInt(names(index)-1)
      index+=1
    }
    if(reconstructed+1!=rank)
      throw new IllegalStateException(
        "La selezione legacy con rimpiazzo non e' stata riprodotta.")

    val historical=LegacyDuplicatedMonthNameAdapter.oldMonthNameDuplicated(
      count,rank)
    if(historical.legacyCanonicalNameIndices!=names ||
       historical.permittedDistinctChoices!=distinct ||
       historical.legacyReplacementSpace!=replacement)
      throw new IllegalStateException("La vera cicatrice e' stata modificata.")
  }

  def requirePatch16Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_16_CONTIGUOUS_MONTH_DAY" ||
       ctx.status!="PATCH_16_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_16_CONTIGUOUS_MONTH_DAY",
         "PATCH_16_CONTIGUOUS_MONTH_DAY") ||
       ctx.contiguousAnnualWeaving.isEmpty ||
       ctx.contiguousDayOffset.isEmpty ||
       ctx.contiguousInputSnapshot.isEmpty ||
       ctx.legacyContiguousMonthLengths.isEmpty ||
       ctx.legacyContiguousSelectedMonthId.isEmpty ||
       ctx.legacyContiguousAssumedStartOffset.isEmpty ||
       ctx.legacyContiguousDayInMonth.isEmpty ||
       ctx.patchedContiguousMonthId.isEmpty ||
       ctx.patchedContiguousDayInMonth.isEmpty ||
       !ctx.patch16Applied)
      throw new IllegalStateException("PATCH 16 non completa.")

    val annual=ctx.contiguousAnnualWeaving.get
    val day=ctx.contiguousDayOffset.get
    if(ctx.contiguousInputSnapshot.get!=(annual,day))
      throw new IllegalStateException(
        "Fotografia originaria della tessitura o del giorno falsificata.")
    try LegacyDaywiseWeavingAdapter.validateCandidates(Vector(annual))
    catch {
      case ex:IllegalArgumentException =>
        throw new IllegalStateException("Tessitura annuale illegale.",ex)
    }
    if(day<0 || day>=annual.size)
      throw new IllegalStateException("Giorno fuori intervallo.")

    // Ricostruzione autonoma del conto contiguo sbagliato.
    val monthCount=annual.max
    val lengths=Array.fill(monthCount)(0)
    var i=0
    while(i<annual.size){
      lengths(annual(i)-1)+=1
      i+=1
    }
    val id=annual(day)
    var oldStart=0
    i=0
    while(i<id-1){
      oldStart+=lengths(i)
      i+=1
    }
    val oldDay=day-oldStart+1
    if(ctx.legacyContiguousMonthLengths.get!=lengths.toVector ||
       ctx.legacyContiguousSelectedMonthId.get!=id ||
       ctx.legacyContiguousAssumedStartOffset.get!=oldStart ||
       ctx.legacyContiguousDayInMonth.get!=oldDay)
      throw new IllegalStateException("Cicatrice dei mesi contigui falsificata.")

    // La seguente scansione non richiama né patch né adapter legacy:
    // conta esattamente quante volte e' apparso l'ID del mese.
    var trueDay=0
    i=0
    while(i<=day){
      if(annual(i)==id)trueDay+=1
      i+=1
    }
    if(trueDay<1 || trueDay>lengths(id-1) ||
       ctx.patchedContiguousMonthId.get!=id ||
       ctx.patchedContiguousDayInMonth.get!=trueDay)
      throw new IllegalStateException("Contatore mensile tessuto falsificato.")
  }

  def requireDiscovery16Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="DISCOVERY_16_CONTIGUOUS_MONTH_DAY" ||
       ctx.status!="LEGACY_CONTIGUOUS_MONTH_DAY_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_16_CONTIGUOUS_MONTH_DAY") ||
       ctx.contiguousAnnualWeaving.isEmpty ||
       ctx.contiguousDayOffset.isEmpty ||
       ctx.contiguousInputSnapshot.isEmpty ||
       ctx.legacyContiguousMonthLengths.isEmpty ||
       ctx.legacyContiguousSelectedMonthId.isEmpty ||
       ctx.legacyContiguousAssumedStartOffset.isEmpty ||
       ctx.legacyContiguousDayInMonth.isEmpty)
      throw new IllegalStateException("DISCOVERY 16 non completa.")

    val weave=ctx.contiguousAnnualWeaving.get
    val day=ctx.contiguousDayOffset.get
    if(ctx.contiguousInputSnapshot.get!=(weave,day))
      throw new IllegalStateException(
        "Gli input sono mutati dopo la DISCOVERY 16.")

    try LegacyDaywiseWeavingAdapter.validateCandidates(Vector(weave))
    catch {
      case error:IllegalArgumentException=>
        throw new IllegalStateException("Tessitura invalida.",error)
    }
    if(day<0 || day>=weave.length)
      throw new IllegalStateException("Giorno fuori dominio.")

    val count=weave.max
    val lengths=Vector.tabulate(count)(id=>{
      var total=0
      var i=0
      while(i<weave.length) {
        if(weave(i)==id+1)total+=1
        i+=1
      }
      total
    })
    val id=weave(day)
    var start=0
    var j=0
    while(j<id-1){start+=lengths(j);j+=1}
    val guessed=day-start+1
    if(ctx.legacyContiguousMonthLengths.get!=lengths ||
       ctx.legacyContiguousSelectedMonthId.get!=id ||
       ctx.legacyContiguousAssumedStartOffset.get!=start ||
       ctx.legacyContiguousDayInMonth.get!=guessed)
      throw new IllegalStateException(
        "La ricostruzione contigua della cicatrice è stata falsificata.")

    val trueOld=LegacyContiguousMonthDayAdapter.oldContiguousMonthDayGuess(
      weave,day)
    if(trueOld.monthLengths!=ctx.legacyContiguousMonthLengths.get ||
       trueOld.selectedMonthId!=ctx.legacyContiguousSelectedMonthId.get ||
       trueOld.assumedMonthStartOffset!=ctx.legacyContiguousAssumedStartOffset.get ||
       trueOld.guessedDayInMonth!=ctx.legacyContiguousDayInMonth.get)
      throw new IllegalStateException("Legacy originale non riproducibile.")
  }

  def requirePatch15Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_15_DAYWISE_WEAVING" ||
       ctx.status!="PATCH_15_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_15_DAYWISE_WEAVING","PATCH_15_DAYWISE_WEAVING") ||
       ctx.daywiseCandidateWeavings.isEmpty || ctx.daywiseYearRank1.isEmpty ||
       ctx.daywiseOffset.isEmpty || ctx.daywiseInputSnapshot.isEmpty ||
       ctx.legacyDaywiseRank1.isEmpty || ctx.legacyDaywiseMonthId.isEmpty ||
       ctx.patchedAnnualWeaving.isEmpty || ctx.patchedMonthId.isEmpty ||
       ctx.patchedDayInMonth.isEmpty || !ctx.patch15Applied)
      throw new IllegalStateException("PATCH 15 non completa.")

    val all=ctx.daywiseCandidateWeavings.get
    val rank=ctx.daywiseYearRank1.get
    val day=ctx.daywiseOffset.get
    if(ctx.daywiseInputSnapshot.get!=(all,rank,day))
      throw new IllegalStateException(
        "Fotografia dei candidati o del rango annuale contraffatta.")
    try LegacyDaywiseWeavingAdapter.validateCandidates(all)
    catch {
      case ex:IllegalArgumentException=>
        throw new IllegalStateException("Famiglia annuale invalida.",ex)
    }
    if(rank<1 || rank>all.length || day<0 || day>=all.head.length)
      throw new IllegalStateException("Rango o giorno invalido.")

    // Controllo indipendente: non richiama il wrapper corretto.
    val offset=(rank-BigInt(1)).toInt
    val annual=all(offset)
    val legacyShift=(offset.toLong+day.toLong)%all.length.toLong
    val oldRank=BigInt(legacyShift+1)
    val oldMonth=all(legacyShift.toInt)(day)
    if(ctx.legacyDaywiseRank1.get!=oldRank ||
       ctx.legacyDaywiseMonthId.get!=oldMonth)
      throw new IllegalStateException("Il percorso storico e' cambiato.")
    val original=LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately(
      all,rank,day)
    if(original.dayRank1!=ctx.legacyDaywiseRank1.get ||
       original.monthId!=ctx.legacyDaywiseMonthId.get)
      throw new IllegalStateException("La cicatrice non e' riproducibile.")

    val expectedMonth=annual(day)
    var elapsed=0
    var pos=0
    while(pos<=day){
      if(annual(pos)==expectedMonth)elapsed+=1
      pos+=1
    }
    if(ctx.patchedAnnualWeaving.get!=annual ||
       ctx.patchedMonthId.get!=expectedMonth ||
       ctx.patchedDayInMonth.get!=elapsed)
      throw new IllegalStateException(
        "La tessitura annuale, il mese o il giorno del mese sono falsificati.")
  }

  def requireDiscovery15Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="DISCOVERY_15_DAYWISE_WEAVING" ||
       ctx.status!="LEGACY_DAYWISE_WEAVING_READY" ||
       ctx.branchTrace.toVector!=Vector("BOOT","DISCOVERY_15_DAYWISE_WEAVING") ||
       ctx.daywiseCandidateWeavings.isEmpty ||
       ctx.daywiseYearRank1.isEmpty || ctx.daywiseOffset.isEmpty ||
       ctx.daywiseInputSnapshot.isEmpty ||
       ctx.legacyDaywiseRank1.isEmpty || ctx.legacyDaywiseMonthId.isEmpty)
      throw new IllegalStateException("DISCOVERY 15 non completa.")

    val weaves=ctx.daywiseCandidateWeavings.get
    val rank=ctx.daywiseYearRank1.get
    val offset=ctx.daywiseOffset.get
    if(ctx.daywiseInputSnapshot.get!=(weaves,rank,offset))
      throw new IllegalStateException(
        "Gli input sono stati modificati dopo la selezione storica.")
    try LegacyDaywiseWeavingAdapter.validateCandidates(weaves)
    catch {
      case ex:IllegalArgumentException =>
        throw new IllegalStateException("Famiglia sintetica contraffatta.",ex)
    }
    if(rank<1 || rank>weaves.size || offset<0 || offset>=weaves.head.length)
      throw new IllegalStateException("Rank o giorno fuori dominio.")

    // Calcolo indipendente del rango con aritmetica Int, il vettore è
    // materializzato e la sua dimensione è sempre limitata a Int.
    val n=weaves.length
    val rank0=(rank-1).toInt
    val shifted=(((rank0.toLong+offset.toLong)%n.toLong)+n.toLong)%n.toLong
    val expectedRank=BigInt(shifted+1)
    val expectedMonth=weaves(shifted.toInt)(offset)
    if(ctx.legacyDaywiseRank1.get!=expectedRank ||
       ctx.legacyDaywiseMonthId.get!=expectedMonth)
      throw new IllegalStateException("Mese o rango storico falsificato.")
    val original=LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately(
      weaves,rank,offset)
    if(original.dayRank1!=ctx.legacyDaywiseRank1.get ||
       original.monthId!=ctx.legacyDaywiseMonthId.get)
      throw new IllegalStateException("La cicatrice reale non è riproducibile.")
  }

  def requirePatch14Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_14_VIRTUAL_GATE_LIST" ||
       ctx.status!="PATCH_14_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_14_VIRTUAL_GATE_LIST","PATCH_14_VIRTUAL_GATE_LIST") ||
       ctx.virtualFirstGateIndex.isEmpty ||
       ctx.virtualGateStride.isEmpty ||
       ctx.virtualCandidateCount.isEmpty ||
       ctx.virtualRequestedRank.isEmpty ||
       ctx.legacyVirtualNarrowedRank.isEmpty ||
       ctx.legacyVirtualSelectedGateIndex.isEmpty ||
       ctx.virtualDiscoveryInputSnapshot.isEmpty ||
       ctx.patchedVirtualSelectedGateIndex.isEmpty ||
       !ctx.patch14Applied)
      throw new IllegalStateException("PATCH 14 non completa.")

    val start=ctx.virtualFirstGateIndex.get
    val step=ctx.virtualGateStride.get
    val size=ctx.virtualCandidateCount.get
    val rank=ctx.virtualRequestedRank.get
    if(ctx.virtualDiscoveryInputSnapshot.get!=(start,step,size,rank))
      throw new IllegalStateException("La fotografia dei dati originali è mutata.")
    if(step==0 || size<1 || rank<1 || rank>size)
      throw new IllegalStateException("Dominio virtuale invalido.")

    // Il residuo signed 32-bit viene ricostruito senza usare il helper.
    val width=BigInt(1)<<32
    val low=rank & (width-1)
    val signed=if(low >= (BigInt(1)<<31)) low-width else low
    val oldIndex=start+(signed-1)*step
    if(ctx.legacyVirtualNarrowedRank.get!=signed.toInt ||
       ctx.legacyVirtualSelectedGateIndex.get!=oldIndex)
      throw new IllegalStateException("Cicatrice storica alterata.")

    val original=VirtualLegacyListAdapter.oldVirtualGateAt(start,step,size,rank)
    if(original.narrowedRank!=ctx.legacyVirtualNarrowedRank.get ||
       original.guessedGateIndex!=ctx.legacyVirtualSelectedGateIndex.get)
      throw new IllegalStateException("Il vero legacy non corrisponde.")

    val selected=ctx.patchedVirtualSelectedGateIndex.get
    if(selected-start != (rank-BigInt(1))*step)
      throw new IllegalStateException("Rango BigInt corretto falsificato.")
  }

  def requireDiscovery14Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="DISCOVERY_14_VIRTUAL_GATE_LIST" ||
       ctx.status!="LEGACY_VIRTUAL_GATE_READY" ||
       ctx.branchTrace.toVector!=Vector("BOOT","DISCOVERY_14_VIRTUAL_GATE_LIST") ||
       ctx.virtualFirstGateIndex.isEmpty ||
       ctx.virtualGateStride.isEmpty ||
       ctx.virtualCandidateCount.isEmpty ||
       ctx.virtualRequestedRank.isEmpty ||
       ctx.legacyVirtualNarrowedRank.isEmpty ||
       ctx.legacyVirtualSelectedGateIndex.isEmpty) {
      throw new IllegalStateException("DISCOVERY 14 incompleta.")
    }
    val first=ctx.virtualFirstGateIndex.get
    val stride=ctx.virtualGateStride.get
    val count=ctx.virtualCandidateCount.get
    val rank=ctx.virtualRequestedRank.get
    if(stride==0 || count<1 || rank<1 || rank>count)
      throw new IllegalStateException("Dominio virtuale contraffatto.")

    // Calcolo indipendente di Int signed modulo 2^32 senza toInt.
    val modulus=BigInt(1)<<32
    val unsigned=rank & (modulus-1)
    val signed=if(unsigned >= (BigInt(1)<<31))
      unsigned-modulus else unsigned
    val expected=first+(signed-1)*stride
    if(ctx.legacyVirtualNarrowedRank.get!=signed.toInt ||
       ctx.legacyVirtualSelectedGateIndex.get!=expected)
      throw new IllegalStateException("La cicatrice virtuale è falsificata.")
    val original=VirtualLegacyListAdapter.oldVirtualGateAt(
      first,stride,count,rank)
    if(original.narrowedRank!=ctx.legacyVirtualNarrowedRank.get ||
       original.guessedGateIndex!=ctx.legacyVirtualSelectedGateIndex.get)
      throw new IllegalStateException(
        "Il percorso storico della lista virtuale non è riproducibile.")
  }

  def requirePatch13Ready(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!="PATCH_13_YEAR_JUMP" ||
       ctx.status!="PATCH_13_READY" ||
       ctx.branchTrace.toVector!=Vector("BOOT","DISCOVERY_13_YEAR_JUMP",
         "PATCH_13_YEAR_JUMP") ||
       ctx.jumpAnchorOpenDay.isEmpty ||
       ctx.jumpBeforeLengths.isEmpty || ctx.jumpFromAnchorLengths.isEmpty ||
       ctx.legacyJumpOffset.isEmpty || ctx.legacyJumpOpenDay.isEmpty ||
       ctx.legacyJumpCloseDay.isEmpty || ctx.patchedJumpOffset.isEmpty ||
       ctx.patchedJumpOpenDay.isEmpty || ctx.patchedJumpCloseDay.isEmpty ||
       !ctx.patch13Applied)
      throw new IllegalStateException("PATCH 13 incompleta.")
    val before=ctx.jumpBeforeLengths.get
    val after=ctx.jumpFromAnchorLengths.get
    if(before.isEmpty || after.isEmpty ||
       (before++after).exists(x=>x<252 || x>5778))
      throw new IllegalStateException("Durate fuori dominio.")
    val anchor=ctx.jumpAnchorOpenDay.get
    val old=LegacyYearJumpAdapter.oldJumpGuess(
      anchor,before,after,ctx.targetDay)
    if(ctx.legacyJumpOffset.get!=old.guessedOffset ||
       ctx.legacyJumpOpenDay.get!=old.guessedOpenDay ||
       ctx.legacyJumpCloseDay.get!=old.guessedCloseDay)
      throw new IllegalStateException("Cicatrice storica alterata.")

    var offset=BigInt(0)
    var open=anchor
    var close=anchor
    var found=false
    if(ctx.targetDay>anchor) {
      var boundary=anchor
      var i=0
      while(i<after.size && !found) {
        val next=boundary+BigInt(after(i))
        if(boundary<ctx.targetDay && ctx.targetDay<=next) {
          offset=BigInt(i);open=boundary;close=next;found=true
        }
        boundary=next
        i+=1
      }
    } else {
      var boundary=anchor
      var i=0
      while(i<before.size && !found) {
        val previous=boundary-BigInt(before(i))
        if(previous<ctx.targetDay && ctx.targetDay<=boundary) {
          offset = -BigInt(i) - 1; open=previous; close=boundary; found=true
        }
        boundary=previous
        i+=1
      }
    }
    if(!found ||
       ctx.patchedJumpOffset.get!=offset ||
       ctx.patchedJumpOpenDay.get!=open ||
       ctx.patchedJumpCloseDay.get!=close)
      throw new IllegalStateException(
        "Il confine normativo o l'offset della PATCH 13 è falsificato.")
  }

  def requireDiscovery13Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_13_YEAR_JUMP" ||
        ctx.status != "LEGACY_YEAR_JUMP_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_13_YEAR_JUMP") ||
        ctx.jumpAnchorOpenDay.isEmpty ||
        ctx.jumpBeforeLengths.isEmpty ||
        ctx.jumpFromAnchorLengths.isEmpty ||
        ctx.legacyJumpOffset.isEmpty ||
        ctx.legacyJumpOpenDay.isEmpty ||
        ctx.legacyJumpCloseDay.isEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 13 richiede un salto storico completo.")
    }
    val before=ctx.jumpBeforeLengths.get
    val after=ctx.jumpFromAnchorLengths.get
    if (before.isEmpty || after.isEmpty ||
        (before++after).exists(x=>x<252 || x>5778)) {
      throw new IllegalStateException("Durate degli anni fuori dal dominio.")
    }
    val anchor=ctx.jumpAnchorOpenDay.get
    val guessedOffset=ctx.legacyJumpOffset.get
    val guessedOpen=ctx.legacyJumpOpenDay.get
    val guessedClose=ctx.legacyJumpCloseDay.get
    // Prova indipendente della divisione matematica verso meno infinito.
    val relative=ctx.targetDay-anchor-BigInt(1)
    val width=BigInt(5778)
    val quotient=relative/width
    val remainder=relative%width
    val expectedOffset=if(relative<0 && remainder!=0)quotient-1 else quotient
    if (guessedOffset!=expectedOffset ||
        guessedOpen!=anchor+width*expectedOffset ||
        guessedClose!=guessedOpen+width) {
      throw new IllegalStateException("Il salto storico è stato falsificato.")
    }
    val original=LegacyYearJumpAdapter.oldJumpGuess(
      anchor,before,after,ctx.targetDay)
    if (original.guessedOffset!=guessedOffset ||
        original.guessedOpenDay!=guessedOpen ||
        original.guessedCloseDay!=guessedClose) {
      throw new IllegalStateException("La cicatrice storica non è riproducibile.")
    }
  }

  def requirePatch12Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_12_YEAR_CEILING" ||
        ctx.status != "PATCH_12_READY" ||
        ctx.branchTrace.toVector != Vector(
          "BOOT","DISCOVERY_12_YEAR_CEILING","PATCH_12_YEAR_CEILING") ||
        ctx.legacyYearGapsInput.isEmpty || ctx.legacyYearLengthOutput.isEmpty ||
        ctx.legacyYearAcceptedOutput.isEmpty || ctx.legacyYearMaxOutput.isEmpty ||
        ctx.patchedYearAcceptedOutput.isEmpty ||
        ctx.patchedYearMaxOutput.isEmpty || !ctx.patch12Applied) {
      throw new IllegalStateException(
        "PATCH 12 richiede la DISCOVERY 12 completa nella stessa invocazione.")
    }
    val gaps = ctx.legacyYearGapsInput.get
    if (gaps.isEmpty || gaps.exists(g=>g<42 || g>963))
      throw new IllegalStateException("Divari non normativi.")
    val length = gaps.foldLeft(BigInt(0))((acc,g)=>acc+BigInt(g))
    val historical = gaps.length>=6 && length>=252 && length<=5777
    val normative = gaps.length>=6 && length>=252 && length<=5778
    if (ctx.legacyYearLengthOutput.get!=length ||
        ctx.legacyYearMaxOutput.get!=5777 ||
        ctx.legacyYearAcceptedOutput.get!=historical ||
        ctx.patchedYearMaxOutput.get!=5778 ||
        ctx.patchedYearAcceptedOutput.get!=normative) {
      throw new IllegalStateException(
        "La PATCH 12 o la cicatrice storica sono state contraffatte.")
    }
    val original=LegacyYearCeilingAdapter.legacyYearMax(gaps)
    if (original.gateGaps!=gaps ||
        original.yearLength!=length ||
        original.oldMaximum!=ctx.legacyYearMaxOutput.get ||
        original.accepted!=ctx.legacyYearAcceptedOutput.get) {
      throw new IllegalStateException(
        "La PATCH 12 deve conservare il percorso legacy reale.")
    }
  }

  def requireDiscovery12Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_12_YEAR_CEILING" ||
        ctx.status != "LEGACY_YEAR_CEILING_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_12_YEAR_CEILING") ||
        ctx.legacyYearGapsInput.isEmpty ||
        ctx.legacyYearLengthOutput.isEmpty ||
        ctx.legacyYearAcceptedOutput.isEmpty ||
        ctx.legacyYearMaxOutput.isEmpty) {
      throw new IllegalStateException(
        "DISCOVERY 12 richiede una candidata storica completa.")
    }
    val gaps = ctx.legacyYearGapsInput.get
    if (gaps.isEmpty || gaps.exists(x=>x<42||x>963)) {
      throw new IllegalStateException("I divari dei cancelli sono falsificati.")
    }
    val length = gaps.foldLeft(BigInt(0))((sum,g)=>sum+BigInt(g))
    val correctOldAcceptance =
      gaps.size>=6 && length>=252 && length<=5777
    if (ctx.legacyYearLengthOutput.get!=length ||
        ctx.legacyYearMaxOutput.get!=5777 ||
        ctx.legacyYearAcceptedOutput.get!=correctOldAcceptance) {
      throw new IllegalStateException("La firma del tetto storico non coincide.")
    }
    val historic=LegacyYearCeilingAdapter.legacyYearMax(gaps)
    if (historic.yearLength!=length ||
        historic.oldMaximum!=ctx.legacyYearMaxOutput.get ||
        historic.accepted!=ctx.legacyYearAcceptedOutput.get) {
      throw new IllegalStateException("Il legacy non è stato attraversato.")
    }
  }

  def requirePatch11Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_11_SHORT_REJECTION" ||
        ctx.status != "PATCH_11_READY" ||
        ctx.branchTrace.toVector != Vector(
          "BOOT","DISCOVERY_11_BIASED_SHORT_PICK","PATCH_11_SHORT_REJECTION") ||
        ctx.selectionSampleInput.isEmpty || ctx.selectionDirectionInput.isEmpty ||
        ctx.selectionFamilySizeInput.isEmpty ||
        ctx.legacyBiasedSampleOutput.isEmpty ||
        ctx.legacyBiasedRankOutput.isEmpty ||
        ctx.legacyAcceptanceLimitOutput.isEmpty ||
        ctx.patchedAcceptedSample.isEmpty ||
        ctx.patchedShortPickRank.isEmpty ||
        ctx.patchedSkippedSamples.isEmpty || !ctx.patch11Applied) {
      throw new IllegalStateException(
        "PATCH 11 richiede una DISCOVERY 11 completa nella stessa invocazione.")
    }
    val first = ctx.selectionSampleInput.get
    val direction = ctx.selectionDirectionInput.get
    val n = ctx.selectionFamilySizeInput.get
    val legacySample = ctx.legacyBiasedSampleOutput.get
    val legacyRank = ctx.legacyBiasedRankOutput.get
    val legacyLimit = ctx.legacyAcceptanceLimitOutput.get
    val accepted = ctx.patchedAcceptedSample.get
    val rank = ctx.patchedShortPickRank.get
    val skipped = ctx.patchedSkippedSamples.get
    val modulus = (BigInt(1)<<127)-1
    if (first<1 || first>modulus || n<1 || n>modulus ||
        (direction!=1 && direction != -1) ||
        legacySample!=first || legacyLimit!=(modulus/n)*n ||
        legacyRank!=((first-1)%n)+1) {
      throw new IllegalStateException("Cicatrice di scelta corta contraffatta.")
    }
    // Validatore indipendente: calcola l'intervallo di rifiuto
    // [limite+1,M] e la sua distanza ciclica dal prossimo ammesso.
    val limit=(modulus/n)*n
    val rejected=first>limit
    val wantedSkip =
      if (!rejected) BigInt(0)
      else if (direction==1) modulus-first+1
      else first-limit
    val wantedAccepted =
      if (!rejected) first
      else if (direction==1) BigInt(1)
      else limit
    val wantedRank=((wantedAccepted-1)%n)+1
    if (skipped!=wantedSkip || accepted!=wantedAccepted ||
        rank!=wantedRank || accepted<1 || accepted>limit ||
        rank<1 || rank>n || skipped<0 || skipped>modulus-limit) {
      throw new IllegalStateException(
        "PATCH 11 non coincide con il flusso normativo di accettazione.")
    }
    val historic=LegacyBiasedPickAdapter.biasedLegacyPick(first,direction,n)
    if (historic.firstSample!=legacySample ||
        historic.legacyRank!=legacyRank ||
        historic.acceptanceLimit!=legacyLimit) {
      throw new IllegalStateException("Il percorso storico è stato manomesso.")
    }
  }

  def requireDiscovery11Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_11_BIASED_SHORT_PICK" ||
        ctx.status != "LEGACY_BIASED_PICK_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_11_BIASED_SHORT_PICK") ||
        ctx.selectionSampleInput.isEmpty ||
        ctx.selectionDirectionInput.isEmpty ||
        ctx.selectionFamilySizeInput.isEmpty ||
        ctx.legacyBiasedSampleOutput.isEmpty ||
        ctx.legacyBiasedRankOutput.isEmpty ||
        ctx.legacyAcceptanceLimitOutput.isEmpty) {
      throw new IllegalStateException("La selezione corta storica non è pronta.")
    }
    val m=(BigInt(1)<<127)-1
    val sample=ctx.selectionSampleInput.get
    val direction=ctx.selectionDirectionInput.get
    val n=ctx.selectionFamilySizeInput.get
    val rank=ctx.legacyBiasedRankOutput.get
    val limit=ctx.legacyAcceptanceLimitOutput.get
    if (sample<1 || sample>m || n<1 || n>m ||
        (direction!=1 && direction != -1) ||
        ctx.legacyBiasedSampleOutput.get!=sample ||
        rank<1 || rank>n ||
        limit!=(m/n)*n ||
        rank!=((sample-1)%n)+1) {
      throw new IllegalStateException(
        "Dati della selezione corta storica falsificati.")
    }
    val actual=LegacyBiasedPickAdapter.biasedLegacyPick(sample,direction,n)
    if (actual.firstSample!=ctx.legacyBiasedSampleOutput.get ||
        actual.legacyRank!=rank ||
        actual.acceptanceLimit!=limit) {
      throw new IllegalStateException("Il legacy non è stato attraversato.")
    }
  }

  def requirePatch10Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_10_ORDER46_FREEZE" ||
        ctx.status != "PATCH_10_READY" ||
        ctx.branchTrace.toVector != Vector(
          "BOOT","DISCOVERY_10_ORDER46_LATCH","PATCH_10_ORDER46_FREEZE") ||
        ctx.penultimateDropValue.isEmpty || ctx.finalDropValue.isEmpty ||
        ctx.queriedBowlInput.isEmpty ||
        ctx.legacyLatchedOrder45.isEmpty || ctx.observedOrder46.isEmpty ||
        ctx.legacyNextBowlOutput.isEmpty ||
        ctx.patchedLatchedOrder46.isEmpty || ctx.patchedNextBowlOutput.isEmpty ||
        !ctx.patch10Applied) {
      throw new IllegalStateException(
        "PATCH 10 richiede una DISCOVERY 10 completa nella stessa invocazione.")
    }
    val queried = ctx.queriedBowlInput.get
    val drop45 = ctx.penultimateDropValue.get
    val drop46 = ctx.finalDropValue.get
    val old = ctx.legacyLatchedOrder45.get
    val observed = ctx.observedOrder46.get
    val fixed = ctx.patchedLatchedOrder46.get
    val previousNext = ctx.legacyNextBowlOutput.get
    val patchedNext = ctx.patchedNextBowlOutput.get
    if (queried < 1 || queried > 6 ||
        patchedNext < 1 || patchedNext > 6 || patchedNext == queried ||
        fixed.sorted != Vector(1,2,3,4,5,6) ||
        observed.sorted != Vector(1,2,3,4,5,6) ||
        old.sorted != Vector(1,2,3,4,5,6)) {
      throw new IllegalStateException("Domini della PATCH 10 malformati.")
    }
    // Unranking fattoriale indipendente dal wrapper PATCH 10.
    def expectedOrder(drop: BigInt): Vector[Int] = {
      val mod = BigInt(720)
      var remainingRank = (((drop-1)%mod+mod)%mod).toInt
      var available = Vector(1,2,3,4,5,6)
      val out = Vector.newBuilder[Int]
      for (count <- 6 to 1 by -1) {
        val factorial = (1 until count).product
        val position = remainingRank / factorial
        remainingRank = remainingRank % factorial
        out += available(position)
        available = available.patch(position,Vector.empty[Int],1)
      }
      out.result()
    }
    val order45 = expectedOrder(drop45)
    val order46 = expectedOrder(drop46)
    val legacyPosition = order45.indexOf(queried)
    val correctPosition = order46.indexOf(queried)
    if (old != order45 || observed != order46 || fixed != order46 ||
        previousNext != order45((legacyPosition+1)%6) ||
        patchedNext != order46((correctPosition+1)%6)) {
      throw new IllegalStateException(
        "Il latch storico o il nuovo latch PATCH 10 è stato contraffatto.")
    }
  }

  def requireDiscovery10Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_10_ORDER46_LATCH" ||
        ctx.status != "LEGACY_ORDER46_LATCH_READY" ||
        ctx.branchTrace.toVector != Vector(
          "BOOT","DISCOVERY_10_ORDER46_LATCH") ||
        ctx.penultimateDropValue.isEmpty || ctx.finalDropValue.isEmpty ||
        ctx.queriedBowlInput.isEmpty ||
        ctx.legacyLatchedOrder45.isEmpty ||
        ctx.observedOrder46.isEmpty ||
        ctx.legacyNextBowlOutput.isEmpty) {
      throw new IllegalStateException("La fotografia della goccia 46 non è pronta.")
    }
    val queried = ctx.queriedBowlInput.get
    val oldOrder = ctx.legacyLatchedOrder45.get
    val finalOrder = ctx.observedOrder46.get
    val next = ctx.legacyNextBowlOutput.get
    if (queried < 1 || queried > 6 ||
        next < 1 || next > 6 || next == queried ||
        oldOrder.sorted != Vector(1,2,3,4,5,6) ||
        finalOrder.sorted != Vector(1,2,3,4,5,6)) {
      throw new IllegalStateException("Identificatore o ordine delle ciotole alterato.")
    }
    val expected = LegacyOrder46LatchAdapter.orderAt46Latch(
      ctx.penultimateDropValue.get,ctx.finalDropValue.get,queried)
    if (expected.order45 != oldOrder ||
        expected.order46 != finalOrder ||
        expected.legacyNextBowl != next) {
      throw new IllegalStateException(
        "Il percorso della registrazione storica è stato falsificato.")
    }
  }

  def requirePatch09Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_09_VAULT_ROLL" ||
        ctx.status != "PATCH_09_READY" ||
        ctx.branchTrace.toVector != Vector(
          "BOOT", "DISCOVERY_09_VAULT", "PATCH_09_VAULT_ROLL") ||
        ctx.postStirInput.isEmpty ||
        ctx.legacyVaultRounds.isEmpty || ctx.legacyVaultOutput.isEmpty ||
        ctx.patchedVaultRounds.isEmpty || ctx.patchedVaultOutput.isEmpty ||
        !ctx.patch09Applied) {
      throw new IllegalStateException(
        "PATCH 09 richiede lo storico completo nella stessa invocazione.")
    }
    val initial = ctx.postStirInput.get
    val historical = ctx.legacyVaultRounds.get
    val historicalOutput = ctx.legacyVaultOutput.get
    val patched = ctx.patchedVaultRounds.get
    val published = ctx.patchedVaultOutput.get
    if (initial.length != 6 || historical.length != 12 ||
        patched.length != 12 || published.length != 6 ||
        published != patched.last.bowls ||
        patched.map(_.step) != (1 to 12).toVector ||
        patched.exists(r => r.bowls.length != 6 ||
          r.order.sorted != Vector(1,2,3,4,5,6) ||
          r.bowls.exists(x=>x<1||x>((BigInt(1)<<127)-1)))) {
      throw new IllegalStateException(
        "Registro e risultati della PATCH 09 malformati.")
    }

    // Validator indipendente: ricalcola ogni giro dalla fotografia
    // del giro precedente, senza richiamare il wrapper.
    var snapshot = initial
    val verified = Vector.newBuilder[LegacyVaultRound]
    for (step <- 1 to 12) {
      val saved = Patch01SaveWrapper.savePatch(snapshot.sum + 149*step)
      val rank = ((saved-1)%720+1).toInt
      val order = Patch07PermutationWrapper.permutationPatch(rank)
      val next = Vector.newBuilder[(Int,BigInt)]
      for (position <- 1 to 6) {
        val at = order(position-1)-1
        val prev = order((position+4)%6)-1
        val following = order(position%6)-1
        val x = snapshot(at)+3*snapshot(prev)+5*snapshot(following)+
          saved+step+position*position
        val value = Patch01SaveWrapper.savePatch(
          x*x+7*snapshot(prev)*snapshot(following))
        next += (at->value)
      }
      val calculated = next.result().sortBy(_._1).map(_._2)
      verified += LegacyVaultRound(step,saved,rank,order,calculated)
      snapshot = calculated
    }
    val original = LegacyVaultAdapter.vaultOld(initial)
    if (original.rounds != historical ||
        original.bowls != historicalOutput ||
        verified.result() != patched || snapshot != published) {
      throw new IllegalStateException(
        "PATCH 09 non normativa o cicatrice storica alterata.")
    }
  }

  def requireDiscovery09Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_09_VAULT" ||
        ctx.status != "LEGACY_VAULT_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_09_VAULT") ||
        ctx.postStirInput.isEmpty || ctx.legacyVaultRounds.isEmpty ||
        ctx.legacyVaultOutput.isEmpty) {
      throw new IllegalStateException("DISCOVERY 09 richiede dodici giri completi.")
    }
    val initial = ctx.postStirInput.get
    val rounds = ctx.legacyVaultRounds.get
    val output = ctx.legacyVaultOutput.get
    if (initial.length != 6 || rounds.length != 12 ||
        output.length != 6 || output != rounds.last.bowls ||
        rounds.map(_.step) != (1 to 12).toVector ||
        rounds.exists(r => r.bowls.length != 6 ||
          r.order.sorted != Vector(1,2,3,4,5,6) ||
          r.bowls.exists(x => x < 1 || x > ((BigInt(1)<<127)-1)))) {
      throw new IllegalStateException("Registro storico incompleto o incoerente.")
    }
    // La validazione conferma tutte le dodici istantanee diagnostiche;
    // la corrispondenza normativa è verificata solo nei test.
    val rebuilt = LegacyVaultAdapter.vaultOld(initial)
    if (rebuilt.rounds != rounds || rebuilt.bowls != output) {
      throw new IllegalStateException("Le tracce del caveau storico sono contraffatte.")
    }
  }

  def requirePatch08Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_08_BOWL_FREEZE" ||
        ctx.status != "PATCH_08_READY" ||
        ctx.branchTrace.toVector != Vector(
          "BOOT", "DISCOVERY_08_BOWL_ALIAS", "PATCH_08_BOWL_FREEZE") ||
        ctx.bowlStepInput.isEmpty || ctx.bowlRankInput.isEmpty ||
        ctx.bowlInput.isEmpty || ctx.bowlDropInput.isEmpty ||
        ctx.bowlStonesInput.isEmpty || ctx.legacyBowlOrderOutput.isEmpty ||
        ctx.legacyBowlPoursOutput.isEmpty || ctx.legacyBowlOutput.isEmpty ||
        ctx.patchedBowlOutput.isEmpty || !ctx.patch08Applied) {
      throw new IllegalStateException("PATCH 08 richiede la discovery nella stessa invocazione.")
    }
    val step = ctx.bowlStepInput.get
    val rank = ctx.bowlRankInput.get
    val old = ctx.bowlInput.get
    val stones = ctx.bowlStonesInput.get
    val drop = ctx.bowlDropInput.get
    val order = ctx.legacyBowlOrderOutput.get
    val pours = ctx.legacyBowlPoursOutput.get
    val legacy = ctx.legacyBowlOutput.get
    val patched = ctx.patchedBowlOutput.get
    if (step < 1 || step > 46 || rank < 1 || rank > 720 ||
        old.length != 6 || stones.length != 5 || pours.length != 6 ||
        order.length != 6 || order.sorted != Vector(1,2,3,4,5,6) ||
        legacy.length != 6 || patched.length != 6) {
      throw new IllegalStateException("Dimensione, indice o ordine PATCH 08 non valido.")
    }
    // Verifica fattoriale, getti e ricorrenza indipendente dal wrapper.
    val expectedOrder = Patch07PermutationWrapper.permutationPatch(rank)
    if (order != expectedOrder)
      throw new IllegalStateException("Ordine delle ciotole manomesso.")
    val expectedPours = Vector.tabulate[BigInt](6) { index =>
      if (index >= 3) BigInt(0)
      else Patch01SaveWrapper.savePatch(
        drop*drop + stones(index)*old(order(index)-1) +
        (3 + 2*index)*step)
    }
    if (pours != expectedPours)
      throw new IllegalStateException("I getti non vengono dall'istantanea vecchia.")
    val stoneKinds = Vector(0,1,2,3,4,0)
    val values = Vector.newBuilder[(Int,BigInt)]
    for (position <- 1 to 6) {
      val current = order(position-1)-1
      val previous = order((position+4)%6)-1
      val following = order(position%6)-1
      val sum = old(current) + 2*old(previous) + 3*old(following) +
        pours(position-1) + drop + stones(stoneKinds(position-1))
      val value = Patch01SaveWrapper.savePatch(
        sum*sum + 5*old(previous)*old(following) + step*position)
      values += ((current,value))
    }
    val frozen = values.result().sortBy(_._1).map(_._2)
    val historical = LegacyBowlAliasAdapter.bowlAlias(old,drop,stones,step,rank)
    if (frozen != patched || historical.order != order ||
        historical.pours != pours || historical.bowls != legacy)
      throw new IllegalStateException("Output normativo o cicatrice storica falsificati.")
  }

  def requireDiscovery08Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_08_BOWL_ALIAS" ||
        ctx.status != "LEGACY_BOWL_ALIAS_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_08_BOWL_ALIAS") ||
        ctx.bowlStepInput.isEmpty || ctx.bowlRankInput.isEmpty ||
        ctx.bowlInput.isEmpty || ctx.bowlDropInput.isEmpty ||
        ctx.bowlStonesInput.isEmpty || ctx.legacyBowlOrderOutput.isEmpty ||
        ctx.legacyBowlPoursOutput.isEmpty || ctx.legacyBowlOutput.isEmpty) {
      throw new IllegalStateException("La mescolatura legacy non è pronta.")
    }
    val step = ctx.bowlStepInput.get
    val rank = ctx.bowlRankInput.get
    val original = ctx.bowlInput.get
    val stones = ctx.bowlStonesInput.get
    val order = ctx.legacyBowlOrderOutput.get
    val pours = ctx.legacyBowlPoursOutput.get
    val result = ctx.legacyBowlOutput.get
    if (step < 1 || step > 46 || rank < 1 || rank > 720 ||
        original.length != 6 || stones.length != 5 ||
        order.length != 6 || order.sorted != Vector(1,2,3,4,5,6) ||
        pours.length != 6 || result.length != 6 ||
        result.exists(x => x < 1 || x > ((BigInt(1) << 127)-1)) ||
        order != Patch07PermutationWrapper.permutationPatch(rank)) {
      throw new IllegalStateException("Parametri o rango della mescolatura incoerenti.")
    }
    val expected = LegacyBowlAliasAdapter.bowlAlias(
      original, ctx.bowlDropInput.get, stones, step, rank)
    if (expected.order != order || expected.pours != pours ||
        expected.bowls != result) {
      throw new IllegalStateException("Risultato o getti della mescolatura falsificati.")
    }
  }

  def requirePatch07Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_07_PERMUTATION" ||
        ctx.status != "PATCH_07_READY" ||
        ctx.permutationRankInput.isEmpty ||
        ctx.legacyPermutationOutput.isEmpty ||
        ctx.patchedPermutationOutput.isEmpty ||
        !ctx.patch07Applied ||
        ctx.branchTrace.toVector != Vector(
          "BOOT", "DISCOVERY_07_PERMUTATION", "PATCH_07_PERMUTATION")) {
      throw new IllegalStateException(
        "PATCH 07 richiede la discovery e il risultato nello stesso contesto.")
    }
    val rank = ctx.permutationRankInput.get
    if (rank < 1 || rank > 720 ||
        ctx.legacyPermutationOutput.get !=
          LegacyPermutationAdapter.oldPermutationUnrank0(rank)) {
      throw new IllegalStateException("La prova della permutazione legacy è incoerente.")
    }

    // Validazione indipendente dalla formula del wrapper: unranking 1-based
    // sul sistema fattoriale, con rango ridotto a zero UNA SOLA volta.
    var rest = rank - 1
    val factorials = Vector(1, 1, 2, 6, 24, 120, 720)
    val remaining = scala.collection.mutable.ArrayBuffer(1, 2, 3, 4, 5, 6)
    val answer = Vector.newBuilder[Int]
    for (slots <- 6 to 1 by -1) {
      val block = factorials(slots - 1)
      val index = rest / block
      rest = rest % block
      answer += remaining.remove(index)
    }
    val normative = answer.result()
    if (remaining.nonEmpty || rest != 0 ||
        ctx.patchedPermutationOutput.get != normative ||
        normative.sorted != Vector(1, 2, 3, 4, 5, 6)) {
      throw new IllegalStateException("Permutazione PATCH 07 alterata o non normativa.")
    }
  }

  def requireDiscovery07Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_07_PERMUTATION" ||
        ctx.status != "LEGACY_PERMUTATION_READY" ||
        ctx.permutationRankInput.isEmpty ||
        ctx.legacyPermutationOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_07_PERMUTATION")) {
      throw new IllegalStateException("La permutazione legacy non è pronta.")
    }
    val rank = ctx.permutationRankInput.get
    val out = ctx.legacyPermutationOutput.get
    if (rank < 1 || rank > 720 || out.length != 6 ||
        out.sorted != Vector(1, 2, 3, 4, 5, 6) ||
        out != LegacyPermutationAdapter.oldPermutationUnrank0(rank)) {
      throw new IllegalStateException("La permutazione legacy non corrisponde al suo rango.")
    }
  }

  def requirePatch06Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_06_GRIND" || ctx.status != "PATCH_06_READY" ||
        ctx.grindStepInput.isEmpty || ctx.grindValueInput.isEmpty ||
        ctx.grindPrev1Input.isEmpty || ctx.grindPrev3Input.isEmpty ||
        ctx.grindPrev7Input.isEmpty || ctx.grindStonesInput.isEmpty ||
        ctx.legacyGrindRuleOutput.isEmpty || ctx.legacyGrindOutput.isEmpty ||
        ctx.patchedGrindRuleOutput.isEmpty || ctx.patchedGrindOutput.isEmpty ||
        !ctx.patch06Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_06_GRIND", "PATCH_06_GRIND")) {
      throw new IllegalStateException("La PATCH 06 richiede la discovery nello stesso contesto.")
    }
    val step = ctx.grindStepInput.get
    val stones = ctx.grindStonesInput.get
    if (step < 1 || step > 11 || stones.length != 5)
      throw new IllegalStateException("Parametri di macinatura PATCH 06 non validi.")
    val table = LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL
    if (table.length != 12 ||
        ctx.legacyGrindRuleOutput.get != table(step - 1) ||
        ctx.patchedGrindRuleOutput.get != table(step))
      throw new IllegalStateException("Letture di macinatura legacy e patched incoerenti.")

    def evaluate(rule: LegacyGrindRule): BigInt =
      Patch01SaveWrapper.savePatch(
        ctx.grindValueInput.get * ctx.grindValueInput.get +
          rule.a * ctx.grindValueInput.get +
          rule.b * ctx.grindPrev1Input.get +
          rule.c * ctx.grindPrev3Input.get +
          rule.d * ctx.grindPrev7Input.get + stones(rule.stoneKind)
      )

    if (ctx.legacyGrindOutput.get != evaluate(table(step - 1)) ||
        ctx.patchedGrindOutput.get != evaluate(table(step))) {
      throw new IllegalStateException("Risultato di macinatura falsificato o non normativo.")
    }
  }

  def requireDiscovery06Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_06_GRIND" ||
        ctx.status != "LEGACY_GRIND_READY" ||
        ctx.grindStepInput.isEmpty || ctx.grindValueInput.isEmpty ||
        ctx.grindPrev1Input.isEmpty || ctx.grindPrev3Input.isEmpty ||
        ctx.grindPrev7Input.isEmpty || ctx.grindStonesInput.isEmpty ||
        ctx.legacyGrindRuleOutput.isEmpty || ctx.legacyGrindOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_06_GRIND")) {
      throw new IllegalStateException("La macinatura legacy non è pronta.")
    }
    val step = ctx.grindStepInput.get
    if (step < 1 || step > 11 || ctx.grindStonesInput.get.length != 5 ||
        ctx.legacyGrindRuleOutput.get != LegacyGrindTableAdapter.legacyGrindRule(step)) {
      throw new IllegalStateException("Catalogo dei macinamenti legacy incoerente.")
    }
  }

  def requirePatch05Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_05_PRIOR" ||
        ctx.status != "PATCH_05_READY" ||
        ctx.priorHiddenInput.isEmpty || ctx.priorVisibleInput.isEmpty ||
        ctx.priorIndexInput.isEmpty || ctx.priorLagInput.isEmpty ||
        ctx.legacyPriorOutput.isEmpty || ctx.patchedPriorOutput.isEmpty ||
        !ctx.patch05Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_05_PRIOR", "PATCH_05_PRIOR")) {
      throw new IllegalStateException("La PATCH 05 non è pronta nella stessa invocazione.")
    }
    val hidden = ctx.priorHiddenInput.get
    val visible = ctx.priorVisibleInput.get
    val index = ctx.priorIndexInput.get
    val lag = ctx.priorLagInput.get
    if (hidden.length != 7 || index < 1 || index > 47 ||
        visible.length != index - 1 || !Set(1, 3, 7).contains(lag)) {
      throw new IllegalStateException("Finestra temporale PATCH 05 non valida.")
    }
    val expectedPosition = index - lag
    val expected =
      if (expectedPosition <= 0) hidden(-expectedPosition)
      else visible(expectedPosition - 1)
    if (ctx.patchedPriorOutput.get != expected ||
        ctx.legacyPriorOutput.get != LegacyPriorAdapter.legacyPrior(hidden, visible, index, lag)) {
      throw new IllegalStateException("La PATCH 05 non corrisponde alle due letture attese.")
    }
  }

  def requireDiscovery05Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_05_PRIOR" ||
        ctx.status != "LEGACY_PRIOR_READY" ||
        ctx.priorHiddenInput.isEmpty || ctx.priorVisibleInput.isEmpty ||
        ctx.priorIndexInput.isEmpty || ctx.priorLagInput.isEmpty ||
        ctx.legacyPriorOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_05_PRIOR")) {
      throw new IllegalStateException("Registro temporale legacy non pronto.")
    }
    if (ctx.priorHiddenInput.get.length != 7 ||
        ctx.priorIndexInput.get < 1 || ctx.priorIndexInput.get > 47 ||
        ctx.priorVisibleInput.get.length != ctx.priorIndexInput.get - 1 ||
        !Set(1, 3, 7).contains(ctx.priorLagInput.get)) {
      throw new IllegalStateException("Dati temporali della discovery incoerenti.")
    }
  }

  def requirePatch04Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_04_STONES" ||
        ctx.status != "PATCH_04_READY" ||
        ctx.legacyStoneRowsOutput.isEmpty ||
        ctx.patchedStoneRowsOutput.isEmpty ||
        !ctx.patch04Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_04_STONES", "PATCH_04_STONES")) {
      throw new IllegalStateException("La PATCH 04 delle pietre non è pronta.")
    }
    val legacy = ctx.legacyStoneRowsOutput.get
    val corrected = ctx.patchedStoneRowsOutput.get
    if (legacy.length != 46 || legacy.exists(_.length != 5) ||
        corrected.length != 46 || corrected.exists(_.length != 5) ||
        corrected != Patch04StonesWrapper.stonesPatch(legacy)) {
      throw new IllegalStateException(
        "La PATCH 04 deve ricostruire le righe dallo snapshot precedente."
      )
    }
  }

  def requireDiscovery04Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_04_STONES" ||
        ctx.status != "LEGACY_STONES_READY" ||
        ctx.legacyStoneRowsOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_04_STONES")) {
      throw new IllegalStateException("La tabella legacy delle pietre non è pronta.")
    }
    val rows = ctx.legacyStoneRowsOutput.get
    if (rows.length != 46 || rows.exists(_.length != 5)) {
      throw new IllegalStateException("Forma della tabella legacy delle pietre non valida.")
    }
  }

  def requirePatch03Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_03_DISTANCE" ||
        ctx.status != "PATCH_03_READY" ||
        ctx.legacyDistanceOutput.isEmpty ||
        ctx.patchedDistanceOutput.isEmpty ||
        !ctx.patch03Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_03_DISTANCE", "PATCH_03_DISTANCE")) {
      throw new IllegalStateException("La distanza PATCH 03 non è pronta.")
    }
    if (ctx.legacyDistanceOutput.get < 0 ||
        ctx.patchedDistanceOutput.get != ctx.legacyDistanceOutput.get + 1) {
      throw new IllegalStateException("PATCH 03 deve aggiungere esattamente un giorno.")
    }
  }

  def requireDiscovery03Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_03_DISTANCE" ||
        ctx.status != "LEGACY_DISTANCE_READY" ||
        ctx.legacyDistanceOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_03_DISTANCE")) {
      throw new IllegalStateException("La distanza legacy non è pronta nel contesto corrente.")
    }
  }

  def requirePatch02Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_02_DAY_TAG" ||
        ctx.status != "PATCH_02_READY" ||
        ctx.legacyDayTagInput.isEmpty ||
        ctx.legacyDayTagOutput.isEmpty ||
        ctx.patchedDayTagOutput.isEmpty ||
        !ctx.patch02Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_02_DAY_TAG", "PATCH_02_DAY_TAG")) {
      throw new IllegalStateException("Il PATCH 02 non è pronto nel contesto corrente.")
    }
    // Convalida indipendente del delta locale, senza usare l'oracolo di test.
    val expectedIncrement =
      if (ctx.legacyDayTagInput.get >= BigInt(-15055671)) BigInt(1) else BigInt(0)
    if (ctx.patchedDayTagOutput.get != ctx.legacyDayTagOutput.get + expectedIncrement) {
      throw new IllegalStateException("Il PATCH 02 ha alterato la cicatrice in modo non consentito.")
    }
  }

  def requireDiscovery02Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_02_DAY_TAG" ||
        ctx.status != "LEGACY_DAY_TAG_READY" ||
        ctx.legacyDayTagInput.isEmpty ||
        ctx.legacyDayTagOutput.isEmpty ||
        ctx.branchTrace.lastOption != Some("DISCOVERY_02_DAY_TAG")) {
      throw new IllegalStateException("La nota del giorno legacy non è pronta.")
    }
  }

  def requirePatch01Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_01_SAVE" ||
        ctx.status != "PATCH_01_READY" ||
        ctx.legacyRemainderInput.isEmpty ||
        ctx.legacyRemainderOutput.isEmpty ||
        ctx.patchedSaveOutput.isEmpty ||
        !ctx.patch01Applied ||
        ctx.branchTrace.lastOption != Some("PATCH_01_SAVE")) {
      throw new IllegalStateException("Il PATCH 01 non è pronto nel contesto corrente.")
    }
  }

  def requireDiscovery01Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_01_REMAINDER" ||
        ctx.status != "LEGACY_REMAINDER_READY" ||
        ctx.legacyRemainderInput.isEmpty ||
        ctx.legacyRemainderOutput.isEmpty) {
      throw new IllegalStateException("Il residuo legacy non è pronto nel contesto corrente.")
    }
  }
}

final case class WrappedMonsterError(messageItalian: String, cause: Throwable)
  extends RuntimeException(messageItalian, cause)

object BaseErrorWrapper {
  def wrap(where: String, error: Throwable): WrappedMonsterError =
    WrappedMonsterError("Errore deterministico nello strato di base: " + where, error)
}

trait BasePhaseHandler {
  def phase: String
  def handle(ctx: BaseMonsterContext): Unit
}

final class BaseMonsterDispatcher(handlers: Vector[BasePhaseHandler]) {
  private val byPhase: Map[String, BasePhaseHandler] = {
    val pairs = handlers.map(h => h.phase -> h)
    if (pairs.map(_._1).distinct.size != pairs.size) {
      throw new IllegalArgumentException("Ogni fase di base deve avere un solo handler.")
    }
    pairs.toMap
  }

  def dispatch(ctx: BaseMonsterContext): Unit = {
    val handler = byPhase.getOrElse(
      ctx.phase,
      throw new IllegalStateException("Fase di base non registrata: " + ctx.phase)
    )
    handler.handle(ctx)
  }
}

final class BaseBootstrapHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "BOOT"

  override def handle(ctx: BaseMonsterContext): Unit = {
    ctx.branchTrace.append("BOOT")
    metrics.bump("base.bootstrap.calls")
    ctx.status = "BOOTSTRAPPED"
  }
}

final class BaseMonsterManager {
  private val metrics = new BaseMetricsShell
  private val validation = new BaseValidationManager
  private val dispatcher = new BaseMonsterDispatcher(Vector(
    new BaseBootstrapHandler(metrics),
    new Discovery01RemainderHandler(metrics),
    new Patch01SaveHandler(metrics),
    new Discovery02DayTagHandler(metrics),
    new Patch02DayTagHandler(metrics),
    new Discovery03DistanceHandler(metrics),
    new Patch03DistanceHandler(metrics),
    new Discovery04StonesHandler(metrics),
    new Patch04StonesHandler(metrics),
    new Discovery05PriorHandler(metrics),
    new Patch05PriorHandler(metrics),
    new Discovery06GrindHandler(metrics),
    new Patch06GrindHandler(metrics),
    new Discovery07PermutationHandler(metrics),
    new Patch07PermutationHandler(metrics),
    new Discovery08BowlAliasHandler(metrics),
    new Patch08BowlHandler(metrics),
    new Discovery09VaultHandler(metrics),
    new Patch09VaultHandler(metrics),
    new Discovery10Order46LatchHandler(metrics),
    new Patch10Order46Handler(metrics),
    new Discovery11BiasedPickHandler(metrics),
    new Patch11ShortPickHandler(metrics),
    new Discovery12YearCeilingHandler(metrics),
    new Patch12YearCeilingHandler(metrics),
    new Discovery13YearJumpHandler(metrics),
    new Patch13YearJumpHandler(metrics),
    new Discovery14VirtualGateListHandler(metrics),
    new Patch14VirtualGateHandler(metrics),
    new Discovery15DaywiseWeavingHandler(metrics),
    new Patch15MonthWeavingHandler(metrics),
    new Discovery16ContiguousMonthDayHandler(metrics),
    new Patch16ContiguousMonthDayHandler(metrics),
    new Discovery17DuplicatedMonthNameHandler(metrics),
    new Patch17DistinctMonthNameHandler(metrics),
    new Discovery18SourceCatalogMismatchHandler(metrics),
    new Patch18SourceCatalogHandler(metrics),
    new Discovery19DayIndexedMonthNameHandler(metrics),
    new Patch19DayIndexedMonthNameHandler(metrics),
    new Discovery20CutletOpenBoundaryHandler(metrics),
    new Patch20CutletOpenBoundaryHandler(metrics)
  ))

  def bootstrap(calculationDay: BigInt, targetDay: BigInt): BaseMonsterContext = {
    val ctx = BaseMonsterContext(calculationDay, targetDay)
    try {
      validation.requireFreshContext(ctx)
      dispatcher.dispatch(ctx)
      ctx
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("bootstrap", e)
    }
  }

  def discover01Remainder(calculationDay: BigInt, targetDay: BigInt, input: BigInt): Discovery01Report = {
    // La stessa invocazione possiede sia lo stato BOOT sia quello DISCOVERY 01.
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyRemainderInput = Some(input)
    ctx.phase = "DISCOVERY_01_REMAINDER"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery01Ready(ctx)
      Discovery01Report(
        input = ctx.legacyRemainderInput.get,
        legacyOutput = ctx.legacyRemainderOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery01", e)
    }
  }

  def patch01Save(calculationDay: BigInt, targetDay: BigInt, input: BigInt): Patch01SaveReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyRemainderInput = Some(input)
    ctx.phase = "DISCOVERY_01_REMAINDER"
    try {
      // La cicatrice storica viene percorsa davvero prima del wrapper PATCH 01.
      dispatcher.dispatch(ctx)
      validation.requireDiscovery01Ready(ctx)
      ctx.phase = "PATCH_01_SAVE"
      dispatcher.dispatch(ctx)
      validation.requirePatch01Ready(ctx)
      Patch01SaveReport(
        input = ctx.legacyRemainderInput.get,
        legacyOutput = ctx.legacyRemainderOutput.get,
        patchedOutput = ctx.patchedSaveOutput.get,
        patchApplied = ctx.patch01Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch01", e)
    }
  }

  def discover02DayTag(calculationDay: BigInt, targetDay: BigInt, day: BigInt): Discovery02DayTagReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyDayTagInput = Some(day)
    ctx.phase = "DISCOVERY_02_DAY_TAG"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery02Ready(ctx)
      Discovery02DayTagReport(
        queriedDay = ctx.legacyDayTagInput.get,
        legacyTag = ctx.legacyDayTagOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery02", e)
    }
  }

  def patch02DayTag(calculationDay: BigInt, targetDay: BigInt, day: BigInt): Patch02DayTagReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyDayTagInput = Some(day)
    ctx.phase = "DISCOVERY_02_DAY_TAG"
    try {
      // Stessa invocazione: la cicatrice storica deve essere osservata prima della patch.
      dispatcher.dispatch(ctx)
      validation.requireDiscovery02Ready(ctx)
      ctx.phase = "PATCH_02_DAY_TAG"
      dispatcher.dispatch(ctx)
      validation.requirePatch02Ready(ctx)
      Patch02DayTagReport(
        queriedDay = ctx.legacyDayTagInput.get,
        legacyTag = ctx.legacyDayTagOutput.get,
        patchedTag = ctx.patchedDayTagOutput.get,
        patchApplied = ctx.patch02Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch02", e)
    }
  }

  def discover03Distance(calculationDay: BigInt, targetDay: BigInt): Discovery03DistanceReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_03_DISTANCE"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery03Ready(ctx)
      Discovery03DistanceReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyDistance = ctx.legacyDistanceOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery03", e)
    }
  }

  def patch03Distance(calculationDay: BigInt, targetDay: BigInt): Patch03DistanceReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_03_DISTANCE"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery03Ready(ctx)
      ctx.phase = "PATCH_03_DISTANCE"
      dispatcher.dispatch(ctx)
      validation.requirePatch03Ready(ctx)
      Patch03DistanceReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyDistance = ctx.legacyDistanceOutput.get,
        patchedDistance = ctx.patchedDistanceOutput.get,
        patchApplied = ctx.patch03Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch03", e)
    }
  }

  def discover04Stones(calculationDay: BigInt, targetDay: BigInt): Discovery04StonesReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_04_STONES"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery04Ready(ctx)
      Discovery04StonesReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyStoneRows = ctx.legacyStoneRowsOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery04", e)
    }
  }

  def patch04Stones(calculationDay: BigInt, targetDay: BigInt): Patch04StonesReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_04_STONES"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery04Ready(ctx)
      ctx.phase = "PATCH_04_STONES"
      dispatcher.dispatch(ctx)
      validation.requirePatch04Ready(ctx)
      Patch04StonesReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyStoneRows = ctx.legacyStoneRowsOutput.get,
        patchedStoneRows = ctx.patchedStoneRowsOutput.get,
        patchApplied = ctx.patch04Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch04", e)
    }
  }

  def discover05Prior(
    calculationDay: BigInt, targetDay: BigInt,
    hiddenDrops: Vector[BigInt], visibleDropsSoFar: Vector[BigInt],
    index: Int, lag: Int
  ): Discovery05PriorReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.priorHiddenInput = Some(hiddenDrops)
    ctx.priorVisibleInput = Some(visibleDropsSoFar)
    ctx.priorIndexInput = Some(index)
    ctx.priorLagInput = Some(lag)
    ctx.phase = "DISCOVERY_05_PRIOR"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery05Ready(ctx)
      Discovery05PriorReport(
        ctx.calculationDay, ctx.targetDay,
        ctx.priorHiddenInput.get, ctx.priorVisibleInput.get,
        ctx.priorIndexInput.get, ctx.priorLagInput.get,
        ctx.legacyPriorOutput.get, ctx.phase, ctx.status,
        ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery05", e)
    }
  }

  def patch05Prior(
    calculationDay: BigInt, targetDay: BigInt,
    hiddenDrops: Vector[BigInt], visibleDropsSoFar: Vector[BigInt],
    index: Int, lag: Int
  ): Patch05PriorReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.priorHiddenInput = Some(hiddenDrops)
    ctx.priorVisibleInput = Some(visibleDropsSoFar)
    ctx.priorIndexInput = Some(index)
    ctx.priorLagInput = Some(lag)
    ctx.phase = "DISCOVERY_05_PRIOR"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery05Ready(ctx)
      ctx.phase = "PATCH_05_PRIOR"
      dispatcher.dispatch(ctx)
      validation.requirePatch05Ready(ctx)
      Patch05PriorReport(
        ctx.calculationDay, ctx.targetDay,
        ctx.priorHiddenInput.get, ctx.priorVisibleInput.get,
        ctx.priorIndexInput.get, ctx.priorLagInput.get,
        ctx.legacyPriorOutput.get, ctx.patchedPriorOutput.get,
        ctx.patch05Applied, ctx.phase, ctx.status,
        ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch05", e)
    }
  }

  def discover06Grind(
    calculationDay: BigInt, targetDay: BigInt, step: Int,
    oldValue: BigInt, previous1: BigInt, previous3: BigInt,
    previous7: BigInt, stones: Vector[BigInt]
  ): Discovery06GrindReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.grindStepInput = Some(step)
    ctx.grindValueInput = Some(oldValue)
    ctx.grindPrev1Input = Some(previous1)
    ctx.grindPrev3Input = Some(previous3)
    ctx.grindPrev7Input = Some(previous7)
    ctx.grindStonesInput = Some(stones)
    ctx.phase = "DISCOVERY_06_GRIND"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery06Ready(ctx)
      Discovery06GrindReport(
        calculationDay = ctx.calculationDay, targetDay = ctx.targetDay,
        step = ctx.grindStepInput.get, oldValue = ctx.grindValueInput.get,
        previous1 = ctx.grindPrev1Input.get, previous3 = ctx.grindPrev3Input.get,
        previous7 = ctx.grindPrev7Input.get, stones = ctx.grindStonesInput.get,
        legacyRule = ctx.legacyGrindRuleOutput.get, legacyValue = ctx.legacyGrindOutput.get,
        phase = ctx.phase, status = ctx.status, trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery06", e)
    }
  }

  def patch06Grind(
    calculationDay: BigInt, targetDay: BigInt, step: Int,
    oldValue: BigInt, previous1: BigInt, previous3: BigInt,
    previous7: BigInt, stones: Vector[BigInt]
  ): Patch06GrindReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.grindStepInput = Some(step)
    ctx.grindValueInput = Some(oldValue)
    ctx.grindPrev1Input = Some(previous1)
    ctx.grindPrev3Input = Some(previous3)
    ctx.grindPrev7Input = Some(previous7)
    ctx.grindStonesInput = Some(stones)
    ctx.phase = "DISCOVERY_06_GRIND"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery06Ready(ctx)
      ctx.phase = "PATCH_06_GRIND"
      dispatcher.dispatch(ctx)
      validation.requirePatch06Ready(ctx)
      Patch06GrindReport(
        calculationDay = ctx.calculationDay, targetDay = ctx.targetDay,
        step = ctx.grindStepInput.get, oldValue = ctx.grindValueInput.get,
        previous1 = ctx.grindPrev1Input.get, previous3 = ctx.grindPrev3Input.get,
        previous7 = ctx.grindPrev7Input.get, stones = ctx.grindStonesInput.get,
        legacyRule = ctx.legacyGrindRuleOutput.get, legacyValue = ctx.legacyGrindOutput.get,
        patchedRule = ctx.patchedGrindRuleOutput.get, patchedValue = ctx.patchedGrindOutput.get,
        patchApplied = ctx.patch06Applied,
        phase = ctx.phase, status = ctx.status, trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch06", e)
    }
  }

  def discover07Permutation(
    calculationDay: BigInt, targetDay: BigInt, rank1: Int
  ): Discovery07PermutationReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.permutationRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_07_PERMUTATION"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery07Ready(ctx)
      Discovery07PermutationReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        requestedRank1 = ctx.permutationRankInput.get,
        legacyPermutation = ctx.legacyPermutationOutput.get,
        phase = ctx.phase, status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery07", e)
    }
  }

  def patch07Permutation(
    calculationDay: BigInt, targetDay: BigInt, rank1: Int
  ): Patch07PermutationReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.permutationRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_07_PERMUTATION"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery07Ready(ctx)
      ctx.phase = "PATCH_07_PERMUTATION"
      dispatcher.dispatch(ctx)
      validation.requirePatch07Ready(ctx)
      Patch07PermutationReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        requestedRank1 = ctx.permutationRankInput.get,
        legacyPermutation = ctx.legacyPermutationOutput.get,
        patchedPermutation = ctx.patchedPermutationOutput.get,
        patchApplied = ctx.patch07Applied,
        phase = ctx.phase, status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch07", e)
    }
  }

  def discover08BowlAlias(
    calculationDay: BigInt, targetDay: BigInt,
    initial: Vector[BigInt], drop: BigInt,
    stones: Vector[BigInt], step: Int, rank1: Int
  ): Discovery08BowlAliasReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.bowlInput = Some(initial)
    ctx.bowlDropInput = Some(drop)
    ctx.bowlStonesInput = Some(stones)
    ctx.bowlStepInput = Some(step)
    ctx.bowlRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_08_BOWL_ALIAS"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery08Ready(ctx)
      Discovery08BowlAliasReport(
        ctx.calculationDay,ctx.targetDay,ctx.bowlInput.get,
        ctx.bowlDropInput.get,ctx.bowlStonesInput.get,ctx.bowlStepInput.get,
        ctx.bowlRankInput.get,ctx.legacyBowlOrderOutput.get,
        ctx.legacyBowlPoursOutput.get,ctx.legacyBowlOutput.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("discovery08",error)
    }
  }

  def patch08Bowls(
    calculationDay: BigInt, targetDay: BigInt,
    initial: Vector[BigInt], drop: BigInt,
    stones: Vector[BigInt], step: Int, rank1: Int
  ): Patch08BowlReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.bowlInput = Some(initial)
    ctx.bowlDropInput = Some(drop)
    ctx.bowlStonesInput = Some(stones)
    ctx.bowlStepInput = Some(step)
    ctx.bowlRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_08_BOWL_ALIAS"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery08Ready(ctx)
      ctx.phase = "PATCH_08_BOWL_FREEZE"
      dispatcher.dispatch(ctx)
      validation.requirePatch08Ready(ctx)
      Patch08BowlReport(
        ctx.calculationDay,ctx.targetDay,ctx.bowlInput.get,
        ctx.bowlDropInput.get,ctx.bowlStonesInput.get,
        ctx.bowlStepInput.get,ctx.bowlRankInput.get,
        ctx.legacyBowlOrderOutput.get,ctx.legacyBowlPoursOutput.get,
        ctx.legacyBowlOutput.get,ctx.patchedBowlOutput.get,
        ctx.patch08Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("patch08",error)
    }
  }


  def discover09Vault(
    calculationDay: BigInt, targetDay: BigInt,
    bowlsAfterDrops: Vector[BigInt]
  ): Discovery09VaultReport = {
    val ctx = bootstrap(calculationDay,targetDay)
    ctx.postStirInput = Some(bowlsAfterDrops)
    ctx.phase = "DISCOVERY_09_VAULT"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery09Ready(ctx)
      Discovery09VaultReport(
        ctx.calculationDay,ctx.targetDay,ctx.postStirInput.get,
        ctx.legacyVaultRounds.get,ctx.legacyVaultOutput.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("discovery09",error)
    }
  }

  def patch09Vault(
    calculationDay: BigInt, targetDay: BigInt,
    bowlsAfterDrops: Vector[BigInt]
  ): Patch09VaultReport = {
    val ctx = bootstrap(calculationDay,targetDay)
    ctx.postStirInput = Some(bowlsAfterDrops)
    ctx.phase = "DISCOVERY_09_VAULT"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery09Ready(ctx)
      ctx.phase = "PATCH_09_VAULT_ROLL"
      dispatcher.dispatch(ctx)
      validation.requirePatch09Ready(ctx)
      Patch09VaultReport(
        ctx.calculationDay,ctx.targetDay,ctx.postStirInput.get,
        ctx.legacyVaultRounds.get,ctx.legacyVaultOutput.get,
        ctx.patchedVaultRounds.get,ctx.patchedVaultOutput.get,
        ctx.patch09Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("patch09",error)
    }
  }

  def discover10Order46Latch(
    calculationDay: BigInt, targetDay: BigInt,
    drop45: BigInt, drop46: BigInt, queriedBowlId: Int
  ): Discovery10Order46LatchReport = {
    val ctx = bootstrap(calculationDay,targetDay)
    ctx.penultimateDropValue = Some(drop45)
    ctx.finalDropValue = Some(drop46)
    ctx.queriedBowlInput = Some(queriedBowlId)
    ctx.phase = "DISCOVERY_10_ORDER46_LATCH"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery10Ready(ctx)
      Discovery10Order46LatchReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.penultimateDropValue.get,ctx.finalDropValue.get,
        ctx.queriedBowlInput.get,ctx.legacyLatchedOrder45.get,
        ctx.observedOrder46.get,ctx.legacyNextBowlOutput.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("discovery10",error)
    }
  }

  def patch10Order46(
    calculationDay: BigInt, targetDay: BigInt,
    drop45: BigInt, drop46: BigInt, queriedBowlId: Int
  ): Patch10Order46Report = {
    val ctx = bootstrap(calculationDay,targetDay)
    ctx.penultimateDropValue = Some(drop45)
    ctx.finalDropValue = Some(drop46)
    ctx.queriedBowlInput = Some(queriedBowlId)
    ctx.phase = "DISCOVERY_10_ORDER46_LATCH"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery10Ready(ctx)
      ctx.phase = "PATCH_10_ORDER46_FREEZE"
      dispatcher.dispatch(ctx)
      validation.requirePatch10Ready(ctx)
      Patch10Order46Report(
        ctx.calculationDay,ctx.targetDay,
        ctx.penultimateDropValue.get,ctx.finalDropValue.get,
        ctx.queriedBowlInput.get,ctx.legacyLatchedOrder45.get,
        ctx.observedOrder46.get,ctx.legacyNextBowlOutput.get,
        ctx.patchedLatchedOrder46.get,ctx.patchedNextBowlOutput.get,
        ctx.patch10Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch10",e)
    }
  }

  def discover11BiasedPick(
    calculationDay: BigInt, targetDay: BigInt,
    firstSample: BigInt, directionStep: Int, familySize: BigInt
  ): Discovery11BiasedPickReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.selectionSampleInput=Some(firstSample)
    ctx.selectionDirectionInput=Some(directionStep)
    ctx.selectionFamilySizeInput=Some(familySize)
    ctx.phase="DISCOVERY_11_BIASED_SHORT_PICK"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery11Ready(ctx)
      Discovery11BiasedPickReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.selectionSampleInput.get,ctx.selectionDirectionInput.get,
        ctx.selectionFamilySizeInput.get,ctx.legacyBiasedSampleOutput.get,
        ctx.legacyBiasedRankOutput.get,ctx.legacyAcceptanceLimitOutput.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery11",e)
    }
  }

  def patch11ShortPick(
    calculationDay: BigInt, targetDay: BigInt,
    firstSample: BigInt, directionStep: Int, familySize: BigInt
  ): Patch11ShortPickReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.selectionSampleInput=Some(firstSample)
    ctx.selectionDirectionInput=Some(directionStep)
    ctx.selectionFamilySizeInput=Some(familySize)
    ctx.phase="DISCOVERY_11_BIASED_SHORT_PICK"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery11Ready(ctx)
      ctx.phase="PATCH_11_SHORT_REJECTION"
      dispatcher.dispatch(ctx)
      validation.requirePatch11Ready(ctx)
      Patch11ShortPickReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.selectionSampleInput.get,ctx.selectionDirectionInput.get,
        ctx.selectionFamilySizeInput.get,
        ctx.legacyBiasedSampleOutput.get,
        ctx.legacyBiasedRankOutput.get,
        ctx.legacyAcceptanceLimitOutput.get,
        ctx.patchedAcceptedSample.get,
        ctx.patchedShortPickRank.get,
        ctx.patchedSkippedSamples.get,
        ctx.patch11Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("patch11",error)
    }
  }

  def discover12YearCeiling(
    calculationDay: BigInt, targetDay: BigInt,
    gateGaps: Vector[Int]
  ): Discovery12YearCeilingReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.legacyYearGapsInput=Some(gateGaps)
    ctx.phase="DISCOVERY_12_YEAR_CEILING"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery12Ready(ctx)
      Discovery12YearCeilingReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.legacyYearGapsInput.get,
        ctx.legacyYearLengthOutput.get,
        ctx.legacyYearAcceptedOutput.get,
        ctx.legacyYearMaxOutput.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case err: Throwable => throw BaseErrorWrapper.wrap("discovery12",err)
    }
  }

  def patch12YearCeiling(
    calculationDay: BigInt, targetDay: BigInt,
    gateGaps: Vector[Int]
  ): Patch12YearCeilingReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.legacyYearGapsInput=Some(gateGaps)
    ctx.phase="DISCOVERY_12_YEAR_CEILING"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery12Ready(ctx)
      ctx.phase="PATCH_12_YEAR_CEILING"
      dispatcher.dispatch(ctx)
      validation.requirePatch12Ready(ctx)
      Patch12YearCeilingReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.legacyYearGapsInput.get,ctx.legacyYearLengthOutput.get,
        ctx.legacyYearAcceptedOutput.get,ctx.legacyYearMaxOutput.get,
        ctx.patchedYearAcceptedOutput.get,ctx.patchedYearMaxOutput.get,
        ctx.patch12Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case err: Throwable => throw BaseErrorWrapper.wrap("patch12",err)
    }
  }

  def discover13YearJump(
    calculationDay: BigInt, targetDay: BigInt,
    anchorOpenDay: BigInt,
    yearsBefore: Vector[Int], yearsFromAnchor: Vector[Int]
  ): Discovery13YearJumpReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.jumpAnchorOpenDay=Some(anchorOpenDay)
    ctx.jumpBeforeLengths=Some(yearsBefore)
    ctx.jumpFromAnchorLengths=Some(yearsFromAnchor)
    ctx.phase="DISCOVERY_13_YEAR_JUMP"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery13Ready(ctx)
      Discovery13YearJumpReport(
        ctx.calculationDay,ctx.targetDay,ctx.jumpAnchorOpenDay.get,
        ctx.jumpBeforeLengths.get,ctx.jumpFromAnchorLengths.get,
        ctx.legacyJumpOffset.get,ctx.legacyJumpOpenDay.get,
        ctx.legacyJumpCloseDay.get,ctx.phase,ctx.status,
        ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("discovery13",error)
    }
  }

  def patch13YearJump(
    calculationDay: BigInt, targetDay: BigInt,
    anchorOpenDay: BigInt, yearsBefore: Vector[Int],
    yearsFromAnchor: Vector[Int]
  ): Patch13YearJumpReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.jumpAnchorOpenDay=Some(anchorOpenDay)
    ctx.jumpBeforeLengths=Some(yearsBefore)
    ctx.jumpFromAnchorLengths=Some(yearsFromAnchor)
    ctx.phase="DISCOVERY_13_YEAR_JUMP"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery13Ready(ctx)
      ctx.phase="PATCH_13_YEAR_JUMP"
      dispatcher.dispatch(ctx)
      validation.requirePatch13Ready(ctx)
      Patch13YearJumpReport(
        ctx.calculationDay,ctx.targetDay,ctx.jumpAnchorOpenDay.get,
        ctx.jumpBeforeLengths.get,ctx.jumpFromAnchorLengths.get,
        ctx.legacyJumpOffset.get,ctx.legacyJumpOpenDay.get,
        ctx.legacyJumpCloseDay.get,ctx.patchedJumpOffset.get,
        ctx.patchedJumpOpenDay.get,ctx.patchedJumpCloseDay.get,
        ctx.patch13Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("patch13",error)
    }
  }

  def discover14VirtualGateList(
    calculationDay: BigInt,
    targetDay: BigInt,
    firstGateIndex: BigInt,
    gateStride: BigInt,
    candidateCount: BigInt,
    rank1: BigInt
  ): Discovery14VirtualGateListReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.virtualFirstGateIndex=Some(firstGateIndex)
    ctx.virtualGateStride=Some(gateStride)
    ctx.virtualCandidateCount=Some(candidateCount)
    ctx.virtualRequestedRank=Some(rank1)
    ctx.phase="DISCOVERY_14_VIRTUAL_GATE_LIST"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery14Ready(ctx)
      Discovery14VirtualGateListReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.virtualFirstGateIndex.get,ctx.virtualGateStride.get,
        ctx.virtualCandidateCount.get,ctx.virtualRequestedRank.get,
        ctx.legacyVirtualNarrowedRank.get,
        ctx.legacyVirtualSelectedGateIndex.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("discovery14",error)
    }
  }

  def patch14VirtualGateList(
    calculationDay: BigInt,
    targetDay: BigInt,
    firstGateIndex: BigInt,
    gateStride: BigInt,
    candidateCount: BigInt,
    rank1: BigInt
  ): Patch14VirtualGateReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.virtualFirstGateIndex=Some(firstGateIndex)
    ctx.virtualGateStride=Some(gateStride)
    ctx.virtualCandidateCount=Some(candidateCount)
    ctx.virtualRequestedRank=Some(rank1)
    ctx.phase="DISCOVERY_14_VIRTUAL_GATE_LIST"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery14Ready(ctx)
      ctx.phase="PATCH_14_VIRTUAL_GATE_LIST"
      dispatcher.dispatch(ctx)
      validation.requirePatch14Ready(ctx)
      Patch14VirtualGateReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.virtualFirstGateIndex.get,ctx.virtualGateStride.get,
        ctx.virtualCandidateCount.get,ctx.virtualRequestedRank.get,
        ctx.legacyVirtualNarrowedRank.get,
        ctx.legacyVirtualSelectedGateIndex.get,
        ctx.patchedVirtualSelectedGateIndex.get,
        ctx.patch14Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable => throw BaseErrorWrapper.wrap("patch14",error)
    }
  }

  def discover15DaywiseWeaving(
    calculationDay: BigInt,
    targetDay: BigInt,
    candidates: Vector[Vector[Int]],
    yearRank1: BigInt,
    dayOffset: Int
  ): Discovery15DaywiseWeavingReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.daywiseCandidateWeavings=Some(candidates)
    ctx.daywiseYearRank1=Some(yearRank1)
    ctx.daywiseOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_15_DAYWISE_WEAVING"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery15Ready(ctx)
      Discovery15DaywiseWeavingReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.daywiseCandidateWeavings.get,ctx.daywiseYearRank1.get,
        ctx.daywiseOffset.get,ctx.legacyDaywiseRank1.get,
        ctx.legacyDaywiseMonthId.get,ctx.phase,ctx.status,
        ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("discovery15",error)
    }
  }

  def patch15DaywiseWeaving(
    calculationDay: BigInt,
    targetDay: BigInt,
    candidates: Vector[Vector[Int]],
    yearRank1: BigInt,
    dayOffset: Int
  ): Patch15MonthWeavingReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.daywiseCandidateWeavings=Some(candidates)
    ctx.daywiseYearRank1=Some(yearRank1)
    ctx.daywiseOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_15_DAYWISE_WEAVING"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery15Ready(ctx)
      ctx.phase="PATCH_15_DAYWISE_WEAVING"
      dispatcher.dispatch(ctx)
      validation.requirePatch15Ready(ctx)
      Patch15MonthWeavingReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.daywiseCandidateWeavings.get,ctx.daywiseYearRank1.get,
        ctx.daywiseOffset.get,ctx.legacyDaywiseRank1.get,
        ctx.legacyDaywiseMonthId.get,ctx.patchedAnnualWeaving.get,
        ctx.patchedMonthId.get,ctx.patchedDayInMonth.get,
        ctx.patch15Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("patch15",error)
    }
  }

  def discover16ContiguousMonthDay(
    calculationDay: BigInt,
    targetDay: BigInt,
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): Discovery16ContiguousMonthDayReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.contiguousAnnualWeaving=Some(annualWeaving)
    ctx.contiguousDayOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery16Ready(ctx)
      Discovery16ContiguousMonthDayReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.contiguousAnnualWeaving.get,ctx.contiguousDayOffset.get,
        ctx.legacyContiguousMonthLengths.get,
        ctx.legacyContiguousSelectedMonthId.get,
        ctx.legacyContiguousAssumedStartOffset.get,
        ctx.legacyContiguousDayInMonth.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable=>
        throw BaseErrorWrapper.wrap("discovery16",error)
    }
  }

  def patch16ContiguousMonthDay(
    calculationDay: BigInt,
    targetDay: BigInt,
    annualWeaving: Vector[Int],
    dayOffset: Int
  ): Patch16ContiguousMonthDayReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.contiguousAnnualWeaving=Some(annualWeaving)
    ctx.contiguousDayOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery16Ready(ctx)
      ctx.phase="PATCH_16_CONTIGUOUS_MONTH_DAY"
      dispatcher.dispatch(ctx)
      validation.requirePatch16Ready(ctx)
      Patch16ContiguousMonthDayReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.contiguousAnnualWeaving.get,ctx.contiguousDayOffset.get,
        ctx.legacyContiguousMonthLengths.get,
        ctx.legacyContiguousSelectedMonthId.get,
        ctx.legacyContiguousAssumedStartOffset.get,
        ctx.legacyContiguousDayInMonth.get,
        ctx.patchedContiguousMonthId.get,
        ctx.patchedContiguousDayInMonth.get,
        ctx.patch16Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("patch16",error)
    }
  }

  def discover17DuplicatedMonthName(
    calculationDay: BigInt,
    targetDay: BigInt,
    monthCount: Int,
    rank1: BigInt
  ): Discovery17DuplicatedMonthNameReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.monthNameCount=Some(monthCount)
    ctx.monthNameRank1=Some(rank1)
    ctx.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery17Ready(ctx)
      Discovery17DuplicatedMonthNameReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.monthNameCount.get,ctx.monthNameRank1.get,
        ctx.legacyMonthNameDistinctChoices.get,
        ctx.legacyMonthNameReplacementSpace.get,
        ctx.legacyMonthNameIndices.get,ctx.phase,ctx.status,
        ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("discovery17",error)
    }
  }

  def patch17DistinctMonthName(
    calculationDay: BigInt,
    targetDay: BigInt,
    monthCount: Int,
    rank1: BigInt
  ): Patch17DistinctMonthNameReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.monthNameCount=Some(monthCount)
    ctx.monthNameRank1=Some(rank1)
    ctx.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery17Ready(ctx)
      ctx.phase="PATCH_17_DISTINCT_MONTH_NAME"
      dispatcher.dispatch(ctx)
      validation.requirePatch17Ready(ctx)
      Patch17DistinctMonthNameReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.monthNameCount.get,ctx.monthNameRank1.get,
        ctx.legacyMonthNameDistinctChoices.get,
        ctx.legacyMonthNameReplacementSpace.get,
        ctx.legacyMonthNameIndices.get,
        ctx.patchedDistinctMonthNameIndices.get,
        ctx.patch17Applied,ctx.phase,ctx.status,
        ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("patch17",error)
    }
  }

  def discover18SourceCatalogMismatch(
    calculationDay: BigInt,
    targetDay: BigInt,
    canonicalMonthIndices: Vector[Int]
  ): Discovery18SourceCatalogMismatchReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.catalogMonthIndices=Some(canonicalMonthIndices)
    ctx.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery18Ready(ctx)
      Discovery18SourceCatalogMismatchReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.catalogMonthIndices.get,
        ctx.catalogFrozenVersion.get,
        ctx.catalogLegacyItalianNames.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable=>
        throw BaseErrorWrapper.wrap("discovery18",error)
    }
  }

  def patch18SourceCatalogIndex(
    calculationDay: BigInt,
    targetDay: BigInt,
    canonicalMonthIndices: Vector[Int]
  ): Patch18SourceCatalogReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.catalogMonthIndices=Some(canonicalMonthIndices)
    ctx.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery18Ready(ctx)
      ctx.phase="PATCH_18_SOURCE_CATALOG_INDEX"
      dispatcher.dispatch(ctx)
      validation.requirePatch18Ready(ctx)
      Patch18SourceCatalogReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.catalogMonthIndices.get,
        ctx.catalogFrozenVersion.get,
        ctx.catalogLegacyItalianNames.get,
        ctx.patchedCatalogItalianNames.get,
        ctx.patch18Applied,ctx.phase,ctx.status,
        ctx.branchTrace.toVector)
    } catch {
      case error:Throwable=>
        throw BaseErrorWrapper.wrap("patch18",error)
    }
  }

  def discover19DayIndexedMonthName(
    calculationDay: BigInt,
    targetDay: BigInt,
    annualWeaving: Vector[Int],
    canonicalMonthNameIndices: Vector[Int],
    dayOffset: Int
  ): Discovery19DayIndexedMonthNameReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.dayNameWeaving=Some(annualWeaving)
    ctx.dayNameCanonicalIndices=Some(canonicalMonthNameIndices)
    ctx.dayNameOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_19_DAY_INDEXED_MONTH_NAME"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery19Ready(ctx)
      Discovery19DayIndexedMonthNameReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.dayNameWeaving.get,ctx.dayNameCanonicalIndices.get,
        ctx.dayNameOffset.get,ctx.dayNameLegacyMonthId.get,
        ctx.dayNameLegacySlot.get,ctx.dayNameFrozenVersion.get,
        ctx.dayNameLegacyItalian.get,ctx.phase,ctx.status,
        ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("discovery19",error)
    }
  }


  def patch19DayIndexedMonthName(
    calculationDay: BigInt,
    targetDay: BigInt,
    annualWeaving: Vector[Int],
    canonicalMonthNameIndices: Vector[Int],
    dayOffset: Int
  ): Patch19DayIndexedMonthNameReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.dayNameWeaving=Some(annualWeaving)
    ctx.dayNameCanonicalIndices=Some(canonicalMonthNameIndices)
    ctx.dayNameOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_19_DAY_INDEXED_MONTH_NAME"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery19Ready(ctx)
      ctx.phase="PATCH_19_DAY_INDEXED_MONTH_NAME"
      dispatcher.dispatch(ctx)
      validation.requirePatch19Ready(ctx)
      Patch19DayIndexedMonthNameReport(
        ctx.calculationDay,ctx.targetDay,ctx.dayNameWeaving.get,
        ctx.dayNameCanonicalIndices.get,ctx.dayNameOffset.get,
        ctx.dayNameLegacyMonthId.get,ctx.dayNameLegacySlot.get,
        ctx.dayNameFrozenVersion.get,ctx.dayNameLegacyItalian.get,
        ctx.dayNamePatchedItalian.get,ctx.patch19Applied,
        ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("patch19",error)
    }
  }


  def discover20CutletOpenBoundary(
    calculationDay: BigInt,
    targetDay: BigInt,
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    dayOffset: Int
  ): Discovery20CutletOpenBoundaryReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.cutletGateGaps=Some(gateGaps)
    ctx.cutletGatePartition=Some(cutletPartition)
    ctx.cutletDayOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_20_CUTLET_OPEN_BOUNDARY"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery20Ready(ctx)
      Discovery20CutletOpenBoundaryReport(
        ctx.calculationDay,ctx.targetDay,
        ctx.cutletGateGaps.get,ctx.cutletGatePartition.get,
        ctx.cutletDayOffset.get,ctx.legacyCutletStartOffsets.get,
        ctx.legacyCutletId.get,ctx.legacyDayInCutlet.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("discovery20",error)
    }
  }


  def patch20CutletOpenBoundary(
    calculationDay: BigInt,
    targetDay: BigInt,
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    dayOffset: Int
  ): Patch20CutletOpenBoundaryReport = {
    val ctx=bootstrap(calculationDay,targetDay)
    ctx.cutletGateGaps=Some(gateGaps)
    ctx.cutletGatePartition=Some(cutletPartition)
    ctx.cutletDayOffset=Some(dayOffset)
    ctx.phase="DISCOVERY_20_CUTLET_OPEN_BOUNDARY"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery20Ready(ctx)
      ctx.phase="PATCH_20_CUTLET_OPEN_BOUNDARY"
      dispatcher.dispatch(ctx)
      validation.requirePatch20Ready(ctx)
      Patch20CutletOpenBoundaryReport(
        ctx.calculationDay,ctx.targetDay,ctx.cutletGateGaps.get,
        ctx.cutletGatePartition.get,ctx.cutletDayOffset.get,
        ctx.legacyCutletStartOffsets.get,ctx.legacyCutletId.get,
        ctx.legacyDayInCutlet.get,ctx.patchedCutletId.get,
        ctx.patchedDayInCutlet.get,ctx.patch20Applied,
        ctx.phase,ctx.status,ctx.branchTrace.toVector)
    } catch {
      case error:Throwable =>
        throw BaseErrorWrapper.wrap("patch20",error)
    }
  }

  def metricsSnapshot: Map[String, BigInt] = metrics.snapshot
}
