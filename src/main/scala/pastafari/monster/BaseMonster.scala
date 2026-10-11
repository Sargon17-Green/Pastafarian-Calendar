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
  var legacyPriorOutput: Option[BigInt] = None
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
    new Discovery05PriorHandler(metrics)
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

  def metricsSnapshot: Map[String, BigInt] = metrics.snapshot
}
