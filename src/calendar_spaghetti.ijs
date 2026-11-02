load 'src/source_language_catalog.ijs'
load 'src/monster_base.ijs'
load 'src/stage02_counts.ijs'

NB. Intrarea Bootstrap nu importă și nu apelează oracle-ul de test.
NB. Motorul istoric complet va fi construit treptat în etapele următoare.

calendarDateSpaghettiBootstrap=: 4 : 0
  ctx=. x newMonsterContext y
  ctx=. monsterBaseDispatch ctx
  dayA=. monsterContextCalculationDay ctx
  dayB=. monsterContextTargetDay ctx
  observations=. dayA stage02WorkCounts dayB
  ctx=. (9;observations) replaceBoxedItem ctx
  ctx=. MONSTER_STATUS_NOT_INTEGRATED monsterContextSetStatus ctx
  ctx
)
