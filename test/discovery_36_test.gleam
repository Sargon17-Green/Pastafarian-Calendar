// Stadio 40: rekta fenestra orakolo; minimuma denominatoro, ne gcd.
import gleam/list
import gleeunit/should
import pastafari/bootstrap
import pastafari/discovery_19_interval_value
import pastafari/discovery_21_gate_batch
import pastafari/discovery_27_sum_bands
import pastafari/discovery_36_directional_coverage

fn band(a: Int, b: Int) {
  discovery_27_sum_bands.SumBand(lower: a, upper: b)
}

fn prefix_sums(gs: List(Int), n: Int) -> List(Int) {
  case gs {
    [] -> []
    [g, ..rest] -> [n + g, ..prefix_sums(rest, n + g)]
  }
}

fn sums(gs: List(Int)) -> List(Int) {
  case gs {
    [] -> []
    [_, ..rest] -> list.append(prefix_sums(gs, 0), sums(rest))
  }
}

fn member(bs: List(discovery_27_sum_bands.SumBand), value: Int) -> Bool {
  list.any(bs, fn(b) { b.lower <= value && value <= b.upper })
}

fn minimum_q(i: Int, n: Int, q: Int) -> Int {
  case i * q % n == 0 {
    True -> q
    False -> minimum_q(i, n, q + 1)
  }
}

fn oracle(i: Int, n: Int) -> #(Int, Int) {
  case n == 0 {
    True -> #(1, 1)
    False -> {
      let q = minimum_q(i, n, 1)
      #(i * q / n, q)
    }
  }
}

fn gaps(context: bootstrap.MonsterContext, ids: List(Int)) -> List(Int) {
  let assert Ok(samples) =
    discovery_21_gate_batch.dispatch_discovery_21(context, ids)
  list.map(samples, fn(s) { s.gap })
}

fn verify(
  ids: List(Int),
  a: List(discovery_27_sum_bands.SumBand),
  b: List(discovery_27_sum_bands.SumBand),
) -> #(#(Int, Int), #(Int, Int)) {
  let context = bootstrap.new_context(11, 21)
  let windows = sums(gaps(context, ids))
  let l = list.length(list.filter(windows, fn(w) { member(a, w) }))
  let r = list.length(list.filter(windows, fn(w) { member(b, w) }))
  let i =
    list.length(list.filter(windows, fn(w) { member(a, w) && member(b, w) }))
  let u =
    list.length(list.filter(windows, fn(w) { member(a, w) || member(b, w) }))
  let x =
    list.length(list.filter(windows, fn(w) { member(a, w) != member(b, w) }))
  let t = list.length(windows)
  let assert Ok(out) =
    discovery_36_directional_coverage.dispatch_discovery_36(context, ids, a, b)
  let p = out.previous
  #(
    p.left_windows,
    p.right_windows,
    p.intersection_windows,
    p.combined_windows,
    p.symmetric_difference_windows,
    p.total_windows,
  )
  |> should.equal(#(l, r, i, u, x, t))
  #(p.jaccard_numerator, p.jaccard_denominator) |> should.equal(oracle(i, u))
  #(p.dice_numerator, p.dice_denominator) |> should.equal(oracle(2 * i, l + r))
  let m = case l <= r {
    True -> l
    False -> r
  }
  let o = case m == 0 && l + r > 0 {
    True -> #(0, 1)
    False -> oracle(i, m)
  }
  #(p.overlap_numerator, p.overlap_denominator) |> should.equal(o)
  let left = #(out.left_coverage_numerator, out.left_coverage_denominator)
  let right = #(out.right_coverage_numerator, out.right_coverage_denominator)
  left |> should.equal(oracle(i, l))
  right |> should.equal(oracle(i, r))
  { left == #(1, 1) } |> should.equal(i == l)
  { right == #(1, 1) } |> should.equal(i == r)
  #(left, right)
}

fn wide(n: Int, v: Int) -> Int {
  case n == 0 {
    True -> v
    False -> wide(n - 1, v * 10)
  }
}

pub fn discovery_36_empty_test() {
  verify([], [], []) |> should.equal(#(#(1, 1), #(1, 1)))
}

pub fn discovery_36_empty_with_bands_test() {
  verify([], [band(1, 3), band(9, 8)], [band(-9, -1)])
  |> should.equal(#(#(1, 1), #(1, 1)))
}

pub fn discovery_36_closed_endpoints_test() {
  let assert [g] = gaps(bootstrap.new_context(11, 21), [2])
  verify([2], [band(g, g)], [band(g, g)]) |> should.equal(#(#(1, 1), #(1, 1)))
}

pub fn discovery_36_vacuous_direction_test() {
  let all = [band(0, 1000)]
  verify([2], all, []) |> should.equal(#(#(0, 1), #(1, 1)))
  verify([2], [], all) |> should.equal(#(#(1, 1), #(0, 1)))
  verify([2], [], []) |> should.equal(#(#(1, 1), #(1, 1)))
}

pub fn discovery_36_two_gaps_test() {
  let assert [g, _] = gaps(bootstrap.new_context(11, 21), [2, 2])
  verify([2, 2], [band(g, g)], [band(g, 2 * g)])
  |> should.equal(#(#(1, 1), #(2, 3)))
}

pub fn discovery_36_asymmetric_nontrivial_test() {
  let assert [g, _, _] = gaps(bootstrap.new_context(11, 21), [2, 2, 2])
  verify([2, 2, 2], [band(g, 2 * g)], [band(2 * g, 3 * g)])
  |> should.equal(#(#(2, 5), #(2, 3)))
}

pub fn discovery_36_strict_subset_test() {
  let assert [g, _, _, _] = gaps(bootstrap.new_context(11, 21), [3, 3, 3, 3])
  let a = [band(2 * g, 2 * g)]
  let b = [band(g, 2 * g)]
  verify([3, 3, 3, 3], a, b) |> should.equal(#(#(1, 1), #(3, 7)))
  verify([3, 3, 3, 3], b, a) |> should.equal(#(#(3, 7), #(1, 1)))
}

pub fn discovery_36_equal_sets_test() {
  let a = [band(0, 5000), band(20, 30), band(0, 5000)]
  let b = [band(0, 2500), band(2501, 5000)]
  verify([4, 2, 5, 1], a, b) |> should.equal(#(#(1, 1), #(1, 1)))
}

pub fn discovery_36_wide_and_inverted_test() {
  let w = wide(70, 1)
  let a = [band(-w, -1), band(0, 100), band(101, 2000), band(3, 2)]
  let b = [band(-w, w), band(w, w)]
  let _ = verify([3, 5, 2, 4], a, b)
  let assert Ok(out) =
    discovery_36_directional_coverage.dispatch_discovery_36(
      bootstrap.new_context(11, 21),
      [3, 5, 2, 4],
      a,
      b,
    )
  out.previous.canonical_left_bands |> should.equal([band(-w, 2000)])
  out.previous.canonical_right_bands |> should.equal([band(-w, w)])
  out.previous.canonical_combined_bands |> should.equal([band(-w, w)])
}

pub fn discovery_36_index_multiplicity_test() {
  let assert [g, _, _, _] = gaps(bootstrap.new_context(11, 21), [4, 4, 4, 4])
  verify([4, 4, 4, 4], [band(g, 2 * g)], [band(2 * g, 3 * g)])
  |> should.equal(#(#(3, 7), #(3, 5)))
}

pub fn discovery_36_error_priority_test() {
  let context = bootstrap.new_context(11, 21)
  discovery_36_directional_coverage.dispatch_discovery_36(context, [7], [], [])
  |> should.equal(Error(discovery_19_interval_value.InvalidBowlId))
  let invalid = bootstrap.MonsterContext(..context, retry_budget: -1)
  discovery_36_directional_coverage.dispatch_discovery_36(invalid, [7], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
  discovery_36_directional_coverage.dispatch_discovery_36(invalid, [], [], [])
  |> should.equal(
    Error(discovery_19_interval_value.InvalidContext(
      bootstrap.InvalidRetryBudget,
    )),
  )
}

pub fn discovery_36_matrix_test() {
  let ids = [6, 2, 6, 3, 5, 1, 4, 4, 2, 6, 1, 5]
  let families = [
    [],
    [band(42, 963)],
    [band(500, 3000)],
    [band(0, 20_000)],
    [band(100, 99), band(800, 900)],
  ]
  list.each(list.range(0, 12), fn(k) {
    let selected = list.take(ids, k)
    list.each(families, fn(a) {
      list.each(families, fn(b) {
        let #(l, r) = verify(selected, a, b)
        verify(selected, b, a) |> should.equal(#(r, l))
      })
    })
  })
}
