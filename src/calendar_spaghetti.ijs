load 'src/source_language_catalog.ijs'
load 'src/monster_base.ijs'

NB. Intrarea Bootstrap nu importă și nu apelează oracle-ul de test.
NB. Motorul istoric complet va fi construit treptat în etapele următoare.

calendarDateSpaghettiBootstrap=: 4 : 0
  ctx=. x newMonsterContext y
  ctx=. monsterBaseDispatch ctx
  ctx=. MONSTER_STATUS_NOT_INTEGRATED monsterContextSetStatus ctx
  ctx
)
