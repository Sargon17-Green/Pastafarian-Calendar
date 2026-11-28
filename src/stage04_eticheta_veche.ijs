NB. Stage 4 / DISCOVERY 02: proiectarea veche atribuie tuturor zilelor etichete pare.
FUNDATIE_ETICHETA_VECHE=: _15055671x

etichetaZiVeche=: 3 : 0
  assert. monsterValidateDiscreteDay y
  pereche=. 2 x: y
  assert. 1x = 1 { pereche
  intreg=. 0 { pereche
  2x * | intreg - FUNDATIE_ETICHETA_VECHE
)

dispecerEtichetaZiVeche=: 3 : 0
  etichetaZiVeche y
)

calendarEtichetaZiSpaghete=: 3 : 0
  dispecerEtichetaZiVeche y
)

monsterContextEtichetaCalcul=: 3 : '> 11 { y'
monsterContextEtichetaTinta=: 3 : '> 12 { y'
