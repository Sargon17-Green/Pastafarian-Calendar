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
