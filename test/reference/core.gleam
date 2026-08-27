import gleam/list

pub const m = 170141183460469231731687303715884105727
pub const tablets_day = -278522
pub const foundation_day = -15055671
pub const gate_gap_min = 42
pub const gate_gap_max = 963
pub const year_min_days = 252
pub const year_max_days = 5778
pub const min_gate_gaps_per_year = 6
pub const min_cutlets = 6
pub const max_cutlets = 17
pub const min_months = 3
pub const max_months = 47
pub const min_month_days = 4
pub const max_month_days = 123

pub const seal_gate_gap = 1
pub const seal_year_5000 = 10
pub const seal_next_year = 11
pub const seal_previous_year = 12
pub const seal_cutlet_count = 20
pub const seal_cutlet_partition = 21
pub const seal_cutlet_names = 22
pub const seal_month_count = 30
pub const seal_month_lengths = 31
pub const seal_month_weaving = 32
pub const seal_month_names = 33

pub type WorkCounts {
  WorkCounts(
    action: Int,
    target: Int,
    distance: Int,
    connection: Int,
    direction: Int,
  )
}

pub type Stone {
  Stone(wheat: Int, barley: Int, salt: Int, bitter: Int, red: Int)
}

pub type Grind {
  Grind(a: Int, b: Int, c: Int, d: Int, kind: Int)
}

pub type SauceResult {
  SauceResult(bowls: List(Int), order_at_drop_46: List(Int))
}

pub type AnswerStream {
  AnswerStream(first: Int, direction_step: Int)
}

pub fn abs_int(x: Int) -> Int {
  case x < 0 {
    True -> { -x }
    False -> { x }
  }
}

pub fn regular_mod(x: Int, d: Int) -> Int {
  let r = x % d
  case r < 0 {
    True -> { r + d }
    False -> { r }
  }
}

pub fn floor_div(a: Int, b: Int) -> Int {
  let q = a / b
  let r = a % b
  case r == 0, (r < 0) != (b < 0) {
    True, _ -> q
    False, True -> q - 1
    False, False -> q
  }
}

pub fn ceil_div(a: Int, b: Int) -> Int {
  floor_div(a + b - 1, b)
}

pub fn save(x: Int) -> Int {
  1 + regular_mod(x - 1, m)
}

pub fn square(x: Int) -> Int {
  x * x
}

pub fn wrap1(position: Int, size: Int) -> Int {
  regular_mod(position - 1, size) + 1
}

pub fn at1(items: List(a), index: Int) -> a {
  let assert Ok(value) = list.at(items, index - 1)
  value
}

pub fn replace_at1(items: List(a), index: Int, value: a) -> List(a) {
  replace_at1_loop(items, index, value, 1, [])
  |> list.reverse
}

fn replace_at1_loop(items: List(a), index: Int, value: a, current: Int, acc: List(a)) -> List(a) {
  case items {
    [] -> acc
    [head, ..tail] -> {
      let chosen = case current == index {
        True -> { value }
        False -> { head }
      }
      replace_at1_loop(tail, index, value, current + 1, [chosen, ..acc])
    }
  }
}

pub fn remove_at1(items: List(a), index: Int) -> List(a) {
  remove_at1_loop(items, index, 1, [])
  |> list.reverse
}

fn remove_at1_loop(items: List(a), index: Int, current: Int, acc: List(a)) -> List(a) {
  case items {
    [] -> acc
    [head, ..tail] ->
      case current == index {
        True -> {
        list.reverse(acc) |> list.append(tail)
      }
        False -> {
        remove_at1_loop(tail, index, current + 1, [head, ..acc])
      }
      }
  }
}

pub fn position_of(items: List(Int), wanted: Int) -> Int {
  position_of_loop(items, wanted, 1)
}

fn position_of_loop(items: List(Int), wanted: Int, position: Int) -> Int {
  case items {
    [] -> panic as "Mankas atendita kanona ero"
    [head, ..tail] ->
      case head == wanted {
        True -> { position }
        False -> { position_of_loop(tail, wanted, position + 1) }
      }
  }
}

pub fn range_inclusive(first: Int, last: Int) -> List(Int) {
  case first > last {
    True -> { [] }
    False -> { [first, ..range_inclusive(first + 1, last)] }
  }
}

pub fn min_int(a: Int, b: Int) -> Int {
  case a < b {
    True -> { a }
    False -> { b }
  }
}

pub fn factorial(n: Int) -> Int {
  factorial_loop(n, 1)
}

fn factorial_loop(n: Int, acc: Int) -> Int {
  case n <= 1 {
    True -> { acc }
    False -> { factorial_loop(n - 1, acc * n) }
  }
}

pub fn falling_factorial(n: Int, k: Int) -> Int {
  falling_factorial_loop(n, k, 0, 1)
}

fn falling_factorial_loop(n: Int, k: Int, j: Int, acc: Int) -> Int {
  case j >= k {
    True -> { acc }
    False -> { falling_factorial_loop(n, k, j + 1, acc * (n - j)) }
  }
}

pub fn day_count(day: Int) -> Int {
  case day == foundation_day {
    True -> {
    1
  }
    False -> case day > foundation_day {
    True -> {
    2 * (day - foundation_day) + 1
  }
    False -> {
    2 * (foundation_day - day)
  }
  }
  }
}

pub fn work_counts(calculation_day: Int, target_day: Int) -> WorkCounts {
  let action = day_count(calculation_day)
  let target = day_count(target_day)
  let direction = case target_day < calculation_day {
    True -> { 1 }
    False -> case target_day == calculation_day {
    True -> { 2 }
    False -> { 3 }
  }
  }
  WorkCounts(
    action: action,
    target: target,
    distance: abs_int(target_day - calculation_day) + 1,
    connection: action + target,
    direction: direction,
  )
}

pub fn stone_value(stone: Stone, kind: Int) -> Int {
  case kind {
    1 -> stone.wheat
    2 -> stone.barley
    3 -> stone.salt
    4 -> stone.bitter
    5 -> stone.red
    _ -> panic as "Nevalida ŝtona speco"
  }
}

pub fn build_stones() -> List(Stone) {
  let first = Stone(wheat: 17, barley: 29, salt: 43, bitter: 71, red: 101)
  build_stones_loop(2, first, [first]) |> list.reverse
}

fn build_stones_loop(i: Int, old: Stone, acc: List(Stone)) -> List(Stone) {
  case i > 46 {
    True -> {
    acc
  }
    False -> {
    let next = Stone(
      wheat: save(square(old.wheat) + 3 * old.barley + i),
      barley: save(square(old.barley) + 5 * old.salt + old.wheat),
      salt: save(square(old.salt) + 7 * old.bitter + old.barley),
      bitter: save(square(old.bitter) + 11 * old.red + old.salt),
      red: save(square(old.red) + 13 * old.wheat + old.bitter),
    )
    build_stones_loop(i + 1, next, [next, ..acc])
  }
  }
}

pub fn permutation_unrank1(rank1: Int, items_ascending: List(Int)) -> List(Int) {
  permutation_loop(rank1 - 1, items_ascending, list.length(items_ascending), [])
  |> list.reverse
}

fn permutation_loop(rank0: Int, remaining: List(Int), slots_left: Int, acc: List(Int)) -> List(Int) {
  case slots_left == 0 {
    True -> {
    acc
  }
    False -> {
    let block = factorial(slots_left - 1)
    let q = floor_div(rank0, block)
    let next_rank0 = regular_mod(rank0, block)
    let chosen = at1(remaining, q + 1)
    let next_remaining = remove_at1(remaining, q + 1)
    permutation_loop(next_rank0, next_remaining, slots_left - 1, [chosen, ..acc])
  }
  }
}

pub fn bowl_order_from_number(order_number: Int) -> List(Int) {
  permutation_unrank1(order_number, [1, 2, 3, 4, 5, 6])
}

pub fn bowl_order_from_drop(drop_value: Int) -> List(Int) {
  bowl_order_from_number(regular_mod(drop_value - 1, 720) + 1)
}
