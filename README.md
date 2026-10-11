# Calendario pastafariano — linea Scala + italiano

Questo albero nasce da zero per la linea indipendente `Scala + italiano`. Il primo stadio contiene soltanto il catalogo linguistico canonico, un riferimento normativo destinato ai test e una base architetturale neutrale per la futura crescita del mostro.

## Regole della linea

- Tutto il codice eseguibile della linea è Scala.
- Il riferimento normativo di test deriva direttamente dal riferimento incorporato nel prompt di progetto.
- Il codice di produzione non chiama mai il riferimento normativo.
- Nessun risultato, fixture, hash, tabella o log di un'altra implementazione è usato come fonte di verità.
- Il catalogo italiano è indicizzato da `canonicalIndex`; il testo localizzato non partecipa a ranking, unranking, chiavi semantiche o ordinamento normativo.
- Nel primo stadio non esisteva alcuna cicatrice legacy né alcuna patch; gli stadi successivi accumulano le cicatrici storiche in ordine.

## Struttura

- `src/main/scala/pastafari/catalog/SourceLanguageCatalog.scala`: catalogo italiano immutabile.
- `src/main/scala/pastafari/monster/BaseMonster.scala`: infrastruttura neutrale di contesto, dispatcher, validazione, errori e metriche.
- `src/test/scala/pastafari/oracle/NormativeOracle.scala`: riferimento normativo test-only.
- `src/test/scala/pastafari/Stage01Tests.scala`: harness senza framework esterno.
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`: storia accumulata, limitata a ciò che è realmente avvenuto.

## Esecuzione

Con Scala 2.13.18 e sbt disponibili:

```text
sbt "Test / run"
```

In alternativa si possono compilare i file Scala con `scalac` e avviare `pastafari.Stage01Tests` con `scala`.

## Stadio 2 — DISCOVERY 01 (non corretto)

L'adattatore aritmetico di produzione introduce volutamente `oldRemainder(x)`,
residuo euclideo ordinario modulo `2^127-1`. Questo residuo restituisce zero
sui multipli del modulo, mentre il `SAVE` normativo restituisce il modulo stesso.
Il percorso attivo è `BaseMonsterManager.discover01Remainder` →
`BaseMonsterDispatcher` → `Discovery01RemainderHandler` →
`LegacyArithmeticAdapter`. Ogni invocazione ha uno stato autonomo.

Per verificare la regressione volutamente rossa:

```text
sbt -batch 'Test / runMain pastafari.Stage02Tests'
```

L'esito corretto dello stadio è `7 PASS, 3 FAIL`, con processo non-zero per
`SAVE(M)`, `SAVE(2M)`, `SAVE(3M)`; `SAVE(M+1)` deve passare.
Il job `native-stage02-discovery` tratta *solo questa precisa firma*
come discovery attesa, non accetta errori di compilazione o guasti inattesi.
Il test del Bootstrap continua a dover passare autonomamente.
Nello stadio 2 non era presente alcun `savePatch`; dopo lo stadio 3 il diagnostico storico continua a esporre il valore zero.

## Prova nativa verificata

Lo stadio 2 è stato compilato ed eseguito su GitHub Actions con Java 17
e Scala 2.13.18, commit `4cb63f84d20bebb8a58934b5b2211811276bffc0`.
La [run 38151729014](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151729014)
è conclusa con successo: `native-stage01` 18 PASS, 0 FAIL;
`native-stage02-discovery` 7 PASS, 3 FAIL intenzionali;
`verify` PASS. Il job di discovery controlla la firma degli errori
invece di scambiare il rosso normativo per un guasto accidentale.

## Stadio 3 — PATCH 01 (SAVE sopra il residuo legacy)

La cicatrice `LegacyArithmeticAdapter.oldRemainder` resta immutata.
`Patch01SaveWrapper.savePatch` la richiama direttamente, conserva ogni
residuo non nullo e converte soltanto lo zero in `M = 2^127-1`.

Il percorso semantico `BaseMonsterManager.patch01Save` attraversa
`BOOT → DISCOVERY_01_REMAINDER → PATCH_01_SAVE` nel medesimo contesto.
Il report conserva simultaneamente il risultato legacy, il valore patched e
la traccia dei due handler. `discover01Remainder` resta una diagnosi reale
del comportamento vecchio, non una simulazione.

Comandi autonomi:

```text
sbt -batch 'Test / runMain pastafari.Stage01Tests'
sbt -batch 'Test / runMain pastafari.Stage02Tests'
sbt -batch 'Test / runMain pastafari.Stage03Tests'
```

La regressione storica Stage02 continua a produrre esattamente
`7 PASS, 3 FAIL` intenzionali. Stage03 deve produrre `12 PASS, 0 FAIL`.
Il job CI Stage02 riconosce solo la firma storica corretta; Stage03
richiede uscita zero. Il job Stage01 resta indipendente.

### Verifica nativa dello stadio 3

La [run 38152588729](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152588729),
commit `6b87eface71a93b19d5c98b30da7bc3b670d9bff`, si è conclusa
con `success`: Stage01 18 PASS/0 FAIL, Stage02 7 PASS/3 FAIL storici
previsti, Stage03 12 PASS/0 FAIL, blocco dei nomi canonici PASS.
La modifica della sola documentazione successiva conserva la prova
sul commit di produzione testato; le prove rimangono eseguibili in CI.

## Stadio 4 — DISCOVERY 02 (giorno legacy non corretto)

`LegacyDayTagAdapter.oldDayTag(day)` restituisce `2 * abs(day - F)`,
con `F = -15055671`. Produce lo stesso numero pari sui due lati
di Fondazione, ignorando la distinzione normativa.
Il percorso `BaseMonsterManager.discover02DayTag` → dispatcher →
handler → adapter espone l'uscita errata senza modificarla.

```text
sbt -batch 'Test / runMain pastafari.Stage04Tests'
```

Firma attesa: `14 PASS, 3 FAIL`, precisamente le divergenze
`F`, `F+1`, `F+2` (i due giorni anteriori concordano con la norma).
Il job `native-stage04-discovery` convalida il conteggio e le etichette;
tutti i job preesistenti restano attivi.
Il prossimo stadio introdurrà PATCH 02; qui nessuna correzione è applicata.

### Certificazione della DISCOVERY 02

La [GitHub Actions run 38153510206](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38153510206)
ha compilato ed eseguito in Scala nativo tutte le regressioni:
18/18 del Bootstrap, 7 PASS e 3 FAIL intenzionali di DISCOVERY 01,
12/12 di PATCH 01 e 14 PASS con 3 FAIL intenzionali di DISCOVERY 02.
Il commit di codice verificato è
`46b58a474899028d686e23f50cf2aa6191a29db4`.
La suite di DISCOVERY 02 resta RED per progettazione: è una
prova dell'errore preservato, non un difetto della CI.

## Stadio 5 — PATCH 02: ripristino della numerazione del giorno

Il helper `LegacyDayTagAdapter.oldDayTag(day)` non viene modificato.
La funzione `Patch02DayTagWrapper.dayTagPatch(day)` lo chiama realmente,
e aggiunge **esattamente 1** quando `day >= FoundationDay`, altrimenti
restituisce il valore legacy inalterato.

Il percorso `BaseMonsterManager.patch02DayTag` attraversa
`BOOT → DISCOVERY_02_DAY_TAG → PATCH_02_DAY_TAG` nello stesso contesto.
Il report conserva `legacyTag`, `patchedTag` e la traccia;
`discover02DayTag` continua a esporre il difetto senza correzioni.
Il validatore verifica una seconda volta il delta ammesso senza chiamare
l'oracolo di test.

```text
sbt -batch 'Test / runMain pastafari.Stage05Tests'
```

Stage05 richiede 18 PASS, 0 FAIL e testa 8193 giorni intorno alla Fondazione,
interi oltre 16.000 bit, campioni deterministici, precondizioni del manager,
isolamento tra invocazioni e cicatrici precedenti. Il CI esegue anche tutti
i test nativi dei primi quattro stadi: Stage02 e Stage04 restano RED soltanto
nei tre casi storici previsti per ciascuno.

### Certificazione nativa dello stadio 5

La [GitHub Actions run 38154485765](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154485765)
è conclusa con SUCCESS sul commit
`0e533d9f91929a01d7da4d44c31501d841bf992e`.
Tutti i sei job sono riusciti: blocco dei nomi canonici, Stage01
18 PASS, Stage02 7 PASS con 3 divergenze intenzionali, Stage03
12 PASS, Stage04 14 PASS con 3 divergenze intenzionali e Stage05
18 PASS senza errori. Lo stadio 6 non è stato iniziato.

## Stadio 6 — DISCOVERY 03: distanza esclusiva invece di inclusiva

Il modulo legacy `LegacyDistanceAdapter.oldDistance(c,t)` calcola
`abs(t-c)`: conta gli intervalli fra i due giorni e omette il
primo estremo. La distanza normativa è `abs(t-c)+1`, perché
include entrambi i giorni. Il difetto produce una differenza
di uno per ogni coppia, compresi i giorni coincidenti.

Il manager `discover03Distance(c,t)` percorre
`BOOT → DISCOVERY_03_DISTANCE` nello stesso contesto, passando
per il dispatcher e l'handler dedicato. Il valore legacy viene
restituito senza normalizzazione, con traccia e metriche.
Nessuna patch di distanza è presente in questo stadio.

```text
sbt -batch 'Test / runMain pastafari.Stage06Tests'
```

La firma RED attesa è `15 PASS, 3 FAIL`, con gli unici confronti
normativi volutamente rossi per giorno identico, giorni contigui
e intervallo gigantesco. Il job CI controlla esattamente le tre
etichette oltre al codice d'uscita e al riepilogo. I job 1–5
continuano a funzionare senza modificare i percorsi storici.

### Certificazione nativa dello stadio 6

La [run 38155138650](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155138650)
sul commit `c322aa6c8d9de01cf8ec4163ca04c32fe6e30722`
è conclusa con SUCCESS su sette job: blocco del catalogo, Stage01
18 PASS, Stage02 7 PASS/3 FAIL attesi, Stage03 12 PASS,
Stage04 14 PASS/3 FAIL attesi, Stage05 18 PASS e Stage06
15 PASS/3 FAIL attesi. La firma della DISCOVERY 03 è esattamente
quella inclusiva: stesso giorno, giorni contigui, intervallo enorme.
Non è stata introdotta la riparazione dello stadio 7.

## Stadio 7 — PATCH 03: distanza inclusiva

`Patch03DistanceWrapper.distancePatch(c,t)` richiama realmente
`LegacyDistanceAdapter.oldDistance(c,t)` e aggiunge uno;
la funzione legacy non viene modificata. Il manager attraversa
`BOOT → DISCOVERY_03_DISTANCE → PATCH_03_DISTANCE` nello stesso
contesto e conserva in uno snapshot entrambe le uscite.
La diagnostica `discover03Distance` continua a esporre il difetto.

```text
sbt -batch 'Test / runMain pastafari.Stage07Tests'
```

Attesi `20 PASS, 0 FAIL`; copertura: 66.049 coppie esaustive,
1.024 coppie deterministiche, oltre 16.000 bit, simmetria,
traslazione, isolamento e precondizioni. Le regressioni degli
stadi 1–6 restano attive, compresa la firma rossa storica di Stage06.

### Certificazione nativa dello stadio 7

La [GitHub Actions run 38155941165](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155941165)
è conclusa con SUCCESS sul commit
`ba789b7d536091494f4f9000a533dd04344e4bf1`.
Otto job riusciti: blocco nomi, Stage01 18 PASS/0 FAIL,
Stage02 7 PASS/3 FAIL attesi, Stage03 12 PASS/0 FAIL,
Stage04 14 PASS/3 FAIL attesi, Stage05 18 PASS/0 FAIL,
Stage06 15 PASS/3 FAIL attesi e Stage07 20 PASS/0 FAIL.
Lo stadio 8 non è iniziato.

## Stadio 8 — DISCOVERY 04: mutazione delle pietre nella stessa riga

L'adattatore `LegacyStoneMutationAdapter.mutateStonesWrong`
parte dalle cinque pietre iniziali `[17,29,43,71,101]`.
Per ognuna delle righe 2–46 aggiorna i cinque registri
**uno dopo l'altro**: per l'orzo usa il frumento già aggiornato,
per il sale l'orzo nuovo e così via. La norma richiede invece
che ogni componente usi la precedente riga congelata.

L'operazione esegue il vero percorso
`BaseMonsterManager.discover04Stones → dispatcher → handler →
LegacyStoneMutationAdapter`. Ogni chiamata ha un array locale,
ma il risultato è congelato in `Vector[Vector[BigInt]]`.
La cicatrice è intenzionale e non viene riparata.

```text
sbt -batch 'Test / runMain pastafari.Stage08Tests'
```

Attesa una firma RED esatta `19 PASS, 3 FAIL`, soltanto sui
confronti normativi della riga 2 (orzo, sale) e riga 3
(frumento). Le altre verifiche controllano la ricorrenza
errata, 46 righe, modulo SAVE, assenza di alias, isolamento,
disponibilità delle patch precedenti e mancanza di PATCH 04.

### Certificazione nativa di DISCOVERY 04

La [GitHub Actions run 38157155909](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157155909)
è conclusa con SUCCESS sul commit
`4b4d5b6c11c4d9dc9300fd1cbad84c9def7a0248`.
Nove job riusciti: controllo del catalogo, Stage01 18 PASS,
Stage02 7 PASS/3 FAIL attesi, Stage03 12 PASS,
Stage04 14 PASS/3 FAIL attesi, Stage05 18 PASS,
Stage06 15 PASS/3 FAIL attesi, Stage07 20 PASS e
Stage08 19 PASS/3 FAIL intenzionali.

Valori osservati per le differenze previste:
riga 2 orzo `1073 → 1434`, riga 2 sale `2375 → 3780`,
riga 3 frumento `146106 → 147189`.
È stata resa compatibile con gli stadi successivi anche la
regressione di metadata di Stage07. Nessuna PATCH 04 introdotta.

## Stadio 9 — PATCH 04: cinque pietre dalla riga precedente congelata

Il modulo `LegacyStoneMutationAdapter.mutateStonesWrong` resta
immutato e continua a produrre le discrepanze di DISCOVERY 04.
`Patch04StonesWrapper.stonesPatch` riceve il risultato legacy,
ne preserva la riga iniziale e costruisce 46 righe con
tutti e cinque i componenti letti da un'unica riga precedente
immutabile. Le righe legacy successive non entrano nel calcolo
corretto; rimangono invece nel report per la diagnosi storica.

Il manager esegue realmente
`BOOT → DISCOVERY_04_STONES → PATCH_04_STONES`.
La validazione ricostruisce indipendentemente la tabella patched
e verifica traccia, forme, flag e output. Report e metriche
rimangono di proprietà della singola invocazione.

```text
sbt -batch 'Test / runMain pastafari.Stage09Tests'
```

Sono attesi `26 PASS, 0 FAIL`: confronto integrale di 230
pietre con l'oracolo test-only, ricorrenza di ogni riga,
resistenza alla corruzione delle righe legacy successive,
isolamento, precondizioni e regressioni dei primi otto stadi.

### Certificazione nativa dello stadio 9

La [GitHub Actions run 38158857156](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38158857156)
si è conclusa con SUCCESS sul commit
`bbe7759af121e08f81b18d2b8c0de243741266e7`.
Tutti e dieci i job sono riusciti: blocco del catalogo;
Stage01 18 PASS; Stage02 7 PASS/3 FAIL attesi;
Stage03 12 PASS; Stage04 14 PASS/3 FAIL attesi;
Stage05 18 PASS; Stage06 15 PASS/3 FAIL attesi;
Stage07 20 PASS; Stage08 19 PASS/3 FAIL attesi;
Stage09 26 PASS/0 FAIL.

Sono state verificate tutte le 230 pietre nelle 46 righe.
L'adattatore storico rimane inalterato e il risultato non corretto
resta percorribile nel suo diagnostico. Lo stadio 10 non è iniziato.

## Stadio 10 — DISCOVERY 05: il settimo precedente è indicizzato male

Nel riferimento normativo la goccia visibile `i` consulta
`i-1`, `i-3` e `i-7`. Le sette gocce nascoste
occupano gli indici `0,-1,...,-6`. Il helper storico
`LegacyPriorAdapter.legacyPrior` sbaglia solo la terza
lettura: per `lag=7` consulta la posizione `i-6`.

Il manager `discover05Prior` attraversa davvero
`BOOT → DISCOVERY_05_PRIOR`, con stato di proprietà
della singola chiamata, report immutabile e metrica
non semantica. Riceve la finestra hidden e le sole visibili
già esistenti: è una diagnostica dei precedenti,
**non** una pretesa implementazione completa delle 46 gocce.
Le letture lag 1 e lag 3 continuano a essere normative.

```text
sbt -batch 'Test / runMain pastafari.Stage10Tests'
```

Firma RED attesa: `15 PASS, 3 FAIL`, solo per la
lettura normativa prior7 delle gocce 1, 7 e 47. Il test
controlla anche tutte le 47 finestre sintetiche, BigInt
giganti, input incompleti, ownership e PATCH 01–04.
Nessuna correzione anticipata dello stadio 11.
