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
