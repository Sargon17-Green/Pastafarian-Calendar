⍝ Neutrale Monster-Grundlage. Keine spätere Legacy- oder Patchlogik ist in Stage 1 zulässig.

∇ z←c MonsterNewContext t
  ⍝ Felder: Eingaben, Phase, Unterphase, Modus, Status, Retry-Budget, Trace, Metriken, Protokoll, pending, committed.
  z←(⊂c),(⊂t),(⊂'BOOTSTRAP'),(⊂0),(⊂'AUTHORITATIVE_BOOTSTRAP'),(⊂'NEW'),(⊂2),(⊂⍬),(⊂0 0 0),(⊂⍬),(⊂⍬),(⊂⍬)
∇

∇ z←MonsterBaseValidate ctx
  z←12=⍴ctx
∇

∇ z←MonsterBaseDispatch ctx
  :If ~MonsterBaseValidate ctx
      ⎕SIGNAL 11
  :EndIf
  ctx[3]←⊂'BOOTSTRAP_DISPATCH'
  ctx[6]←⊂'READY'
  z←ctx
∇

∇ z←MonsterBaseExecute ctx
  ctx←MonsterBaseDispatch ctx
  :If ~MonsterBaseValidate ctx
      ⎕SIGNAL 11
  :EndIf
  ctx[6]←⊂'BOOTSTRAP_OK'
  z←ctx
∇
