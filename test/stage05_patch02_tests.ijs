load 'src/calendar_spaghetti.ijs'
load 'test/normative_reference.ijs'

stage05Verifica=: 4 : 0
  if. -. x do.
    echo 'ESEC_STAGE05: ',y
    assert. 0
  end.
  echo 'OK_STAGE05: ',y
  1
)

stage05Ruleaza=: 3 : 0
  zile=. FOUNDATION_DAY + _2x _1x 0x 1x 2x
  for_k. i. 5 do.
    zi=. k { zile
    rezultat=. calendarEtichetaZiSpaghete zi
    (rezultat -: nr_dayCount zi) stage05Verifica 'oracle ',":k
    (64 = 3!:0 rezultat) stage05Verifica 'intreg extins ',":k
  end.
  mare=. 2x ^ 240
  ((calendarEtichetaZiSpaghete FOUNDATION_DAY+mare) -: 1x+2x*mare) stage05Verifica 'pozitiv foarte mare'
  ((calendarEtichetaZiSpaghete FOUNDATION_DAY-mare) -: 2x*mare) stage05Verifica 'negativ foarte mare'
  rat5=. _15055670r1
  (128 = 3!:0 rat5) stage05Verifica 'fixture rational'
  ((calendarEtichetaZiSpaghete rat5) -: 3x) stage05Verifica 'rational intreg'
  ((dispecerEtichetaZiVeche FOUNDATION_DAY) -: 0x) stage05Verifica 'legacy intact la fundatie'
  ctx5=. FOUNDATION_DAY calendarDateSpaghettiBootstrap FOUNDATION_DAY+1x
  ((monsterContextEtichetaCalcul ctx5) -: 1x) stage05Verifica 'context calcul'
  ((monsterContextEtichetaTinta ctx5) -: 3x) stage05Verifica 'context tinta'
  ((monsterContextRestVechi ctx5) -: nr_save FOUNDATION_DAY) stage05Verifica 'SAVE nemodificat'
  (MONSTER_STATUS_NOT_INTEGRATED -: monsterContextStatus ctx5) stage05Verifica 'data publica neintegrata'
  respins=. 0
  try.
    calendarEtichetaZiSpaghete 1r2
  catch.
    respins=. 1
  end.
  (respins = 1) stage05Verifica 'fractia respinsa'
  echo 'STAGE05_PATCH02_GREEN_COMPLETE'
  1
)
stage05Ruleaza ''
