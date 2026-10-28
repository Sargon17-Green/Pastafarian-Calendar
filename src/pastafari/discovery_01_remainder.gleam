// Stadio 2 / DISCOVERY 01: intence malnova restaĵo, sen korekta flikaĵo.
// La normiga SAVE troviĝas nur en la sendependa testa referenco.
import pastafari/bootstrap

pub const old_modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery01Output {
  Discovery01Output(context: bootstrap.MonsterContext, legacy_remainder: Int)
}

pub fn old_remainder(value: Int) -> Int {
  let remainder = value % old_modulus
  case remainder < 0 {
    True -> remainder + old_modulus
    False -> remainder
  }
}

pub fn dispatch_discovery_01(
  context: bootstrap.MonsterContext,
  value: Int,
) -> Result(Discovery01Output, bootstrap.BootstrapError) {
  case bootstrap.dispatch_context(context) {
    Error(error) -> Error(error)
    Ok(completed) ->
      Ok(
        Discovery01Output(
          context: completed,
          legacy_remainder: old_remainder(value),
        ),
      )
  }
}
