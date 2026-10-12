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

### Certificazione nativa dello stadio 10

La [run GitHub Actions 38161316033](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38161316033)
si è conclusa con SUCCESS sul commit
`d462d2afbb4f80eb17a61489b377e9fa3f97ff7b`.
Tutti gli undici job sono riusciti: catalogo canonico, Stage01
18 PASS, Stage02 7 PASS/3 FAIL deliberati, Stage03 12 PASS,
Stage04 14 PASS/3 FAIL deliberati, Stage05 18 PASS,
Stage06 15 PASS/3 FAIL deliberati, Stage07 20 PASS,
Stage08 19 PASS/3 FAIL deliberati, Stage09 26 PASS,
Stage10 15 PASS/3 FAIL deliberati.

Il compile iniziale aveva individuato un errore lessicale
nella lambda di un test BigInt, corretto prima della
certificazione senza cambiare il calcolo legacy.

## Stadio 11 — PATCH 05: precedente settimo corretto

`Patch05PriorWrapper.priorPatch` chiama realmente il helper
`LegacyPriorAdapter.legacyPrior`. Ai ritardi 1 e 3
restituisce l'uscita legacy senza modificarla; al ritardo
7 ricava la goccia in `i-7` dalle sette nascoste
o dalla porzione visibile già disponibile. La cicatrice
storica `i-6` resta intatta e verificabile da
`discover05Prior`.

Il percorso `BaseMonsterManager.patch05Prior` attraversa
`BOOT → DISCOVERY_05_PRIOR → PATCH_05_PRIOR` nella
stessa invocazione. Il report immutabile conserva sia
`legacyValue` sia `patchedValue`; il validatore
confronta autonomamente l'indice normativo e quello
legacy con i due valori presenti, oltre a traccia,
ownership e precondizioni.

```text
sbt -batch 'Test / runMain pastafari.Stage11Tests'
```

Firma attesa: `27 PASS, 0 FAIL`. La suite verifica
tutti e tre i ritardi sulle 47 finestre sintetiche,
tutti e tre sui valori reali delle gocce normative,
i tre casi RED storici, BigInt oltre 16.000 bit,
512 campioni deterministici, input invalidi,
isolamento e le quattro patch precedenti. Stage10
resta volutamente RED. Non è anticipato lo stadio 12.

### Certificazione nativa dello stadio 11

La [GitHub Actions run 38162946752](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38162946752)
è conclusa con SUCCESS sul commit
`47c2d8673650270c4bfec543f50cdd7405460bcd`.
Tutti i dodici job sono riusciti: blocco del catalogo,
Stage01 18 PASS; Stage02 7 PASS/3 FAIL attesi;
Stage03 12 PASS; Stage04 14 PASS/3 FAIL attesi;
Stage05 18 PASS; Stage06 15 PASS/3 FAIL attesi;
Stage07 20 PASS; Stage08 19 PASS/3 FAIL attesi;
Stage09 26 PASS; Stage10 15 PASS/3 FAIL attesi;
Stage11 27 PASS/0 FAIL.

Lo stesso risultato è stato verificato contro 47 finestre
e tre ritardi, con 512 campioni deterministici. Il codice
del helper storico non è stato alterato; Stage12 non iniziato.

## Stadio 12 — DISCOVERY 06: la tabella con sentinel sposta le macinature

Il contratto normativo del ciclo visibile descrive undici
passaggi, numerati da 1 a 11; ognuno porta quattro
coefficienti e un indice di pietra. Il vecchio modulo
`LegacyGrindTableAdapter` conserva tutte le undici regole
ma ne antepone una dodicesima, il sentinel
`(0,0,0,0,0)`. La lettura legacy usa ancora
`GRIND_TABLE_WITH_SENTINEL(step - 1)`, perciò
la macinatura 1 usa il sentinel e le altre macinature
leggono la regola precedente. Non manca alcuna riga:
l'errore è l'indice di lettura.

Il manager `discover06Grind` passa attraverso
`BOOT → DISCOVERY_06_GRIND`, con handler e validazione
dedicati. Vengono acquisiti numero di passaggio, valore
precedente, tre gocce precedenti e cinque pietre.
Il helper applica realmente il calcolo quadratico usando
la vecchia regola, con SAVE già corretto da PATCH 01;
non ci si limita a mostrare una tabella statica.

```text
sbt -batch 'Test / runMain pastafari.Stage12Tests'
```

Firma deliberatamente RED: `22 PASS, 3 FAIL`,
corrispondente esclusivamente alle macinature 1, 6 e 11.
Tutti i coefficienti corretti rimangono fisicamente
nella tabella. I test verificano limiti, aritmetica BigInt,
SAVE, riproducibilità e tutte le patch precedenti.
Non viene anticipata la correzione di Stage13.

### Certificazione nativa dello stadio 12

La [run GitHub Actions 38164763029](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38164763029)
ha concluso SUCCESS sul commit
`58caeee944b2987f344bbb69db93c236e39b5a0f`.
Tutti i tredici job sono riusciti: blocco dei nomi,
Stage01 18 PASS; Stage02 7 PASS/3 FAIL attesi;
Stage03 12 PASS; Stage04 14 PASS/3 FAIL attesi;
Stage05 18 PASS; Stage06 15 PASS/3 FAIL attesi;
Stage07 20 PASS; Stage08 19 PASS/3 FAIL attesi;
Stage09 26 PASS; Stage10 15 PASS/3 FAIL attesi;
Stage11 27 PASS; Stage12 22 PASS/3 FAIL deliberati.

Tre discrepanze calcolate con il medesimo input e
la ricorrenza di SAVE:
macinatura 1 `422 → 68`;
macinatura 6 `1188 → 1002`;
macinatura 11 `2136 → 1974`.
Non è stata introdotta PATCH 06.

## Stadio 13 — PATCH 06: correzione dell'indice del sentinel

La tabella storica `GRIND_TABLE_WITH_SENTINEL` conserva il sentinel
alla posizione zero. `LegacyGrindTableAdapter.legacyGrindRule(step)`
continua deliberatamente ad usare `step-1`: la cicatrice di Stage12
non viene riscritta. La nuova `Patch06GrindWrapper.grindPatch`
attraversa realmente `legacyGrind`, seleziona la regola in
`GRIND_TABLE_WITH_SENTINEL(step)` e ricalcola il valore con
`Patch01SaveWrapper.savePatch`.

Il percorso `BaseMonsterManager.patch06Grind` attraversa
`BOOT → DISCOVERY_06_GRIND → PATCH_06_GRIND` nello
stesso contesto. Il report e la validazione indipendente conservano
entrambe le regole e i rispettivi risultati. I controlli
del test verificano tutti gli undici passi contro regole
normative test-only, casi signed, 512 campioni deterministici,
BigInt oltre 16.000 bit, metrica, ownership e cinque patch precedenti.

```text
sbt -batch 'Test / runMain pastafari.Stage13Tests'
```

Firma attesa: `26 PASS, 0 FAIL`. La suite storica
Stage12 resta `22 PASS, 3 FAIL` intenzionali, mentre il
CI controlla automaticamente anche tutte le regressioni 1–11.

### Certificazione nativa dello stadio 13

La [GitHub Actions run 38165345584](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165345584)
ha concluso SUCCESS sul commit
`53f35b0bd633cd77b9efd2c9bad052fbf24d78b2`.
Tutti i quattordici job sono riusciti: blocco dei nomi canonici,
Stage01 18 PASS; Stage02 7 PASS/3 FAIL intenzionali;
Stage03 12 PASS; Stage04 14 PASS/3 FAIL intenzionali;
Stage05 18 PASS; Stage06 15 PASS/3 FAIL intenzionali;
Stage07 20 PASS; Stage08 19 PASS/3 FAIL intenzionali;
Stage09 26 PASS; Stage10 15 PASS/3 FAIL intenzionali;
Stage11 27 PASS; Stage12 22 PASS/3 FAIL intenzionali;
Stage13 26 PASS, 0 FAIL. Stage14 non è stato iniziato.

## Stadio 14 — DISCOVERY 07: il rango delle permutazioni parte dalla base sbagliata

Il repertorio normativo ordina le 720 permutazioni delle
sei ciotole con ranghi **da 1 a 720**. Il vecchio adattatore
`LegacyPermutationAdapter.oldPermutationUnrank0` riceve
un rango di quella famiglia ma lo interpreta come indice
iniziale **da zero**, facendo avanzare ogni scelta di un posto.
Per il rango 720 il vecchio algoritmo applica il riavvolgimento
modulo 720 e restituisce la prima permutazione invece dell'ultima.

La cicatrice è nel vero helper Scala: esso svolge la
decomposizione fattoriale con una lista temporanea dei sei
identificatori e non richiama il test-only oracle. Il manager
esegue `BOOT → DISCOVERY_07_PERMUTATION`, con contesto,
report immutabile, validazione e metrica per invocazione.

```text
sbt -batch 'Test / runMain pastafari.Stage14Tests'
```

Firma rossa prevista: `20 PASS, 3 FAIL`, sulle
equivalenze normative dei ranghi 1, 2 e 720.
Gli altri test esauriscono tutte le 720 permutazioni,
provano unicità, classi di 120 per primo elemento,
determinismo, rango non valido, integrità di stato,
grandi giorni BigInt e continuità delle patch 01–06.
Non viene introdotta alcuna PATCH 07.

### Certificazione nativa dello stadio 14

La [GitHub Actions run 38166231716](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38166231716)
è terminata con SUCCESS sul commit
`209bd05ce484eb1b128e26a0959a8c80a3c3c832`.
Tutti i quindici job sono riusciti: lock dei nomi;
Stage01 18 PASS; Stage02 7 PASS/3 FAIL attesi;
Stage03 12 PASS; Stage04 14 PASS/3 FAIL attesi;
Stage05 18 PASS; Stage06 15 PASS/3 FAIL attesi;
Stage07 20 PASS; Stage08 19 PASS/3 FAIL attesi;
Stage09 26 PASS; Stage10 15 PASS/3 FAIL attesi;
Stage11 27 PASS; Stage12 22 PASS/3 FAIL attesi;
Stage13 26 PASS; Stage14 20 PASS/3 FAIL deliberati.

I fallimenti della discovery sono esattamente i ranghi
`1`, `2` e `720`. Le 720 permutazioni sono tutte
presenti una sola volta; l'associazione ai ranghi è
storicamente traslata di uno. PATCH 07 non introdotta.

## Stadio 15 — PATCH 07: la base del rango delle permutazioni

L'algoritmo legacy `oldPermutationUnrank0(rank1)` conserva
la cicatrice di Stage14: ogni rango seleziona la permutazione
successiva, e il rango 720 ritorna alla prima. Il wrapper
`Patch07PermutationWrapper.permutationPatch` attraversa
il vero helper storico prima di chiedere il rango `r-1`,
con riavvolgimento corretto all'ingresso 720 per `r=1`.
Non viene copiata né sostituita la decomposizione fattoriale.

`BaseMonsterManager.patch07Permutation` esegue
`BOOT → DISCOVERY_07_PERMUTATION → PATCH_07_PERMUTATION`
nello stesso contesto. Il report contiene sia la
permutazione errata sia quella corretta; il validator
controlla in modo indipendente il rango con la
decomposizione fattoriale 1-based, non attraverso il wrapper.

```text
sbt -batch 'Test / runMain pastafari.Stage15Tests'
```

Firma prevista: `31 PASS, 0 FAIL`. La suite prova
esaustivamente tutti i 720 ranghi del riferimento,
l'inversione del rango, tutti gli input illegali,
2.048 campioni casuali deterministici, la semantica
delle metriche, i report isolati e tutte e sei le
patch precedenti. Stage14 rimane RED per i soli ranghi 1, 2 e 720.

### Certificazione nativa dello stadio 15

La [GitHub Actions run 38166893216](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38166893216)
ha concluso SUCCESS sul commit
`2ad0799b04fb9f5598d962882050c44d1d9abd5a`.
Tutti i sedici job sono riusciti: blocco dei nomi,
Stage01 18 PASS, Stage02 7 PASS/3 FAIL intenzionali,
Stage03 12 PASS, Stage04 14 PASS/3 FAIL intenzionali,
Stage05 18 PASS, Stage06 15 PASS/3 FAIL intenzionali,
Stage07 20 PASS, Stage08 19 PASS/3 FAIL intenzionali,
Stage09 26 PASS, Stage10 15 PASS/3 FAIL intenzionali,
Stage11 27 PASS, Stage12 22 PASS/3 FAIL intenzionali,
Stage13 26 PASS, Stage14 20 PASS/3 FAIL intenzionali,
Stage15 31 PASS/0 FAIL. Nessuna logica di Stage16 anticipata.

## Stadio 16 — DISCOVERY 08: registro delle ciotole in alias

Il calcolo normativo di una mescolatura visibile usa tutte le
sei ciotole precedenti come istantanea immutabile. Il vecchio
`LegacyBowlAliasAdapter.bowlAlias` calcola prima i getti e
sceglie l'ordine dalla PATCH 07, ma fa coincidere `old` e
`next` con lo stesso `Array[BigInt]`. Le posizioni successive
leggono ciotole già modificate. L'errore rimane solo nella
mescolatura; il rango e SAVE sono corretti.

Il manager attraversa `BOOT → DISCOVERY_08_BOWL_ALIAS`,
e il report conserva gli input, l'ordine, i getti e le
uscite storiche. Il test confronta i risultati con una
formula su istantanea congelata e con una ricostruzione
funzionale indipendente dell'alias storico.

```text
sbt -batch 'Test / runMain pastafari.Stage16Tests'
```

Firma intenzionalmente RED: `25 PASS, 3 FAIL`;
i soli tre confronti errati sono l'ordine diretto,
l'ordine inverso e la goccia 46. Sono inclusi tutti i
720 ranghi, 256 campioni deterministici, interi oltre
8192 bit e sette patch precedenti. Non è stata introdotta
la PATCH 08.

### Certificazione nativa dello stadio 16

La [run GitHub Actions 38170838806](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38170838806)
è terminata con SUCCESS sul commit
`1e2ffa32651f1f280853e1592f8aaa16086040ad`.
Tutti i 17 job sono riusciti: lock dei nomi,
Stage01 18 PASS; Stage02 7 PASS/3 FAIL intenzionali;
Stage03 12 PASS; Stage04 14 PASS/3 FAIL intenzionali;
Stage05 18 PASS; Stage06 15 PASS/3 FAIL intenzionali;
Stage07 20 PASS; Stage08 19 PASS/3 FAIL intenzionali;
Stage09 26 PASS; Stage10 15 PASS/3 FAIL intenzionali;
Stage11 27 PASS; Stage12 22 PASS/3 FAIL intenzionali;
Stage13 26 PASS; Stage14 20 PASS/3 FAIL intenzionali;
Stage15 31 PASS; Stage16 25 PASS/3 FAIL intenzionali.

I tre confronti di Stage16 divergono esclusivamente
per ordine diretto, ordine inverso e goccia 46.
La PATCH 08 non è stata introdotta.

## Stadio 17 — PATCH 08: mescolatura da istantanea immutata

La cicatrice dello stadio 16 (`LegacyBowlAliasAdapter.bowlAlias`)
continua a usare lo stesso array per `old` e `next`;
non viene riscritta. La nuova `Patch08BowlWrapper.bowlPatch`
esegue realmente il helper storico e conserva l'ordine
normativo da PATCH 07 e i getti precalcolati. Calcola poi
le sei nuove ciotole in un registro **separato**, leggendo
sempre dai sei valori immutabili dell'ingresso.

Il manager attraversa `BOOT → DISCOVERY_08_BOWL_ALIAS →
PATCH_08_BOWL_FREEZE` nello stesso contesto. Il report
immutabile custodisce entrambe le uscite. Il validator
ricalcola autonomamente le sei equazioni, i getti e il
risultato storico, invece di considerare il wrapper
come prova di se stesso.

```text
sbt -batch 'Test / runMain pastafari.Stage17Tests'
```

Firma prevista: `31 PASS, 0 FAIL`. Copertura:
720 ranghi per la norma e per il validator, 46 gocce
concatenate, 512 campioni signed deterministici,
BigInt oltre 16.000 bit, difese dei contesti e sette
patch precedenti. Stage16 mantiene `25 PASS, 3 FAIL`
intenzionali, senza cancellare la cicatrice.

### Certificazione nativa dello stadio 17

La [GitHub Actions run 38171645454](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38171645454)
ha concluso SUCCESS sul commit
`993e96370f2e2f236efd0346edbbb4ff1a8d74bc`.
Tutti i diciotto job sono riusciti: nomi canonici,
Stage01 18 PASS; Stage02 7 PASS/3 FAIL intenzionali;
Stage03 12 PASS; Stage04 14 PASS/3 FAIL intenzionali;
Stage05 18 PASS; Stage06 15 PASS/3 FAIL intenzionali;
Stage07 20 PASS; Stage08 19 PASS/3 FAIL intenzionali;
Stage09 26 PASS; Stage10 15 PASS/3 FAIL intenzionali;
Stage11 27 PASS; Stage12 22 PASS/3 FAIL intenzionali;
Stage13 26 PASS; Stage14 20 PASS/3 FAIL intenzionali;
Stage15 31 PASS; Stage16 25 PASS/3 FAIL intenzionali;
Stage17 31 PASS/0 FAIL.

Il vecchio array condiviso continua a produrre i
tre fallimenti previsti nello Stage16. La PATCH 08
supera il confronto delle sei ciotole con istantanee
congelate senza introdurre logica del prossimo stadio.

## Stadio 18 — DISCOVERY 09: dodici giri con un caveau obsoleto

Dopo le 46 gocce, la norma richiede dodici mescolature
finali. Ogni giro deve rileggere il risultato del precedente.
Il nuovo adattatore storico `LegacyVaultAdapter.vaultOld`
conserva per errore il **Vector originale** e lo riusa
come `old` in tutti i dodici giri. Il calcolo di un
singolo giro è corretto: SAVE della PATCH 01,
permutazione della PATCH 07 e sei aggiornamenti
simultanei come PATCH 08. Il solo difetto è il
mancato avanzamento del vecchio caveau.

`BaseMonsterManager.discover09Vault` attraversa
`BOOT → DISCOVERY_09_VAULT` nello stesso contesto;
il report immutabile espone tutte le dodici tracce
(`savedSum`, rango, ordine e sei uscite) e il valore
finale. Il validator confronta l'intero registro
alla vera elaborazione legacy. La formula normativa
sui dodici giri consecutivi è test-only.

```text
sbt -batch 'Test / runMain pastafari.Stage18Tests'
```

Firma RED prevista: `27 PASS, 3 FAIL` per
i vettori ordinario, simmetrico e signed.
La suite verifica 720 permutazioni del primo giro,
256 campioni deterministici, BigInt signed oltre
16.000 bit, ownership e tutte le otto patch
precedenti. Nessuna PATCH 09 è introdotta.

### Certificazione nativa della DISCOVERY 09

La [GitHub Actions run 38180656627](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38180656627)
ha concluso SUCCESS su
`7b2c7892873ed7a986ea7fbbfa8572763cfccd91`.
Sono riusciti **19 job su 19**: lock del catalogo
e tutte le suite native Stage01–Stage18.
Stage18 ha la firma storica **27 PASS, 3 FAIL
intenzionali**, limitati ai tre confronti
`ordinario`, `simmetrico` e `signed`.
Tutte le firme storiche degli stadi precedenti
sono rimaste invarianti. La PATCH 09 non è introdotta.

## Stadio 19 — PATCH 09: il caveau avanza a ogni giro

La DISCOVERY 09 conserva il difetto storico:
`LegacyVaultAdapter.vaultOld` rilegge sempre le sei
ciotole iniziali per ciascuna delle dodici mescolature.
La nuova `Patch09VaultWrapper.vaultPatch` attraversa
davvero quel codice storico, ma esegue poi dodici
mescolature consecutive, aggiornando la fotografia
`snapshot` solo dopo aver calcolato tutte le sei
nuove ciotole. Il report rende confrontabili
**tutte e dodici le righe storiche e normative**,
senza mutare l'helper legacy.

`BaseMonsterManager.patch09Vault` gestisce
`BOOT → DISCOVERY_09_VAULT → PATCH_09_VAULT_ROLL`
nello stesso contesto e valida ogni giro
indipendentemente dal wrapper, ricontrollando
anche tutte le prove storiche. La produzione
non dipende dall'oracolo di test.

```text
sbt -batch 'Test / runMain pastafari.Stage19Tests'
```

Firma GREEN prevista: **37 PASS, 0 FAIL**.
La suite include 720 ranghi testati su 12 giri,
512 campioni signed deterministici, BigInt oltre
16.384 bit, input invalidi, prove di integrità
di ogni giro, isolation e le otto patch precedenti.
La firma Stage18 **27 PASS / 3 FAIL** resta
volutamente invariata. Non è introdotta la
futura logica dello Stage20.

### Certificazione nativa dello Stadio 19

La [GitHub Actions run 38181781612](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38181781612)
ha terminato **SUCCESS in tutti i 20 job**
sul commit `06d290255c849ad15069606d6e65fd9c31c58112`.
Stage19 ha eseguito **37 PASS / 0 FAIL**:
720 ingressi coperti su dodici giri, 512 campioni
deterministici signed, numeri oltre 16.384 bit,
validazione indipendente dei record intermedi,
provenienza del vecchio codice e separazione
dell'ownership. Stage18 conserva **27 PASS / 3 FAIL**
intenzionali, e tutte le suite Stage01–Stage17
mantengono la firma storica originaria.
Il catalogo dei nomi è bloccato; Stage20 non è
iniziato.

## Stadio 20 — DISCOVERY 10: la fotografia della goccia 46

L'ordine delle sei ciotole scelto alla **goccia 46**
deve restare disponibile anche dopo le dodici
mescolature finali, perché determina la ciotola
successiva durante la lettura del sugo.
`LegacyOrder46LatchAdapter.orderAt46Latch`
documenta un difetto storico isolato:
la registrazione `captured` è agganciata
all'ordine della goccia **45**, non al vero
ordine della goccia **46**. Gli ordini derivano
entrambi dalla PATCH 07, usando la stessa
riduzione regolare modulo 720 dell'oracolo.

Il report conserva entrambi gli ordini e
il successore legacy. Il manager percorre
`BOOT → DISCOVERY_10_ORDER46_LATCH`;
validator, handler e metrica garantiscono
il percorso storico e l'isolamento del contesto.
La PATCH 10 non viene introdotta.

```text
sbt -batch 'Test / runMain pastafari.Stage20Tests'
```

Firma attesa RED: **26 PASS, 3 FAIL**
per tre confronti normativi sul successore.
720 ranghi, sei ciotole, 1.024 coppie signed
deterministiche, BigInt di oltre 16.000 bit,
input invalidi e nove patch precedenti
sono verificati senza mutare gli stadi 1–19.
