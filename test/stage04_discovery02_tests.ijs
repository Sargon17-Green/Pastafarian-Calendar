load 'src/calendar_spaghetti.ijs'
load 'test/normative_reference.ijs'

stage04Verifica=: 4 : 0
  if. -. x do.
    echo 'ESEC_STAGE04: ',y
    assert. 0
  end.
  echo 'OK_STAGE04: ',y
  1
)

stage04Ruleaza=: 3 : 0
  (FOUNDATION_DAY -: FUNDATIE_ETICHETA_VECHE) stage04Verifica 'constanta fundatiei'
  zile=. FOUNDATION_DAY + _2x _1x 0x 1x 2x
  vechi=. 4x 2x 0x 2x 4x
  normativ=. 4x 2x 1x 3x 5x
  for_k. i. 5 do.
    zi=. k { zile
    actual=. calendarEtichetaZiSpaghete zi
    asteptat=. nr_dayCount zi
    (actual -: k { vechi) stage04Verifica 'martor legacy ',":k
    (asteptat -: k { normativ) stage04Verifica 'oracle si fixture ',":k
    (64 = 3!:0 actual) stage04Verifica 'tip exact ',":k
    if. k < 2 do.
      (actual -: asteptat) stage04Verifica 'control normativ ',":k
      echo 'GREEN_STAGE04: ',":k
    else.
      ((actual + 1x) -: asteptat) stage04Verifica 'divergenta exacta ',":k
      echo 'RED_STAGE04: ',":k
    end.
  end.
  mare=. 2x ^ 240
  ((calendarEtichetaZiSpaghete FOUNDATION_DAY+mare) -: 2x*mare) stage04Verifica 'zi foarte mare dupa fundatie'
  ((calendarEtichetaZiSpaghete FOUNDATION_DAY-mare) -: 2x*mare) stage04Verifica 'zi foarte mare inainte de fundatie'
  rat4=. _15055670r1
  (128 = 3!:0 rat4) stage04Verifica 'fixture rational intreg'
  ((calendarEtichetaZiSpaghete rat4) -: 2x) stage04Verifica 'rational intreg exact'
  ctx4=. FOUNDATION_DAY calendarDateSpaghettiBootstrap FOUNDATION_DAY+1x
  ((monsterContextEtichetaCalcul ctx4) -: 0x) stage04Verifica 'ruta publica calcul legacy'
  ((monsterContextEtichetaTinta ctx4) -: 2x) stage04Verifica 'ruta publica tinta legacy'
  ctx4b=. (FOUNDATION_DAY-1x) calendarDateSpaghettiBootstrap FOUNDATION_DAY-2x
  ((monsterContextEtichetaCalcul ctx4b) -: 2x) stage04Verifica 'context separat calcul'
  ((monsterContextEtichetaTinta ctx4b) -: 4x) stage04Verifica 'context separat tinta'
  ((monsterContextEtichetaCalcul ctx4) -: 0x) stage04Verifica 'contextul anterior ramane intact'
  ((monsterContextRestVechi ctx4) -: nr_save FOUNDATION_DAY) stage04Verifica 'PATCH01 ramane activ'
  (MONSTER_STATUS_NOT_INTEGRATED -: monsterContextStatus ctx4) stage04Verifica 'data publica neintegrata'
  respins4=. 0
  try.
    calendarEtichetaZiSpaghete 1r2
  catch.
    respins4=. 1
  end.
  (respins4 = 1) stage04Verifica 'fractia este respinsa'
  echo 'STAGE04_DISCOVERY02_EXPECTED_RED_COMPLETE'
  1
)
stage04Ruleaza ''
