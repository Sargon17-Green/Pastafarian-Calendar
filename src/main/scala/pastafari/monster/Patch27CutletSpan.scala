package pastafari.monster

/** PATCH27: la lunghezza normativa somma TUTTE le porte della cotoletta.
  * La lettura legacy della singola porta rimane in un campo distinto.
  */
final case class Patch27CutletSpanCalculation(historicalSpan:Int,correctedSpan:Int)

object Patch27CutletSpanWrapper {
  def correct(gaps:Vector[Int],part:Vector[Int],c:Int):Patch27CutletSpanCalculation={
    val historical=LegacyCutletSpanAdapter.oldCutletSpan(gaps,part,c)
    val first=part.iterator.take(c-1).sum
    val corrected=gaps.slice(first,first+part(c-1)).foldLeft(0)(_+_)
    Patch27CutletSpanCalculation(historical,corrected)
  }
}

final case class Patch27CutletSpanReport(
  calculationDay:BigInt,targetDay:BigInt,
  gateGaps:Vector[Int],cutletPartition:Vector[Int],cutletIndex:Int,
  legacySpan:Int,correctedSpan:Int,patchApplied:Boolean,
  phase:String,status:String,trace:Vector[String]
)

final class Patch27CutletSpanHandler(metrics:BaseMetricsShell)
  extends BasePhaseHandler {
  override val phase="PATCH_27_CUTLET_SPAN"
  override def handle(ctx:BaseMonsterContext):Unit={
    if(ctx.phase!=phase || ctx.status!="LEGACY_CUTLET_SPAN_READY" ||
       ctx.branchTrace.toVector!=Vector("BOOT","DISCOVERY_27_CUTLET_SPAN") ||
       ctx.cutletSpanGaps.isEmpty || ctx.cutletSpanPartition.isEmpty ||
       ctx.cutletSpanIndex.isEmpty || ctx.cutletSpanSnapshot.isEmpty ||
       ctx.cutletSpanLegacyLength.isEmpty ||
       ctx.patch27CorrectedLength.nonEmpty || ctx.patch27Applied)
      throw new IllegalStateException("PATCH27 richiede DISCOVERY27 integra.")
    val gaps=ctx.cutletSpanGaps.get
    val part=ctx.cutletSpanPartition.get
    val index=ctx.cutletSpanIndex.get
    if(ctx.cutletSpanSnapshot.get!=(gaps,part,index))
      throw new IllegalStateException("Snapshot DISCOVERY27 mutata.")
    val calculation=Patch27CutletSpanWrapper.correct(gaps,part,index)
    if(calculation.historicalSpan!=ctx.cutletSpanLegacyLength.get)
      throw new IllegalStateException("Cicatrice DISCOVERY27 mutata.")
    ctx.patch27CorrectedLength=Some(calculation.correctedSpan)
    ctx.patch27Applied=true
    ctx.branchTrace.append(phase)
    ctx.status="PATCH_27_READY"
    metrics.bump("patch27.cutlet.span.calls")
  }
}
