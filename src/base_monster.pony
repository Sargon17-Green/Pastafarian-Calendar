use "collections"

class val MonsterSnapshot
  let calculation_day_text: String
  let target_day_text: String
  let phase: String
  let status: String
  let branch_trace_size: USize
  let metric_size: USize
  let log_size: USize
  let diagnostic_size: USize
  let warning_size: USize

  new val create(ctx: MonsterContext box) =>
    calculation_day_text = ctx.calculation_day.string()
    target_day_text = ctx.target_day.string()
    phase = ctx.phase
    status = ctx.status
    branch_trace_size = ctx.branch_trace.size()
    metric_size = ctx.metrics.size()
    log_size = ctx.logs.size()
    diagnostic_size = ctx.diagnostics.size()
    warning_size = ctx.warnings.size()

class MonsterContext
  let calculation_day: BigInt val
  let target_day: BigInt val
  var phase: String = "ENTRY"
  var sub_phase: USize = 0
  var mode: String = "BOOTSTRAP"
  var status: String = "NEW"
  var retry_budget: USize = 0
  var recovery_depth: USize = 0
  let branch_trace: Array[String] ref = Array[String]
  let metrics: Map[String, U64] ref = Map[String, U64]
  let logs: Array[String] ref = Array[String]
  let diagnostics: Array[String] ref = Array[String]
  let warnings: Array[String] ref = Array[String]
  var last_error: String = ""

  new create(calculation_day': BigInt val, target_day': BigInt val) =>
    calculation_day = calculation_day'
    target_day = target_day'

  fun box snapshot(): MonsterSnapshot => MonsterSnapshot(this)

  fun box owns_distinct_internal_arrays(): Bool =>
    (branch_trace isnt logs)
      and (branch_trace isnt diagnostics)
      and (branch_trace isnt warnings)
      and (logs isnt diagnostics)
      and (logs isnt warnings)
      and (diagnostics isnt warnings)

  fun box mutable_storage_is_distinct_from(that: MonsterContext box): Bool =>
    (branch_trace isnt that.branch_trace)
      and (metrics isnt that.metrics)
      and (logs isnt that.logs)
      and (diagnostics isnt that.diagnostics)
      and (warnings isnt that.warnings)

class MetricsManager
  fun ref bump(ctx: MonsterContext, key: String) =>
    let prior = try ctx.metrics(key)? else 0 end
    ctx.metrics(key) = prior + 1

class ValidationManager
  fun require_same(a: BigInt box, b: BigInt box): Bool => a.eqv(b)

  fun require_five(size: USize): Bool => size == 5

  fun require_context_owner_shape(ctx: MonsterContext box): Bool =>
    ctx.owns_distinct_internal_arrays()

  fun require_invocation_isolation(a: MonsterContext box, b: MonsterContext box): Bool =>
    a.mutable_storage_is_distinct_from(b)
      and a.owns_distinct_internal_arrays()
      and b.owns_distinct_internal_arrays()

  fun require_snapshot_copy(ctx: MonsterContext box, snap: MonsterSnapshot): Bool =>
    (snap.calculation_day_text == ctx.calculation_day.string())
      and (snap.target_day_text == ctx.target_day.string())
      and (snap.phase == ctx.phase)
      and (snap.status == ctx.status)
      and (snap.branch_trace_size == ctx.branch_trace.size())
      and (snap.metric_size == ctx.metrics.size())
      and (snap.log_size == ctx.logs.size())
      and (snap.diagnostic_size == ctx.diagnostics.size())
      and (snap.warning_size == ctx.warnings.size())

class ErrorWrapper
  fun wrap(code: String val, detail: String val): String val =>
    recover val
      let out = String(code.size() + detail.size() + 1)
      out.append(code)
      out.push(58)
      out.append(detail)
      out
    end

class MonsterDispatcher
  let validation: ValidationManager = ValidationManager
  let metrics: MetricsManager = MetricsManager

  fun ref enter(ctx: MonsterContext ref) ? =>
    if not validation.require_context_owner_shape(ctx) then error end
    ctx.phase = "BOOTSTRAP"
    ctx.status = "READY"
    ctx.branch_trace.push("BASE_DISPATCH")
    metrics.bump(ctx, "dispatch.enter")

class MonsterManager
  let dispatcher: MonsterDispatcher = MonsterDispatcher

  fun ref prepare(ctx: MonsterContext ref) ? =>
    dispatcher.enter(ctx)?
