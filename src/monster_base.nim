import std/[tables]
import ./exact_bigint

type
  MonsterPhase* = enum
    mpCreated,
    mpValidated,
    mpReady,
    mpFailed

  MonsterStatus* = enum
    msNew,
    msActive,
    msSuccess,
    msFailure

  MonsterContext* = ref object
    calculationDay*: BigInt
    targetDay*: BigInt
    phase*: MonsterPhase
    status*: MonsterStatus
    semanticRevision*: int
    metrics*: Table[string, int]
    logs*: seq[string]
    diagnostics*: seq[string]
    lastErrorCode*: string

  MonsterValidationError* = object of CatchableError
  MonsterExecutionError* = object of CatchableError

  BaseValidationManager* = ref object
  BaseMetricsManager* = ref object
  BaseDispatcher* = ref object
  BaseErrorWrapper* = ref object
  MonsterManager* = ref object
    validator*: BaseValidationManager
    metrics*: BaseMetricsManager
    dispatcher*: BaseDispatcher
    errors*: BaseErrorWrapper

proc newMonsterContext*(calculationDay, targetDay: BigInt): MonsterContext =
  MonsterContext(
    calculationDay: calculationDay,
    targetDay: targetDay,
    phase: mpCreated,
    status: msNew,
    semanticRevision: 0,
    metrics: initTable[string, int](),
    logs: @[],
    diagnostics: @[],
    lastErrorCode: ""
  )

proc newMonsterManager*(): MonsterManager =
  MonsterManager(
    validator: BaseValidationManager(),
    metrics: BaseMetricsManager(),
    dispatcher: BaseDispatcher(),
    errors: BaseErrorWrapper()
  )

proc bump*(manager: BaseMetricsManager, ctx: MonsterContext, key: string) =
  let current = ctx.metrics.getOrDefault(key, 0)
  ctx.metrics[key] = current + 1

proc validateBootstrapContext*(manager: BaseValidationManager, ctx: MonsterContext) =
  if ctx.isNil:
    raise newException(MonsterValidationError, "E_CONTEXT_NIL")
  if ctx.phase != mpCreated:
    raise newException(MonsterValidationError, "E_CONTEXT_PHASE")
  if ctx.status != msNew:
    raise newException(MonsterValidationError, "E_CONTEXT_STATUS")

proc dispatchBootstrap*(dispatcher: BaseDispatcher, ctx: MonsterContext) =
  if ctx.isNil:
    raise newException(MonsterExecutionError, "E_DISPATCH_CONTEXT_NIL")
  ctx.phase = mpReady
  ctx.status = msActive

proc wrapError*(wrapper: BaseErrorWrapper, code: string): MonsterExecutionError =
  newException(MonsterExecutionError, code)
