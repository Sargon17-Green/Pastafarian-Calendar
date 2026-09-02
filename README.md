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
