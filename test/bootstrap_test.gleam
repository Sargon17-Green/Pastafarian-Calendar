import gleam/list
import gleeunit
import gleeunit/should
import pastafari/bootstrap
import pastafari/source_language_catalog
import reference/core
import reference/sauce

pub fn main() {
  gleeunit.main()
}

pub fn foundation_distance_fixture_test() {
  core.tablets_day - core.foundation_day
  |> should.equal(14_777_149)
}

pub fn save_fixture_test() {
  core.save(1) |> should.equal(1)
  core.save(core.m - 1) |> should.equal(core.m - 1)
  core.save(core.m) |> should.equal(core.m)
  core.save(core.m + 1) |> should.equal(1)
  core.save(2 * core.m) |> should.equal(core.m)
}

pub fn day_count_fixture_test() {
  core.day_count(core.foundation_day) |> should.equal(1)
  core.day_count(core.foundation_day + 1) |> should.equal(3)
  core.day_count(core.foundation_day - 1) |> should.equal(2)
}

pub fn work_counts_same_day_fixture_test() {
  let counts = core.work_counts(core.foundation_day, core.foundation_day)
  counts.action |> should.equal(1)
  counts.target |> should.equal(1)
  counts.distance |> should.equal(1)
  counts.connection |> should.equal(2)
  counts.direction |> should.equal(2)
}

pub fn permutation_boundary_fixture_test() {
  core.bowl_order_from_number(1) |> should.equal([1, 2, 3, 4, 5, 6])
  core.bowl_order_from_number(720) |> should.equal([6, 5, 4, 3, 2, 1])
}

pub fn source_catalog_fixture_test() {
  source_language_catalog.cutlet_name(12) |> should.equal("tritiko")
  source_language_catalog.month_name(44) |> should.equal("salo")
  source_language_catalog.cutlet_count |> should.equal(17)
  source_language_catalog.month_count |> should.equal(47)
}

pub fn source_catalog_is_index_total_test() {
  core.range_inclusive(1, 17)
  |> list.map(source_language_catalog.cutlet_name)
  |> list.length
  |> should.equal(17)

  core.range_inclusive(1, 47)
  |> list.map(source_language_catalog.month_name)
  |> list.length
  |> should.equal(47)
}

pub fn neutral_monster_bootstrap_test() {
  let context = bootstrap.new_context(core.foundation_day, core.foundation_day)
  bootstrap.dispatch_context(context)
  |> should.be_ok
}

pub fn sauce_is_deterministic_test() {
  let first = sauce.sauce(core.foundation_day, core.foundation_day)
  let second = sauce.sauce(core.foundation_day, core.foundation_day)
  first |> should.equal(second)
  list.length(first.bowls) |> should.equal(6)
  list.length(first.order_at_drop_46) |> should.equal(6)
}
