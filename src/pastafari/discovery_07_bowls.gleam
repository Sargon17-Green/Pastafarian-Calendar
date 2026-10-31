// Stadio 11 / DISCOVERY 07: propra ses-bovla faktoriala malkodilo.
// Neniu importa dependeco de la test-referenco aŭ de aliaj branĉoj.
import gleam/list
import pastafari/bootstrap

pub type Discovery07Output {
  Discovery07Output(
    context: bootstrap.MonsterContext,
    drop_value: Int,
    rank1: Int,
    order: List(Int),
  )
}

fn normalized_rank0(drop_value: Int) -> Int {
  let remainder = { drop_value - 1 } % 720
  case remainder < 0 {
    True -> remainder + 720
    False -> remainder
  }
}

fn take_at(index: Int, bowls: List(Int)) -> #(Int, List(Int)) {
  case bowls {
    [] -> panic as "Mankas bovlo por la permuta cifero"
    [first, ..rest] ->
      case index == 0 {
        True -> #(first, rest)
        False -> {
          let #(chosen, remaining) = take_at(index - 1, rest)
          #(chosen, [first, ..remaining])
        }
      }
  }
}

fn decode_digits(
  rank0: Int,
  factors: List(Int),
  remaining: List(Int),
  reverse_order: List(Int),
) -> List(Int) {
  case factors {
    [] -> list.reverse(reverse_order)
    [factor, ..more] -> {
      let position = rank0 / factor
      let #(chosen, rest) = take_at(position, remaining)
      decode_digits(rank0 % factor, more, rest, [chosen, ..reverse_order])
    }
  }
}

pub fn bowl_order_from_drop(drop_value: Int) -> List(Int) {
  decode_digits(
    normalized_rank0(drop_value),
    [120, 24, 6, 2, 1, 1],
    [1, 2, 3, 4, 5, 6],
    [],
  )
}

pub fn dispatch_discovery_07(
  context: bootstrap.MonsterContext,
  drop_value: Int,
) -> Result(Discovery07Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery07Output(
        context: completed,
        drop_value: drop_value,
        rank1: normalized_rank0(drop_value) + 1,
        order: bowl_order_from_drop(drop_value),
      ))
  }
}
