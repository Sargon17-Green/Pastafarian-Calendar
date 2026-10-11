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
  var legacyRemainderOutput: Option[BigInt] = None
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
    new Discovery01RemainderHandler(metrics)
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

  def metricsSnapshot: Map[String, BigInt] = metrics.snapshot
}
