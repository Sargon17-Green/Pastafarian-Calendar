// Stadio 4: du kontrolaj sukcesoj, tri intencaj normigaj malsukcesoj.
// La normiga day_count estas nur en la sendependa testa referenco.
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_02_day_tag
import reference/core

fn legacy_from_production_path(day: Int) -> Int {
  let context = bootstrap.new_context(core.foundation_day, day)
  let assert Ok(output) =
    discovery_02_day_tag.dispatch_discovery_02(context, day)
  output.legacy_day_tag
}

pub fn discovery_02_f_minus_2_control_test() {
  legacy_from_production_path(core.foundation_day - 2)
  |> should.equal(core.day_count(core.foundation_day - 2))
}

pub fn discovery_02_f_minus_1_control_test() {
  legacy_from_production_path(core.foundation_day - 1)
  |> should.equal(core.day_count(core.foundation_day - 1))
}

pub fn discovery_02_f_expected_red_test() {
  legacy_from_production_path(core.foundation_day)
  |> should.equal(core.day_count(core.foundation_day))
}

pub fn discovery_02_f_plus_1_expected_red_test() {
  legacy_from_production_path(core.foundation_day + 1)
  |> should.equal(core.day_count(core.foundation_day + 1))
}

pub fn discovery_02_f_plus_2_expected_red_test() {
  legacy_from_production_path(core.foundation_day + 2)
  |> should.equal(core.day_count(core.foundation_day + 2))
}
