import ./[exact_bigint, monster_base]

type
  CalendarDateSpaghettiResult* = object
    yearNumber*: int64
    cutletCanonicalIndex*: int
    dayInCutlet*: BigInt
    monthCanonicalIndex*: int
    dayInMonth*: BigInt

proc bootstrapContextOnly*(calculationDay, targetDay: BigInt): MonsterContext =
  let manager = newMonsterManager()
  let ctx = newMonsterContext(calculationDay, targetDay)
  manager.validator.validateBootstrapContext(ctx)
  manager.metrics.bump(ctx, "bootstrap.context.validated")
  manager.dispatcher.dispatchBootstrap(ctx)
  result = ctx

proc calendarDateSpaghetti*(calculationDay, targetDay: BigInt): CalendarDateSpaghettiResult =
  discard bootstrapContextOnly(calculationDay, targetDay)
  raise newException(MonsterExecutionError, "E_STAGE01_PRODUCTION_NOT_YET_ASSEMBLED")
