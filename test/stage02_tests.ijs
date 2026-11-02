load 'src/calendar_spaghetti.ijs'

NB. Verificari independente pentru noua cale de productie: fara oracle de test.
stage02Check=: 4 : 0
  if. -. x do.
    echo 'FAIL_STAGE02: ',y
    assert. 0
  end.
  echo 'OK_STAGE02: ',y
  1
)

F2=. _15055671x
((F2 stage02WorkCounts F2) -: 1x 1x 1x 2x 2x) stage02Check 'egalitate la ziua fundatiei'
((stage02CountForDay F2) = 1x) stage02Check 'fundatia are eticheta 1'
((stage02CountForDay F2+1x) = 3x) stage02Check 'ziua urmatoare are eticheta 3'
((stage02CountForDay F2-1x) = 2x) stage02Check 'ziua precedenta are eticheta 2'
((stage02CountForDay F2+3x) = 7x) stage02Check 'trei zile dupa fundatie'
((stage02CountForDay F2-3x) = 6x) stage02Check 'trei zile inainte de fundatie'
((F2 stage02WorkCounts F2+3x) -: 1x 7x 4x 8x 3x) stage02Check 'sens inainte si distanta inclusiva'
(((F2+3x) stage02WorkCounts F2) -: 7x 1x 4x 8x 1x) stage02Check 'sens inapoi si distanta inclusiva'
(((F2-2x) stage02WorkCounts F2+2x) -: 4x 5x 5x 9x 3x) stage02Check 'traversare fundatie inainte'
(((F2+2x) stage02WorkCounts F2-2x) -: 5x 4x 5x 9x 1x) stage02Check 'traversare fundatie inapoi'
huge2=. 2x^100
((stage02CountForDay F2+huge2) = 1x+2x*huge2) stage02Check 'intreg extins pozitiv 2 la puterea 100'
((stage02CountForDay F2-huge2) = 2x*huge2) stage02Check 'intreg extins negativ 2 la puterea 100'
(((F2+huge2) stage02WorkCounts (F2+huge2)) -: (1x+2x*huge2),(1x+2x*huge2),1x,(2x+4x*huge2),2x) stage02Check 'aceeasi zi mare are distanta 1 si sens 2'
ctx2=. F2 calendarDateSpaghettiBootstrap F2+3x
((stage02CountsInContext ctx2) -: 1x 7x 4x 8x 3x) stage02Check 'valorile de lucru ajung in contextul de productie'
(MONSTER_STATUS_NOT_INTEGRATED -: monsterContextStatus ctx2) stage02Check 'nu pretindem existenta celor cinci componente de data'
((5 = # stage02CountsInContext ctx2)) stage02Check 'numai cinci valori de lucru, nu data finala'
((0 = +/ 'normative_reference' E. 1!:1 <'src/stage02_counts.ijs')) stage02Check 'sursa noua nu importa oracle de test'

echo 'STAGE02_DISCOVERY01_CHECKS_COMPLETE'
