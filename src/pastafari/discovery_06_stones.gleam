// Stadio 10 / DISCOVERY 06: propra ŝtongeneratoro kun 46 ŝtonoj.
// La testa referenco neniam estas importita de produktkodo.
import gleam/list
import pastafari/bootstrap

const stone_modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Stone {
  Stone(wheat: Int, barley: Int, salt: Int, bitter: Int, red: Int)
}

pub type Discovery06Output {
  Discovery06Output(context: bootstrap.MonsterContext, stones: List(Stone))
}

fn normalized_save(value: Int) -> Int {
  let remainder = { value - 1 } % stone_modulus
  case remainder < 0 {
    True -> remainder + stone_modulus + 1
    False -> remainder + 1
  }
}

fn next_stone(previous: Stone, index: Int) -> Stone {
  Stone(
    wheat: normalized_save(
      previous.wheat * previous.wheat + 3 * previous.barley + index,
    ),
    barley: normalized_save(
      previous.barley * previous.barley + 5 * previous.salt + previous.wheat,
    ),
    salt: normalized_save(
      previous.salt * previous.salt + 7 * previous.bitter + previous.barley,
    ),
    bitter: normalized_save(
      previous.bitter * previous.bitter + 11 * previous.red + previous.salt,
    ),
    red: normalized_save(
      previous.red * previous.red + 13 * previous.wheat + previous.bitter,
    ),
  )
}

fn extend_stones(
  index: Int,
  previous: Stone,
  reverse_accumulator: List(Stone),
) -> List(Stone) {
  case index > 46 {
    True -> list.reverse(reverse_accumulator)
    False -> {
      let next = next_stone(previous, index)
      extend_stones(index + 1, next, [next, ..reverse_accumulator])
    }
  }
}

pub fn build_stones() -> List(Stone) {
  let seed = Stone(wheat: 17, barley: 29, salt: 43, bitter: 71, red: 101)
  extend_stones(2, seed, [seed])
}

pub fn dispatch_discovery_06(
  context: bootstrap.MonsterContext,
) -> Result(Discovery06Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(Discovery06Output(context: completed, stones: build_stones()))
  }
}
