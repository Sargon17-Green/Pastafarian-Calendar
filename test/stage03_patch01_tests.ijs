load 'src/calendar_spaghetti.ijs'

NB. Stage 3 PATCH 01: regressions for canonical exact-integer day representation.
NB. The rational fixtures below are intentionally type 128 (not extended integers).

stage03Check=: 4 : 0
  if. -. x do.
    echo 'FAIL_STAGE03: ',y
    assert. 0
  end.
  echo 'OK_STAGE03: ',y
  1
)

stage03RejectsFraction=: 3 : 0
  rejected=. 0
  try.
    (1r2) calendarDateSpaghettiBootstrap 1x
  catch.
    rejected=. 1
  end.
  rejected
)

rationalFoundation=. _15055671r1
rationalTarget=. rationalFoundation + 3r1
(128 = 3!:0 rationalFoundation) stage03Check 'fixture de baza este rational type 128'
(((stage02CountForDay rationalFoundation) -: 1x) *. (64 = 3!:0 stage02CountForDay rationalFoundation)) stage03Check 'numaratoarea unei zile rational-intregi devine extended integer'

ctxForward=. rationalFoundation calendarDateSpaghettiBootstrap rationalTarget
countsForward=. stage02CountsInContext ctxForward
((countsForward -: 1x 7x 4x 8x 3x) *. (64 = 3!:0 countsForward)) stage03Check 'cinci valori inainte sunt exacte si de tip extended integer'
((64 = 3!:0 monsterContextCalculationDay ctxForward) *. (64 = 3!:0 monsterContextTargetDay ctxForward)) stage03Check 'zilele din context sunt canonizate ca extended integer'
(5 = #countsForward) stage03Check 'rezultatul semantic contine exact cinci valori intermediare'

ctxReverse=. rationalTarget calendarDateSpaghettiBootstrap rationalFoundation
countsReverse=. stage02CountsInContext ctxReverse
((countsReverse -: 7x 1x 4x 8x 1x) *. (64 = 3!:0 countsReverse)) stage03Check 'cinci valori inapoi sunt exacte si de tip extended integer'

ctxSame=. rationalFoundation calendarDateSpaghettiBootstrap rationalFoundation
countsSame=. stage02CountsInContext ctxSame
((countsSame -: 1x 1x 1x 2x 2x) *. (64 = 3!:0 countsSame)) stage03Check 'aceeasi zi rationala pastreaza distanta 1 si directia 2'

hugeRational=. 2r1 ^ 100x
(128 = 3!:0 hugeRational) stage03Check 'fixture-ul mare ramane rational type 128'
hugeInteger=. stage02CanonicalDay hugeRational
countsHuge=. rationalFoundation stage02WorkCounts rationalFoundation+hugeRational
expectedHuge=. 1x,(1x+2x*hugeInteger),(1x+hugeInteger),(2x+2x*hugeInteger),3x
((countsHuge -: expectedHuge) *. (64 = 3!:0 countsHuge)) stage03Check 'numere rational-intregi mari sunt canonizate fara pierdere de precizie'

(stage03RejectsFraction '') stage03Check 'rational neintreg continua sa fie respins la intrarea publica'
(MONSTER_STATUS_NOT_INTEGRATED -: monsterContextStatus ctxForward) stage03Check 'PATCH 01 nu integreaza prematur data finala'

echo 'STAGE03_PATCH01_CHECKS_COMPLETE'
