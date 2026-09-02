primitive SpaghettiBootstrap
  fun prepare(calculation_day: BigInt, target_day: BigInt): MonsterContext =>
    let ctx = MonsterContext(calculation_day, target_day)
    let manager = MonsterManager
    manager.prepare(ctx)
    ctx
