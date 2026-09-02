use "collections"

class MonsterContext
  let calculation_day: BigInt
  let target_day: BigInt
  var phase: String = "ENTRY"
  var sub_phase: USize = 0
  var mode: String = "BOOTSTRAP"
  var status: String = "NEW"
  var retry_budget: USize = 0
  var recovery_depth: USize = 0
  let branch_trace: Array[String] = Array[String]
  let metrics: Map[String, U64] = Map[String, U64]
  let logs: Array[String] = Array[String]
  let diagnostics: Array[String] = Array[String]
  let warnings: Array[String] = Array[String]
  var last_error: String = ""

  new create(calculation_day': BigInt, target_day': BigInt) =>
    calculation_day = calculation_day'
    target_day = target_day'

class MetricsManager
  fun ref bump(ctx: MonsterContext, key: String) =>
    let prior = try ctx.metrics(key)? else 0 end
    ctx.metrics(key) = prior + 1

class ValidationManager
  fun require_same(a: BigInt box, b: BigInt box): Bool => a.eqv(b)

  fun require_five(size: USize): Bool => size == 5

class ErrorWrapper
  fun wrap(code: String, detail: String): String =>
    let out = String(code.size() + detail.size() + 1)
    out.append(code)
    out.push(58)
    out.append(detail)
    out

class MonsterDispatcher
  let validation: ValidationManager = ValidationManager
  let metrics: MetricsManager = MetricsManager

  fun ref enter(ctx: MonsterContext) =>
    ctx.phase = "BOOTSTRAP"
    ctx.status = "READY"
    ctx.branch_trace.push("BASE_DISPATCH")
    metrics.bump(ctx, "dispatch.enter")

class MonsterManager
  let dispatcher: MonsterDispatcher = MonsterDispatcher

  fun ref prepare(ctx: MonsterContext) =>
    dispatcher.enter(ctx)
