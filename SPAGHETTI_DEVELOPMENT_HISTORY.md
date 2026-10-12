# Storia dello sviluppo del mostro spaghetti

## Stadio 1 — Bootstrap

### Che cosa si pensava

Non esiste ancora alcuna ipotesi legacy specifica. Lo scopo è creare una base indipendente, verificabile e deliberatamente pronta ad accumulare cicatrici senza anticiparle.

### Che cosa si è scoperto

Nessun difetto storico è stato introdotto o scoperto in questo stadio. Il riferimento normativo e il catalogo linguistico sono separati dal percorso di produzione.

### Che cosa è stato aggirato

Nulla. Qualunque aggiramento appartenente alle patch 01–26 sarebbe contaminazione futura e quindi è escluso.

### Perché resta normativamente equivalente

Lo stadio non pretende ancora di fornire il percorso finale del mostro. Il riferimento di test implementa la semantica normativa; la base di produzione è soltanto un'infrastruttura neutrale.

### Strato di mostruosità aggiunto

Sono presenti un contesto per invocazione, un dispatcher a fasi, un validatore, un involucro deterministico degli errori e un guscio di metriche. Nessuno di questi componenti contiene logica specifica di una patch o influenza una decisione normativa.

## Stadio 2 — DISCOVERY 01: il residuo ordinario non è SAVE

### Che cosa si pensava

Un vecchio adattatore aritmetico suppone che il residuo euclideo
`oldRemainder(x) = x mod M`, nell'intervallo `0..M-1`, sia sufficiente
per rappresentare i numeri conservati. Il modulo è `M=2^127-1`.

### Che cosa si è scoperto

Il riferimento normativo di test definisce
`SAVE(x) = 1 + regularMod(x-1, M)`, con immagine `1..M`.
Per `x=M,2M,3M` il vecchio residuo vale zero mentre `SAVE(x)=M`.
Per `x=M+1` entrambi danno uno. La regressione attraversa davvero il manager,
il dispatcher, l'handler e l'adattatore, non un simulatore del percorso attivo.

### Che cosa è stato aggirato

Nulla. Il valore zero viene esposto intatto e il test di equivalenza
fallisce deliberatamente sulle tre molteplicità. Non esiste `savePatch`,
né una sostituzione silenziosa dei valori non conformi.

### Perché non è ancora normativamente equivalente

La congruenza modulo `M` non basta a garantire la rappresentazione
normativa in `1..M`: zero e `M` sono congruenti ma non sono lo stesso
output. Questa divergenza è la specifica cicatrice DISCOVERY 01.

### Strato di mostruosità aggiunto

Nuovi campi semantici propri del contesto, un adattatore legacy,
un handler dedicato, validazione di readiness, uno snapshot di output e
una metrica puramente osservativa. La regressione precedente rimane
separata e lo stesso contesto attraversa Bootstrap e Discovery 01.

### Verifica nativa compiuta

La run GitHub Actions 38151729014, su commit
`4cb63f84d20bebb8a58934b5b2211811276bffc0`, è conclusa
con successo. Scala 2.13.18 ha compilato sia produzione sia test.
I 18 controlli di Bootstrap sono tutti passati. La regressione dedicata
ha registrato esattamente sette PASS e tre FAIL deliberati su M, 2M, 3M,
mentre M+1 è passato. Il job controlla anche il codice d'uscita non nullo
del test rosso. Nessun codice dello stadio 3 è stato introdotto.

## Stadio 3 — PATCH 01: SAVE sopra il residuo storico

### Che cosa si pensava

Il residuo ordinario introdotto in DISCOVERY 01 poteva essere riutilizzato
separando l'identità della classe di congruenza dalla rappresentazione.
La cicatrice `oldRemainder` non deve scomparire.

### Che cosa si è scoperto

`oldRemainder(x)` restituisce sempre l'unico rappresentante `r`
nell'intervallo `0 ≤ r < M`. Il SAVE normativo rappresenta la stessa
classe nell'intervallo `1..M`. Se `r != 0`, i rappresentanti coincidono;
se `r == 0`, il SAVE restituisce necessariamente `M`.
Non occorrono cambiamenti di algoritmo o interpolazioni.

### Che cosa è stato aggirato

Aggiunto `Patch01SaveWrapper.savePatch(x)`: chiama davvero
`LegacyArithmeticAdapter.oldRemainder(x)` e sostituisce soltanto
l'uscita zero con `M`. Il manager esegue la discovery originale
prima della patch nello stesso contesto, registrando entrambi gli
output senza cambiare la funzione legacy.

### Perché è normativamente equivalente

Per ogni intero, incluso uno negativo o arbitrariamente grande,
il residuo euclideo è `r ∈ [0,M-1]`. Se non nullo vale già
`SAVE(x)=r`; se nullo `SAVE(x)=M`. Sono casi esaustivi.
Il test dello stadio 3 confronta il percorso corretto con
l'oracolo test-only su bordi, cicli, interi grandi e campioni deterministici.

### Strato di mostruosità aggiunto

Nuovo wrapper, handler PATCH dedicato, snapshot a doppia uscita,
readiness del contesto, metrica separata, e due percorsi indipendenti:
`discover01Remainder` per il difetto storico ancora osservabile,
`patch01Save` per l'uscita corretta. Stato condiviso fra invocazioni:
nessuno. Correzione futura introdotta: nessuna.

### Verifica nativa compiuta

La GitHub Actions run 38152588729 è conclusa con esito SUCCESS sul commit
`6b87eface71a93b19d5c98b30da7bc3b670d9bff`.
La suite Stage01 ha fornito 18 PASS, 0 FAIL; Stage02 ha conservato
7 PASS, 3 FAIL storici intenzionali, riconosciuti dal job di discovery;
Stage03 ha fornito 12 PASS, 0 FAIL. Anche la verifica del
catalogo canonico è passata. La funzione legacy è rimasta immutata.
Nessuno stadio 4 è stato iniziato.

## Stadio 4 — DISCOVERY 02: il vecchio tag ignora il lato temporale

### Che cosa si pensava
La distanza assoluta da Fondazione, moltiplicata per due, appariva una
numerazione sufficiente. Il modulo legacy calcola esattamente
`oldDayTag(day) = 2*abs(day-FoundationDayOld)`.

### Che cosa si è scoperto
La funzione normativa conta Fondazione come 1, poi il passato in
2,4,... e il futuro in 3,5,... . Il helper antico dà 0 alla Fondazione
e 2,4,... anche al futuro. La regressione distingue due casi anteriori
concordi da tre casi errati `F,F+1,F+2`.

### Che cosa è stato aggirato
Nulla. Nessun wrapper di riparazione è stato introdotto. Il percorso
manager → dispatcher → handler → adapter legge veramente il risultato
storico e lo espone come uscita semantica volutamente RED.

### Perché non è ancora normativamente equivalente
Per ogni giorno alla Fondazione o successivo, l'output è uno meno
dell'etichetta normativa; inoltre i giorni simmetrici collidono.
La riparazione appartiene allo stadio 5 e non può essere anticipata.

### Strato di mostruosità aggiunto
Nuovo adattatore, handler, stato semantico per invocazione, metrica,
validazione, snapshot e regressione RED dedicata. PATCH 01 resta verde,
la sua cicatrice resta osservabile.

### Verifica nativa compiuta

La run GitHub Actions 38153510206 sul commit
`46b58a474899028d686e23f50cf2aa6191a29db4`
è conclusa con SUCCESS. Stage01 18 PASS/0 FAIL;
Stage02 7 PASS/3 FAIL storici intenzionali;
Stage03 12 PASS/0 FAIL;
Stage04 14 PASS/3 FAIL intenzionali.
La regressione DISCOVERY 02 ha mostrato esattamente
`F:1→0`, `F+1:3→2`, `F+2:5→4`,
con due confronti anteriori PASS. Il catalogo canonico resta
bloccato e lo stadio 5 non è stato anticipato.

## Stadio 5 — PATCH 02: correzione additiva del lato temporale

### Che cosa si pensava

Il helper `oldDayTag` già calcolava correttamente la distanza assoluta,
ma perdeva l'informazione del lato temporale. Annullarne la cicatrice
cambiando la formula interna distruggerebbe il percorso di DISCOVERY 02.

### Che cosa si è scoperto

Per `d < F`, il tag legacy vale `2(F-d)`, già uguale a `dayCount(d)`.
Per `d >= F`, il tag legacy vale `2(d-F)`, mentre `dayCount(d)`
vale `2(d-F)+1`. La distanza fra i due risultati è quindi esattamente
0 nel passato e 1 dalla Fondazione in avanti, senza altri casi.

### Che cosa è stato aggirato

Il nuovo `Patch02DayTagWrapper.dayTagPatch` chiama
`LegacyDayTagAdapter.oldDayTag` e aggiunge uno solo nel secondo
ramo. `Patch02DayTagHandler` richiede prima la vera uscita legacy
nello stesso contesto. La via diagnostica di Stage04 resta invariata
e il vecchio valore viene conservato nello snapshot finale.

### Perché è normativamente equivalente

Gli interi sono partizionati in `d<F` e `d>=F`.
In ciascuna parte la formula patched coincide algebricamente
con la definizione normativa di `dayCount`. La dimostrazione
non dipende da limiti di bit; in Scala `BigInt` è illimitato.
La suite test-only confronta il risultato con il riferimento normativo
su bordi, finestre esaustive, campioni deterministici e interi enormi.

### Strato di mostruosità aggiunto

Un wrapper, un handler, due nuovi campi del contesto, un validator
di delta, snapshot immutabile, metrica propria e due percorsi
indipendenti (diagnostico storico e patch verde). Nessuna correzione
futura viene anticipata; PATCH 01 resta intatta.

### Verifica nativa compiuta

GitHub Actions run 38154485765, commit
`0e533d9f91929a01d7da4d44c31501d841bf992e`:
tutti i sei job conclusi con SUCCESS. Stage01 18 PASS/0 FAIL;
Stage02 7 PASS/3 FAIL deliberati; Stage03 12 PASS/0 FAIL;
Stage04 14 PASS/3 FAIL deliberati; Stage05 18 PASS/0 FAIL.
La suite di Stage05 ha verificato 8193 giorni contigui,
512 giorni casuali deterministici, valori oltre 16.000 bit,
stato per invocazione, validazione del delta e la presenza
reale delle cicatrici legacy. Nessun codice Stage06 è presente.

## Stadio 6 — DISCOVERY 03: distanza che perde un giorno

### Che cosa si pensava

La distanza ordinaria fra due giorni `abs(target-calculation)`
sembrava sufficiente per calcolare il contatore di lavoro.
In realtà la funzione conta gli intervalli separatori,
non i giorni inclusi dall'intervallo richiesto.

### Che cosa si è scoperto

La norma `workCounts(c,t).distance` definisce
`abs(t-c)+1`. Per `c=t` deve dare 1, mentre il
helper legacy dà 0; per giorni contigui il risultato
normativo è 2 contro 1; per intervalli giganti
il difetto continua a essere esattamente 1.
Non si tratta di overflow né di scelta della direzione.

### Che cosa è stato aggirato

Nulla. `LegacyDistanceAdapter.oldDistance` restituisce il
valore non corretto intatto, dal manager attraverso un vero
handler del dispatcher. Il test normativo deve fallire
esattamente in tre scenari; non è presente `distancePatch`.

### Perché non è ancora normativamente equivalente

Per ogni coppia di interi `c,t`, il helper legacy
produce uno meno del conteggio normativo inclusivo.
Il difetto è universale e non dipende dal segno dei giorni,
dalla Fondazione o dalla quantità di bit.

### Strato di mostruosità aggiunto

Un adattatore di distanza legacy, handler dedicato,
campo semantico per invocazione, validazione di readiness,
report immutabile, metrica di discovery, test RED di
simmetria, ordine, monotonia, BigInt e regressioni passate.

### Verifica nativa compiuta

La GitHub Actions run 38155138650 ha eseguito Scala nativo sul
commit `c322aa6c8d9de01cf8ec4163ca04c32fe6e30722`.
I sette job sono tutti SUCCESS: Stage01 18 PASS, Stage02
7 PASS/3 FAIL deliberati, Stage03 12 PASS, Stage04
14 PASS/3 FAIL deliberati, Stage05 18 PASS e Stage06
15 PASS/3 FAIL deliberati. Le tre discrepanze della distanza
sono state riscontrate su date identiche, contigue e distanti
oltre 16.000 bit. Non è stata introdotta alcuna PATCH 03.

## Stadio 7 — PATCH 03: distanza inclusiva sopra il numero di intervalli

### Che cosa si pensava

Il helper antico era adatto agli intervalli ma non al conteggio
inclusivo. Sostituirlo direttamente cancellerebbe la cicatrice.

### Che cosa si è scoperto

Per tutti gli interi `c,t`, il helper storico produce
`abs(t-c)` e la norma produce `abs(t-c)+1`.
Lo scarto è quindi sempre uno, anche per giorni identici,
giorni contigui, numeri negativi e interi enormi.

### Che cosa è stato aggirato

Il nuovo wrapper `Patch03DistanceWrapper.distancePatch`
richiama `LegacyDistanceAdapter.oldDistance` senza modificarlo.
Il manager esegue DISCOVERY 03 e PATCH 03 in ordine nello
stesso contesto e produce un report con i due output.

### Perché è normativamente equivalente

Il wrapper aggiunge l'unità mancante alla vera funzione
legacy; l'identità risultante è `abs(t-c)+1` per ogni coppia.
La suite test-only verifica l'equivalenza su 66.049 coppie,
1.024 campioni deterministici e interi oltre 16.000 bit.

### Strato di mostruosità aggiunto

Fase, handler, wrapper, due campi del contesto, readiness,
validazione indipendente del delta, metrica e doppio report.
Le cicatrici precedenti restano direttamente osservabili;
nessun codice dello stadio 8 è introdotto.

### Verifica nativa compiuta

La run GitHub Actions 38155941165 ha compilato ed eseguito
Scala 2.13.18 sul commit
`ba789b7d536091494f4f9000a533dd04344e4bf1`.
Tutti gli otto job sono SUCCESS: Stage01 18 PASS,
Stage02 7 PASS/3 FAIL storici, Stage03 12 PASS,
Stage04 14 PASS/3 FAIL storici, Stage05 18 PASS,
Stage06 15 PASS/3 FAIL storici e Stage07 20 PASS/0 FAIL.
La suite Stage07 ha verificato il percorso reale della patch,
66.049 coppie, 1.024 coppie deterministiche, grandi BigInt,
isolamento e tutte le cicatrici precedenti.
Nessuna logica dello stadio 8 è presente.

## Stadio 8 — DISCOVERY 04: le pietre cambiano mentre vengono lette

### Che cosa si pensava

Aggiornare cinque registri uno dopo l'altro sembrava equivalente
a costruire una nuova riga da quella precedente. Il risultato
si discosta invece dalla norma non appena il secondo registro
legge il primo già aggiornato.

### Che cosa si è scoperto

La norma calcola simultaneamente frumento, orzo, sale, amaro
e rosso sulla base della riga precedente. La ricorrenza
legacy aggiorna i registri in-place: il frumento della riga 2
resta 378, ma l'orzo diventa 1434 anziché 1073 e il sale 3780
anziché 2375. Le differenze si propagano alla riga 3.

### Che cosa è stato aggirato

Nulla. La tabella errata è utilizzata dal vero adattatore,
dal dispatcher e dal manager; gli output non vengono
normalizzati. Nessun wrapper PATCH 04 viene introdotto.

### Perché non è ancora normativamente equivalente

Per la seconda componente della riga 2, la formula legacy usa
il frumento nuovo (378), ma la norma usa quello vecchio (17).
La divergenza non dipende dal modulo, che nei due percorsi
è il medesimo SAVE: nasce dalla proprietà dello stato.

### Strato di mostruosità aggiunto

Un adattatore con registri mutabili locali, handler dedicato,
campo semantico, validazione, report immutabile, metrica e
regressione RED con tre valori normativi esatti. La tabella
storica di 46 righe viene costruita e restituita per invocazione,
conservando tutte le cicatrici e patch precedenti.

### Verifica nativa compiuta

La GitHub Actions run 38157155909 ha compilato ed eseguito
Scala nativo sul commit
`4b4d5b6c11c4d9dc9300fd1cbad84c9def7a0248`.
I nove job sono SUCCESS: Stage01 18 PASS, Stage02 7 PASS/3 FAIL
deliberati, Stage03 12 PASS, Stage04 14 PASS/3 FAIL deliberati,
Stage05 18 PASS, Stage06 15 PASS/3 FAIL deliberati,
Stage07 20 PASS e Stage08 19 PASS/3 FAIL deliberati.

Le tre divergenze sono esattamente:
riga 2, orzo `1073 → 1434`;
riga 2, sale `2375 → 3780`;
riga 3, frumento `146106 → 147189`.
L'audit ha inoltre rilevato che una verifica di metadata della
regressione Stage07 richiedeva ancora `CURRENT_STAGE=7`.
La verifica è stata corretta per continuare a convalidare
la certificazione storica negli stadi successivi,
senza cambiare l'algoritmo del PATCH 03.
Non è stata avviata PATCH 04.

## Stadio 9 — PATCH 04: una riga congelata contro la mutazione sequenziale

### Che cosa si pensava

L'algoritmo legacy aggiornava i cinque registri durante
la costruzione della nuova riga. Le pietre successive
leggevano valori già cambiati e la divergenza aumentava
con ogni nuova riga.

### Che cosa si è scoperto

Il seme comune è `[17,29,43,71,101]`. Il frumento
della seconda riga è uguale in entrambi i percorsi,
ma la sequenza sbagliata usa quel frumento nuovo per
calcolare l'orzo. La norma richiede di usare, per
tutte e cinque le pietre, la riga precedente congelata.

### Che cosa è stato aggirato

`Patch04StonesWrapper.stonesPatch` parte dal vero
risultato di DISCOVERY 04 ma usa solo la sua riga
iniziale e ricostruisce autonomamente ogni riga corretta.
Il percorso diagnostico `discover04Stones` e l'uscita
legacy del percorso `patch04Stones` non vengono modificati.

### Perché è normativamente equivalente

Per induzione sulle 46 righe: la riga 1 coincide col seme
normativo; se la riga precedente coincide, le cinque
formule successive leggono gli stessi valori e usano lo
stesso SAVE, quindi coincidono anch'esse. La verifica
test-only confronta tutti i 230 elementi con l'oracolo.

### Strato di mostruosità aggiunto

Un wrapper di ricostruzione, handler e fase, due nuovi
campi nel contesto, validazione deterministica di output,
report a due tabelle, metrica di PATCH 04, diagnostica
storica e regressioni specifiche per proprietà dello stato.

### Verifica nativa compiuta

La run GitHub Actions 38158857156 ha compilato ed eseguito
Scala nativo sul commit
`bbe7759af121e08f81b18d2b8c0de243741266e7`.
Tutti i dieci job sono SUCCESS: Stage01 18 PASS;
Stage02 7 PASS/3 FAIL deliberati; Stage03 12 PASS;
Stage04 14 PASS/3 FAIL deliberati; Stage05 18 PASS;
Stage06 15 PASS/3 FAIL deliberati; Stage07 20 PASS;
Stage08 19 PASS/3 FAIL deliberati; Stage09 26 PASS/0 FAIL.

La suite Stage09 confronta tutte le 230 pietre con l'oracolo,
dimostra che il wrapper non prende le righe successive
dalla tabella errata, e protegge isolamento, metriche
e percorso del dispatcher. Non è stato avviato lo stadio 10.

## Stadio 10 — DISCOVERY 05: una goccia troppo vicina

### Che cosa si pensava

I ritardi 1, 3 e 7 potevano condividere un accessor,
ma la distanza sette è stata erroneamente risolta
come distanza sei.

### Che cosa si è scoperto

Il primo campione visibile legge normativamente, a
ritardo sette, la goccia nascosta nella posizione -6.
La cicatrice legge -5. Al campione 7 la norma torna
al primo nascosto, mentre la cicatrice legge il primo
visibile. Anche dopo la 46esima goccia permane
lo slittamento.

### Che cosa è stato aggirato

Nessuna correzione è introdotta. L'handler delega
all'autentico `legacyPrior`, conserva il valore
storico in uno snapshot e permette di compararlo
con l'accesso normativo solo nel codice di test.

### Perché non è normativamente equivalente

Per `lag=7` l'indice del risultato è sempre
`i-6`, diverso dall'indice prescritto `i-7`.
I test RED confrontano valori realmente distinti
della sequenza normativa delle gocce, senza
anticipare la futura PATCH 05.

### Strato di mostruosità aggiunto

Helper, handler, fase, cinque campi di stato semantico,
validation, report, metriche e test di confine
e finestre storiche. Le quattro patch precedenti
restano disponibili. ### Verifica nativa compiuta

La run GitHub Actions 38161316033, sul commit
`d462d2afbb4f80eb17a61489b377e9fa3f97ff7b`,
ha concluso con SUCCESS tutti gli undici job.
Stage10 registra 15 PASS e tre divergenze deliberatamente
RED per le gocce 1, 7 e 47. Le patch 01–04 sono rimaste
verdi e gli stadi di discovery conservano le firme storiche.
Una svista di sintassi della lambda Scala nel test BigInt
è stata corretta dopo la prima esecuzione e prima della
certificazione finale; l'adattatore legacy non è cambiato.

## Stadio 11 — PATCH 05: la settima goccia ritorna alla posizione giusta

### Che cosa si pensava

La lettura storica del precedente settimo
prendeva `i-6` per un errore di indice. Sovrascrivere
`legacyPrior` avrebbe distrutto la prova di DISCOVERY 05.

### Che cosa si è scoperto

Gli indici dei precedenti sono definiti dai ritardi
`1,3,7`: per il ritardo 7 servono la posizione
`i-7` e i sette valori nascosti iniziali alle
posizioni `0,-1,...,-6`. Gli altri due ritardi
erano già normativi.

### Che cosa è stato aggirato

`Patch05PriorWrapper.priorPatch` chiama l'accessor
storico e ne preserva il risultato per i ritardi
1 e 3. Soltanto per il ritardo 7 legge il valore
normativo, senza modificare l'accessor originale.
Il manager fa eseguire entrambi gli handler e
conserva entrambi gli output.

### Perché è normativamente equivalente

Per `lag=1,3`, il helper legacy coincide già
con il riferimento e il wrapper non lo cambia.
Per `lag=7` il wrapper consulta l'indice
`i-7` esplicitamente. Questi sono tutti i
ritardi ammessi e coprono ogni `i ∈ [1,47]`.
Le prove di test comparano le letture con le
finestre normative e con campioni interi enormi.

### Strato di mostruosità aggiunto

Wrapper, handler, fase, due campi nel contesto,
validator indipendente per i due output, report
doppio e metrica di patch. Tutte le cicatrici e
le patch precedenti restano osservabili.
### Verifica nativa compiuta

La run GitHub Actions 38162946752 ha compilato ed eseguito
Scala nativo sul commit
`47c2d8673650270c4bfec543f50cdd7405460bcd`.
Tutti i dodici job sono SUCCESS: Stage01 18 PASS,
Stage02 7 PASS/3 FAIL deliberati, Stage03 12 PASS,
Stage04 14 PASS/3 FAIL deliberati, Stage05 18 PASS,
Stage06 15 PASS/3 FAIL deliberati, Stage07 20 PASS,
Stage08 19 PASS/3 FAIL deliberati, Stage09 26 PASS,
Stage10 15 PASS/3 FAIL deliberati e Stage11
27 PASS senza errori.

Sono stati verificati sia il vero percorso legacy sia
il PATCH 05, tutte le 47 finestre dei tre ritardi,
512 campioni deterministici, grandi interi, invarianti
di ownership e validazione indipendente. Il helper
`legacyPrior` rimane immutato.

## Stadio 12 — DISCOVERY 06: un sentinel davanti alle undici macinature

### Che cosa si pensava

Aggiungere un record iniziale di sentinella a una
tabella di undici regole sembrava innocuo. Il lettore
continuava però a tradurre il numero di macinatura
nell'indice `step-1`, valido soltanto senza sentinel.

### Che cosa si è scoperto

La prima macinatura legge coefficienti tutti zero
invece della regola `(3,5,7,11,Wheat)`.
Ogni passo successivo usa la regola precedente;
l'undicesima regola corretta non è mai letta.
Con dati di prova `oldValue=7`, precedenti
`11,13,17` e pietre `19,23,29,31,37`,
il primo calcolo dà 68 anziché 422.

### Che cosa è stato aggirato

Nulla. `LegacyGrindTableAdapter.legacyGrind`
usa realmente il catalogo con sentinel ed esegue
l'aritmetica, mentre il dispatcher e l'handler
conservano regola e risultato nel report.
Non è presente un wrapper che corregga l'indice.

### Perché non è normativamente equivalente

Per la macinatura numerata `step` la norma
usa la regola al posto `step` della tabella con
sentinel, ma l'implementazione legacy legge
il posto `step-1`. La differenza è evidente
nei tre confronti normativi intenzionalmente RED
ai passi 1, 6 e 11.

### Strato di mostruosità aggiunto

Catalogo di dodici record con sentinel, funzione
di lookup sbagliata, calcolo legacy reale, handler,
otto campi del contesto, validazione e report,
metrica specifica e suite di regressione.
Le cinque patch precedenti restano invariate.
### Verifica nativa compiuta

La run GitHub Actions 38164763029 ha compilato ed eseguito
Scala nativo sul commit
`58caeee944b2987f344bbb69db93c236e39b5a0f`.
Tutti i tredici job sono SUCCESS: Stage01 18 PASS;
Stage02 7 PASS/3 FAIL deliberati; Stage03 12 PASS;
Stage04 14 PASS/3 FAIL deliberati; Stage05 18 PASS;
Stage06 15 PASS/3 FAIL deliberati; Stage07 20 PASS;
Stage08 19 PASS/3 FAIL deliberati; Stage09 26 PASS;
Stage10 15 PASS/3 FAIL deliberati; Stage11 27 PASS;
Stage12 22 PASS/3 FAIL deliberati.

Le tre divergenze della formula di macinatura sono
`422 → 68`, `1188 → 1002` e `2136 → 1974`,
rispettivamente per i passi 1, 6 e 11. Il risultato
della discovery è stato osservato dal vero manager e
dal dispatcher; le cinque patch precedenti continuano
a funzionare. Nessuna correzione è stata anticipata.

## Stadio 13 — PATCH 06: il sentinel resta, l'indice torna esatto

### Che cosa si pensava

La tabella a dodici record aggiungeva una sentinella
prima delle undici macinature, ma il helper storico
continuava a leggere l'indice `step-1`.
Rimuovere il sentinel o riscrivere la lookup originaria
avrebbe distrutto la traccia della DISCOVERY 06.

### Che cosa si è scoperto

Tutte le undici regole normative sono già memorizzate
alla posizione `step`, mentre `legacyGrindRule`
legge `step-1`. La formula quadratica e SAVE
funzionano correttamente; si deve correggere
soltanto la selezione del record usato nel calcolo.

### Che cosa è stato aggirato

Il wrapper `Patch06GrindWrapper.grindPatch` esegue
il vero helper `legacyGrind`, ottiene poi la
regola `GRIND_TABLE_WITH_SENTINEL(step)` e
ricalcola l'uscita. Il manager attraversa
DISCOVERY 06 e PATCH 06 nella medesima invocazione,
conservando il report legacy e il report patched.

### Perché è normativamente equivalente

Per ogni `step ∈ [1,11]`, il record di indice
`step` contiene esattamente i coefficienti e
la pietra normativi. Il wrapper usa la stessa
espressione quadratica e la stessa rappresentazione
SAVE verificata in PATCH 01. I test confrontano
tutti gli undici passi, campioni signed, valori
oltre 16.000 bit e bordi con la tabella test-only.

### Strato di mostruosità aggiunto

Wrapper, handler, flag, due output del contesto,
report immutabile a quattro valori, metrica
separata e validadore indipendente con le due
formule. Restano osservabili tutte le sei
cicatrici precedenti, le cinque patch già concluse
e il sentinel originale.

### Verifica nativa compiuta

La GitHub Actions run 38165345584, commit
`53f35b0bd633cd77b9efd2c9bad052fbf24d78b2`,
è conclusa con SUCCESS per tutti i quattordici job.
Stage13 ha superato 26 controlli senza errori.
Stage12 mantiene esattamente 22 PASS e 3 FAIL intenzionali;
tutte le regressioni storiche dal primo stadio sono verdi
rispetto alle proprie firme previste.

Sono stati confrontati tutti gli undici record corretti,
più di 2600 piccoli input signed, 512 campioni
deterministici, interi oltre 16.000 bit, gli invarianti
di stato e l'accesso diagnostico reale alla cicatrice.
L'oracolo non entra nel codice di produzione.


## Stadio 14 — DISCOVERY 07: il rango diventa un indice

### Che cosa si pensava

L'algoritmo riceveva un rango numerato da uno ma
lo trattava come indice di un elenco numerato da zero.
Applicando `rank % 720`, tutti gli ordini vengono
ciclati di una posizione.

### Che cosa si è scoperto

Il rango normativo 1 dà `[1,2,3,4,5,6]`,
mentre la cicatrice dà `[1,2,3,4,6,5]`.
Il rango normativo 720 dà `[6,5,4,3,2,1]`,
mentre il legacy riavvolge a `[1,2,3,4,5,6]`.
La tabella delle permutazioni non perde elementi,
ma è mappata ai ranghi sbagliati.

### Che cosa è stato aggirato

Nulla. Il vecchio algoritmo fattoriale è scritto
in produzione e chiamato realmente da un handler,
tramite dispatcher e manager. Gli output errati
restano diagnostici; la PATCH 07 non è anticipata.

### Perché non è normativamente equivalente

Per ogni `r` in `1..720`, il percorso legacy
sceglie l'indice `r mod 720` dove la norma
richiede `r-1`. I 720 ranghi sono tutti verificati
contro l'oracolo test-only, e tre confronti
indipendenti ne costituiscono la firma RED.

### Strato di mostruosità aggiunto

Decomposizione fattoriale legacy, handler di discovery,
fase del dispatcher, due campi nuovi del contesto,
validazione, report immutabile e contatore;
nessuna mutazione del catalogo delle lingue.
### Verifica nativa compiuta

La run 38166231716, sul commit
`209bd05ce484eb1b128e26a0959a8c80a3c3c832`,
è SUCCESS in tutti i quindici job Scala e blocco nomi.
Stage14 registra 20 PASS e 3 FAIL voluti: i ranghi
1, 2 e 720 non coincidono con la norma. La suite
ha controllato esaustivamente l'insieme delle 720
permutazioni e 1.024 campioni deterministici, mentre
le sei patch precedenti e tutte le firme storiche
delle discovery sono rimaste integre.
Nessuna PATCH 07 è stata introdotta.

## Stadio 15 — PATCH 07: il rango riacquista la prima posizione

### Che cosa si pensava

Il helper storico riceve un rango fra 1 e 720 e
ne calcola la permutazione trattandolo come indice
zero-based. Correggere direttamente `oldPermutationUnrank0`
avrebbe annullato la prova della DISCOVERY 07.

### Che cosa si è scoperto

Le 720 permutazioni sono già costruite correttamente.
L'unico errore è la corrispondenza dal rango all'indice:
per l'ingresso storico `r` esce la permutazione
normativa `r+1`, con ciclo all'ultimo rango.

### Che cosa è stato aggirato

La PATCH 07 chiama il vero algoritmo storico e
poi lo usa nuovamente con rango `r-1`, oppure 720
se il rango chiesto è 1. Vengono preservati
l'output vecchio, l'output patched, il flag e la
traccia delle tre fasi nel medesimo contesto.

### Perché è normativamente equivalente

Per ogni rango in `1..720`, la mappa corretta
del wrapper richiede esattamente l'indice `r-1`,
quindi il helper produce la permutazione desiderata.
La suite verifica la famiglia completa, i bordi,
l'inversione indipendente dei ranghi, 2048 campioni
deterministici e tutte le sei patch precedenti.

### Strato di mostruosità aggiunto

Un wrapper, un handler, due campi nel contesto,
un report doppio, una metrica, validazione fattoriale
autonoma e la suite nativa dello stadio 15.
La cicatrice di Stage14 conserva la propria firma
`20 PASS, 3 FAIL` intenzionali. La logica di
Stage16 non è stata introdotta.

### Verifica nativa compiuta

La GitHub Actions run 38166893216, commit
`2ad0799b04fb9f5598d962882050c44d1d9abd5a`,
ha completato con SUCCESS i sedici job. Stage15
ha ottenuto 31 PASS e zero FAIL. Il riferimento
normativo è stato controllato contro la PATCH
per tutti i 720 ranghi, con verifica anche del rango
inverso, delle transizioni lessicografiche, di 2048
campioni deterministici, di giorni BigInt enormi e
dell'ownership delle invocazioni.

Stage14 conserva la cicatrice: 20 PASS e tre FAIL
voluti per i ranghi 1, 2, 720. Gli altri
stadi storici hanno mantenuto ciascuno la
propria firma predefinita. Nessun codice di
Stage16 è stato introdotto.

## Stadio 16 — DISCOVERY 08: sei ciotole, un solo array

### Che cosa si pensava

Risparmiare una copia del registro di sei ciotole
sembrava innocuo perché i getti erano già pronti.
Tuttavia le sei equazioni normative devono leggere
tutte la stessa istantanea dei valori precedenti.

### Che cosa si è scoperto

L'errore non è nella permutazione (già riparata
in PATCH 07) né in SAVE (PATCH 01): il ciclo
assegna `old` e `next` alla stessa memoria.
Dopo ogni posizione, le seguenti leggono
parte dei valori già aggiornati.

### Che cosa è stato aggirato

Nulla. Il helper storico rimane intenzionalmente
difettoso; manager, handler, validator e report
mostrano il percorso reale e i valori legacy.

### Perché non è normativamente equivalente

La formula delle sei nuove ciotole deve usare
esclusivamente sei valori congelati. L'alias
trasforma la ricorrenza simultanea in una
sequenziale dipendente dall'ordine. Sono registrati
tre fallimenti intenzionali in ordini e passi distinti.

### Strato di mostruosità aggiunto

Array mutabile locale alias, output immutabili,
nuova fase nel dispatcher, otto campi del contesto,
handler e metrica, report e suite di regressione.
Tutte e sette le patch già certificate rimangono.
Non è ancora introdotta la futura PATCH 08.

### Verifica nativa compiuta

La run GitHub Actions 38170838806, sul commit
`1e2ffa32651f1f280853e1592f8aaa16086040ad`,
è terminata con SUCCESS in tutti i 17 job.
Stage16 ha registrato 25 PASS e precisamente tre FAIL
deliberati per i tre confronti normativi: ordine
diretto, ordine inverso e goccia 46.

Il test ha verificato anche tutti i 720 ranghi
dell'ordine delle ciotole con la PATCH 07 attiva,
256 simulazioni storiche indipendenti, BigInt signed,
input non validi, report isolati, metriche e
le sette patch precedenti. Le firme storiche
degli stadi 1–15 rimangono invariate e non è
stata introdotta la PATCH 08.

## Stadio 17 — PATCH 08: il vecchio registro non cambia più

### Che cosa si pensava

Le sei equazioni di mescolatura sembravano poter
condividere un registro in memoria. Ma la semantica
normativa è simultanea: ogni nuova ciotola dipende
soltanto dalle sei vecchie, mai da una nuova.

### Che cosa si è scoperto

Il codice legacy e i suoi getti erano già diagnostici
e i ranghi erano stati corretti in PATCH 07. Il solo
difetto da aggirare era la sovrascrittura in-place.

### Che cosa è stato aggirato

Il wrapper attraversa davvero il helper legacy,
poi scrive i risultati in un registro separato,
leggendo esclusivamente dal Vector originale.
Il manager conserva sia l'uscita alias sia
l'uscita congelata nello stesso report.

### Perché è normativamente equivalente

Le sei equazioni usano ciascuna `old` della stessa
istantanea, i getti precedenti alla mutazione,
lo stesso rango normativo e SAVE corretto.
Il validator calcola la ricorrenza in modo
indipendente e la suite copre 720 ranghi,
46 gocce concatenate, 512 campioni casuali
e BigInt oltre 16.000 bit.

### Strato di mostruosità aggiunto

Wrapper, handler, fase, due campi di contesto,
report doppio, metrica e validator frozen indipendente.
La cicatrice di Stage16 e le sette patch precedenti
rimangono osservabili. Stage18 non è iniziato.

### Verifica nativa compiuta

La run GitHub Actions 38171645454, commit
`993e96370f2e2f236efd0346edbbb4ff1a8d74bc`,
è terminata con SUCCESS per tutti e diciotto i job.
Stage17 ha ottenuto 31 PASS senza errori, verificando
la mescolatura normativamente corretta per tutti i
720 ordini, le 46 gocce concatenate, 512 campioni
deterministici signed, grandi interi, input malformati,
ownership e validazione indipendente.

Stage16 mantiene esattamente 25 PASS e tre FAIL
intenzionali: ordine diretto, ordine inverso e
goccia 46. Le sette patch precedenti restano
intatte e non si è anticipato lo Stage18.

## Stadio 18 — DISCOVERY 09: dodici giri sul caveau del passato

### Che cosa si pensava

Il caveau originale delle sei ciotole veniva
conservato per il controllo diagnostico. Il ciclo
di dodici mescolature leggeva però sempre proprio
questo caveau iniziale, dimenticando di usare
l'uscita pubblicata dal giro precedente.

### Che cosa si è scoperto

Il primo giro è normativo: stesso SAVE, stessa
permutazione e stesse sei equazioni. Dal secondo
giro le somme, i ranghi e tutte le uscite
seguono un riferimento temporale obsoleto.
Questo errore è distinto dal vecchio aliasing
della DISCOVERY 08, già corretto dalla PATCH 08.

### Che cosa è stato aggirato

Nulla. L'helper storico conserva espressamente
`val vaultOld = initial` e legge quell'istantanea
in ognuno dei dodici giri. Dispatcher e manager
lo eseguono veramente, archiviando tutte le
istantanee per la diagnosi.

### Perché non è normativamente equivalente

Il riferimento normativo aggiorna il vecchio
caveau dopo ogni mescolatura. Tre confronti
separati, con sei ciotole ordinarie, uguali
e signed, devono fallire intenzionalmente.

### Strato di mostruosità aggiunto

Dodici record immutabili, ciclo di mescolatura
completo, handler, dispatcher, campi nel contesto,
metrica, validatore, report e suite RED dedicata.
Le otto patch precedenti restano verificabili.

### Certificazione nativa della discovery

GitHub Actions run 38180656627 è terminata
con SUCCESS per tutti i diciannove job sul commit
`7b2c7892873ed7a986ea7fbbfa8572763cfccd91`.
La prova Scala Stage18 ha eseguito 27 controlli
verdi e precisamente tre confronti rossi intenzionali
(ordinario, simmetrico, signed). Sono conservate tutte
le firme storiche da Stage01 a Stage17; il catalogo
canonico è rimasto bloccato e nessuna PATCH 09
è stata anticipata.

## Stadio 19 — PATCH 09: il caveau ricorda il giro precedente

### Che cosa si pensava

Il vecchio caveau doveva restare disponibile
come traccia diagnostica, ma il suo Vector
veniva riutilizzato in tutte le dodici
mescolature finali. L'assenza di un avanzamento
temporale non è un semplice errore d'indice.

### Che cosa si è scoperto

Il primo giro è corretto e perciò può trarre
in inganno. Nei giri 2..12 cambia la somma SAVE,
e da essa possono cambiare anche rango, ordine
delle sei ciotole e tutte le uscite.

### Che cosa è stato aggirato

Il wrapper attraversa la cicatrice originale,
archivia tutti e dodici i record legacy e
ricomputa dodici record normativi usando
l'uscita completa del giro precedente.

### Perché è normativamente equivalente

La somma al giro N usa le sei ciotole del giro
N-1; il ranghi sono quelli normativi PATCH 07,
SAVE resta quello della PATCH 01 e ogni giro
calcola le sei equazioni da una sola istantanea,
come PATCH 08. Un validator indipendente
certifica ciascun record e l'ultimo vettore.

### Strato di mostruosità aggiunto

Wrapper, report doppio da ventiquattro righe,
handler, nuova fase, tre campi del contesto,
metrica, validator e suite dedicata. La
DISCOVERY 09 continua ad esibire esattamente
tre FAIL intenzionali; nessun Stage20 anticipato.

### Certificazione nativa compiuta

La run GitHub Actions 38181781612, sul commit
`06d290255c849ad15069606d6e65fd9c31c58112`,
ha concluso SUCCESS nei 20 job. La PATCH 09
ha 37 PASS e zero FAIL; i dodici giri consecutivi
coincidono con il riferimento normativo indipendente.
La cicatrice originale dello Stage18 continua
a generare i tre FAIL intenzionali previsti,
senza alterare le altre otto patch storiche.

## Stadio 20 — DISCOVERY 10: il fermaglio arrivò una goccia troppo presto

### Che cosa si pensava

Il fermaglio di memoria del quarantaseiesimo
ordine doveva conservarsi attraverso i dodici
giri finali del caveau e le interrogazioni
successive, senza utilizzare il loro nuovo
ordine di mescolatura.

### Che cosa si è scoperto

Un percorso legacy prende invece la
permutazione del quarantacinquesimo giro:
la scelta del rango è corretta, ma il
momento della fotografia non lo è.
Quando i due ordini coincidono il difetto
non è osservabile; occorrono confronti
mirati con ordini diversi.

### Che cosa è stato aggirato

Nulla nella fase DISCOVERY. L'helper storico
è realmente invocato, registra i due
ordini e sceglie il vicino secondo il
primo, documentando la cicatrice precisa.

### Perché non è normativamente equivalente

Il prossimo ID della ciotola dipende dalla
posizione del suo identificatore **nel vero
ordine della goccia 46**. Tre confronti
indipendenti devono quindi fallire per
la scelta legacy, mentre le prove di
unranking e le nove patch precedenti
devono restare verdi.

### Strato di mostruosità aggiunto

Handler, report, validator, tre risultati
di contesto, dispatcher, metrica e test
differenziali. Non viene avviata PATCH 10.

### Risultato della verifica nativa

La run GitHub Actions 38212623612 sul commit
`8dd1253520bccfb5a51fe1a1d08afa3a43c41d26`
ha concluso SUCCESS in tutti i ventuno job.
La firma della DISCOVERY 10 è precisamente
26 PASS, 3 FAIL intenzionali (ordine diretto,
ordine inverso, giro finale); nessun altro
controllo è rosso. La cicatrice del
quarantacinquesimo ordine resta verificabile,
mentre tutte le nove patch precedenti
e i certificati Stage01–Stage19 restano integri.

## Stadio 21 — PATCH 10: il fermaglio finalmente alla goccia 46

### Che cosa si pensava

La permutazione giusta veniva già calcolata
nella discovery, ma il vecchio fermaglio
continuava a prendere quella precedente.

### Che cosa si è scoperto

Il bug cambia il successore ciclico di una
ciotola anche quando le sei ciotole e le dodici
mescolature successive sono corrette.
È una perdita dell'ordine storico, non una
corruzione dei valori delle ciotole.

### Che cosa è stato aggirato

Il wrapper attraversa davvero il vecchio
latch, lo registra e ne conserva il risultato
sbagliato. Successivamente aggancia
l'ordine 46 normativo dalla PATCH 07 e
interroga il vicino su quel Vector immutabile.

### Perché è normativamente equivalente

Il validator rifà indipendentemente
l'unranking fattoriale di entrambe le
permutazioni; i test confrontano il successore
con l'oracolo che conserva l'ordine 46 anche
dopo le dodici mescolature. Il difetto
Stage20 resta riproducibile e rosso.

### Strato di mostruosità aggiunto

Wrapper, handler, report storico/corretto,
validator autonomo, metrica, tre campi nel
contesto e nuovo passaggio di fase. Nessun
codice Stage22 viene anticipato.

### Certificazione eseguita

La run 38222151847 del commit
`3b3c6f7d4a6d8d861f18d293582a63ae6d2f79c1`
si è conclusa con SUCCESS per 22 job su 22.
La PATCH 10 ha superato 40 controlli senza
alcun errore: i successori calcolati dal vero
ordine 46 sono normativi, mentre il vecchio
latch della goccia 45 resta eseguito e
diagnosticato. Lo Stage20 continua ad avere
esattamente tre confronti rossi intenzionali
e tutte le firme precedenti sono invariate.

## Stadio 22 — DISCOVERY 11: un resto preso troppo presto

### Che cosa si pensava

Bastava ricondurre la prima risposta del flusso
fra 1 e N. Per quasi tutti i campioni piccoli
questo sembra equivalente alla regola normativa.

### Che cosa si è scoperto

L'intervallo dei valori possibili ha lunghezza
M. Se N non divide M, il calcolo del semplice
resto privilegia alcuni ranghi. La normativa
esige di rifiutare il tratto finale oltre
`floor(M/N)*N` e proseguire nel flusso.

### Che cosa è stato aggirato

Nulla nella discovery: l'adapter legacy
preserva il calcolo distorto, insieme al
campione e alla soglia di accettazione.

### Perché non è normativamente equivalente

Tre casi di frontiera rendono osservabile
la divergenza: ultimo campione con direzione
positiva, ultimo campione con direzione
negativa e penultimo campione con direzione
negativa. In tutti e tre cambia il rango.

### Strato di mostruosità aggiunto

Helper, handler, report, registrazioni
nel contesto, metrica, validator autonomo
e test dedicati. Le dieci patch esistenti
rimangono intatte; PATCH 11 non anticipata.

### Certificazione native Stage22

La run GitHub Actions 38228272450, sul commit
`13fe8d60508dd4804372f73d2cb340918e2faa5d`,
ha concluso SUCCESS in tutti i 23 job.
La firma verificata della DISCOVERY 11 è
34 PASS e precisamente tre FAIL intenzionali
(positiva, negativa, soglia); le firme
Stage01–Stage21 restano tutte intatte.
Non è stata introdotta la correzione della PATCH 11.

## Stadio 23 — PATCH 11: lo scarto giusto senza miliardi di passi

### Che cosa si pensava

La prima risposta del flusso sembrava già
un rango sufficientemente casuale, quindi
il vecchio adapter prendeva subito il resto.

### Che cosa si è scoperto

Il resto introduce un bias se N non divide M.
La norma impone il rifiuto della coda finale
del dominio dei campioni, e l'avanzamento
circolare fino a un campione valido.

### Che cosa è stato aggirato

La patch esegue davvero la selezione legacy,
ne conserva la prova e calcola il primo
campione ammissibile. Poiché i campioni
vietati sono contigui, il numero di passi
può essere calcolato esattamente senza
eseguirli uno ad uno.

### Perché è normativamente equivalente

I campioni ammessi non cambiano.
Per un campione vietato, un passo positivo
porta infine a 1, un passo negativo al
limite ammesso. Le prove exhaustive sui
720 valori piccoli di N confrontano ogni
rango con l'oracolo; valori BigInt molto
grandi controllano la scorciatoia esatta.

### Strato di mostruosità aggiunto

Wrapper, handler, report con entrambi i
ranghi e campioni, contatore BigInt degli
scarti, validator indipendente, campi nel
contesto e metrica. Stage22 rimane
intenzionalmente rosso con tre divergenze.

### Certificazione nativa con prove storiche conservate

La run GitHub Actions 38232681790, commit
`64545b94fbccc90f74faedf658b68e022ea14a54`,
si è conclusa SUCCESS in tutti i 24 job.
La PATCH 11 ha superato 42 verifiche senza
alcun FAIL; la cicatrice Stage22 resta RED
con 34 PASS e tre divergenze intenzionali.
Tutti i certificati e le regressioni anteriori
sono stati preservati senza introdurre Stage24.

## Stadio 24 — DISCOVERY 12: un anno di un giorno troppo corto

### Che cosa si pensava

La durata massima dell'anno sembrava fermarsi
a 5777 giorni. La maggior parte delle candidate
valide continuava a passare inosservata.

### Che cosa si è scoperto

Il tetto normativo è **5778**, inclusivo.
Con sei cancelli consecutivi ognuno dei
sei divari può essere lungo esattamente 963
giorni, per un totale di 5778. Anche
partizioni di sette e otto divari possono
raggiungere la stessa durata.

### Che cosa è stato aggirato

Nulla nella discovery: l'helper storico
resta genuinamente errato, esponendo
l'intero vettore dei divari, il suo totale
e il verdetto di un anno troppo breve.

### Perché non è normativamente equivalente

Tre confronti su strutture di sei, sette
e otto divari raggiungono esattamente
la durata canonica 5778 e falliscono
deliberatamente solo per l'ultimo giorno.

### Strato di mostruosità aggiunto

Adapter, handler, manager, validator,
quattro valori diagnostici nel contesto,
metrica e una suite di prove indipendenti.
PATCH 12 non è anticipata; Stage23 resta GREEN.
