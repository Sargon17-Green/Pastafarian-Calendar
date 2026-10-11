# Architettura del Bootstrap

## Proprietà dello stato

Ogni invocazione riceve un nuovo `BaseMonsterContext`. I campi semantici futuri non sono ancora presenti: questo evita di anticipare cicatrici che devono comparire soltanto nei relativi stadi storici.

## Dispatcher

`BaseMonsterDispatcher` instrada una fase verso un handler registrato. L'ordine di registrazione non può determinare il risultato: la chiave di fase è esplicita e univoca.

## Validazione ed errori

`BaseValidationManager` verifica soltanto invarianti generici del Bootstrap. `BaseErrorWrapper` conserva la causa e produce messaggi umani in italiano. Non esiste normalizzazione silenziosa di input o stato.

## Metriche

`BaseMetricsShell` è osservabilità non semantica. I contatori non sono letti da nessuna decisione del percorso di produzione.

## Catalogo della lingua sorgente

Il catalogo contiene 17 nomi di cotolette e 47 nomi di mesi. Ogni voce ha un `canonicalIndex` stabile. Le parole con significato lessicale sono tradotte semanticamente; i toponimi e i nomi inventati sono traslitterati in modo deterministico. L'ordinamento normativo usa soltanto l'indice.

## Regola di traslitterazione

Per i nomi propri o inventati senza significato lessicale si conserva la sequenza fonetica fornita dalla fonte. Le consonanti non italiane sono rese con grafemi latini stabili: il suono `sh` resta `sh`, le occlusive sonore restano `g`, `d`, `b`, e le vocali esplicite sono conservate. La stessa forma viene usata in ogni occorrenza. Non si inventa una traduzione semantica per un nome privo di significato.

## DISCOVERY 01: una cicatrice aritmetica non corretta

Il manager mantiene un contesto nuovo per ogni chiamata a
`discover01Remainder(calculationDay, targetDay, input)`.
Il Bootstrap viene eseguito e registrato prima che il dispatcher
invochi `Discovery01RemainderHandler` sullo stesso contesto.
L'adattatore `LegacyArithmeticAdapter.oldRemainder` calcola soltanto
un residuo euclideo non negativo; non conosce l'oracolo normativo.

`legacyRemainderInput` e `legacyRemainderOutput` appartengono al contesto
della singola invocazione. Il report restituito è uno snapshot immutabile.
Le metriche registrano soltanto le chiamate e non decidono il risultato.
La validazione verifica lo stato pronto e non sostituisce mai un valore errato.

La regressione autonoma dello stadio 2 conserva tre discrepanze obbligatorie
rispetto a `SAVE`; non è una patch e non anticipa il suo stadio futuro.

## PATCH 01: correttore sopra la cicatrice

`BaseMonsterManager.patch01Save` avvia Bootstrap, esegue il vero handler
`DISCOVERY_01_REMAINDER` e ne convalida lo stato, poi esegue
`PATCH_01_SAVE` nello stesso `BaseMonsterContext`.
`Patch01SaveWrapper.savePatch` richiama effettivamente
`LegacyArithmeticAdapter.oldRemainder`: il suo unico ramo condizionale
sostituisce zero con `M`. Nessuna funzione legacy è stata riscritta.

`patchedSaveOutput` e `patch01Applied` sono proprietà del contesto di
invocazione, non variabili globali. I report sono snapshot immutabili.
Il validatore controlla la fase, lo stato, il flag e la presenza di entrambi
gli output; le metriche non guidano decisioni semantiche.

Si mantengono in parallelo il percorso diagnostico storico con errore
osservabile e il percorso patched normativamente equivalente.
Le prove coprono residui nulli/non nulli, interi negativi,
numeri oltre 256 bit e controllo deterministico delle chiamate.

## DISCOVERY 02: tag del giorno simmetrico ed errato

Un nuovo handler registrato nel `BaseMonsterDispatcher` espone
la cicatrice `oldDayTag(day) = 2*abs(day-Foundation)`. Un
`BaseMonsterContext` nuovo conserva per invocazione `legacyDayTagInput`
e `legacyDayTagOutput`; validazione e metrica non influenzano l'output.
Il report copia valori e tracciato immutabili. Il calcolo non chiama
l'oracolo né una correzione futura. Il percorso PATCH 01 e le regressioni
storiche degli stadi 1–3 non vengono riscritti.

## PATCH 02: correzione additiva sopra il vecchio day tag

Il manager esegue in ordine il Bootstrap, l'handler di DISCOVERY 02 e
l'handler di PATCH 02 nello stesso contesto; non simula la chiamata legacy.
`Patch02DayTagWrapper.dayTagPatch` chiama `oldDayTag` e introduce
una sola biforcazione su `day >= FoundationDay`.
Lo stato semantico nuovo (`patchedDayTagOutput`, `patch02Applied`)
appartiene al singolo `BaseMonsterContext`.

`BaseValidationManager.requirePatch02Ready` controlla presenza,
stato, sequenza della traccia e incremento consentito `0/1`
senza utilizzare il riferimento normativo di test. Il report finale
è immutabile; le metriche sono osservabilità non semantica.
Il vecchio percorso rimane direttamente invocabile e deliberatamente RED.

## DISCOVERY 03: distanza legacy esclusiva (non corretta)

`BaseMonsterContext` riceve il nuovo campo `legacyDistanceOutput`.
Il manager `discover03Distance` inizializza la stessa invocazione
con Bootstrap e inoltra `DISCOVERY_03_DISTANCE` al relativo handler.
Quest'ultimo legge direttamente `calculationDay` e `targetDay`
già propri del contesto, e richiama `LegacyDistanceAdapter.oldDistance`
per calcolare il numero degli intervalli, senza aggiungere il giorno
iniziale. La validazione richiede un output e una traccia coerenti;
il report è uno snapshot immutabile. La metrica resta osservativa.

L'intero percorso è deliberatamente RED contro il conteggio inclusivo
normativo; la correzione non sarà introdotta prima di PATCH 03.

## PATCH 03: lo stesso percorso legacy con un giorno incluso

Il manager esegue Bootstrap e la vera DISCOVERY 03 prima di
PATCH 03, usando il medesimo `BaseMonsterContext`. Lo
`Patch03DistanceWrapper.distancePatch` chiama
`LegacyDistanceAdapter.oldDistance` e restituisce il risultato +1.

`patchedDistanceOutput` e `patch03Applied` sono locali
all'invocazione. `requirePatch03Ready` controlla l'intera
traccia e `patchedDistance = legacyDistance + 1`, senza
chiamare l'oracolo. I due output sono restituiti in uno
snapshot immutabile; le metriche non alterano la semantica.

## DISCOVERY 04: mutazione sequenziale delle cinque pietre

La ricorrenza normativa di `buildStones` legge ogni nuovo
componente interamente da una riga precedente immutabile.
L'adattatore storico `mutateStonesWrong` invece mantiene
un `Array[BigInt]` locale e aggiorna in ordine i registri,
facendo leggere ai passi successivi i risultati già mutati.

Il risultato viene congelato riga per riga in una struttura
immutabile. Lo handler `DISCOVERY_04_STONES` viene eseguito
dal dispatcher dopo Bootstrap e registra un output di 46×5
e una metrica, senza correggere i valori. Il manager restituisce
uno snapshot della singola invocazione; il validatore verifica
traccia e forma. Non esiste PATCH 04 a questo stadio.

## PATCH 04: ricostruzione della tabella su righe congelate

Il manager `patch04Stones` esegue la vera DISCOVERY 04 nel
medesimo contesto e conserva l'intera tabella errata. Il
nuovo handler PATCH 04 richiama `stonesPatch` sulla tabella
legacy: usa esclusivamente la prima riga iniziale, dopodiché
legge tutte le cinque componenti da `previous` senza
mutazioni in-place e pubblica `next` solo a fine riga.

Il validatore controlla la traccia completa, le dimensioni,
il flag e l'uguaglianza alla ricostruzione deterministica
dalla stessa prima riga. Le due tabelle sono istantanee
immutabili nel report; nessun dato di test entra nel prodotto.

## DISCOVERY 05 — accessor del registro temporale legacy

La storia delle sette gocce nascoste si dispone sulle
posizioni `0,-1,...,-6`; la visibile 1 occupa la
posizione 1. `legacyPrior(hidden,visible,index,lag)`
esige esattamente `index-1` visibili già note e
ritardi appartenenti a `{1,3,7}`. Il difetto,
intenzionale, è localizzato soltanto nella lettura
`index-6` richiesta per ritardo 7. Non è un problema
di aritmetica modulare.

`DISCOVERY_05_PRIOR` ha un handler registrato nel dispatcher,
input e output locali al contesto, validazione di readiness,
report congelato e metrica osservativa. Il riferimento
normativo è importato esclusivamente nei test, non nel
codice di produzione.

## PATCH 05 — accessor corretto dei precedenti

Il dispatcher chiama prima `Discovery05PriorHandler` e
poi `Patch05PriorHandler` nello stesso
`BaseMonsterContext`. `priorPatch` attraversa
davvero l'adattatore legacy, ma solo per `lag=7`
sostituisce il risultato con la posizione `index-7`.
Il valore precedente e il corretto sono entrambi
presenti nel report immutabile e protetti dal
validator.

`requirePatch05Ready` controlla in modo indipendente
gli input della finestra, l'indice, i ritardi,
la traccia completa e l'uguaglianza di ciascun
output alla propria formula. La logica non importa
l'oracolo test-only e non avvia la costruzione
completa delle gocce dei futuri stadi.

## DISCOVERY 06 — tabella a dodici record per undici macinature

La struttura `GRIND_TABLE_WITH_SENTINEL` contiene
il sentinel iniziale `(0,0,0,0,0)` e undici regole
normative. `legacyGrindRule(step)` sbaglia l'indice
`step-1`: l'indice corretto sarebbe `step`.
`legacyGrind` applica effettivamente la regola letta
alla formula con `oldValue²`, tre valori precedenti
e la pietra determinata dalla regola, quindi usa
il wrapper SAVE di Stage03.

Il manager esegue `DISCOVERY_06_GRIND` dopo Bootstrap,
con input/output propri dell'invocazione, controllo
della regola selezionata, report immutabile e metrica.
Il riferimento normativo delle undici regole compare
nei test, non nell'adattatore di produzione.
