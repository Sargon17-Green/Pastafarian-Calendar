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

La verifica nativa deve confermare la firma esatta di tre fallimenti
deliberati; l'esecuzione non è ancora certificata da questa registrazione.
