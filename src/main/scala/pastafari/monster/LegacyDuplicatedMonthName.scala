package pastafari.monster

/**
 * DISCOVERY 17: la vecchia scelta dei nomi mensili usa un prodotto
 * cartesiano CON rimpiazzo, non le disposizioni distinte ordinate.
 * Il catalogo originale contiene 47 nomi: gli indici sono 1..47.
 *
 * Questa routine e' una cicatrice sintetica della selezione, non
 * ricostruisce la salsa che determina il rango normativo.
 */
final case class LegacyDuplicatedMonthNameResult(
  monthCount: Int,
  sourceRank1: BigInt,
  permittedDistinctChoices: BigInt,
  legacyReplacementSpace: BigInt,
  legacyCanonicalNameIndices: Vector[Int]
)

object LegacyDuplicatedMonthNameAdapter {
  def fallingProduct47(count: Int): BigInt = {
    require(count>=3 && count<=47,
      "Il numero di mesi deve appartenere all'intervallo 3..47.")
    var n=BigInt(1)
    var i=0
    while(i<count){
      n *= BigInt(47-i)
      i+=1
    }
    n
  }

  def oldMonthNameDuplicated(
    monthCount: Int,
    rank1: BigInt
  ): LegacyDuplicatedMonthNameResult = {
    val permitted=fallingProduct47(monthCount)
    require(rank1>=1 && rank1<=permitted,
      "Il rango richiesto supera le disposizioni distinte lecite.")
    val replacement=BigInt(47).pow(monthCount)
    // ERRORE INTENZIONALE: cifra per cifra in base 47, senza
    // eliminare i nomi gia' scelti dai candidati disponibili.
    val arr=Array.fill[Int](monthCount)(1)
    var v=rank1-BigInt(1)
    var pos=monthCount-1
    while(pos>=0){
      val qr=v /% BigInt(47)
      arr(pos)=qr._2.toInt+1
      v=qr._1
      pos-=1
    }
    LegacyDuplicatedMonthNameResult(
      monthCount,rank1,permitted,replacement,arr.toVector)
  }
}

final case class Discovery17DuplicatedMonthNameReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  monthCount: Int,
  rank1: BigInt,
  permittedDistinctChoices: BigInt,
  legacyReplacementSpace: BigInt,
  legacyCanonicalNameIndices: Vector[Int],
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Discovery17DuplicatedMonthNameHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"

  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase ||
       ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.monthNameCount.isEmpty ||
       ctx.monthNameRank1.isEmpty ||
       ctx.monthNameInputSnapshot.nonEmpty ||
       ctx.legacyMonthNameIndices.nonEmpty ||
       ctx.legacyMonthNameDistinctChoices.nonEmpty ||
       ctx.legacyMonthNameReplacementSpace.nonEmpty)
      throw new IllegalStateException(
        "DISCOVERY 17 richiede un Bootstrap nuovo con input completi.")

    val result=LegacyDuplicatedMonthNameAdapter.oldMonthNameDuplicated(
      ctx.monthNameCount.get,ctx.monthNameRank1.get)
    ctx.monthNameInputSnapshot=Some((result.monthCount,result.sourceRank1))
    ctx.legacyMonthNameIndices=Some(result.legacyCanonicalNameIndices)
    ctx.legacyMonthNameDistinctChoices=Some(result.permittedDistinctChoices)
    ctx.legacyMonthNameReplacementSpace=Some(result.legacyReplacementSpace)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery17.month.names.calls")
    ctx.status="LEGACY_DUPLICATED_MONTH_NAMES_READY"
  }
}
