package pastafari.monster

/**
 * PATCH 17: nomi mensili distinti dal catalogo congelato 1..47.
 *
 * Il rango BigInt 1-based riguarda P(47,m), in ordine lessicografico
 * delle disposizioni senza rimpiazzo. La vecchia scelta con
 * rimpiazzo è chiamata davvero e pubblicata separatamente.
 * Il rango è già scelto dal chiamante; nessuna salsa normativa qui.
 */
final case class Patch17DistinctMonthNamesResult(
  historical: LegacyDuplicatedMonthNameResult,
  correctedCanonicalNameIndices: Vector[Int]
)

object Patch17DistinctMonthNameWrapper {
  def monthNameDistinctPatch(
    monthCount: Int,
    rank1: BigInt
  ): Patch17DistinctMonthNamesResult = {
    val old=LegacyDuplicatedMonthNameAdapter.oldMonthNameDuplicated(
      monthCount,rank1)
    val available=scala.collection.mutable.ArrayBuffer.from(1 to 47)
    val chosen=Vector.newBuilder[Int]
    var rank0=rank1-BigInt(1)
    var position=0
    while(position<monthCount){
      var block=BigInt(1)
      var i=0
      val remainingSlots=monthCount-position-1
      while(i<remainingSlots){
        block*=BigInt(available.size-1-i)
        i+=1
      }
      val q=(rank0/block).toInt
      rank0=rank0%block
      require(q>=0 && q<available.size,"Indice di nome fuori rango.")
      chosen+=available.remove(q)
      position+=1
    }
    require(rank0==0,"Rango residuo inatteso.")
    Patch17DistinctMonthNamesResult(old,chosen.result())
  }
}

final case class Patch17DistinctMonthNameReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  monthCount: Int,
  rank1: BigInt,
  permittedDistinctChoices: BigInt,
  legacyReplacementSpace: BigInt,
  legacyCanonicalNameIndices: Vector[Int],
  correctedCanonicalNameIndices: Vector[Int],
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch17DistinctMonthNameHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_17_DISTINCT_MONTH_NAME"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_DUPLICATED_MONTH_NAMES_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_17_DUPLICATED_MONTH_NAME") ||
       ctx.monthNameCount.isEmpty || ctx.monthNameRank1.isEmpty ||
       ctx.monthNameInputSnapshot.isEmpty ||
       ctx.legacyMonthNameIndices.isEmpty ||
       ctx.legacyMonthNameDistinctChoices.isEmpty ||
       ctx.legacyMonthNameReplacementSpace.isEmpty ||
       ctx.patchedDistinctMonthNameIndices.nonEmpty ||
       ctx.patch17Applied)
      throw new IllegalStateException(
        "PATCH 17 richiede DISCOVERY 17 completa nella stessa chiamata.")

    val count=ctx.monthNameCount.get
    val rank=ctx.monthNameRank1.get
    if(ctx.monthNameInputSnapshot.get!=(count,rank))
      throw new IllegalStateException("Input modificati dopo DISCOVERY 17.")

    val result=Patch17DistinctMonthNameWrapper.monthNameDistinctPatch(
      count,rank)
    if(result.historical.monthCount!=count ||
       result.historical.sourceRank1!=rank ||
       result.historical.permittedDistinctChoices!=
         ctx.legacyMonthNameDistinctChoices.get ||
       result.historical.legacyReplacementSpace!=
         ctx.legacyMonthNameReplacementSpace.get ||
       result.historical.legacyCanonicalNameIndices!=
         ctx.legacyMonthNameIndices.get)
      throw new IllegalStateException(
        "La cicatrice storica dei nomi duplicati è falsificata.")

    val names=result.correctedCanonicalNameIndices
    if(names.length!=count || names.distinct.length!=count ||
       names.exists(x=>x<1 || x>47))
      throw new IllegalStateException("PATCH 17 ha prodotto nomi invalidi.")

    // Pubblica soltanto dopo aver verificato input, legacy e output.
    ctx.patchedDistinctMonthNameIndices=Some(names)
    ctx.patch17Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch17.distinct.month.names.calls")
    ctx.status="PATCH_17_READY"
  }
}
