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

### Verifikasyon korektif pou baz Stage 1

Yon enspeksyon endepandan te jwenn ke tès fòm lang lan t ap chèche yon fichye HANDOFF ki pa fè pati pyebwa GitHub la; fichye livrezon sa yo rezève pou itilizatè a. Tès la kounye a egzamine sèlman dokiman ki nan depo a. Anplis, konvèsyon antye Lua ki pi piti a, gwo miltiplikatè yo, ak retou nan antye Lua jwenn tès limit egzak. Tout 17 non kotlèt yo ak 47 non mwa yo rete idantik nan endis yo ak nan chèn yo. Nou te verifye SHA-256 fichye orijinal la ak kadna a, apre sa nou te ajoute yon tablo pwoteksyon pou anpeche ranplasman metòd ki deja egziste, san manyen okenn non. Nou te renouvle SHA-256 pou fichye ki pwoteje a epi nou te ajoute tès kont chanjman API yo. Kopi eta semantik yo kounye a posede sou-tab yo tou, konsa yon referans kandida pa ka modifye tranzaksyon an apre kòmansman li. Koreksyon sa yo pa entwodui okenn defo istorik ni okenn patch Stage 2.

## Stage 2 — DISCOVERY 01: `oldRemainder`

### Sa nou te kwè

Premye chemen SAVE la sipoze ke yon rès modulo òdinè ak modil `M` toujou bay menm valè ak operasyon SAVE normatif la. Sipozisyon istorik sa a antre nan `oldRemainder(x) = BigInt.mod(x, M)` epi li konekte ak dispatcher pwodiksyon an atravè `saveSpaghetti`; `legacySaveProbe` toujou bay dyagnostik legacy a.

### Sa nou dekouvri

Pou `M`, `2M` ak `3M`, rès òdinè a se `0`, men SAVE normatif la se `M`. Pou `M+1`, de chemen yo bay `1`. Nou verifye tou limit `0` ak `-M`, kote diferans lan parèt ankò. Se pa yon pwoblèm prezantasyon oswa presizyon: de algoritm yo aplike de entèval rezilta diferan, `[0, M-1]` kont `[1, M]`.

### Kouch monstè a ki grandi

Yon handler `LEGACY_SAVE` antre nan dispatcher pwodiksyon an. Li kenbe input ak output kòm chèn desimal egzak pandan tranzaksyon an, valide eta annatant, komèt rezilta a, anrejistre metrik ak dyagnostik epi retounen yon BigInt. Chak apèl gen pwòp kontèks li. Tout estrikti sa yo prezève rezilta legacy ki mal la; yo pa kache diferans lan ak oracle la.

### Sa ki rete pou Stage 3

Pa gen `savePatch`, pa gen chanjman pou ranplase zewo ak `M`, pa gen koreksyon silencieux. Tès ekivalans lan dwe rete wouj jouk PATCH 01. Nou kenbe ansyen chemen an pou istwa a.

### Verifikasyon apwofondi ki rete nan Discovery 01

Yon odit API te jwenn yon dezyèm valè ki t ap soti nan `saveSpaghetti` pa aksidan, paske yon `return` Lua te remèt tout valè `LegacySave.execute` yo. Nou mete rezilta a nan yon varyab lokal anvan `return`: sa kenbe yon sèl rezilta piblik san li pa chanje `oldRemainder`, chemen dispatcher la, oswa tras dyagnostik `legacySaveProbe` a.

Nou teste 125 antre ant -12M ak 12M ak deplasman -2, -1, 0, 1, 2; sis lòt antre depase 256 bit. Nou teste izolasyon state, refi antre ki pa antye, ak kantite valè ki soti nan API a. Yon tès odit apa kouri regresyon wouj la anba `pcall` epi li aksepte **sèlman** twa diferans nonmen yo. Apre li pase, regresyon endepandan an kontinye echwe fè espre. Sa bay yon prèv ke wouj la se defo ki nan istwa a, pa yon aksidan enfrastrikti.

Pa gen okenn koreksyon SAVE, okenn import oracle nan production, ni okenn chanjman non kanonik. Premye koreksyon normatif la rete rezève pou Stage 3.

### Odit pwopriyete repwodiktib la

Nan menm etap Discovery 01 la, nou ogmante sijè tès yo pou kouvri 575 antre egzak. Nou teste idantite `x=qM+r` ak `0<=r<M`, nonmodifikasyon rès la lè nou ajoute oswa retire yon miltip `M`, ak izolasyon chak tranzaksyon. Nan mayaj sou miltip `M` yo, se 65 ka rès zewo ki bay diferans atann ant rès òdinè ak SAVE. Nou mete yon tès limit istorik ki refize kode patch 01 nan production. Sa pa chanje algoritim nan, tras la, ni defo a; tès ekivalans lan rete wouj entansyonèlman.
