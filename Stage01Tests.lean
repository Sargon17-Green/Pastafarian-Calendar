import PastafariLean.BootstrapFixtures

open PastafariLean.BootstrapFixtures

private def printFixture (f : BooleanFixture) : IO Bool := do
  if f.passed then
    IO.println s!"BESTÅTT: {f.name}"
    return true
  else
    IO.println s!"FEIL: {f.name}"
    return false


def main : IO UInt32 := do
  let mut ok := true
  for f in fixtures do
    let passed ← printFixture f
    if !passed then
      ok := false
  if ok then
    IO.println "STAGE01_PASS"
    return 0
  else
    IO.println "STAGE01_FAIL"
    return 1
