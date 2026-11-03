load 'src/calendar_spaghetti.ijs'

NB. Stage 4 / DISCOVERY 02: checks without importing the test-only oracle.
stage04Check=: 4 : 0
  if. -. x do.
    echo 'FAIL_STAGE04: ',y
    assert. 0
  end.
  echo 'OK_STAGE04: ',y
  1
)

stage04RejectFraction=: 3 : 0
  rejected=. 0
  try.
    stage04Save 1r2
  catch.
    rejected=. 1
  end.
  rejected
)

stage04RejectScalarVector=: 3 : 0
  rejected=. 0
  try.
    stage04Save 1x 2x
  catch.
    rejected=. 1
  end.
  rejected
)

stage04RejectWrongCounts=: 3 : 0
  rejected=. 0
  try.
    stage04SaveCounts 1x 2x
  catch.
    rejected=. 1
  end.
  rejected
)

stage04RejectMatrixCounts=: 3 : 0
  rejected=. 0
  try.
    stage04SaveCounts 1 5 $ 1x
  catch.
    rejected=. 1
  end.
  rejected
)

saveM4=. STAGE04_SAVE_MODULUS
(saveM4 = <: 2x ^ 127) stage04Check 'modulul exact M=2^127-1'
(64 = 3!:0 saveM4) stage04Check 'modulul M este extended integer'
((stage04Save 1x) = 1x) stage04Check 'SAVE(1)=1'
((stage04Save saveM4) = saveM4) stage04Check 'SAVE(M)=M, nu zero'
((stage04Save saveM4+1x) = 1x) stage04Check 'SAVE(M+1)=1'
((stage04Save 2x*saveM4) = saveM4) stage04Check 'SAVE(2M)=M'
((stage04Save 0x) = saveM4) stage04Check 'SAVE(0)=M'
((stage04Save _1x) = saveM4-1x) stage04Check 'SAVE(-1)=M-1'
((stage04Save -saveM4) = saveM4) stage04Check 'SAVE(-M)=M'
((stage04Save 1x+10x*saveM4) = 1x) stage04Check 'multipli pozitivi de M sunt eliminati exact'
(128 = 3!:0 3r1) stage04Check 'fixture rational-intreg are tip J128'
(((stage04Save 3r1) = 3x) *. (64 = 3!:0 stage04Save 3r1)) stage04Check 'rational-intreg devine rezultat exact J64'
large4=. 2x ^ 240
((stage04Save large4) = stage04Save large4+saveM4) stage04Check 'periodicitate pentru un numar foarte mare'
((stage04Save large4) = stage04Save large4-5x*saveM4) stage04Check 'periodicitate la deplasari negative de multipli M'
((stage04Save stage04Save large4) = stage04Save large4) stage04Check 'idempotenta SAVE(SAVE(n))'
inputs4=. 1x,0x,(saveM4+1x),_1x,3x
expected4=. 1x,saveM4,1x,(saveM4-1x),3x
((stage04SaveCounts inputs4) -: expected4) stage04Check 'vectorul celor cinci numaratori este redus element-cu-element'
((64 = 3!:0 stage04SaveCounts inputs4) *. (5 = #stage04SaveCounts inputs4)) stage04Check 'vectorul redus are cinci extended integers'
(stage04RejectFraction '') stage04Check 'fractia neintreaga este respinsa'
(stage04RejectScalarVector '') stage04Check 'intrarea nescalara este respinsa de SAVE'
(stage04RejectWrongCounts '') stage04Check 'vectorul cu doua componente este respins'
(stage04RejectMatrixCounts '') stage04Check 'matricea 1x5 este respinsa'
ctx4=. _15055671x calendarDateSpaghettiBootstrap _15055668x
((stage02CountsInContext ctx4) -: 1x 7x 4x 8x 3x) stage04Check 'cele cinci valori deja acceptate raman neschimbate'
(MONSTER_STATUS_NOT_INTEGRATED -: monsterContextStatus ctx4) stage04Check 'functia publica nu revendica o data integrata'
(0 = +/ 'normative_reference' E. 1!:1 <'src/stage04_save.ijs') stage04Check 'codul de productie nu importa referinta de test'
echo 'STAGE04_DISCOVERY02_CHECKS_COMPLETE'
