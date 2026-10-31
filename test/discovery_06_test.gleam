// Stadio 10 / DISCOVERY 06: la orakolo estas nur en la testa spaco.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_06_stones
import reference/core

fn built() -> List(discovery_06_stones.Stone) {
  let assert Ok(output) =
    discovery_06_stones.dispatch_discovery_06(bootstrap.new_context(11, 21))
  output.stones
}

fn observed_fields() -> List(List(Int)) {
  list.map(built(), fn(stone) {
    [stone.wheat, stone.barley, stone.salt, stone.bitter, stone.red]
  })
}

fn reference_fields() -> List(List(Int)) {
  list.map(core.build_stones(), fn(stone) {
    [stone.wheat, stone.barley, stone.salt, stone.bitter, stone.red]
  })
}

pub fn discovery_06_count_test() {
  list.length(built()) |> should.equal(46)
}

pub fn discovery_06_seed_test() {
  let assert [first, ..] = built()
  first.wheat |> should.equal(17)
  first.barley |> should.equal(29)
  first.salt |> should.equal(43)
  first.bitter |> should.equal(71)
  first.red |> should.equal(101)
}

pub fn discovery_06_second_test() {
  let assert [_, second, ..] = built()
  second.wheat |> should.equal(378)
  second.barley |> should.equal(1073)
  second.salt |> should.equal(2375)
  second.bitter |> should.equal(6195)
  second.red |> should.equal(10_493)
}

pub fn discovery_06_third_test() {
  let assert [_, _, third, ..] = built()
  third.wheat |> should.equal(146_106)
  third.barley |> should.equal(1_163_582)
  third.salt |> should.equal(5_685_063)
  third.bitter |> should.equal(38_495_823)
  third.red |> should.equal(110_114_158)
}

pub fn discovery_06_final_stone_test() {
  let assert [last, ..] = list.reverse(built())
  last.wheat |> should.equal(73_799_454_308_499_791_987_382_386_781_055_001_470)
  last.barley
  |> should.equal(147_925_408_106_533_232_424_672_641_008_220_632_365)
  last.salt |> should.equal(94_499_522_601_819_303_005_579_577_099_149_028_685)
  last.bitter
  |> should.equal(108_473_647_672_201_258_090_947_028_490_673_028_834)
  last.red |> should.equal(137_131_922_036_975_206_684_616_468_948_804_344_042)
}

pub fn discovery_06_full_independent_oracle_test() {
  observed_fields() |> should.equal(reference_fields())
}

pub fn discovery_06_modulus_invariant_test() {
  let valid =
    list.all(observed_fields(), fn(fields) {
      list.all(fields, fn(value) { value >= 1 && value <= core.m })
    })
  valid |> should.equal(True)
}

pub fn discovery_06_repeatability_test() {
  built() |> should.equal(built())
}

pub fn discovery_06_isolated_contexts_test() {
  let first = bootstrap.new_context(-11, 23)
  let first = bootstrap.MonsterContext(..first, diagnostics: ["UNUA"])
  let second = bootstrap.new_context(400, -900)
  let second = bootstrap.MonsterContext(..second, diagnostics: ["DUA"])
  let assert Ok(a) = discovery_06_stones.dispatch_discovery_06(first)
  let assert Ok(b) = discovery_06_stones.dispatch_discovery_06(second)
  a.stones |> should.equal(b.stones)
  a.context.calculation_day |> should.equal(-11)
  b.context.target_day |> should.equal(-900)
  a.context.diagnostics |> should.equal(["UNUA"])
  b.context.diagnostics |> should.equal(["DUA"])
  a.context.status |> should.equal(bootstrap.Complete)
  b.context.status |> should.equal(bootstrap.Complete)
}

pub fn discovery_06_invalid_retry_budget_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_06_stones.dispatch_discovery_06(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}

pub fn discovery_06_invalid_recovery_depth_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_06_stones.dispatch_discovery_06(invalid)
  |> should.equal(Error(bootstrap.InvalidRecoveryDepth))
}

pub fn discovery_06_invalid_both_priority_test() {
  let base = bootstrap.new_context(0, 0)
  let invalid =
    bootstrap.MonsterContext(..base, retry_budget: -1, recovery_depth: -1)
  discovery_06_stones.dispatch_discovery_06(invalid)
  |> should.equal(Error(bootstrap.InvalidRetryBudget))
}
