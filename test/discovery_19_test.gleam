// Stadio 23 / DISCOVERY 19: 12 novaj, apartaj testfunkcioj.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_18_choose_rank
import pastafari/discovery_19_interval_value
import reference/core
import reference/sauce

const modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

fn actual(a: Int, b: Int, id: Int, seal: Int, low: Int, high: Int) {
  discovery_19_interval_value.value_for_days(a, b, id, seal, low, high)
}

fn select(first: Int, step: Int, low: Int, high: Int) {
  discovery_19_interval_value.select_interval(first, step, low, high)
}

fn cover(n: Int, k: Int, space: Int) -> #(Int, Int) {
  case space >= n {
    True -> #(k, space)
    False -> cover(n, k + 1, space * modulus)
  }
}

fn wide_digits(
  stream: core.AnswerStream,
  j: Int,
  k: Int,
  weight: Int,
  acc: Int,
) -> Int {
  case j >= k {
    True -> acc
    False ->
      wide_digits(
        stream,
        j + 1,
        k,
        weight * modulus,
        acc + { sauce.answer_at(stream, j) - 1 } * weight,
      )
  }
}

fn check_oracle(a: Int, b: Int, id: Int, seal: Int, low: Int, high: Int) {
  let n = high - low + 1
  let stream = sauce.ask_bowl(sauce.sauce(a, b), id, seal)
  let #(space, first_candidate) = case n <= modulus {
    True -> #(modulus, sauce.answer_at(stream, 0))
    False -> {
      let #(k, space) = cover(n, 2, modulus * modulus)
      #(space, wide_digits(stream, 0, k, 1, 1))
    }
  }
  let limit = { space / n } * n
  let rejected = case first_candidate <= limit, stream.direction_step {
    True, _ -> 0
    False, 1 -> space - first_candidate + 1
    False, -1 -> first_candidate - limit
    False, _ -> panic as "Malvalida kanona fluo"
  }
  let assert Ok(value) = actual(a, b, id, seal, low, high)
  { value >= low && value <= high } |> should.equal(True)
  case rejected <= 8 {
    True ->
      value |> should.equal(low + sauce.choose_rank(stream, n) - 1)
    False -> {
      let assert Ok(rank) =
        discovery_18_choose_rank.choose_rank_for_days(a, b, id, seal, n)
      value |> should.equal(low + rank - 1)
    }
  }
}

fn check_pure(first: Int, step: Int, low: Int, high: Int) {
  let assert Ok(value) = select(first, step, low, high)
  let n = high - low + 1
  let assert Ok(rank_selection) =
    discovery_18_choose_rank.select_rank(first, step, n)
  value.selection |> should.equal(rank_selection)
  value.n |> should.equal(n)
  value.lower |> should.equal(low)
  value.upper |> should.equal(high)
  value.value |> should.equal(low + value.rank - 1)
  { value.value >= low && value.value <= high } |> should.equal(True)
}

pub fn discovery_19_gate_gap_short_oracle_test() {
  check_oracle(11, 21, 1, 1, core.gate_gap_min, core.gate_gap_max)
  check_pure(1, 1, core.gate_gap_min, core.gate_gap_max)
}

pub fn discovery_19_year_and_month_examples_test() {
  check_oracle(11, 21, 2, 1, core.year_min_days, core.year_max_days)
  check_oracle(11, 21, 3, 1, core.min_month_days, core.max_month_days)
  check_pure(modulus, -1, core.year_min_days, core.year_max_days)
}

pub fn discovery_19_singleton_zero_and_negative_test() {
  list.each([0, -1, -963, 100_000], fn(bound) {
    check_pure(modulus, -1, bound, bound)
    let assert Ok(choice) = select(modulus, -1, bound, bound)
    choice.value |> should.equal(bound)
    choice.rank |> should.equal(1)
  })
}

pub fn discovery_19_short_wide_transition_test() {
  let assert Ok(short) = select(1, 1, 0, modulus - 1)
  let assert Ok(wide) = select(1, -1, 0, modulus)
  let assert Ok(negative) = select(modulus, 1, -modulus, 0)
  case short.selection {
    discovery_18_choose_rank.ShortRank(_) -> True |> should.equal(True)
    _ -> False |> should.equal(True)
  }
  case wide.selection, negative.selection {
    discovery_18_choose_rank.WideRank(_), discovery_18_choose_rank.WideRank(_) ->
      True |> should.equal(True)
    _, _ -> False |> should.equal(True)
  }
  check_pure(1, -1, 0, modulus)
  check_pure(modulus, 1, -modulus, 0)
}

pub fn discovery_19_synthetic_directions_test() {
  let cases = [
    #(1, 1),
    #(1, -1),
    #(modulus - 1, 1),
    #(modulus - 1, -1),
    #(modulus, 1),
    #(modulus, -1),
  ]
  list.each(cases, fn(pair) {
    let #(first, step) = pair
    list.each([#(-7, 7), #(0, 0), #(42, 963)], fn(bounds) {
      let #(low, high) = bounds
      check_pure(first, step, low, high)
    })
  })
}

pub fn discovery_19_very_large_signed_bounds_test() {
  let huge = modulus * modulus
  let pairs = [
    #(-huge, huge),
    #(huge + 50, huge + 923),
    #(-huge - modulus, -huge + modulus),
  ]
  list.each(pairs, fn(bounds) {
    let #(low, high) = bounds
    check_pure(1, 1, low, high)
    check_pure(modulus, -1, low, high)
  })
}

pub fn discovery_19_six_bowls_oracle_test() {
  list.each([1, 2, 3, 4, 5, 6], fn(id) {
    check_oracle(11, 21, id, 1, 42, 963)
  })
}

pub fn discovery_19_seal_and_previous_preserved_test() {
  let huge = 1_000_000_000_000_000_000_000_000_000_000
  list.each([0, 1, -1, huge, -huge], fn(seal) {
    check_oracle(11, 21, 3, seal, 42, 963)
    let assert Ok(output) =
      discovery_19_interval_value.dispatch_discovery_19(
        bootstrap.new_context(11, 21),
        3,
        seal,
        42,
        963,
      )
    output.previous.previous.previous.seal |> should.equal(seal)
  })
}

pub fn discovery_19_foundation_and_reverse_days_test() {
  let f = core.foundation_day
  let pairs = [#(f - 1, f), #(f, f), #(f, f + 1), #(f + 1, f - 1)]
  list.each(pairs, fn(pair) {
    let #(a, b) = pair
    check_oracle(a, b, 2, 11, -7, 7)
  })
  let huge = modulus * modulus
  actual(huge, -huge, 4, huge, -huge, huge)
  |> should.equal(actual(huge, -huge, 4, huge, -huge, huge))
}

pub fn discovery_19_exact_stage22_preservation_test() {
  let base = bootstrap.new_context(-11, 23)
  let a = bootstrap.MonsterContext(..base, diagnostics: ["KONTROLO"])
  let n = modulus + 1
  let assert Ok(got) =
    discovery_19_interval_value.dispatch_discovery_19(a, 6, -7, -modulus, 0)
  let assert Ok(expected) =
    discovery_18_choose_rank.dispatch_discovery_18(a, 6, -7, n)
  got.previous |> should.equal(expected)
  got.value |> should.equal(-modulus + expected.rank - 1)
  got.previous.previous.previous.previous.context.diagnostics
  |> should.equal(["KONTROLO"])
}

pub fn discovery_19_long_rejection_without_oracle_test() {
  let short_n = { modulus / 2 } + 1
  let wide_n = { modulus * modulus / 2 } + 1
  check_pure(modulus, 1, 3, short_n + 2)
  check_pure(modulus, -1, -short_n, 0)
  check_pure(modulus - 1, 1, 3, wide_n + 2)
  check_pure(1, -1, -wide_n, 0)
}

pub fn discovery_19_invalid_interval_stream_and_priority_test() {
  select(0, 0, 7, 6)
  |> should.equal(Error(discovery_19_interval_value.InvalidInterval))
  select(0, 0, -8, 8)
  |> should.equal(Error(discovery_19_interval_value.InvalidStream))
  list.each([0, 7, -1], fn(id) {
    actual(11, 21, id, 0, 7, 6)
    |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  })
  actual(11, 21, 1, 0, 7, 6)
  |> should.equal(Error(discovery_19_interval_value.InvalidInterval))
  let base = bootstrap.new_context(0, 0)
  let bad_retry = bootstrap.MonsterContext(..base, retry_budget: -1)
  discovery_19_interval_value.dispatch_discovery_19(bad_retry, 0, 0, 7, 6)
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(bootstrap.InvalidRetryBudget)),
  )
  let bad_recovery = bootstrap.MonsterContext(..base, recovery_depth: -1)
  discovery_19_interval_value.dispatch_discovery_19(bad_recovery, 7, 0, 7, 6)
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(bootstrap.InvalidRecoveryDepth)),
  )
}
