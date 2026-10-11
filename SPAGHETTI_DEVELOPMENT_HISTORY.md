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
