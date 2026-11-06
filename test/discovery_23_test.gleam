// Stadio 27 / DISCOVERY 23: 12 sam-branĉaj sendependaj fenestrotestoj.
// La ĉefa orakolo uzas rektan Stage25-specimenan faldaĵon, ne Stage26.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_20_gate_gap
import pastafari/discovery_21_gate_batch
import pastafari/discovery_23_gap_windows
import reference/core
import reference/sauce

const span = 922

fn windows(a: Int, b: Int, ids: List(Int), asked: List(#(Int, Int))) {
  discovery_23_gap_windows.dispatch_discovery_23(
    bootstrap.new_context(a, b),
    ids,
    asked,
  )
}

fn independent_total(
  samples: List(discovery_20_gate_gap.GateGapOutput),
  start: Int,
  end: Int,
) -> Int {
  list.take(list.drop(samples, start), end - start)
  |> list.fold(0, fn(sum, sample) { sum + sample.gap })
}

fn check_valid(a: Int, b: Int, ids: List(Int), asked: List(#(Int, Int))) {
  let context = bootstrap.new_context(a, b)
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  let assert Ok(got) =
    discovery_23_gap_windows.dispatch_discovery_23(context, ids, asked)
  list.length(got) |> should.equal(list.length(asked))
  list.each(list.zip(asked, got), fn(pair) {
    let #(asked_window, item) = pair
    let #(start, end) = asked_window
    item.start |> should.equal(start)
    item.end |> should.equal(end)
    item.total |> should.equal(independent_total(samples, start, end))
    let width = end - start
    { item.total >= 42 * width && item.total <= 963 * width }
    |> should.equal(True)
  })
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

pub fn discovery_23_empty_bowls_and_windows_test() {
  windows(11, 21, [], []) |> should.equal(Ok([]))
}

pub fn discovery_23_empty_invalid_context_zero_window_test() {
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_23_gap_windows.dispatch_discovery_23(invalid, [], [#(0, 0)])
  |> should.equal(
    Ok([
      discovery_23_gap_windows.WindowTotal(start: 0, end: 0, total: 0),
    ]),
  )
}

pub fn discovery_23_empty_edges_of_nonempty_list_test() {
  check_valid(11, 21, [1, 2, 3, 4], [#(0, 0), #(4, 4)])
  let assert Ok(got) = windows(11, 21, [1, 2, 3, 4], [#(0, 0), #(4, 4)])
  list.map(got, fn(item) { item.total }) |> should.equal([0, 0])
}

pub fn discovery_23_full_window_matches_stage25_test() {
  check_valid(11, 21, [1, 2, 3, 4, 5, 6], [#(0, 6)])
  check_valid(21, 11, [6, 5, 4, 3, 2, 1], [#(0, 6)])
}

pub fn discovery_23_each_single_sample_test() {
  let ids = [1, 2, 3, 4, 5, 6]
  let asked = [
    #(0, 1),
    #(1, 2),
    #(2, 3),
    #(3, 4),
    #(4, 5),
    #(5, 6),
  ]
  check_valid(11, 21, ids, asked)
}

pub fn discovery_23_disjoint_windows_sum_to_whole_test() {
  let ids = [2, 4, 6, 1]
  let assert Ok(got) = windows(11, 21, ids, [#(0, 2), #(2, 4), #(0, 4)])
  let assert [left, right, whole] = got
  left.total + right.total |> should.equal(whole.total)
  check_valid(11, 21, ids, [#(0, 2), #(2, 4), #(0, 4)])
}

pub fn discovery_23_overlapping_reverse_query_order_test() {
  let ids = [6, 5, 4, 3, 2]
  let asked = [#(3, 5), #(1, 4), #(0, 2)]
  check_valid(11, 21, ids, asked)
  let assert Ok(got) = windows(11, 21, ids, asked)
  list.map(got, fn(item) { #(item.start, item.end) })
  |> should.equal(asked)
}

pub fn discovery_23_duplicate_windows_preserved_test() {
  let ids = [3, 3, 3, 1, 3]
  let asked = [#(1, 4), #(1, 4), #(0, 5), #(1, 4)]
  check_valid(11, 21, ids, asked)
  let assert Ok(got) = windows(11, 21, ids, asked)
  let assert [first, second, _, fourth] = got
  first |> should.equal(second)
  first |> should.equal(fourth)
}

pub fn discovery_23_negative_start_is_error_test() {
  windows(11, 21, [1, 2, 3], [#(-1, 0)])
  |> should.equal(
    Error(discovery_23_gap_windows.InvalidWindow(start: -1, end: 0, size: 3)),
  )
}

pub fn discovery_23_out_of_range_and_reversed_errors_test() {
  let bad_end =
    Error(discovery_23_gap_windows.InvalidWindow(start: 0, end: 4, size: 3))
  windows(11, 21, [1, 2, 3], [#(0, 4), #(2, 1)])
  |> should.equal(bad_end)
  windows(11, 21, [1, 2, 3], [#(2, 1), #(0, 4)])
  |> should.equal(
    Error(discovery_23_gap_windows.InvalidWindow(start: 2, end: 1, size: 3)),
  )
}

pub fn discovery_23_upstream_priority_over_window_test() {
  let bad =
    Error(discovery_23_gap_windows.Upstream(
      discovery_19_interval_value.InvalidBowlId,
    ))
  windows(11, 21, [7], [#(-1, 8)]) |> should.equal(bad)
  windows(11, 21, [0, 1], []) |> should.equal(bad)
  let invalid =
    bootstrap.MonsterContext(..bootstrap.new_context(11, 21), retry_budget: -1)
  discovery_23_gap_windows.dispatch_discovery_23(invalid, [0, 1], [#(-1, 8)])
  |> should.equal(
    Error(
      discovery_23_gap_windows.Upstream(
        discovery_19_interval_value.InvalidContext(bootstrap.InvalidRetryBudget),
      ),
    ),
  )
}

pub fn discovery_23_large_days_context_and_bounded_oracle_test() {
  let huge = core.m * core.m + core.m
  check_valid(huge, -huge, [1, 6, 1], [#(0, 3), #(1, 2), #(3, 3)])
  check_valid(-huge, huge, [6, 2], [#(0, 2), #(0, 0)])

  let stream = sauce.ask_bowl(sauce.sauce(11, 21), 1, core.seal_gate_gap)
  case bounded_rank(stream, 0) {
    Ok(rank) -> {
      let assert Ok(got) = windows(11, 21, [1], [#(0, 1)])
      let assert [first] = got
      first.total |> should.equal(core.gate_gap_min + rank - 1)
    }
    Error(_) -> check_valid(11, 21, [1], [#(0, 1)])
  }
}
