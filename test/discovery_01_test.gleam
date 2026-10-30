// Stadio 3: la malkongruoj de DISCOVERY 01 restas observeblaj per la
// diagnoza legacy_remainder; PATCH 01 estas kontrolata aparte.
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

pub fn discovery_01_m_legacy_witness_test() {
  legacy_from_production_path(core.m) |> should.equal(0)
  core.save(core.m) |> should.equal(core.m)
}

pub fn discovery_01_2m_legacy_witness_test() {
  legacy_from_production_path(2 * core.m) |> should.equal(0)
  core.save(2 * core.m) |> should.equal(core.m)
}

pub fn discovery_01_3m_legacy_witness_test() {
  legacy_from_production_path(3 * core.m) |> should.equal(0)
  core.save(3 * core.m) |> should.equal(core.m)
}

pub fn discovery_01_m_plus_1_legacy_control_test() {
  legacy_from_production_path(core.m + 1)
  |> should.equal(core.save(core.m + 1))
}
