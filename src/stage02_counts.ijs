NB. Stage 2 / DISCOVERY 01: valori de lucru pentru numararea zilelor.
NB. Implementare de productie independenta; nu importa referinta de test.
NB. Aceste cinci valori intermediare NU reprezinta data calendaristica finala.

NB. Converteste o zi intreaga validata in tipul J extended integer (64).
NB. Intrarea poate fi un rational exact cu numitorul 1; 2 x: extrage
NB. numaratorul si numitorul ca extended integers, fara conversie float.
stage02CanonicalDay=: 3 : 0
  assert. monsterValidateDiscreteDay y
  numeratorDenominator=. 2 x: y
  assert. 1x = 1 { numeratorDenominator
  0 { numeratorDenominator
)

stage02CountForExtendedDay=: 3 : 0
  assert. 64 = 3!:0 y
  delta=. y - _15055671x
  if. delta = 0 do.
    1x return.
  end.
  if. delta > 0 do.
    (1x + 2x * delta) return.
  end.
  2x * | delta
)

stage02CountForDay=: 3 : 0
  stage02CountForExtendedDay stage02CanonicalDay y
)

stage02WorkCounts=: 4 : 0
  dayA=. stage02CanonicalDay x
  dayB=. stage02CanonicalDay y
  labelA=. stage02CountForExtendedDay dayA
  labelB=. stage02CountForExtendedDay dayB
  span=. 1x + | dayB - dayA
  combined=. labelA + labelB
  travel=. 2x + (dayB > dayA) - (dayB < dayA)
  labelA,labelB,span,combined,travel
)

stage02CountsInContext=: 3 : '> 9 { y'
