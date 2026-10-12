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

## PATCH 06 — ripristino dell'indice dopo il sentinel

La patch non muta `GRIND_TABLE_WITH_SENTINEL` e non modifica
`legacyGrindRule(step)`. Il wrapper attraversa realmente
`LegacyGrindTableAdapter.legacyGrind` e poi usa
`GRIND_TABLE_WITH_SENTINEL(step)`, il successore della
regola errata letta in `step-1`.
Il handler richiede la precedente `DISCOVERY_06_GRIND`
nello stesso contesto; mantiene `legacyGrindRuleOutput` e
`legacyGrindOutput` e aggiunge due snapshot propri della PATCH 06.

`requirePatch06Ready` convalida sequenza del dispatcher,
tutti gli input, il flag, entrambe le regole e i
risultati quadratici con SAVE, senza alcun riferimento
normativo di produzione. Report e metriche non influiscono
sulla scelta della regola; il catalogo sorgente italiano
rimane congelato.

## DISCOVERY 07 — rango di permutazione spostato di uno

`oldPermutationUnrank0(rank1)` verifica il rango 1..720,
ma usa `rank1 % 720` come indice fattoriale zero-based,
anziché `rank1 - 1`. Ne segue l'ordine lessicografico
successivo e, all'ultimo rango, un ritorno improprio al
primo. Il calcolo è realizzato nel codice Scala di
produzione usando una lista mutabile **locale**, poi
congelata in un `Vector[Int]` immutabile.

`Discovery07PermutationHandler` richiede un Bootstrap
fresco, legge il rango semanticamente posseduto dal
contesto, scrive un output, una trace e una metrica.
Il manager espone lo storico senza normalizzarlo;
il validatore controlla forma, rango e corrispondenza
al vero helper legacy. L'oracolo fattoriale è test-only.

## PATCH 07 — riavvolgimento normativo della base del rango

Il nuovo wrapper non modifica il helper storico di
unranking. Dopo avere attraversato il percorso legacy
con il rango richiesto, usa il medesimo helper con
`rank-1`, sostituendo zero con l'ingresso storico 720.
Questa corrispondenza elimina l'errore di base senza
duplicare la generazione delle 720 permutazioni.

Il dispatcher registra `Patch07PermutationHandler`;
il manager lo esegue dopo la fase `DISCOVERY_07_PERMUTATION`
nello stesso contesto. Due output distinti, un flag,
una metrica e un report immutabile impediscono di
cancellare la cicatrice. Il validator ricalcola unranking
fattoriale 1-based in un algoritmo separato, verifica
la trace e confronta l'output storico al helper original.
L'oracolo normativo rimane nei test, non nella produzione.

## DISCOVERY 08 — alias nel registro delle sei ciotole

Il helper `LegacyBowlAliasAdapter.bowlAlias` riceve sei
valori precedenti, una goccia, cinque pietre, un indice
visibile 1..46 e il rango dell'ordine 1..720. L'ordine
è sempre normalizzato dalla PATCH 07; i tre getti
vengono calcolati prima di qualsiasi mutazione.
Il codice storico usa `old = register` e
`next = register`, condividendo lo stesso array:
le nuove scritture contaminano le letture seguenti.
L'array resta confinato al helper e il risultato
viene congelato in `Vector[BigInt]`.

Il dispatcher esegue `Discovery08BowlAliasHandler`
su un contesto nuovo; il validatore controlla trace,
input, rango, dominio SAVE, getti e riproduzione della
diagnostica. Il test-only oracle confronta separatamente
la formula normativa con input congelati; non è stata
introdotta la PATCH 08.

## PATCH 08 — due registri indipendenti per sei ciotole

`Patch08BowlWrapper.bowlPatch` richiama l'autentico
`LegacyBowlAliasAdapter.bowlAlias`; poi riusa esclusivamente
i suoi getti e l'ordine, già corretti. Il vettore di
ingresso resta immutabile; il nuovo `Array[BigInt]`
contiene solo le sei uscite, pubblicate simultaneamente
come `Vector[BigInt]`. Il primo registro non può essere
contaminato dalle scritture del secondo.

`Patch08BowlHandler` richiede la vera fase
`DISCOVERY_08_BOWL_ALIAS` nella stessa invocazione.
Il manager conserva entrambi i risultati in un report
immutabile e incrementa una metrica separata.
`requirePatch08Ready` ricostruisce le sei equazioni
frozen senza richiamare il wrapper, controllando
sia l'ordine di PATCH07 sia la cicatrice storica.
L'oracolo test-only resta escluso dalla produzione.

## DISCOVERY 09 — il caveau precedente rimane obsoleto

`LegacyVaultAdapter.vaultOld` riceve sei ciotole
dopo l'ultima goccia. Per dodici giri esegue
`saved=SAVE(sum(old)+149*stir)`, sceglie una
permutazione 1-based di sei ID, e calcola sei
nuovi valori con i pesi normativi 3,5,7 e
`stir+position²`. L'errore è un'unica
variabile di stato: `old` resta sempre
il Vector d'ingresso invece del risultato del
giro precedente. Si producono comunque dodici
record osservabili con il loro rango, ordine,
somma SAVE e sei uscite.

Handler, dispatcher, contesto e manager sono
limitati alla fase `DISCOVERY_09_VAULT`; il
validator verifica traccia, ownership, dominio
SAVE e tutta la sequenza storica. Un calcolatore
rolling separato vive esclusivamente nei test.
La fase PATCH 09 rimane futura.

## PATCH 09 — dodici registri concatenati e diagnostica storica

Il wrapper `Patch09VaultWrapper.vaultPatch`
esegue davvero `LegacyVaultAdapter.vaultOld`
prima della correzione, custodendone il risultato.
Poi, per ogni `stir` da 1 a 12, legge il
`Vector[BigInt]` della generazione precedente,
calcola SAVE della somma, rango di permutazione
1-based e sei uscite simultanee. Solo alla fine
del giro sostituisce `snapshot` con il nuovo
vettore immutabile.

Il validatore `requirePatch09Ready` costruisce
autonomamente tutte e dodici le prove normative
con una implementazione diversa (ordinamento
degli ID fisici delle ciotole) e confronta
l'intera sequenza, non soltanto il risultato finale.
Convalida inoltre la cicatrice storica, la
traccia BOOT/DISCOVERY/PATCH e il possesso del
contesto da parte dell'invocazione. L'oracolo
completo vive soltanto nei test.

## DISCOVERY 10 — ordine della goccia 46 trattenuto al punto sbagliato

`LegacyOrder46LatchAdapter.orderAt46Latch` riceve
i due valori consecutivi di goccia (45, 46)
e l'ID della ciotola interrogata. Ricava
separatamente i due ordini attraverso
`Patch07PermutationWrapper.permutationPatch`,
ma il vecchio `captured` viene fissato al
primo ordine. La scelta del vicino avviene
sull'ordine sbagliato, anche se la permutazione
della goccia 46 è stata calcolata correttamente.

Il manager pubblica entrambi gli ordini e
la scelta effettiva storica, con stato e
traccia del contesto verificati dal validator.
L'oracolo per la scelta del vicino corretto
resta unicamente nella suite di test. La
prossima PATCH 10 deve lasciare intatta
la cicatrice storica.

## PATCH 10 — fotografia corretta della goccia 46

`Patch10Order46Wrapper.order46Patch` esegue la
cicatrice reale, poi calcola l'ordine normativo
al quarantaseiesimo getto attraverso la PATCH 07.
Il `Vector[Int]` risultante non cambia quando
vengono eseguite le dodici mescolature del caveau.
L'ID successivo è quello che segue il richiesto
nell'ordine 46, con ritorno ciclico in posizione 1.

La `BaseValidationManager.requirePatch10Ready`
verifica indipendentemente i due ordini tramite
decomposizione fattoriale, conservando anche
l'output errato del vecchio latch. Il controllo
richiede la stessa invocazione
`BOOT/DISCOVERY_10/PATCH_10` e non dipende
dall'oracolo di test. Il report espone entrambi
i successori per agevolare la prova differenziale.

## DISCOVERY 11 — selezione corta con residuo non uniformemente distribuito

Il flusso ha valori in `[1,M]` e una direzione
di incremento o decremento circolare. Per una
famiglia corta di cardinalità `N <= M`,
l'algoritmo canonico rifiuta ogni campione
maggiore di `floor(M/N)*N` prima di calcolare
il rango con riduzione modulo `N`.

`LegacyBiasedPickAdapter.biasedLegacyPick` riproduce
invece la scorciatoia storica: usa il primo valore
anche fuori dal dominio di accettazione, causando
una scelta di rango distorta quando `M` non è
multiplo di `N`. Il report espone campione,
limite e rango; la discovery non anticipa la
futura PATCH 11. L'oracolo resta test-only.

## PATCH 11 — salto aritmetico del segmento di rifiuto

Lo spazio dei campioni è `[1,M]`, il limite
di accettazione è `L = floor(M/N)*N` e il
segmento rifiutato è precisamente `[L+1,M]`.

Se `X <= L`, il campione è accettato senza
scarto. Se `X > L` e il passo è positivo,
si raggiunge il primo campione accettato `1`
dopo `M-X+1` passi circolari. Se il passo è
negativo, il primo accettato è `L` dopo
`X-L` passi. In ogni caso il rango finale
è `((accettato-1) mod N)+1`.

`Patch11ShortPickWrapper` conserva il report
del vero `LegacyBiasedPickAdapter`; manager,
handler e validator mantengono stato e proprietà
separati per invocazione. Il validator calcola
indipendentemente l'intervallo di rifiuto e
confronta tutti i campi senza chiamare il
wrapper corretto. La prova contro l'oracolo
di test è utilizzata solo dove il numero
di passi è trattabile.

## DISCOVERY 12 — tetto storico errato per la lunghezza dell'anno

`LegacyYearCeilingAdapter.legacyYearMax` prende
un `Vector[Int]` di divari consecutivi e
accetta soltanto i valori in [42,963].
Somma la durata con `BigInt` e usa un minimo
di sei divari, una durata minima di 252
giorni e un tetto volutamente storico di
**5777**. Il predicato canonico indipendente,
definito nei test dalle costanti
`NormativeOracle.YearMaxDays=5778`,
differisce solo al confine incluso.

Tre test differenziali distinguono sei
divari da 963 giorni, sette divari
`963*5 + 900 + 63` e otto divari
`963*5 + 321*3`, sempre in forma di
durata totale 5778. Le costruzioni sono
sintetiche e non pretendono di essere
sequenze di cancelli realmente generate
dalla salsa; misurano il predicato
locale di ammissibilità.

## PATCH 12 — confine inclusivo dell'anno con prova storica

`Patch12YearCeilingWrapper.yearMaxPatch` esegue
l'adapter `LegacyYearCeilingAdapter.legacyYearMax`
con il suo originale limite 5777, poi applica
la norma inclusiva `length <= 5778` insieme
alla condizione di almeno sei divari. Ogni
divario deve appartenere a 42..963 giorni,
con somma calcolata nel dominio BigInt.

Il manager conserva vettore dei divari,
somma, vecchia decisione e nuovo giudizio
in campi distinti del contesto. Un validator
indipendente ricostruisce entrambe le
decisioni, verifica la traccia
BOOT/DISCOVERY/PATCH e rifiuta manipolazioni
del risultato. Nessun oracle test-only entra
nel codice di produzione.

## DISCOVERY 13 — il salto approssimato tra anni

La ricerca canonica avanza dall'anno 5000 secondo
i cancelli selezionati e percorre i confini
contigui `(open, close]`. Il vecchio percorso
`LegacyYearJumpAdapter.oldJumpGuess` stima invece
la posizione usando la divisione del numero di
giorni per **5778**, il solo limite superiore
(normativo) della durata di un anno. Il quoziente
negativo è arrotondato verso meno infinito, dunque
il difetto non nasce dal segno di BigInt ma
dall'assunzione di durate fisse.

Il validator ricostruisce la stima con un algoritmo
indipendente, verifica le durate sintetiche, il
bootstrap, la traccia e la pubblicazione dei confini.
La ricerca sequenziale della norma appare soltanto
nei test e non corregge il codice legacy di questa
DISCOVERY.

## DISCOVERY 14 — selezione virtuale con rango ristretto a Int

`VirtualLegacyListAdapter.oldVirtualGateAt` tratta una famiglia
sintetica non materializzata di indici di cancello con rango
1-based BigInt. L'indice per rango `r` è matematicamente
`firstGateIndex + (r-1)*gateStride`; il legacy applica invece
`r.toInt`, causando wrapping signed sui ranghi alti.
La cardinalità e il passo rimangono BigInt.
Il validator controlla il wrapping con aritmetica modulo 2^32
indipendente dal helper. La traccia è BOOT/DISCOVERY 14.
Non è ancora una implementazione del motore reale dei cancelli.

La run GitHub Actions 38253085873 verifica l'isolamento della
cicatrice virtuale e tutte le 28 suite native fino allo Stage28.
Il significato normativo completo del motore dei cancelli resta da
implementare nei passaggi successivi.

## PATCH 14 — rango BigInt senza materializzare la lista virtuale

La lista diagnostica ha cardinalità `N >= 1`, passo signed
`s != 0`, rango `1 <= r <= N` e primo indice `g`.
Il membro corretto è `g + (r - 1) * s`; non c'è alcun
cast a Int o limite artificiale del rango. L'adapter originale
usa sempre `r.toInt` e il suo valore è pubblicato nel
medesimo report. Il validator ricalcola il narrowing legacy
via modulo 2^32 e controlla l'equazione corretta senza
richiamare il wrapper. I test dell'oracolo sono isolati in
`src/test`. Nessuna lista reale di cancelli viene creata.

Il test di falsificazione ha mostrato che la verifica della sola
equazione `selected-first = step*(rank-1)` non garantisce
l'immutabilità degli input a rango uno, perché il lato destro
rimane zero per ogni passo. La DISCOVERY14 conserva quindi
una fotografia separata `(first, step, count, rank)` e
PATCH14 con validator la confrontano con gli input correnti.
La run 38256237425 (30/30 job) verifica anche questo caso.
