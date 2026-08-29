# Historie del developation spaghetti

## Stage 1 — Bootstrap

### Quo esset constructet

Li linea de implementation ha esset creat de zero por JavaScript con Interlingue / Occidental quam unic lingue-fonte human. Un `SourceLanguageCatalog` versionat e congelat contene 17 nomes de cutlettes e 47 nomes de mensus con indices canonic stabil. Un reference normativ local, un generator local de fixtures e un test harness local ha esset creat in JavaScript.

Li production ha solmen un infrastructura monster neutral: `BaseMonsterContext`, `BaseDispatcher`, `BaseValidationManager`, `BaseErrorWrapper`, `BaseMetricsManager` e `BaseMonsterManager`. Chascun invocation crea su propri context. Metrics e logs de ti stage es non-semantic e ne es consultat por decisiones normativ.

### Quo ne esset constructet

Null defect legacy e null patch historic es ancor present. Null path de stages futur ha esset anticipat. `calendarDateSpaghetti` jetta un errore explicit de Bootstrap in vice de simular un implementation prematur.

### Independentie

Null altri implementation ha esset leet quam fonte semantic o calculatori. Null test, fixture, output expectat, table generat, serialized state, hash, checksum o differential cross-implementation ha esset usat. Li reference e li fixtures de ti linea deriva exclusivmen ex li specification includet in li task.

### Crescentie monster in ti stage

Solmen li strat general permisset in Bootstrap ha esset addit: context, dispatcher, validation, wrapping de errores e metrics. Ti strat ne contene semantics del patches e ne altera null resultat normativ.

### Verification supplementari ante Stage 2

Ante crear li prim defect legacy, li Bootstrap ha esset subjectet a un porta de verification plu strict. Un nov test-only verifier in JavaScript compara pluri partes del reference con copies de validation separat e con enumerations exhaustiv de spaces micri. It verifica anc permutationes, portes, annus, isolation de state, congelation del catalog, absentie de imports del oracle in production e absentie de code futur.

Li porta passa con 25 gruppes e 60226 assertions. Null semantic patch e null nove strat monster ha esset addit; ergo li crescentie historic resta exactmen in Stage 1.

Un probe diagnostic plen de `calendarDate` ne finit ante 120 secundes in ti ambiente, pro li grand DP de intertexe de un annu real. Ti observation ne ha esset mascat per approximation o fallback. It es conservat quam nota de performance; li equivalence del DP es verificat exhaustivmen sur spaces micri.

## Stage 2 — DISCOVERY 01

### Quo on pensat

Li prim design historic tractat «save» quam un simplic regular modulo de `M`. Li operation legacy es `oldRemainder(value) = regularMod(value, M_OLD)`, e it es nu conectet a un path real de production.

### Quo esset decovrit

Ti assumption perde li representation reservat del residu zero. Por `M`, `2M` e `3M`, `oldRemainder` rende `0`; li reference normativ `SAVE` rende `M`. Li casu `M+1` rende `1` in ambi paths e demonstra que li defect ne es un shift general.

### Quo esset circumit

Null circumventione existe in ti stage. Li correction es expressmen reservat por PATCH 01 in Stage 3. `savePatch` ne es present.

### Crescentie monster in ti stage

Un `LegacyRemainderAdapter` e un `Discovery01RemainderHandler` ha esset addit. `BaseMonsterManager` crea li context, passa it tra li dispatcher de Bootstrap, e poy route li valore a ti nov handler. Li context conserva handler current/precedent, input e output legacy, trace e metric non-semantic.

### Pro quo li strat nov ne adjunte un altri defect semantic

Li adapter e li handler copia exactmen li operation legacy definat por ti discovery; ili ne normalisa, ne corrige e ne consulta li oracle. Li unic divergentie es li defect historic intentional de `oldRemainder`. Li state del context resta proprietá de un unic invocation.

