import gleam/list
import reference/core.{type AnswerStream, type Grind, type SauceResult, type Stone, type WorkCounts}

fn hidden_coefficients() -> List(#(Int, Int, Int, Int)) {
  [
    #(3, 4, 6, 8),
    #(5, 7, 10, 12),
    #(7, 10, 14, 16),
    #(9, 13, 18, 20),
    #(11, 16, 22, 24),
    #(13, 19, 26, 28),
    #(15, 22, 30, 32),
  ]
}

fn hidden_grind_stone() -> List(Int) {
  [1, 2, 3, 4, 5, 1, 2]
}

fn visible_grinds() -> List(Grind) {
  [
    core.Grind(a: 3, b: 5, c: 7, d: 11, kind: 1),
    core.Grind(a: 5, b: 7, c: 11, d: 13, kind: 2),
    core.Grind(a: 7, b: 11, c: 13, d: 17, kind: 3),
    core.Grind(a: 11, b: 13, c: 17, d: 19, kind: 4),
    core.Grind(a: 13, b: 17, c: 19, d: 23, kind: 5),
    core.Grind(a: 17, b: 19, c: 23, d: 29, kind: 1),
    core.Grind(a: 19, b: 23, c: 29, d: 31, kind: 2),
    core.Grind(a: 23, b: 29, c: 31, d: 37, kind: 3),
    core.Grind(a: 29, b: 31, c: 37, d: 41, kind: 4),
    core.Grind(a: 31, b: 37, c: 41, d: 43, kind: 5),
    core.Grind(a: 37, b: 41, c: 43, d: 47, kind: 1),
  ]
}

pub fn build_hidden_drops(counts: WorkCounts, stones: List(Stone)) -> List(Int) {
  build_hidden_loop(1, counts, stones, []) |> list.reverse
}

fn build_hidden_loop(k: Int, counts: WorkCounts, stones: List(Stone), acc: List(Int)) -> List(Int) {
  case k > 7 {
    True -> {
    acc
  }
    False -> {
    let coeff = core.at1(hidden_coefficients(), k)
    let #(a, b, c, d) = coeff
    let stone = core.at1(stones, k)
    let x0 = core.save(
      counts.action
      + a * counts.target
      + b * counts.distance
      + c * counts.connection
      + d * counts.direction
      + stone.wheat
      + stone.barley
      + stone.salt
      + stone.bitter
      + stone.red,
    )
    let x = hidden_grind_loop(1, x0, stone)
    build_hidden_loop(k + 1, counts, stones, [x, ..acc])
  }
  }
}

fn hidden_grind_loop(grind: Int, x: Int, stone: Stone) -> Int {
  case grind > 7 {
    True -> {
    x
  }
    False -> {
    let kind = core.at1(hidden_grind_stone(), grind)
    let next = core.save(core.square(x) + 3 * x + core.stone_value(stone, kind) + grind)
    hidden_grind_loop(grind + 1, next, stone)
  }
  }
}

fn prior(visible_so_far: List(Int), hidden: List(Int), i: Int, back: Int) -> Int {
  let slot = i - back
  case slot >= 1 {
    True -> {
    core.at1(visible_so_far, slot)
  }
    False -> {
    core.at1(hidden, 1 - slot)
  }
  }
}

pub fn build_visible_drops(counts: WorkCounts, stones: List(Stone), hidden: List(Int)) -> List(Int) {
  build_visible_loop(1, counts, stones, hidden, [])
}

fn build_visible_loop(i: Int, counts: WorkCounts, stones: List(Stone), hidden: List(Int), visible: List(Int)) -> List(Int) {
  case i > 46 {
    True -> {
    visible
  }
    False -> {
    let p1 = prior(visible, hidden, i, 1)
    let p3 = prior(visible, hidden, i, 3)
    let p7 = prior(visible, hidden, i, 7)
    let stone = core.at1(stones, i)
    let x0 = core.save(
      stone.wheat * counts.action
      + stone.barley * counts.target
      + stone.salt * counts.distance
      + stone.bitter * counts.connection
      + stone.red * counts.direction
      + p1
      + 3 * p3
      + 5 * p7
      + i,
    )
    let x = visible_grind_loop(visible_grinds(), x0, p1, p3, p7, stone)
    build_visible_loop(i + 1, counts, stones, hidden, list.append(visible, [x]))
  }
  }
}

fn visible_grind_loop(grinds: List(Grind), x: Int, p1: Int, p3: Int, p7: Int, stone: Stone) -> Int {
  case grinds {
    [] -> x
    [grind, ..rest] -> {
      let next = core.save(
        core.square(x)
        + grind.a * x
        + grind.b * p1
        + grind.c * p3
        + grind.d * p7
        + core.stone_value(stone, grind.kind),
      )
      visible_grind_loop(rest, next, p1, p3, p7, stone)
    }
  }
}

pub fn initial_bowls(counts: WorkCounts) -> List(Int) {
  let primes = [17, 19, 23, 29, 31, 37]
  initial_bowls_loop(1, counts, primes, []) |> list.reverse
}

fn initial_bowls_loop(bowl_id: Int, counts: WorkCounts, primes: List(Int), acc: List(Int)) -> List(Int) {
  case bowl_id > 6 {
    True -> {
    acc
  }
    False -> {
    let prime = core.at1(primes, bowl_id)
    let s = counts.action
      + counts.target * bowl_id
      + counts.distance
      + counts.connection
      + counts.direction
      + core.square(prime)
    let value = core.save(core.square(s) + bowl_id)
    initial_bowls_loop(bowl_id + 1, counts, primes, [value, ..acc])
  }
  }
}

pub fn apply_visible_drops_to_bowls(bowls: List(Int), visible: List(Int), stones: List(Stone)) -> #(List(Int), List(Int)) {
  apply_drop_loop(1, bowls, visible, stones, [])
}

fn apply_drop_loop(i: Int, bowls: List(Int), visible: List(Int), stones: List(Stone), order_at_46: List(Int)) -> #(List(Int), List(Int)) {
  case i > 46 {
    True -> {
    #(bowls, order_at_46)
  }
    False -> {
    let drop = core.at1(visible, i)
    let order = core.bowl_order_from_drop(drop)
    let stone = core.at1(stones, i)
    let pours = build_pours(drop, i, stone, bowls, order)
    let next_bowls = stir_drop_positions(1, bowls, order, pours, stone, drop, i, []) |> list.reverse
    let latch = case i == 46 {
      True -> { order }
      False -> { order_at_46 }
    }
    apply_drop_loop(i + 1, next_bowls, visible, stones, latch)
  }
  }
}

fn build_pours(drop: Int, i: Int, stone: Stone, bowls: List(Int), order: List(Int)) -> List(Int) {
  let first_id = core.at1(order, 1)
  let second_id = core.at1(order, 2)
  let third_id = core.at1(order, 3)
  [
    core.save(core.square(drop) + stone.wheat * core.at1(bowls, first_id) + 3 * i),
    core.save(core.square(drop) + stone.barley * core.at1(bowls, second_id) + 5 * i),
    core.save(core.square(drop) + stone.salt * core.at1(bowls, third_id) + 7 * i),
    0,
    0,
    0,
  ]
}

fn stir_drop_positions(position: Int, old: List(Int), order: List(Int), pours: List(Int), stone: Stone, drop: Int, i: Int, acc_by_id: List(Int)) -> List(Int) {
  case position > 6 {
    True -> {
    acc_by_id
  }
    False -> {
    let bowl_id = position
    let order_position = core.position_of(order, bowl_id)
    let prev_id = core.at1(order, core.wrap1(order_position - 1, 6))
    let next_id = core.at1(order, core.wrap1(order_position + 1, 6))
    let stone_kinds = [1, 2, 3, 4, 5, 1]
    let stone_kind = core.at1(stone_kinds, order_position)
    let s = core.at1(old, bowl_id)
      + 2 * core.at1(old, prev_id)
      + 3 * core.at1(old, next_id)
      + core.at1(pours, order_position)
      + drop
      + core.stone_value(stone, stone_kind)
    let value = core.save(
      core.square(s)
      + 5 * core.at1(old, prev_id) * core.at1(old, next_id)
      + i * order_position,
    )
    stir_drop_positions(position + 1, old, order, pours, stone, drop, i, [value, ..acc_by_id])
  }
  }
}

pub fn post_stir_12(bowls: List(Int)) -> List(Int) {
  post_stir_loop(1, bowls)
}

fn post_stir_loop(stir: Int, bowls: List(Int)) -> List(Int) {
  case stir > 12 {
    True -> {
    bowls
  }
    False -> {
    let saved_bowl_sum = core.save(sum_list(bowls) + 149 * stir)
    let order_number = core.regular_mod(saved_bowl_sum - 1, 720) + 1
    let order = core.bowl_order_from_number(order_number)
    let next = post_stir_bowls_by_id(1, bowls, order, saved_bowl_sum, stir, []) |> list.reverse
    post_stir_loop(stir + 1, next)
  }
  }
}

fn post_stir_bowls_by_id(bowl_id: Int, old: List(Int), order: List(Int), saved_bowl_sum: Int, stir: Int, acc: List(Int)) -> List(Int) {
  case bowl_id > 6 {
    True -> {
    acc
  }
    False -> {
    let position = core.position_of(order, bowl_id)
    let prev_id = core.at1(order, core.wrap1(position - 1, 6))
    let next_id = core.at1(order, core.wrap1(position + 1, 6))
    let s = core.at1(old, bowl_id)
      + 3 * core.at1(old, prev_id)
      + 5 * core.at1(old, next_id)
      + saved_bowl_sum
      + stir
      + position * position
    let value = core.save(core.square(s) + 7 * core.at1(old, prev_id) * core.at1(old, next_id))
    post_stir_bowls_by_id(bowl_id + 1, old, order, saved_bowl_sum, stir, [value, ..acc])
  }
  }
}

fn sum_list(items: List(Int)) -> Int {
  list.fold(items, 0, fn(acc, item) { acc + item })
}

pub fn sauce(calculation_day: Int, target_day: Int) -> SauceResult {
  let counts = core.work_counts(calculation_day, target_day)
  let stones = core.build_stones()
  let hidden = build_hidden_drops(counts, stones)
  let visible = build_visible_drops(counts, stones, hidden)
  let bowls = initial_bowls(counts)
  let #(after_drops, order_at_drop_46) = apply_visible_drops_to_bowls(bowls, visible, stones)
  let final_bowls = post_stir_12(after_drops)
  core.SauceResult(bowls: final_bowls, order_at_drop_46: order_at_drop_46)
}

pub fn next_bowl_in_drop_46_order(result: SauceResult, queried_bowl_id: Int) -> Int {
  let position = core.position_of(result.order_at_drop_46, queried_bowl_id)
  core.at1(result.order_at_drop_46, core.wrap1(position + 1, 6))
}

pub fn ask_bowl(result: SauceResult, queried_bowl_id: Int, seal: Int) -> AnswerStream {
  let next_id = next_bowl_in_drop_46_order(result, queried_bowl_id)
  let first = core.save(
    core.square(core.at1(result.bowls, queried_bowl_id) + seal + 181)
    + 179 * core.at1(result.bowls, next_id)
    + seal,
  )
  let direction_number = core.save(
    core.square(first + seal + 1 + 193)
    + 193 * first
    + 197 * core.at1(result.bowls, 6),
  )
  let step = case core.regular_mod(direction_number, 2) == 1 {
    True -> { 1 }
    False -> { -1 }
  }
  core.AnswerStream(first: first, direction_step: step)
}

pub fn answer_at(stream: AnswerStream, k: Int) -> Int {
  1 + core.regular_mod(stream.first - 1 + stream.direction_step * k, core.m)
}

pub fn choose_rank_short(stream: AnswerStream, n: Int) -> Int {
  let limit = core.floor_div(core.m, n) * n
  choose_rank_short_loop(stream, n, limit, 0)
}

fn choose_rank_short_loop(stream: AnswerStream, n: Int, limit: Int, k: Int) -> Int {
  let x = answer_at(stream, k)
  case x <= limit {
    True -> {
    core.regular_mod(x - 1, n) + 1
  }
    False -> {
    choose_rank_short_loop(stream, n, limit, k + 1)
  }
  }
}

pub fn smallest_power_count(base: Int, n: Int) -> #(Int, Int) {
  smallest_power_loop(base, n, 1, base)
}

fn smallest_power_loop(base: Int, n: Int, k: Int, space: Int) -> #(Int, Int) {
  case space >= n {
    True -> { #(k, space) }
    False -> { smallest_power_loop(base, n, k + 1, space * base) }
  }
}

pub fn choose_rank_wide(stream: AnswerStream, n: Int) -> Int {
  let #(k, space) = smallest_power_count(core.m, n)
  let wide0 = build_wide(stream, 0, k, 1, 1)
  let limit = core.floor_div(space, n) * n
  choose_wide_loop(stream, n, space, limit, wide0)
}

fn build_wide(stream: AnswerStream, j: Int, k: Int, weight: Int, acc: Int) -> Int {
  case j >= k {
    True -> {
    acc
  }
    False -> {
    let digit = answer_at(stream, j) - 1
    build_wide(stream, j + 1, k, weight * core.m, acc + digit * weight)
  }
  }
}

fn choose_wide_loop(stream: AnswerStream, n: Int, space: Int, limit: Int, wide: Int) -> Int {
  case wide <= limit {
    True -> {
    core.regular_mod(wide - 1, n) + 1
  }
    False -> {
    let next = 1 + core.regular_mod(wide - 1 + stream.direction_step, space)
    choose_wide_loop(stream, n, space, limit, next)
  }
  }
}

pub fn choose_rank(stream: AnswerStream, n: Int) -> Int {
  case n <= core.m {
    True -> { choose_rank_short(stream, n) }
    False -> { choose_rank_wide(stream, n) }
  }
}
