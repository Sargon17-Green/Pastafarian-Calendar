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

### Certificazione nativa dello Stadio 20

La [GitHub Actions run 38212623612](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212623612)
ha concluso **SUCCESS per tutti i 21 job**
al commit `8dd1253520bccfb5a51fe1a1d08afa3a43c41d26`.
Stage20 mantiene intenzionalmente
**26 PASS / 3 FAIL** per i tre confronti
con il successore normativo della goccia 46;
l'ordine al passo 45 resta distinto
e riproducibile. Le firme native Stage01–Stage19
sono preservate senza nuove regressioni.
Il catalogo è bloccato, PATCH 10 non è iniziata.

## Stadio 21 — PATCH 10: fotografare la vera goccia 46

La `DISCOVERY 10` mantiene un difetto storico
isolato: `LegacyOrder46LatchAdapter.orderAt46Latch`
salva per errore l'ordine della goccia 45.
`Patch10Order46Wrapper.order46Patch` attraversa
davvero quel codice storico e ne conserva i tre
risultati diagnostici; poi aggancia in un Vector
immutabile l'ordine della goccia **46** e sceglie
il successore ciclico della ciotola interrogata
secondo il vero ordine, come prescritto dalla norma.

Il manager attraversa `BOOT → DISCOVERY_10_ORDER46_LATCH
→ PATCH_10_ORDER46_FREEZE` nello stesso contesto.
Il validator indipendente svolge l'unranking
fattoriale e verifica autonomamente entrambi gli
ordini, il successore storico e il successore
corretto. Le dodici mescolature finali del caveau
non modificano il latch della goccia 46.

```text
sbt -batch 'Test / runMain pastafari.Stage21Tests'
```

La suite copre i 720 ranghi, tutti e sei gli ID,
BigInt signed di oltre 16.000 bit, isolamento dei
contesti, falsificazioni e le nove patch
precedenti. La firma Stage20 (26 PASS, tre FAIL
intenzionali) rimane invariata; Stage22 non
viene anticipato.

### Certificazione nativa di Stage21

La [run GitHub Actions 38222151847](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38222151847)
ha terminato con **SUCCESS nei 22 job**, sul commit
`3b3c6f7d4a6d8d861f18d293582a63ae6d2f79c1`.
Stage21 riporta **40 PASS / 0 FAIL**; Stage20
mantiene la firma storica **26 PASS / 3 FAIL
intenzionali**, mentre Stage01–Stage19 preservano
tutte le firme precedenti. L'oracolo resta
test-only; non è stato introdotto lo Stage22.

## Stadio 22 — DISCOVERY 11: il rango distorto nella scelta corta

Il metodo normativo `chooseRankShort` accetta un campione
`X` soltanto se `X <= floor(M/N)*N`, poi seleziona il
rango `((X-1) mod N)+1`; se il limite viene superato,
continua nel flusso in direzione `+1` o `-1` fino
alla prima risposta valida. La cicatrice
`LegacyBiasedPickAdapter.biasedLegacyPick`
salta l'accettazione e usa immediatamente
il primo campione, anche quando è invalido.

`BaseMonsterManager.discover11BiasedPick` attraversa realmente
`BOOT → DISCOVERY_11_BIASED_SHORT_PICK`, pubblicando
il primo campione, il rango legacy e il limite di accettazione.
Il validator controlla l'origine delle informazioni e lo stato
della stessa invocazione. Non vi è correzione anticipata
nel codice di produzione.

```text
sbt -batch 'Test / runMain pastafari.Stage22Tests'
```

Firma storica attesa: **34 PASS, 3 FAIL intenzionali**,
per campione respinto con direzione positiva, negativa e
caso di soglia. La suite verifica 720 cardinalità,
2.048 campioni signed deterministici, BigInt oltre
16.384 bit e la preservazione delle dieci patch precedenti.

### Certificazione nativa della DISCOVERY 11

La [GitHub Actions run 38228272450](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38228272450)
ha concluso SUCCESS per **23 job su 23** sul commit
`13fe8d60508dd4804372f73d2cb340918e2faa5d`.
Stage22 esibisce **34 PASS / 3 FAIL intenzionali**,
limitati a scelta positiva, negativa e soglia.
Le 21 suite precedenti, incluso il loro RED storico,
sono rimaste immutate. PATCH 11 non è introdotta.

## Stadio 23 — PATCH 11: selezione corta senza bias

La scorciatoia legacy `biasedLegacyPick` riduce
direttamente il primo campione modulo `N` e produce
un bias quando `M` non è multiplo di `N`.
`Patch11ShortPickWrapper.shortPickPatch` attraversa
davvero la cicatrice prima di calcolare la selezione
normativa: accetta solo `X <= floor(M/N)*N`,
proseguendo nel flusso con passo `+1` o `-1`
fino al primo campione ammesso.

Il tratto rifiutato è un unico intervallo finale.
Per questo il wrapper computa con aritmetica BigInt
il primo valore accettabile e il numero esatto di
campioni saltati, senza iterare fino a circa
`2^126` volte per famiglie vicine a `M/2`.
È matematicamente equivalente al cammino circolare.
Un validator indipendente verifica anche il rango,
il conteggio degli scarti, la soglia e tutti i dati
storici nello stesso contesto BOOT/DISCOVERY/PATCH.

```text
sbt -batch 'Test / runMain pastafari.Stage23Tests'
```

Firma GREEN prevista: **42 PASS / 0 FAIL**.
I casi comprendono 720 cardinalità, 2.048 campioni
deterministici, test BigInt di oltre 16.384 bit,
rejection multi-campione, salto astronomico,
falsificazioni e regressioni delle dieci patch
precedenti. Stage22 resta atteso RED con
34 PASS / 3 FAIL intenzionali.

### Certificazione nativa dello Stage23

La [GitHub Actions run 38232681790](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38232681790)
ha terminato SUCCESS **24 job su 24** sul commit
`64545b94fbccc90f74faedf658b68e022ea14a54`.
Stage23 ha raggiunto **42 PASS / 0 FAIL**, mentre
Stage22 conserva esattamente **34 PASS / 3 FAIL
intenzionali**. Le suite Stage01–Stage21
preservano le firme native storiche. La PATCH 11
conserva il vecchio rango e il numero dei rifiuti,
inclusi casi BigInt in cui un ciclo non sarebbe
computabile nel tempo utile. Stage24 non iniziato.

## Stadio 24 — DISCOVERY 12: l'anno perde il giorno 5778

La norma accetta un anno con almeno sei divari di
cancello, ciascuno compreso fra 42 e 963 giorni,
e una lunghezza complessiva fra **252 e 5778**
giorni inclusi. La cicatrice
`LegacyYearCeilingAdapter.legacyYearMax` conserva
invece un tetto storico **5777**, che esclude il
giorno estremo ammesso. Si tratta di un errore
di frontiera, non di uno scarto per durata
inferiore o numero insufficiente di cancelli.

La manager `discover12YearCeiling` percorre
`BOOT → DISCOVERY_12_YEAR_CEILING` nello stesso
contesto, pubblica tutti i divari immutabili,
la durata esatta, il tetto storico e il
verdetto legacy. Il validator ricostruisce
la somma e il verdetto senza chiamare l'oracolo;
il test normativo usa soltanto le costanti
test-only dell'oracolo. Nessuna PATCH 12
viene anticipata.

```text
sbt -batch 'Test / runMain pastafari.Stage24Tests'
```

Firma attesa: **33 PASS, 3 FAIL intenzionali**
su tre strutture sintetiche diverse, ciascuna
di 5778 giorni: sei, sette e otto divari.
Sono provati 921 casi di sei divari sotto
soglia, 2048 combinazioni deterministiche,
input invalidi, isolamenti e tutte le undici
patch precedenti.

### Certificazione nativa dello Stadio 24

La [run GitHub Actions 38239105413](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239105413)
ha terminato con **SUCCESS per 25 job su 25**
sul commit `c7f5647800f02dc2f90dd694a6cce66a51f6a663`.
La firma Stage24 è **33 PASS / 3 FAIL intenzionali**
(sei, sette e otto divari esattamente di 5778 giorni);
tutte le firme Stage01–Stage23 restano invariate.
Il codice di produzione non consulta l'oracolo;
PATCH 12 non è anticipata.

## Stadio 25 — PATCH 12: il confine annuale comprende 5778

La DISCOVERY 12 conserva il vecchio limite
`LEGACY_YEAR_MAX = 5777`; l'adapter storico
viene attraversato realmente dalla
`Patch12YearCeilingWrapper.yearMaxPatch`.
Il percorso corretto include un anno di
**5778 giorni**, se formato da almeno sei
divari validi 42..963 e con durata non
inferiore a 252 giorni. Il report pubblica
separatamente i giudizi legacy e normativo,
senza sovrascrivere la cicatrice storica.

Il manager esegue
`BOOT → DISCOVERY_12_YEAR_CEILING → PATCH_12_YEAR_CEILING`.
Il validator indipendente ricostruisce la
somma BigInt e i due predicati di accettazione
su ciascuna invocazione. La stessa prova
controlla le candidate di sei, sette e otto
divari sommate a 5778 giorni.

```text
sbt -batch 'Test / runMain pastafari.Stage25Tests'
```

Firma GREEN attesa: **42 PASS, 0 FAIL**.
La suite copre 922 valori del divario, 1.024
vettori riproducibili, 4.096 vettori aggiuntivi,
rifiuto di input invalidi, intarsi BigInt,
falsificazione dello stato, regressione delle
undici patch precedenti e il confine annuale.
La firma storica dello Stage24 rimane
**33 PASS e 3 FAIL intenzionali**.

### Certificazione nativa di Stage25

La [run GitHub Actions 38241773207](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38241773207)
ha concluso **SUCCESS in tutti i 26 job** sul commit
`2aa1334193fbb4afd9f804e9133ba25ace4ae915`. Stage25 ha riportato **42 PASS e 0 FAIL**.
La firma Stage24 continua a riportare
**33 PASS, 3 FAIL intenzionali**; tutte le firme
Stage01–Stage23 rimangono invariate.
La cicatrice dell'anno 5777 è riproducibile,
ma il giudizio normativo include 5778.
Non è stata anticipata DISCOVERY 13.

## Stadio 26 — DISCOVERY 13: il salto annuale prende una scorciatoia

`LegacyYearJumpAdapter.oldJumpGuess` riproduce un difetto
storico del percorso di ricerca annuale: calcola l'anno
ipotizzando blocchi consecutivi sempre di **5778 giorni**,
senza attraversare gli anni di lunghezza variabile.
Il contratto canonico, invece, sposta l'anno 5000
attraverso i successivi anni determinati dai veri
cancelli, con intervalli `(open, close]`.

Per non anticipare la PATCH 13, l'adapter opera su
una finestra **sintetica** di durate annuali valide
(252–5778 giorni), e conserva sia la finestra
sia l'offset/inizio/fine inventati dal salto.
La produzione non utilizza l'oracolo del calendario.
`BaseMonsterManager.discover13YearJump` espone la
cicatrice dopo `BOOT → DISCOVERY_13_YEAR_JUMP`.

```text
sbt -batch 'Test / runMain pastafari.Stage26Tests'
```

Firma RED attesa: **38 PASS / 3 FAIL**
intenzionali in avanti, indietro e sul confine di
un cancello sintetico. La suite confronta la ricerca
corretta sequenziale test-only, date assolute BigInt,
2.048 vettori deterministici, 1.024 offset e tutte
le dodici patch storiche. Nessuna PATCH 13 anticipata.

### Certificazione nativa di DISCOVERY 13

La [GitHub Actions run 38245718502](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38245718502)
ha terminato **SUCCESS per tutti i 27 job** sul commit
`727cfa5debaed924ed4b3818986699f32a1f34da`.
Stage26 ha eseguito **38 PASS e tre FAIL intenzionali**
(limitati ad avanti, indietro e confine di porta);
tutte le firme Stage01–Stage25 sono rimaste invarianti.
L'ipotesi errata degli anni lunghi sempre 5778
giorni rimane isolata come cicatrice diagnostica;
PATCH 13 non è introdotta.

## Stadio 27 — PATCH 13 (salto sui veri cancelli annuali)

La durata massima di 5778 giorni **non** è una misura fissa degli anni. La
DISCOVERY 13 ha lasciato visibile il salto legacy basato su 5778 giorni per
anno e le divergenze intenzionali `avanti`, `indietro` e `porta`.

`Patch13YearJumpWrapper.yearJumpPatch` esegue lo stesso helper storico,
conserva i suoi campi nel report, quindi percorre i confini annuali effettivi
sulla finestra diagnostica sintetica. L'intervallo appartiene all'anno se
`open < target <= close`: l'ultimo giorno è incluso, la frontiera di
apertura appartiene all'anno precedente. Per i giorni fuori dai vettori
sintetici non viene inventata alcuna estensione.

L'handler produce la traccia `BOOT → DISCOVERY_13_YEAR_JUMP →
PATCH_13_YEAR_JUMP` nello stesso contesto; il validator ricostruisce
separatamente i confini ed esige la conservazione della cicatrice. Tutta la
produzione è in Scala e non importa `NormativeOracle`.

La [run 38247877764](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38247877764)
ha conclusione **success**: 28/28 job, Stage27 39 PASS/0 FAIL;
Stage26 conserva 38 PASS/3 FAIL intenzionali. Quest'ultima prova riguarda
la navigazione di un insieme di anni sintetici, non certifica ancora il
calcolo end-to-end dell'anno 5000.

```
sbt -batch 'Test / runMain pastafari.Stage27Tests'
```

## Stadio 28 — DISCOVERY 14 (rango BigInt di una lista virtuale)

La scelta di un candidato in una sequenza virtuale di indici di cancello
non deve convertire il rango 1-based da BigInt a Int. L'adapter storico
`VirtualLegacyListAdapter.oldVirtualGateAt` fa esattamente questo:
`rank1.toInt` trattiene solo i 32 bit bassi signed; la lista sintetica
diagnostica è definita da `firstGateIndex + (rank1-1)*gateStride`.
La cardinalità è BigInt, non viene allocata una lista materiale.

I tre test di confronto intenzionalmente RED usano i ranghi
2^31, 2^32 e 2^64+1. Il codice mantiene l'output storico,
lo stato posseduto da ogni invocazione e un validator indipendente
dell'errore. Il confronto normativo vive solo nei test. Questo esercizio
non equivale a una implementazione dei veri cancelli del calendario
né avvia la PATCH 14.

Comando nativo: `sbt -batch 'Test / runMain pastafari.Stage28Tests'`.

Firma prevista: 41 PASS e 3 FAIL intenzionali; tutti i job
storici rimangono necessari per certificare il nuovo commit.

### Certificazione nativa di Stage28

La [run 38253085873](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38253085873)
ha conclusione SUCCESS su tutti i **29 job**, commit
`5b783ea3cddef448ea6363d995fb0e3398f3a8a6`. La prova Stage28
registra **41 PASS e 3 FAIL intenzionali** esattamente ai tre ranghi
sopra Int.MaxValue; Stage01–Stage27 conservano le firme precedenti.
La correzione resta di competenza di Stage29 PATCH 14.

## Stadio 29 — PATCH 14 (ranking virtuale BigInt senza troncamento)

Il difetto della DISCOVERY 14 rimane intatto in
`VirtualLegacyListAdapter.oldVirtualGateAt`: `rank1.toInt` tronca
il rango a 32 bit signed. `Patch14VirtualGateWrapper.virtualGatePatch`
attraversa davvero quel percorso legacy e pubblica poi
`firstGateIndex + (rank1 - 1) * gateStride` usando BigInt
per l'intero calcolo, senza allocare la lista virtuale.

Il dispatcher esegue `BOOT → DISCOVERY_14_VIRTUAL_GATE_LIST →
PATCH_14_VIRTUAL_GATE_LIST` nel medesimo contesto. Lo stato storico
è immutato e il report espone entrambi gli indici. Un validator
indipendente verifica sia la cicatrice modulo 2^32 sia l'identità
aritmetica del rango 1-based.

La suite `sbt -batch 'Test / runMain pastafari.Stage29Tests'`
contiene **55 controlli**, inclusi oltre 10.000
vettori interni riproducibili, ranghi/indici signed di oltre
16384 bit, falsificazioni di stato e regressione delle 13 patch
precedenti. Stage28 rimane RED storico esattamente 41/3.
Nessuna produzione dei cancelli reali o Stage30 è anticipata.

### Certificazione nativa dello Stadio 29

La [run 38256237425](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38256237425),
commit `92b2fcaad104fe7152d1461585d9f5c35291a60c`,
è terminata con **SUCCESS in tutti i 30 job**:
Stage29 **55 PASS / 0 FAIL** e Stage28
**41 PASS / 3 FAIL intenzionali**. Un caso di mutazione
silenziosa del passo a rango 1 è stato individuato dai test:
la DISCOVERY conserva ora una fotografia dei quattro input e
la PATCH con il validator la verifica prima della pubblicazione.
Le suite Stage01–Stage27 mantengono le firme precedenti.

## Stadio 30 — DISCOVERY 15 (tessitura rieletta ogni giorno)

La norma seleziona una **unica** tessitura dei mesi a partire dalla
salsa del primo giorno dell'anno e usa quella stessa sequenza per
tutti i giorni successivi. La cicatrice
`LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately`
usa erroneamente `1 + ((rank-1+dayOffset) mod N)` al posto
del rango annuale costante.

La dimostrazione usa soltanto una famiglia sintetica *lessicografica*
di tre tessiture legali di 252 giorni, ciascuna con tre mesi di 84
giorni. Sono verificate la cardinalità, la legalità di apertura e
chiusura dei mesi, l'ordine rigoroso, la ripetibilità, la proprietà
dei dati per invocazione e la firma dei guasti. Il riferimento del
rango fisso vive solo nei test; la selezione vera mediante salsa e
famiglia `WeavingFamily` non viene riprodotta in produzione in
questa fase.

Comando: `sbt -batch 'Test / runMain pastafari.Stage30Tests'`.
Risultato intenzionale: **53 PASS e 3 FAIL**, precisamente ai
casi `rango2_giorno1`, `rango3_giorno1` e
`rango3_giorno2`. La PATCH15 rimane futura; tutte le PATCH1–14
restano disponibili nel manager.

### Certificazione nativa di Stage30

La [run GitHub Actions 38260196811](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38260196811)
sul commit `b6ed673666bcae8b0e02bffb6e09d42cc5900e23`
ha conclusione **SUCCESS in 31/31 job**, con **53 PASS e 3 FAIL
intenzionali** nello Stage30. Stage29 conserva 55 PASS/0 FAIL
e tutte le firme anteriori rimangono previste. La fase
successiva è Stage31 PATCH15; non è ancora implementata.

## Stadio 31 — PATCH 15 (tessitura mensile annuale unica)

La selezione corretta deve usare un **solo rango annuale** e la
**stessa tessitura** per ogni posizione quotidiana. Il wrapper
`Patch15MonthWeavingWrapper.daywiseWeavingPatch` attraversa
davvero `LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately`
mantenendo il risultato sbagliato, poi usa soltanto
`candidates(yearRank1 - 1)` per identificare il mese e il giorno
del mese, contando le occorrenze dell'ID fino al giorno richiesto.

La trace nella stessa invocazione e' `BOOT → DISCOVERY_15 →
PATCH_15`. Il validator indipendente ricostruisce la scelta legacy,
la sequenza annuale e il contatore discontinuo di ogni mese.
Verifica inoltre la snapshot dei candidati e del rango originario
e rifiuta manipolazioni dello stato.

`sbt -batch 'Test / runMain pastafari.Stage31Tests'`
esegue 66 controlli, fra cui l'intera annata di 252 giorni
per tre ranghi, oltre 4096 vettori deterministici su 24 tessiture,
mesi di lunghezza 123, 47 mesi, alterazioni dei campi e regressioni
delle PATCH01–14. Stage30 conserva le tre divergenze intenzionali
mentre Stage31 e' GREEN. L'esercizio usa famiglie sintetiche fornite
dal chiamante; non dichiara completata la scelta canonica via salsa.

### Certificazione nativa dello Stage31

Il workflow [GitHub Actions 38262934855](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38262934855)
sul commit `8e1183e48e88aa54431692e64c6c5723879140b7`
si e' concluso **SUCCESS per 32/32 job**, con **66 PASS/0 FAIL**
nella suite Stage31. La suite precedente Stage30 conserva
**53 PASS e tre FAIL intenzionali** e le altre firme storiche
sono state confermate. Il limite di 5778 giorni e' incluso
e le prove di regressione delle fasi 29/30 sono state adattate
per preservare i loro certificati mentre avanza CURRENT_STAGE.
La correzione usa candidati sintetici, non ancora la
generazione completa delle tessiture dal calcolo canonico.

## Stadio 32 — DISCOVERY 16 (giorno mensile erroneamente contiguo)

Il calendario normativo conta il giorno del mese come il numero
di occorrenze dello stesso ID mese nel **prefisso** della tessitura
annuale. Il percorso storico
`LegacyContiguousMonthDayAdapter.oldContiguousMonthDayGuess`
presume invece che tutti i giorni precedenti appartengano ai mesi
già terminati. Sottrae quindi la somma delle durate dei mesi
precedenti al giorno assoluto dell'anno, producendo perfino
giorni mensili negativi quando i mesi sono intercalati.

La DISCOVERY 16 non modifica PATCH15 e non seleziona una nuova
tessitura per giorno. Riceve una tessitura sintetica già scelta,
lecita, di 252..5778 giorni e 3..47 mesi da 4..123 giorni;
verifica l'ordine di apertura e chiusura, preserva la cicatrice,
l'istantanea di input, la trace e il validator indipendente.

`sbt -batch 'Test / runMain pastafari.Stage32Tests'`
verifica 58 condizioni che passano e tre divergenze
intenzionali: `C giorno2`, `C giorno3` e `B giorno1`.
L'oracolo a prefisso è confinato ai test. Nessuna PATCH16
o costruzione canonica delle tessiture dalla salsa è anticipata.

### Certificazione nativa dello Stage32

La [run GitHub Actions 38268359013](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38268359013)
sul commit `b138a00a997cbba43c93dbf7169ab4bd3739e969`
ha superato **33/33 job**. La suite Stage32 ha conservato la firma
**58 PASS/3 FAIL intenzionali**, con divergenze esattamente
nei casi `C giorno2`, `C giorno3`, `B giorno1`.
Stage31 continua a passare 66/66 e le firme delle suite
precedenti sono conservate. Il test di confine è stato
corretto per rifiutare solo mesi oltre 123 giorni; un
precedente errore di download sbt in un runner non si
è ripetuto nella run certificata.

## Stadio 33 — PATCH 16 (giorno del mese da prefisso reale)

La scelta corretta usa la tessitura annuale valida e già fissata.
`Patch16ContiguousMonthDayWrapper.contiguousMonthDayPatch`
chiama prima **davvero** il legacy `oldContiguousMonthDayGuess`
per preservare il vecchio indice contiguo, quindi determina il
mese tramite `annualWeaving(dayOffset)` e conta le sue occorrenze
nei giorni `0..dayOffset`. Non presume mai la contiguità.

Il dispatcher percorre `BOOT → DISCOVERY_16 → PATCH_16`
nella stessa invocazione. Il report pubblica valore storico,
valore corretto, ID mese, offset, durate, trace e status.
Il validator indipendente ricostruisce sia la cicatrice
contigua sia il conteggio del prefisso, e confronta gli
input con la snapshot originale prima di accettare output.

`sbt -batch 'Test / runMain pastafari.Stage33Tests'`
contiene **65 controlli** con copertura esaustiva dei
252 giorni per tre tessiture, 4096 vettori pseudo-casuali
riproducibili, 47 mesi e limite 5778 giorni, alterazioni
maliziose del contesto, isolamento di manager e regressioni
delle 15 patch precedenti. Stage32 rimane RED storico
con esattamente tre divergenze; Stage33 è GREEN.

Come le fasi vicine, lo scenario è sintetico e usa sequenze
annuali già selezionate. L'integrazione completa della salsa
e della famiglia canonica non è dichiarata finita.

### Certificazione nativa dello Stage33

La [run GitHub Actions 38273709294](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38273709294)
sul commit `e9b998203355ac6f2df50a39d8c2ff106d0cd1f6`
si è conclusa **SUCCESS in 34/34 job**, con **65 PASS e 0 FAIL**
nella suite PATCH16. La DISCOVERY16 mantiene la firma
**58 PASS e 3 FAIL intenzionali**, mentre Stage31 conserva
66 PASS/0 FAIL e tutte le suite pregresse le proprie firme.

I tre guasti storici sono riprodotti nei risultati legacy,
non corretti a posteriori. Il contatore vero usa l'occorrenza
dell'ID nel prefisso annuale senza ipotizzare mesi contigui.
Questa verifica riguarda una tessitura sintetica valida già
selezionata e non rivendica l'integrazione della salsa normativa.

## Stadio 34 — DISCOVERY 17 (nomi dei mesi con rimpiazzo)

La struttura canonica assegna ai mesi nomi **distinti** da un
catalogo congelato di 47. I vettori di nomi sono ordinati
lessicograficamente con rango 1-based e cardinalità
`47!/(47-m)!`, dove `3 <= m <= 47`. La selezione normativa
usa `SealMonthNames=33` e unrank delle disposizioni distinte.

La cicatrice
`LegacyDuplicatedMonthNameAdapter.oldMonthNameDuplicated`
usa invece una decomposizione del rango in **base 47 con
rimpiazzo**, senza rimuovere i nomi già scelti; può quindi
restituire `[1,1,1]` per tre mesi invece del vettore normativo
`[1,2,3]`. Il numero di mesi e il rango vengono convalidati
sul dominio **normativo** decrescente, senza estendere
artificialmente lo spazio di selezione.

Il manager attraversa `BOOT → DISCOVERY_17_DUPLICATED_MONTH_NAME`;
report, snapshot, trace, metriche e validator indipendente
preservano l'output storico. La suite Stage34 contiene **63
PASS e tre FAIL intenzionali** nei casi di rango 1/2 per tre
mesi e rango 1 per 47 mesi, oltre a 4096 vettori deterministici,
ranghi oltre 128 bit, limiti del catalogo e regressioni
delle precedenti 16 patch.

La riparazione con unrank senza rimpiazzo è rinviata
esclusivamente a Stage35 PATCH17. La produzione non deriva
ancora il rango dalla salsa normativa.

### Certificazione nativa dello Stage34

La [run GitHub Actions 38279304043](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38279304043),
commit `c2259e5c15693cfdc0ffa3640976705a2c0d6094`,
ha superato **35/35 job**. La firma Stage34 è
**63 PASS e tre FAIL intenzionali**, esattamente per
`rango1_tre_mesi`, `rango2_tre_mesi` e
`rango1_47_mesi`. Stage33 mantiene 65 PASS/0 FAIL
e tutte le suite storiche rimangono valide.

La suite iniziale aveva una parentesizzazione errata
dell'operatore BigInt `<<` e un caso di test che
collocava il riporto base47 al rango 2209 anziché 2210:
entrambi sono stati corretti senza modificare il legacy.
Una diversa run aveva inoltre un fallimento di recupero
di sbt su GitHub Actions, non riprodotto nella certificazione.

La selezione resta diagnostica; la PATCH17 senza ripetizioni
e il rango ricavato dalla salsa attendono le fasi successive.

## Stadio 35 — PATCH17 (nomi dei mesi senza ripetizioni)

La PATCH17 corregge la selezione dei nomi mensili scegliendo
un vettore di `m=3..47` indici **distinti** da 47 nomi
canonici, rispettando l'ordinamento lessicografico 1-based di
`P(47,m)=47!/(47-m)!` candidati. Il rango BigInt non viene
troncato né convertito in un Int tranne i singoli indici di
selezione dimostrabilmente compresi in `0..46`.

Il wrapper `monthNameDistinctPatch` invoca realmente
`oldMonthNameDuplicated`, pubblica il risultato storico
con ripetizioni e in parallelo elimina dalla lista dei nomi
disponibili ciascun indice scelto dall'unrank corretto.
La trace `BOOT → DISCOVERY_17 → PATCH_17` opera nella stessa
invocazione. Validator indipendente, snapshot, flag e metriche
impediscono manipolazioni e contaminazioni fra richieste.

La suite Stage35 contiene **71 PASS/0 FAIL** attesi:
primo/ultimo rango per tutti i conteggi mensili, 4096
campioni rispetto all'oracolo test-only, altri 4096 con
inversione del rango, 512 ranghi oltre 128 bit, controlli
di unicità e ordinamento, mutazioni del contesto e
regressioni delle 16 patch precedenti. Stage34 mantiene
**63 PASS e tre FAIL intenzionali** e il catalogo
immutabile di 47 nomi resta invariato.

Questa fase usa un rango già scelto dal chiamante:
la salsa annuale, le famiglie complete e l'integrazione
della data finale non sono dichiarate terminate.
