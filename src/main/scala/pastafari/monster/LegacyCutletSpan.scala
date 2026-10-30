package pastafari.monster

/** DISCOVERY27: ipotesi legacy deliberatamente errata, non un bug storico provato. */
object LegacyCutletSpanAdapter {
  def oldCutletSpan(gaps:Vector[Int],part:Vector[Int],c:Int):Int={
    require(part.length>=6 && part.length<=17,"Servono 6..17 cotolette.")
    require(gaps.length>=6 && gaps.length<=47,"Servono 6..47 porte.")
    require(part.forall(_>=1) && part.sum==gaps.length,"Partizione non valida.")
    require(gaps.forall(x=>x>=42 && x<=963) &&
      gaps.sum>=252 && gaps.sum<=5778,"Anno non valido.")
    require(c>=1 && c<=part.length,"Indice fuori intervallo.")
    gaps(c-1) // CICATRICE: una singola porta rappresenta l'intera cotoletta
  }
}
final case class Discovery27CutletSpanReport(
  calculationDay:BigInt,targetDay:BigInt,
  gateGaps:Vector[Int],cutletPartition:Vector[Int],
  cutletIndex:Int,legacySpan:Int,
  phase:String,status:String,trace:Vector[String]
)
final class Discovery27CutletSpanHandler(
    metrics:BaseMetricsShell) extends BasePhaseHandler {
  override val phase="DISCOVERY_27_CUTLET_SPAN"
  override def handle(ctx:BaseMonsterContext):Unit={
    if(ctx.phase!=phase || ctx.status!="BOOTSTRAPPED" ||
       ctx.branchTrace.toVector!=Vector("BOOT") ||
       ctx.cutletSpanGaps.isEmpty || ctx.cutletSpanPartition.isEmpty ||
       ctx.cutletSpanIndex.isEmpty || ctx.cutletSpanSnapshot.nonEmpty ||
       ctx.cutletSpanLegacyLength.nonEmpty)
      throw new IllegalStateException("DISCOVERY27 richiede bootstrap pulito.")
    val gaps=ctx.cutletSpanGaps.get
    val part=ctx.cutletSpanPartition.get
    val c=ctx.cutletSpanIndex.get
    val value=LegacyCutletSpanAdapter.oldCutletSpan(gaps,part,c)
    ctx.cutletSpanSnapshot=Some((gaps,part,c))
    ctx.cutletSpanLegacyLength=Some(value)
    ctx.branchTrace.append(phase)
    metrics.bump("discovery27.cutlet.span.calls")
    ctx.status="LEGACY_CUTLET_SPAN_READY"
  }
}
