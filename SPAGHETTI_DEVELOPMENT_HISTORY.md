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
la sua cicatrice resta osservabile. La certificazione della nuova run
nativa è ancora da acquisire.
