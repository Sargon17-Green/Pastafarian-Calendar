package pastafari.monster

/** PATCH26: una cotoletta contiene una o piu' porte.
  * La cicatrice gateId = cutletId resta disponibile nel rapporto storico.
  * La partizione e' un input gia' selezionato, non un nuovo calcolo di calendario.
  */
final case class Patch26GateToCutletProjectionResult(
  historical: LegacyGateToCutletProjectionResult,
  correctedCutletId: Int, correctedDayInCutlet: Int
)

object Patch26GateToCutletProjectionWrapper {
  def gateToCutletPatch(
    gateGaps:Vector[Int],cutletPartition:Vector[Int],dayOffset:Int
  ):Patch26GateToCutletProjectionResult={
    val old=LegacyGateToCutletProjectionAdapter.oldGateToCutletProjection(
      gateGaps,cutletPartition,dayOffset)
    var firstGate=0
    var firstDay=0
    var index=0
    while(index<cutletPartition.length){
      val endGate=firstGate+cutletPartition(index)
      val span=gateGaps.slice(firstGate,endGate).sum
      if(dayOffset>=firstDay && dayOffset<firstDay+span)
        return Patch26GateToCutletProjectionResult(
          old,index+1,dayOffset-firstDay+1)
      firstGate=endGate
      firstDay+=span
      index+=1
    }
    throw new IllegalStateException("La partizione non copre il giorno.")
  }
}

final case class Patch26GateToCutletProjectionReport(
  calculationDay:BigInt,targetDay:BigInt,
  gateGaps:Vector[Int],cutletPartition:Vector[Int],dayOffset:Int,
  gateId:Int,gateStartOffset:Int,
  legacyCutletId:Int,legacyDayInCutlet:Int,
  correctedCutletId:Int,correctedDayInCutlet:Int,
  patchApplied:Boolean,phase:String,status:String,trace:Vector[String]
)

final class Patch26GateToCutletProjectionHandler(
  metrics:BaseMetricsShell) extends BasePhaseHandler {
  override val phase="PATCH_26_GATE_TO_CUTLET_PROJECTION"
  override def handle(ctx:BaseMonsterContext):Unit={
    if(ctx.phase!=phase ||
       ctx.status!="LEGACY_GATE_CUTLET_PROJECTION_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_26_GATE_TO_CUTLET_PROJECTION") ||
       ctx.gateProjectionGaps.isEmpty ||
       ctx.gateProjectionPartition.isEmpty ||
       ctx.gateProjectionDayOffset.isEmpty ||
       ctx.gateProjectionSnapshot.isEmpty ||
       ctx.gateProjectionLegacyGateId.isEmpty ||
       ctx.gateProjectionLegacyGateStart.isEmpty ||
       ctx.gateProjectionLegacyCutletId.isEmpty ||
       ctx.gateProjectionLegacyOrdinal.isEmpty ||
       ctx.patch26CutletId.nonEmpty ||
       ctx.patch26DayInCutlet.nonEmpty || ctx.patch26Applied)
      throw new IllegalStateException("PATCH26 richiede DISCOVERY26 integra.")
    val gaps=ctx.gateProjectionGaps.get
    val part=ctx.gateProjectionPartition.get
    val day=ctx.gateProjectionDayOffset.get
    if(ctx.gateProjectionSnapshot.get!=(gaps,part,day))
      throw new IllegalStateException("Input mutati dopo DISCOVERY26.")
    val correct=Patch26GateToCutletProjectionWrapper.gateToCutletPatch(
      gaps,part,day)
    val historical=correct.historical
    if(historical.gateGaps!=gaps ||
       historical.cutletPartition!=part ||
       historical.dayOffset!=day ||
       historical.gateId!=ctx.gateProjectionLegacyGateId.get ||
       historical.gateStartOffset!=ctx.gateProjectionLegacyGateStart.get ||
       historical.legacyCutletId!=ctx.gateProjectionLegacyCutletId.get ||
       historical.legacyDayInCutlet!=ctx.gateProjectionLegacyOrdinal.get)
      throw new IllegalStateException("Cicatrice DISCOVERY26 falsificata.")
    ctx.patch26CutletId=Some(correct.correctedCutletId)
    ctx.patch26DayInCutlet=Some(correct.correctedDayInCutlet)
    ctx.patch26Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch26.gate.cutlet.calls")
    ctx.status="PATCH_26_READY"
  }
}
