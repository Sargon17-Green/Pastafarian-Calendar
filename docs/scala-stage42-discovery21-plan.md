# Stage42 — DISCOVERY21: diagnosi dell'indice del nome della cotoletta

Stato: progettazione iniziale, **non certificato**. Stage41 rimane l'ultimo stadio completato. Non modificare `main`.

## Contratto diagnostico

Dati: intervalli di porte validi (42..963), partizione positiva in 6..17 cotolette, elenco di ID canonici distinti da 1 a 17, offset giornaliero zero-based nell'anno già fissato.

La norma lega il nome alla cotoletta effettiva del giorno: si accumulano le durate dei segmenti e si sceglie l'unica cotoletta con `start <= dayOffset < end`; il suo ID 1-based individua il nome nella lista già scelta. L'adapter storico previsto `oldDayIndexedCutletName` usa erroneamente `dayOffset % cutletCount` per la posizione nel vettore dei nomi. L'errore riguarda solo il ponte nome/giorno, non la selezione delle cotolette, la salsa, né il catalogo congelato.

## Requisiti per la prossima modifica eseguibile

Il manager dovrà invocare un adapter storico isolato, produrre un report con gli input immutabili, nome legacy, indice legacy, versione del catalogo e trace. Il validator indipendente deve ricostruire lo storico senza chiamare l'adapter o l'oracolo test-only. La suite Stage42 deve includere cardinalità 6..17, casi su inizio/fine, ID permutati, BigInt, manager separati, snapshot e tamper.

Casi di divergenza normativa richiesti: un giorno interno alla prima cotoletta; il primo giorno della seconda; il primo giorno della diciassettesima. Devono essere soltanto tre FAIL intenzionali, identificati per etichetta; gli altri test devono essere PASS. Un job CI dedicato deve validare sia le quantità sia le etichette. Non dichiarare Stage42 completato finché la run Native del codice e la run Native del commit documentale non saranno riuscite.

Non anticipare PATCH21. Il riferimento normativo completo rimane fuori dal codice di produzione. Stage40 e Stage41 e tutti i precedenti devono mantenere le firme storiche.
