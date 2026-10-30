// PATCH 02: la vera valida-disenda produktvojo devas redoni day_count.
// La historia legacy_day_tag devas resti havebla por diagnozo.
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_02_day_tag
import reference/core

fn patched_from_production_path(day: Int) -> Int {
  let context = bootstrap.new_context(core.foundation_day, day)
  let assert Ok(output) =
    discovery_02_day_tag.dispatch_discovery_02(context, day)
  output.patched_day_tag
}

pub fn patch_02_f_minus_10_000_test() {
  patched_from_production_path(core.foundation_day - 10_000)
  |> should.equal(core.day_count(core.foundation_day - 10_000))
}

pub fn patch_02_f_minus_1000_test() {
  patched_from_production_path(core.foundation_day - 1000)
  |> should.equal(core.day_count(core.foundation_day - 1000))
}

pub fn patch_02_f_minus_2_test() {
  patched_from_production_path(core.foundation_day - 2)
  |> should.equal(core.day_count(core.foundation_day - 2))
}

pub fn patch_02_f_minus_1_test() {
  patched_from_production_path(core.foundation_day - 1)
  |> should.equal(core.day_count(core.foundation_day - 1))
}

pub fn patch_02_f_test() {
  patched_from_production_path(core.foundation_day)
  |> should.equal(core.day_count(core.foundation_day))
}

pub fn patch_02_f_plus_1_test() {
  patched_from_production_path(core.foundation_day + 1)
  |> should.equal(core.day_count(core.foundation_day + 1))
}

pub fn patch_02_f_plus_2_test() {
  patched_from_production_path(core.foundation_day + 2)
  |> should.equal(core.day_count(core.foundation_day + 2))
}

pub fn patch_02_f_plus_1000_test() {
  patched_from_production_path(core.foundation_day + 1000)
  |> should.equal(core.day_count(core.foundation_day + 1000))
}

pub fn patch_02_f_plus_10_000_test() {
  patched_from_production_path(core.foundation_day + 10_000)
  |> should.equal(core.day_count(core.foundation_day + 10_000))
}
