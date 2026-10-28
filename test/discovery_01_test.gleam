// EXPECTED_RED: nur tri malsukcesoj, ĉiuj ĉe pozitivaj obloj de M.
// La bazaj testoj de Stadio 1 kaj M+1 devas plu pasi.
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_01_remainder
import reference/core

fn legacy_from_production_path(value: Int) -> Int {
  let context = bootstrap.new_context(core.foundation_day, core.foundation_day)
  let assert Ok(output) =
    discovery_01_remainder.dispatch_discovery_01(context, value)
  output.legacy_remainder
}

pub fn discovery_01_m_expected_red_test() {
  legacy_from_production_path(core.m) |> should.equal(core.save(core.m))
}

pub fn discovery_01_2m_expected_red_test() {
  legacy_from_production_path(2 * core.m)
  |> should.equal(core.save(2 * core.m))
}

pub fn discovery_01_3m_expected_red_test() {
  legacy_from_production_path(3 * core.m)
  |> should.equal(core.save(3 * core.m))
}

pub fn discovery_01_m_plus_1_pass_test() {
  legacy_from_production_path(core.m + 1)
  |> should.equal(core.save(core.m + 1))
}
