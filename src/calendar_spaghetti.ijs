load 'src/source_language_catalog.ijs'
load 'src/monster_base.ijs'
load 'src/stage02_counts.ijs'

NB. Intrarea Bootstrap nu importa si nu apeleaza oracle-ul de test.
NB. Motorul istoric complet va fi construit treptat in etapele urmatoare.

calendarDateSpaghettiBootstrap=: 4 : 0
  ctx=. x newMonsterContext y
  ctx=. monsterBaseDispatch ctx
  dayA=. stage02CanonicalDay monsterContextCalculationDay ctx
  dayB=. stage02CanonicalDay monsterContextTargetDay ctx
  NB. Contextul pastreaza zilele discrete in forma canonica extended integer.
  ctx=. (0;dayA) replaceBoxedItem ctx
  ctx=. (1;dayB) replaceBoxedItem ctx
  observations=. dayA stage02WorkCounts dayB
  ctx=. (9;observations) replaceBoxedItem ctx
  ctx=. MONSTER_STATUS_NOT_INTEGRATED monsterContextSetStatus ctx
  ctx
)
