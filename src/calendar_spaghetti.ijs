load 'src/source_language_catalog.ijs'
load 'src/monster_base.ijs'
load 'src/stage02_rest_vechi.ijs'

NB. Calea publica foloseste restul istoric prin dispecer.
NB. Data calendaristica completa nu este inca integrata.
calendarDateSpaghettiBootstrap=: 4 : 0
  ctx=. x newMonsterContext y
  ctx=. monsterBaseDispatch ctx
  rest=. calendarSalvareSpaghete monsterContextCalculationDay ctx
  ctx=. (9;rest) replaceBoxedItem ctx
  ctx=. MONSTER_STATUS_NOT_INTEGRATED monsterContextSetStatus ctx
  ctx
)
