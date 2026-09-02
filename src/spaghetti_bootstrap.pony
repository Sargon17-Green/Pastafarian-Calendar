primitive SpaghettiBootstrap
  fun prepare(calculation_day: BigInt val, target_day: BigInt val): MonsterContext ref ? =>
    let ctx = MonsterContext(calculation_day, target_day)
    let manager = MonsterManager
    manager.prepare(ctx)?
    ctx
