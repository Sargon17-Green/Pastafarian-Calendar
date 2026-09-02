namespace PastafariLean

inductive BasePhase where
  | entry
  | validateInput
  | ready
  | finished
  deriving Repr, BEq

structure MetricEntry where
  key : String
  value : Nat
  deriving Repr, BEq

structure MetricsShell where
  entries : Array MetricEntry := #[]
  deriving Repr

structure LogShell where
  entries : Array String := #[]
  deriving Repr

structure MonsterContext where
  calculationDay : Int
  targetDay : Int
  phase : BasePhase
  status : String
  branchTrace : Array String
  metrics : MetricsShell
  logs : LogShell
  diagnostics : Array String
  semanticCommitVersion : Nat
  deriving Repr

namespace MetricsShell

def bump (shell : MetricsShell) (key : String) : MetricsShell := Id.run do
  let mut entries := shell.entries
  let mut found := false
  for i in [0:entries.size] do
    if !found && entries[i]!.key == key then
      let e := entries[i]!
      entries := entries.set! i { key := e.key, value := e.value + 1 }
      found := true
  if !found then
    entries := entries.push { key, value := 1 }
  return { entries }

end MetricsShell

namespace LogShell

def append (shell : LogShell) (message : String) : LogShell :=
  { entries := shell.entries.push message }

end LogShell

structure ValidationBoundary where
  enabled : Bool := true

namespace ValidationBoundary

def validateBaseContext (boundary : ValidationBoundary) (ctx : MonsterContext) : Except String Unit :=
  if !boundary.enabled then
    .ok ()
  else if ctx.status == "" then
    .error "Grunnkonteksten mangler status."
  else
    .ok ()

end ValidationBoundary

structure BaseDispatcher where
  validator : ValidationBoundary := {}

namespace BaseDispatcher

def dispatch (dispatcher : BaseDispatcher) (ctx : MonsterContext) : Except String MonsterContext := do
  dispatcher.validator.validateBaseContext ctx
  match ctx.phase with
  | .entry =>
      .ok { ctx with
        phase := .validateInput
        status := "INNGANG_GODKJENT"
        branchTrace := ctx.branchTrace.push "ENTRY_TO_VALIDATE"
        metrics := ctx.metrics.bump "bootstrap.dispatch"
      }
  | .validateInput =>
      .ok { ctx with
        phase := .ready
        status := "KLAR"
        branchTrace := ctx.branchTrace.push "VALIDATE_TO_READY"
        metrics := ctx.metrics.bump "bootstrap.dispatch"
      }
  | .ready =>
      .ok { ctx with
        phase := .finished
        status := "FERDIG"
        branchTrace := ctx.branchTrace.push "READY_TO_FINISHED"
        metrics := ctx.metrics.bump "bootstrap.dispatch"
      }
  | .finished => .ok ctx

end BaseDispatcher


def newMonsterContext (calculationDay targetDay : Int) : MonsterContext := {
  calculationDay
  targetDay
  phase := .entry
  status := "NY"
  branchTrace := #[]
  metrics := {}
  logs := {}
  diagnostics := #[]
  semanticCommitVersion := 0
}


def bootstrapDispatchToCompletion (calculationDay targetDay : Int) : Except String MonsterContext := do
  let dispatcher : BaseDispatcher := {}
  let c0 := newMonsterContext calculationDay targetDay
  let c1 ← dispatcher.dispatch c0
  let c2 ← dispatcher.dispatch c1
  let c3 ← dispatcher.dispatch c2
  dispatcher.validator.validateBaseContext c3
  return c3

end PastafariLean
