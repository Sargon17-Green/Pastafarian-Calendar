NB. Stage 2 / DISCOVERY 01: restul istoric ramane gresit la multiplii modulului.
MODUL_REST_VECHI=: <: 2x ^ 127

restVechi=: 3 : 0
  assert. monsterValidateDiscreteDay y
  pereche=. 2 x: y
  assert. 1x = 1 { pereche
  intreg=. 0 { pereche
  MODUL_REST_VECHI | intreg
)

dispecerRestVechi=: 3 : 0
  restVechi y
)

calendarSalvareSpaghete=: 3 : 0
  dispecerRestVechi y
)

monsterContextRestVechi=: 3 : '> 9 { y'
