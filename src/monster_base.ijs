NB. Infrastructură neutră pentru Bootstrap; nu conține niciun patch istoric.

MONSTER_PHASE_ENTRY=: 'ENTRY'
MONSTER_STATUS_NEW=: 'NEW'
MONSTER_STATUS_VALIDATED=: 'VALIDATED'
MONSTER_STATUS_NOT_INTEGRATED=: 'NOT_INTEGRATED'

newMonsterContext=: 4 : 0
  cDay=. x
  tDay=. y
  phase=. MONSTER_PHASE_ENTRY
  status=. MONSTER_STATUS_NEW
  branchTrace=. <'BOOTSTRAP_ENTER'
  metrics=. 0 2$<''
  logs=. 0$a:
  diagnostics=. 0$a:
  warnings=. 0$a:
  semanticPending=. a:
  semanticCommitted=. a:
  cDay;tDay;phase;status;branchTrace;metrics;logs;diagnostics;warnings;semanticPending;semanticCommitted
)

monsterContextCalculationDay=: 3 : '> 0 { y'
monsterContextTargetDay=: 3 : '> 1 { y'
monsterContextPhase=: 3 : '> 2 { y'
monsterContextStatus=: 3 : '> 3 { y'

replaceBoxedItem=: 4 : 0
  NB. x este perechea index;valoare, iar y este lista boxed.
  idx=. >0{x
  value=. >1{x
  (<value) idx} y
)

monsterContextSetPhase=: 4 : 0
  (2;x) replaceBoxedItem y
)

monsterContextSetStatus=: 4 : 0
  (3;x) replaceBoxedItem y
)

monsterValidateDiscreteDay=: 3 : 0
  NB. Zilele normative trebuie să fie întregi exacți, nu valori cu fracție.
  nounType=. 3!:0 y
  assert. nounType e. 1 4 64 128
  assert. y -: <. y
  1
)

monsterBaseValidateInputs=: 3 : 0
  cDay=. >0{y
  tDay=. >1{y
  assert. monsterValidateDiscreteDay cDay
  assert. monsterValidateDiscreteDay tDay
  1
)

monsterBaseDispatch=: 3 : 0
  ctx=. y
  assert. monsterBaseValidateInputs (monsterContextCalculationDay ctx);monsterContextTargetDay ctx
  ctx=. MONSTER_STATUS_VALIDATED monsterContextSetStatus ctx
  ctx=. 'BOOTSTRAP_VALIDATED' monsterContextSetPhase ctx
  ctx
)

monsterBaseErrorWrap=: 4 : 0
  NB. Învelișul de eroare nu normalizează semantic datele de intrare.
  category=. x
  message=. y
  category;message
)
