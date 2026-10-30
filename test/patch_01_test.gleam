// PATCH 01: la vera valida-disenda produktvojo devas redoni SAVE.
// Kovru la tri antaŭajn EXPECTED_RED-kazojn kaj randajn entjerojn.
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_01_remainder
import reference/core

fn patched_from_production_path(value: Int) -> Int {
  let context = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let assert Ok(output) =
    discovery_01_remainder.dispatch_discovery_01(context, value)
  output.patched_remainder
}

pub fn patch_01_m_test() {
  patched_from_production_path(core.m) |> should.equal(core.save(core.m))
}

pub fn patch_01_2m_test() {
  patched_from_production_path(2 * core.m) |> should.equal(core.save(2 * core.m))
}

pub fn patch_01_3m_test() {
  patched_from_production_path(3 * core.m) |> should.equal(core.save(3 * core.m))
}

pub fn patch_01_m_plus_1_test() {
  patched_from_production_path(core.m + 1)
  |> should.equal(core.save(core.m + 1))
}

pub fn patch_01_zero_test() {
  patched_from_production_path(0) |> should.equal(core.save(0))
}

pub fn patch_01_negative_m_test() {
  patched_from_production_path(-core.m) |> should.equal(core.save(-core.m))
}

pub fn patch_01_negative_one_test() {
  patched_from_production_path(-1) |> should.equal(core.save(-1))
}

pub fn patch_01_one_test() {
  patched_from_production_path(1) |> should.equal(core.save(1))
}
