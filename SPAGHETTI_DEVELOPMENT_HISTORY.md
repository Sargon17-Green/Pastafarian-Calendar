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
