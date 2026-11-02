NB. Stage 2 / DISCOVERY 01: valori de lucru pentru numararea zilelor.
NB. Implementare de productie independenta; nu importa referinta de test.
NB. Aceste cinci valori intermediare NU reprezinta data calendaristica finala.

stage02CountForDay=: 3 : 0
  delta=. y - _15055671x
  if. delta = 0 do.
    1x return.
  end.
  if. delta > 0 do.
    (1x + 2x * delta) return.
  end.
  2x * | delta
)

stage02WorkCounts=: 4 : 0
  dayA=. x
  dayB=. y
  labelA=. stage02CountForDay dayA
  labelB=. stage02CountForDay dayB
  span=. 1x + | dayB - dayA
  combined=. labelA + labelB
  travel=. 2x + (dayB > dayA) - (dayB < dayA)
  labelA,labelB,span,combined,travel
)

stage02CountsInContext=: 3 : '> 9 { y'
