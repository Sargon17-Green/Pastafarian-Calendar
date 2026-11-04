// Stadio 26 / DISCOVERY 22: 12 novaj testoj de prefiksaj sumoj.
// Ĉiu orakolo komparas sendependan list.fold de Stage25-specimenoj.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_22_gap_prefixes
import reference/core
import reference/sauce

const span = 922

fn prefixes(a: Int, b: Int, ids: List(Int)) {
  discovery_22_gap_prefixes.dispatch_discovery_22(
    bootstrap.new_context(a, b),
    ids,
  )
}

fn check_pair(a: Int, b: Int, ids: List(Int)) {
  let context = bootstrap.new_context(a, b)
  let assert Ok(expected) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  let assert Ok(got) =
    discovery_22_gap_prefixes.dispatch_discovery_22(context, ids)
  list.length(got.entries) |> should.equal(list.length(ids))
  list.map(got.entries, fn(entry) { entry.sample })
  |> should.equal(expected)

  let expected_total =
    list.fold(expected, 0, fn(total, sample) { total + sample.gap })
  got.total |> should.equal(expected_total)

  let final_prefix =
    list.fold(got.entries, 0, fn(previous, entry) {
      let next = previous + entry.sample.gap
      entry.prefix_total |> should.equal(next)
      next
    })
  got.total |> should.equal(final_prefix)

  let count = list.length(ids)
  { got.total >= 42 * count && got.total <= 963 * count }
  |> should.equal(True)
}

fn bounded_rank(stream: core.AnswerStream, index: Int) -> Result(Int, Nil) {
  let limit = { core.m / span } * span
  case index > 8 {
    True -> Error(Nil)
    False ->
      case sauce.answer_at(stream, index) <= limit {
        True -> Ok(sauce.choose_rank(stream, span))
        False -> bounded_rank(stream, index + 1)
      }
  }
}

pub fn discovery_22_empty_valid_test() {
  let assert Ok(got) = prefixes(11, 21, [])
  got.entries |> should.equal([])
  got.total |> should.equal(0)
}

pub fn discovery_22_empty_invalid_context_test() {
  let base = bootstrap.new_context(11, 21)
  let invalid = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_22_gap_prefixes.dispatch_discovery_22(invalid, [])
  |> should.equal(
    Ok(discovery_22_gap_prefixes.GapPrefixBatch(entries: [], total: 0)),
  )
}

pub fn discovery_22_six_individual_bowls_test() {
  list.each([1, 2, 3, 4, 5, 6], fn(id) {
    check_pair(11, 21, [id])
    let assert Ok(got) = prefixes(11, 21, [id])
    let assert [single] = got.entries
    single.prefix_total |> should.equal(single.sample.gap)
  })
}

pub fn discovery_22_forward_prefixes_test() {
  let ids = [1, 2, 3, 4, 5, 6]
  check_pair(11, 21, ids)
  let assert Ok(got) = prefixes(11, 21, ids)
  list.map(got.entries, fn(entry) { entry.sample.queried_bowl_id })
  |> should.equal(ids)
}

pub fn discovery_22_reverse_order_same_total_test() {
  check_pair(11, 21, [6, 5, 4, 3, 2, 1])
  let assert Ok(forward) = prefixes(11, 21, [1, 2, 3, 4, 5, 6])
  let assert Ok(reverse) = prefixes(11, 21, [6, 5, 4, 3, 2, 1])
  forward.total |> should.equal(reverse.total)
  list.map(reverse.entries, fn(entry) { entry.sample.queried_bowl_id })
  |> should.equal([6, 5, 4, 3, 2, 1])
}

pub fn discovery_22_duplicates_count_separately_test() {
  let ids = [3, 3, 3, 1, 3]
  check_pair(11, 21, ids)
  let assert Ok(got) = prefixes(11, 21, ids)
  list.map(got.entries, fn(entry) { entry.sample.queried_bowl_id })
  |> should.equal(ids)
  let assert [first, second, third, _, fifth] = got.entries
  first.sample |> should.equal(second.sample)
  first.sample |> should.equal(third.sample)
  first.sample |> should.equal(fifth.sample)
}

pub fn discovery_22_same_reverse_negative_days_test() {
  list.each([#(0, 0), #(21, 11), #(-12, -19), #(-11, 23)], fn(pair) {
    let #(a, b) = pair
    check_pair(a, b, [1, 2, 6])
  })
}

pub fn discovery_22_foundation_bounds_test() {
  let f = core.foundation_day
  list.each([#(f - 1, f), #(f, f), #(f, f + 1), #(f + 1, f)], fn(pair) {
    let #(a, b) = pair
    check_pair(a, b, [2, 4, 5])
  })
}

pub fn discovery_22_unbounded_signed_days_test() {
  let huge = core.m * core.m + core.m
  check_pair(huge, -huge, [1, 6, 1])
  check_pair(-huge, huge, [6, 2])
}

pub fn discovery_22_invalid_ids_test() {
  let bad = Error(discovery_19_interval_value.InvalidBowlId)
  prefixes(11, 21, [0, 1, 2]) |> should.equal(bad)
  prefixes(11, 21, [1, 7, 2]) |> should.equal(bad)
  prefixes(11, 21, [1, 2, -1]) |> should.equal(bad)
}

pub fn discovery_22_invalid_context_priorities_test() {
  let base = bootstrap.new_context(11, 21)
  let retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  let depth = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_22_gap_prefixes.dispatch_discovery_22(retry, [0, 1])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_22_gap_prefixes.dispatch_discovery_22(depth, [7, 6])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRecoveryDepth,
    )),
  )

  let a = bootstrap.MonsterContext(..base, diagnostics: ["A"])
  let b = bootstrap.MonsterContext(..base, diagnostics: ["B"])
  let assert Ok(one) =
    discovery_22_gap_prefixes.dispatch_discovery_22(a, [1])
  let assert Ok(two) =
    discovery_22_gap_prefixes.dispatch_discovery_22(b, [1])
  let assert [first_a] = one.entries
  let assert [first_b] = two.entries
  first_a.sample.previous.previous.previous.previous.context.diagnostics
  |> should.equal(["A"])
  first_b.sample.previous.previous.previous.previous.context.diagnostics
  |> should.equal(["B"])
}

pub fn discovery_22_convenience_and_oracle_test() {
  let ids = [1, 4, 3, 3, 6]
  let assert Ok(got) = prefixes(11, 21, ids)
  discovery_22_gap_prefixes.prefix_total_for_days(11, 21, ids)
  |> should.equal(Ok(got.total))

  let stream = sauce.ask_bowl(sauce.sauce(11, 21), 1, core.seal_gate_gap)
  case bounded_rank(stream, 0) {
    Ok(rank) -> {
      let assert [first, ..] = got.entries
      first.sample.gap |> should.equal(core.gate_gap_min + rank - 1)
      first.prefix_total |> should.equal(first.sample.gap)
    }
    Error(_) -> check_pair(11, 21, ids)
  }
}
