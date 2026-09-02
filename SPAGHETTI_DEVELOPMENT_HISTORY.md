# Istwa devlopman monstr espageti a

## Stage 1 — Bootstrap

### Ki sa nou te konstwi

Liy sa a te kòmanse nan yon pyebwa vid pou Lua ak Kreyòl ayisyen. Nou te mete yon BigInt an Lua pou tout kalkil ki ka depase limit antye natif la. Nou te rekonstrui oracle normatif la nan Lua apati referans ki te bay nan enstriksyon yo, epi nou te kreye fixture lokal yo ak oracle sa a sèlman.

Nou te mete yon `SourceLanguageCatalog` ki kenbe 17 non kotlèt ak 47 non mwa. `canonicalIndex` se sèl lòd ki gen valè normatif. Katalòg la pa ekspoze tablo entèn yo pou modifikasyon, epi modil la refize nouvo chan dirèk.

### Kouch monstr ki parèt nan etap sa a

Nou te mete sèlman enfrastrikti jeneral ki otorize nan Bootstrap la: yon `MonsterContext` pou yon sèl invocation, yon `MonsterManager`, yon dispatcher debaz, yon validatè debaz, yon anvlòp erè ak yon koki metrik. Eta semantik la sèvi ak yon ti pwotokòl `begin -> validate -> commit` ak rollback. Pa gen okenn chemen legacy, flag patch, cache istorik oswa ghost computation nan Stage 1.

### Poukisa kouch sa a pa chanje semantik

Koki production Stage 1 la pa kalkile dat kalandriye a ankò. Enfrastrikti a sèlman valide kalite jou yo, kenbe eta lokal pou yon sèl invocation epi pwouve ke eta annatant pa koule. Oracle tès la separe fizikman nan `test/` epi production pa enpòte li.

### Sa nou poko fè

Nou pa ekri davans okenn nan 26 defo legacy yo. Nou pa ekri okenn patch ki pou Stage 2 oswa apre. Premye defo istorik la dwe antre sèlman lè Stage 2 rive.
