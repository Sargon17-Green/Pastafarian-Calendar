load 'src/calendar_spaghetti.ijs'
load 'test/stage02_contract_regresie.ijs'

stage02Verifica=: 4 : 0
  if. -. x do.
    echo 'ESEC_STAGE02: ',y
    assert. 0
  end.
  echo 'OK_STAGE02: ',y
  1
)

stage02Ruleaza=: 3 : 0
  m2=. <: 2x ^ 127
  (m2 -: MODUL_REST_VECHI) stage02Verifica 'modul exact'
  intrari2=. m2,(2x*m2),(3x*m2),m2+1x
  istoric2=. 0x 0x 0x 1x
  normativ2=. m2,m2,m2,1x
  for_k. i. 4 do.
    intrare=. k { intrari2
    actual=. calendarSalvareSpaghete intrare
    martor=. k { istoric2
    asteptat=. k { normativ2
    (martor -: dispecerRestVechi intrare) stage02Verifica 'martor istoric ',":k
    (64 = 3!:0 actual) stage02Verifica 'tip exact ',":k
    asteptat stage02AserteazaNormativ actual
    echo 'GREEN_STAGE02: ',":k
  end.
  ((restVechi 0x) -: 0x) stage02Verifica 'zero istoric'
  ((restVechi _1x) -: m2-1x) stage02Verifica 'reziduu negativ'
  ((restVechi 2x^240) -: 2x^113) stage02Verifica 'intreg foarte mare'
  rat2=. 3r1
  (128 = 3!:0 rat2) stage02Verifica 'fixture rational intreg'
  ((restVechi rat2) -: 3x) stage02Verifica 'reziduu rational intreg exact'
  ctx2=. m2 calendarDateSpaghettiBootstrap 0x
  ((monsterContextRestVechi ctx2) -: m2) stage02Verifica 'calea publica utilizeaza SAVE peste restul istoric'
  (MONSTER_STATUS_NOT_INTEGRATED -: monsterContextStatus ctx2) stage02Verifica 'data publica ramane neintegrata'
  ctx2b=. (m2+1x) calendarDateSpaghettiBootstrap 0x
  ((monsterContextRestVechi ctx2b) -: 1x) stage02Verifica 'context separat pentru alta invocare'
  respins2=. 0
  try.
    calendarSalvareSpaghete 1r2
  catch.
    respins2=. 1
  end.
  (respins2 = 1) stage02Verifica 'fractia este respinsa'
  echo 'STAGE02_PATCH01_GREEN_COMPLETE'
  ((calendarSalvareSpaghete 0x) -: m2) stage02Verifica 'patch zero'
  ((calendarSalvareSpaghete (-m2)) -: m2) stage02Verifica 'patch multiplu negativ'
  ((calendarSalvareSpaghete _1x) -: m2-1x) stage02Verifica 'patch reziduu negativ'
  ((calendarSalvareSpaghete 2x^240) -: 2x^113) stage02Verifica 'patch intreg foarte mare'
  ((calendarSalvareSpaghete rat2) -: 3x) stage02Verifica 'patch rational intreg'
  ((monsterContextRestVechi ctx2) -: m2) stage02Verifica 'patch context anterior intact'
  echo 'STAGE03_PATCH01_GREEN_COMPLETE'
  1
)
stage02Ruleaza ''
