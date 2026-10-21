package pastafari.monster

/** PATCH20: l'inizio della nuova cotoletta le appartiene.
  * L'adapter DISCOVERY20 resta eseguito e pubblicato nel report.
  * Gli intervalli delle porte e la partizione sono input gia' fissati.
  */
final case class Patch20CutletOpenBoundaryResult(
  historical: LegacyCutletOpenBoundaryResult,
  correctedCutletId: Int,
  correctedDayInCutlet: Int
)

object Patch20CutletOpenBoundaryWrapper {
  def cutletBoundaryPatch(
    gateGaps: Vector[Int],
    cutletPartition: Vector[Int],
    dayOffset: Int
  ): Patch20CutletOpenBoundaryResult = {
    val old=LegacyCutletOpenBoundaryAdapter.oldCutletOpenBoundary(
      gateGaps,cutletPartition,dayOffset)
    // Apertura inclusiva del nuovo segmento, chiusura esclusiva.
    val correctedId=old.cutletStartOffsets.count(_<=dayOffset)
    val start=old.cutletStartOffsets(correctedId-1)
    Patch20CutletOpenBoundaryResult(
      old,correctedId,dayOffset-start+1)
  }
}

final case class Patch20CutletOpenBoundaryReport(
  calculationDay: BigInt,
  targetDay: BigInt,
  gateGaps: Vector[Int],
  cutletPartition: Vector[Int],
  dayOffset: Int,
  cutletStartOffsets: Vector[Int],
  legacyCutletId: Int,
  legacyDayInCutlet: Int,
  correctedCutletId: Int,
  correctedDayInCutlet: Int,
  patchApplied: Boolean,
  phase: String,
  status: String,
  trace: Vector[String]
)

final class Patch20CutletOpenBoundaryHandler(metrics: BaseMetricsShell)
    extends BasePhaseHandler {
  override val phase="PATCH_20_CUTLET_OPEN_BOUNDARY"
  override def handle(ctx: BaseMonsterContext): Unit = {
    if(ctx.phase!=phase || ctx.status!="LEGACY_CUTLET_BOUNDARY_READY" ||
       ctx.branchTrace.toVector!=Vector(
         "BOOT","DISCOVERY_20_CUTLET_OPEN_BOUNDARY") ||
       ctx.cutletGateGaps.isEmpty || ctx.cutletGatePartition.isEmpty ||
       ctx.cutletDayOffset.isEmpty || ctx.cutletBoundarySnapshot.isEmpty ||
       ctx.legacyCutletStartOffsets.isEmpty || ctx.legacyCutletId.isEmpty ||
       ctx.legacyDayInCutlet.isEmpty || ctx.patchedCutletId.nonEmpty ||
       ctx.patchedDayInCutlet.nonEmpty || ctx.patch20Applied)
      throw new IllegalStateException(
        "PATCH20 richiede una DISCOVERY20 integra nella stessa richiesta.")
    val gaps=ctx.cutletGateGaps.get
    val parts=ctx.cutletGatePartition.get
    val day=ctx.cutletDayOffset.get
    if(ctx.cutletBoundarySnapshot.get!=(gaps,parts,day))
      throw new IllegalStateException("Input modificato dopo DISCOVERY20.")
    val result=Patch20CutletOpenBoundaryWrapper.cutletBoundaryPatch(
      gaps,parts,day)
    if(result.historical.gateGaps!=gaps ||
       result.historical.cutletPartition!=parts ||
       result.historical.dayOffset!=day ||
       result.historical.cutletStartOffsets!=
         ctx.legacyCutletStartOffsets.get ||
       result.historical.legacyCutletId!=ctx.legacyCutletId.get ||
       result.historical.legacyDayInCutlet!=ctx.legacyDayInCutlet.get)
      throw new IllegalStateException("Cicatrice DISCOVERY20 falsificata.")

    ctx.patchedCutletId=Some(result.correctedCutletId)
    ctx.patchedDayInCutlet=Some(result.correctedDayInCutlet)
    ctx.patch20Applied=true
    ctx.branchTrace.append(phase)
    metrics.bump("patch20.cutlet.boundary.calls")
    ctx.status="PATCH_20_READY"
  }
}
