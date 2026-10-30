// Stadio 3 / PATCH 01: konservu la malnovan restaĵon por diagnozo.
// La korekto mapigas nulan restaĵon al M; aliaj restaĵoj ne ŝanĝiĝas.
// La normiga SAVE restas en la aparta testa referenco.
import pastafari/bootstrap

pub const old_modulus = 170_141_183_460_469_231_731_687_303_715_884_105_727

pub type Discovery01Output {
  Discovery01Output(
    context: bootstrap.MonsterContext,
    legacy_remainder: Int,
    patched_remainder: Int,
  )
}

pub fn old_remainder(value: Int) -> Int {
  let remainder = value % old_modulus
  case remainder < 0 {
    True -> remainder + old_modulus
    False -> remainder
  }
}

pub fn save_patch(value: Int) -> Int {
  let remainder = old_remainder(value)
  case remainder == 0 {
    True -> old_modulus
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
      Ok(Discovery01Output(
        context: completed,
        legacy_remainder: old_remainder(value),
        patched_remainder: save_patch(value),
      ))
  }
}
