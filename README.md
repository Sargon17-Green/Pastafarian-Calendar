# Calendario pastafariano — linea Scala + italiano

Questo albero nasce da zero per la linea indipendente `Scala + italiano`. Il primo stadio contiene soltanto il catalogo linguistico canonico, un riferimento normativo destinato ai test e una base architetturale neutrale per la futura crescita del mostro.

## Regole della linea

- Tutto il codice eseguibile della linea è Scala.
- Il riferimento normativo di test deriva direttamente dal riferimento incorporato nel prompt di progetto.
- Il codice di produzione non chiama mai il riferimento normativo.
- Nessun risultato, fixture, hash, tabella o log di un'altra implementazione è usato come fonte di verità.
- Il catalogo italiano è indicizzato da `canonicalIndex`; il testo localizzato non partecipa a ranking, unranking, chiavi semantiche o ordinamento normativo.
- In questo stadio non esiste alcuna cicatrice legacy e non esiste codice di patch futuro.

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
Nessun `savePatch` è presente in produzione.

## Prova nativa verificata

Lo stadio 2 è stato compilato ed eseguito su GitHub Actions con Java 17
e Scala 2.13.18, commit `4cb63f84d20bebb8a58934b5b2211811276bffc0`.
La [run 38151729014](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151729014)
è conclusa con successo: `native-stage01` 18 PASS, 0 FAIL;
`native-stage02-discovery` 7 PASS, 3 FAIL intenzionali;
`verify` PASS. Il job di discovery controlla la firma degli errori
invece di scambiare il rosso normativo per un guasto accidentale.
