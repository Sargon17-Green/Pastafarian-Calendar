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
  var legacyDayTagOutput: Option[BigInt] = None
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
    new Discovery02DayTagHandler(metrics)
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

  def metricsSnapshot: Map[String, BigInt] = metrics.snapshot
}
